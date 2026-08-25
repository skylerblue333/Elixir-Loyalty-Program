defmodule SkyLoyaltyTest do
  use ExUnit.Case, async: true

  test "earns and redeems points deterministically" do
    ledger = SkyLoyalty.new()

    assert {:ok, ledger, %{balance: 200}} =
             SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 200)

    assert {:ok, ledger, %{balance: 125}} =
             SkyLoyalty.apply(ledger, "tx-2", "member-1", :redeem, 75)

    assert {:ok, 125} = SkyLoyalty.balance(ledger, "member-1")
    assert %{members: 1, transactions: 2, total_points: 125} = SkyLoyalty.summary(ledger)
  end

  test "rejects duplicate transaction ids without mutating the ledger" do
    ledger = SkyLoyalty.new()
    assert {:ok, ledger, _} = SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 100)

    assert {:error, "transaction_id already applied"} =
             SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 100)

    assert {:ok, 100} = SkyLoyalty.balance(ledger, "member-1")
  end

  test "rejects redemption that exceeds the balance" do
    ledger = SkyLoyalty.new()
    assert {:ok, ledger, _} = SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 50)

    assert {:error, "insufficient points"} =
             SkyLoyalty.apply(ledger, "tx-2", "member-1", :redeem, 51)

    assert {:ok, 50} = SkyLoyalty.balance(ledger, "member-1")
  end

  test "supports bounded positive and negative adjustments" do
    ledger = SkyLoyalty.new()

    assert {:ok, ledger, %{balance: 100}} =
             SkyLoyalty.apply(ledger, "tx-1", "member-1", :adjust, 100)

    assert {:ok, ledger, %{balance: 60}} =
             SkyLoyalty.apply(ledger, "tx-2", "member-1", :adjust, -40)

    assert {:error, "balance cannot become negative"} =
             SkyLoyalty.apply(ledger, "tx-3", "member-1", :adjust, -61)

    assert {:ok, 60} = SkyLoyalty.balance(ledger, "member-1")
  end

  test "enforces identifiers, operation and point limits" do
    ledger = SkyLoyalty.new()
    assert {:error, _} = SkyLoyalty.apply(ledger, "bad id", "member-1", :earn, 1)
    assert {:error, _} = SkyLoyalty.apply(ledger, "tx-1", "", :earn, 1)
    assert {:error, _} = SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 0)
    assert {:error, _} = SkyLoyalty.apply(ledger, "tx-1", "member-1", :invalid, 1)
  end

  test "caps balances at one billion points" do
    ledger = SkyLoyalty.new()
    assert {:ok, ledger, _} = SkyLoyalty.apply(ledger, "tx-1", "member-1", :earn, 1_000_000_000)
    assert {:error, _} = SkyLoyalty.apply(ledger, "tx-2", "member-1", :adjust, 1)
    assert {:ok, 1_000_000_000} = SkyLoyalty.balance(ledger, "member-1")
  end
end
