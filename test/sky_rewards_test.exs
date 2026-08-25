defmodule SkyRewardsTest do
  use ExUnit.Case, async: true

  test "quotes configured rewards without assigning monetary value" do
    assert {:ok, policy} = SkyRewards.new(%{"course.complete" => 250})

    assert {:ok, quote} = SkyRewards.quote(policy, "course.complete")
    assert quote.points == 250
    assert quote.monetary_value_assigned == false
    assert quote.external_event_verified == false
  end

  test "applies a reward through the existing loyalty ledger" do
    assert {:ok, policy} = SkyRewards.new(%{"course.complete" => 250})
    ledger = SkyLoyalty.new()

    assert {:ok, next, result} =
             SkyRewards.apply(policy, ledger, "event-1", "member-1", "course.complete")

    assert result.reward_applied == true
    assert result.points == 250
    assert result.balance == 250
    assert result.monetary_value_assigned == false
    assert result.external_event_verified == false
    assert String.starts_with?(result.transaction_id, "reward:")
    assert {:ok, 250} = SkyLoyalty.balance(next, "member-1")
  end

  test "uses deterministic transaction identity to reject duplicate reward events" do
    assert {:ok, policy} = SkyRewards.new(%{"purchase.recorded" => 10})
    ledger = SkyLoyalty.new()

    assert {:ok, next, first} =
             SkyRewards.apply(policy, ledger, "provider-event-7", "member-1", "purchase.recorded")

    assert {:error, "transaction_id already applied"} =
             SkyRewards.apply(policy, next, "provider-event-7", "member-1", "purchase.recorded")

    assert first.transaction_id ==
             (SkyRewards.apply(policy, SkyLoyalty.new(), "provider-event-7", "member-1", "purchase.recorded")
              |> elem(2)
              |> Map.fetch!(:transaction_id))
  end

  test "rejects unknown event types and unsafe policy rules" do
    assert {:error, "reward points must be an integer between 1 and 1000000"} =
             SkyRewards.new(%{"course.complete" => 0})

    assert {:error, "event_type must be 1-48 safe characters"} =
             SkyRewards.new(%{"../unsafe" => 10})

    assert {:ok, policy} = SkyRewards.new(%{"course.complete" => 25})

    assert {:error, "event_type has no configured reward rule"} =
             SkyRewards.quote(policy, "lesson.complete")
  end

  test "caps rule cardinality" do
    rules = for index <- 1..101, into: %{}, do: {"event#{index}", index}
    assert {:error, "rules may contain at most 100 event types"} = SkyRewards.new(rules)
  end
end
