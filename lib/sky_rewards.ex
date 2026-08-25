defmodule SkyRewards do
  @moduledoc """
  Deterministic reward-policy adapter over `SkyLoyalty`.

  Policies map bounded caller-defined event types to positive point awards. Applying an
  event creates a deterministic loyalty transaction ID and delegates balance safety and
  duplicate protection to `SkyLoyalty`.

  This module does not move money, verify purchases, contact partners, or prove that a
  caller-supplied reward event actually occurred.
  """

  @max_rules 100
  @max_points_per_award 1_000_000
  @id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/
  @event_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:-]{0,47}$/

  defstruct rules: %{}

  @type t :: %__MODULE__{rules: %{optional(String.t()) => pos_integer()}}

  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(rules) when is_map(rules) do
    with :ok <- validate_rule_count(rules),
         :ok <- validate_rules(rules) do
      {:ok, %__MODULE__{rules: Map.new(rules)}}
    end
  end

  def new(_rules), do: {:error, "rules must be a map"}

  @spec quote(t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def quote(%__MODULE__{} = policy, event_type) do
    with :ok <- validate_event_type(event_type),
         {:ok, points} <- fetch_rule(policy, event_type) do
      {:ok,
       %{
         event_type: event_type,
         points: points,
         monetary_value_assigned: false,
         external_event_verified: false
       }}
    end
  end

  @spec apply(t(), SkyLoyalty.t(), String.t(), String.t(), String.t()) ::
          {:ok, SkyLoyalty.t(), map()} | {:error, String.t()}
  def apply(%__MODULE__{} = policy, %SkyLoyalty{} = ledger, event_id, member_id, event_type) do
    with :ok <- validate_id("event_id", event_id),
         :ok <- validate_id("member_id", member_id),
         :ok <- validate_event_type(event_type),
         {:ok, points} <- fetch_rule(policy, event_type),
         transaction_id <- transaction_id(event_id),
         {:ok, next_ledger, loyalty_result} <-
           SkyLoyalty.apply(ledger, transaction_id, member_id, :earn, points) do
      {:ok, next_ledger,
       %{
         event_id: event_id,
         event_type: event_type,
         member_id: member_id,
         points: points,
         transaction_id: transaction_id,
         balance: loyalty_result.balance,
         reward_applied: true,
         monetary_value_assigned: false,
         external_event_verified: false
       }}
    end
  end

  @spec rules(t()) :: map()
  def rules(%__MODULE__{} = policy), do: Map.new(policy.rules)

  defp validate_rule_count(rules) do
    if map_size(rules) <= @max_rules,
      do: :ok,
      else: {:error, "rules may contain at most #{@max_rules} event types"}
  end

  defp validate_rules(rules) do
    Enum.reduce_while(rules, :ok, fn {event_type, points}, :ok ->
      case validate_rule(event_type, points) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_rule(event_type, points) do
    with :ok <- validate_event_type(event_type) do
      if is_integer(points) and points in 1..@max_points_per_award,
        do: :ok,
        else: {:error, "reward points must be an integer between 1 and #{@max_points_per_award}"}
    end
  end

  defp validate_event_type(event_type) when is_binary(event_type) do
    if Regex.match?(@event_pattern, event_type),
      do: :ok,
      else: {:error, "event_type must be 1-48 safe characters"}
  end

  defp validate_event_type(_event_type), do: {:error, "event_type must be a string"}

  defp validate_id(name, value) when is_binary(value) do
    if Regex.match?(@id_pattern, value),
      do: :ok,
      else: {:error, "#{name} must be 1-64 safe characters"}
  end

  defp validate_id(name, _value), do: {:error, "#{name} must be a string"}

  defp fetch_rule(%__MODULE__{rules: rules}, event_type) do
    case Map.fetch(rules, event_type) do
      {:ok, points} -> {:ok, points}
      :error -> {:error, "event_type has no configured reward rule"}
    end
  end

  defp transaction_id(event_id) do
    digest = :crypto.hash(:sha256, event_id) |> Base.encode16(case: :lower) |> binary_part(0, 32)
    "reward:#{digest}"
  end
end
