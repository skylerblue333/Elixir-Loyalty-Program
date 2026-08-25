defmodule SkyLoyalty.CLI do
  @moduledoc false

  def main(["demo"]) do
    ledger = SkyLoyalty.new()

    with {:ok, ledger, earned} <- SkyLoyalty.apply(ledger, "tx-001", "member-001", :earn, 250),
         {:ok, ledger, redeemed} <- SkyLoyalty.apply(ledger, "tx-002", "member-001", :redeem, 75) do
      IO.puts("earned=#{earned.points} balance=#{earned.balance}")
      IO.puts("redeemed=#{redeemed.points} balance=#{redeemed.balance}")
      IO.puts("summary=#{inspect(SkyLoyalty.summary(ledger), charlists: :as_lists)}")
    else
      {:error, reason} -> fail(reason)
    end
  end

  def main(["validate", transaction_id, member_id, operation, points_text]) do
    operation = parse_operation(operation)

    with {:ok, points} <- parse_points(points_text),
         {:ok, _ledger, result} <- SkyLoyalty.apply(SkyLoyalty.new(), transaction_id, member_id, operation, points) do
      IO.puts("accepted transaction_id=#{result.transaction_id} member_id=#{result.member_id} operation=#{result.operation} balance=#{result.balance}")
    else
      {:error, reason} -> fail(reason)
    end
  end

  def main(_args) do
    IO.puts("Sky Loyalty Core (engineering beta)")
    IO.puts("usage: sky_loyalty demo | validate <transaction_id> <member_id> <earn|redeem|adjust> <points>")
  end

  defp fail(reason) do
    IO.puts(:stderr, "error=#{reason}")
    System.halt(1)
  end

  defp parse_operation("earn"), do: :earn
  defp parse_operation("redeem"), do: :redeem
  defp parse_operation("adjust"), do: :adjust
  defp parse_operation(_), do: :invalid

  defp parse_points(value) do
    case Integer.parse(value) do
      {points, ""} -> {:ok, points}
      _ -> {:error, "points must be an integer"}
    end
  end
end
