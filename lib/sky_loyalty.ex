defmodule SkyLoyalty do
  @moduledoc """
  Bounded, deterministic loyalty-points ledger primitives.

  The ledger is process-local data. It does not persist balances or move money.
  """

  @max_points 1_000_000_000
  @id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/

  defstruct balances: %{}, transactions: MapSet.new()

  @type t :: %__MODULE__{balances: %{optional(String.t()) => non_neg_integer()}, transactions: MapSet.t(String.t())}
  @type operation :: :earn | :redeem | :adjust

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec balance(t(), String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
  def balance(%__MODULE__{} = ledger, member_id) do
    with :ok <- validate_id("member_id", member_id) do
      {:ok, Map.get(ledger.balances, member_id, 0)}
    end
  end

  @spec apply(t(), String.t(), String.t(), operation(), integer()) ::
          {:ok, t(), map()} | {:error, String.t()}
  def apply(%__MODULE__{} = ledger, transaction_id, member_id, operation, points) do
    with :ok <- validate_id("transaction_id", transaction_id),
         :ok <- validate_id("member_id", member_id),
         :ok <- validate_points(operation, points),
         :ok <- ensure_new_transaction(ledger, transaction_id),
         {:ok, next_balance} <- next_balance(Map.get(ledger.balances, member_id, 0), operation, points) do
      next = %__MODULE__{
        ledger
        | balances: Map.put(ledger.balances, member_id, next_balance),
          transactions: MapSet.put(ledger.transactions, transaction_id)
      }

      {:ok, next,
       %{
         transaction_id: transaction_id,
         member_id: member_id,
         operation: operation,
         points: points,
         balance: next_balance
       }}
    end
  end

  @spec summary(t()) :: map()
  def summary(%__MODULE__{} = ledger) do
    total_points = Enum.reduce(ledger.balances, 0, fn {_member, points}, acc -> acc + points end)

    %{
      members: map_size(ledger.balances),
      transactions: MapSet.size(ledger.transactions),
      total_points: total_points
    }
  end

  defp validate_id(name, value) when is_binary(value) do
    if Regex.match?(@id_pattern, value), do: :ok, else: {:error, "#{name} must be 1-64 safe characters"}
  end

  defp validate_id(name, _value), do: {:error, "#{name} must be a string"}

  defp validate_points(operation, points) when operation in [:earn, :redeem] and is_integer(points) do
    if points in 1..@max_points, do: :ok, else: {:error, "points must be between 1 and #{@max_points}"}
  end

  defp validate_points(:adjust, points) when is_integer(points) do
    if points != 0 and abs(points) <= @max_points,
      do: :ok,
      else: {:error, "adjust points must be non-zero and within +/-#{@max_points}"}
  end

  defp validate_points(operation, _points) when operation in [:earn, :redeem, :adjust],
    do: {:error, "points must be an integer"}

  defp validate_points(_operation, _points), do: {:error, "operation must be earn, redeem, or adjust"}

  defp ensure_new_transaction(%__MODULE__{transactions: transactions}, transaction_id) do
    if MapSet.member?(transactions, transaction_id),
      do: {:error, "transaction_id already applied"},
      else: :ok
  end

  defp next_balance(current, :earn, points), do: bounded_balance(current + points)

  defp next_balance(current, :redeem, points) do
    if points > current, do: {:error, "insufficient points"}, else: {:ok, current - points}
  end

  defp next_balance(current, :adjust, points), do: bounded_balance(current + points)

  defp bounded_balance(value) when value < 0, do: {:error, "balance cannot become negative"}
  defp bounded_balance(value) when value > @max_points, do: {:error, "balance exceeds #{@max_points} point limit"}
  defp bounded_balance(value), do: {:ok, value}
end
