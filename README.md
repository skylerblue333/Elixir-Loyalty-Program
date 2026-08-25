# Sky Loyalty Core

**Status: engineering beta.** A small dependency-free Elixir loyalty-points ledger for deterministic earn, redeem, and adjustment rules.

## Implemented

- integer-only loyalty points
- bounded 1–64 character member and transaction IDs
- idempotency protection through unique transaction IDs
- earn, redeem, and signed adjustment operations
- insufficient-balance rejection
- one-billion-point per-member balance ceiling
- deterministic balance and ledger summaries
- ExUnit coverage for core invariants
- formatter and warnings-as-errors compile gates
- escript CLI smoke tests
- non-root container packaging

## Use

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix escript.build
./sky_loyalty demo
```

Validate a single operation without persisting it:

```bash
./sky_loyalty validate tx-001 member-001 earn 250
```

Library example:

```elixir
ledger = SkyLoyalty.new()
{:ok, ledger, _} = SkyLoyalty.apply(ledger, "tx-001", "member-001", :earn, 250)
{:ok, ledger, _} = SkyLoyalty.apply(ledger, "tx-002", "member-001", :redeem, 75)
{:ok, 175} = SkyLoyalty.balance(ledger, "member-001")
```

## SKYCOIN4444 integration

Use this repository as a points-domain primitive behind a stable adapter for rewards, marketplace incentives, creator programs, education achievements, or community participation. The integrating service must own identity, authorization, persistence, audit history, promotions policy, expiration, and fraud controls.

## Explicit limitations

This is an **in-memory domain core**, not a complete loyalty platform. It does not provide durable storage, multi-node consistency, customer accounts, authentication/RBAC, monetary value, gift cards, tier calculation, promotion campaigns, expiration schedules, partner settlement, fraud detection, accounting treatment, regulatory compliance, HA, or verified production deployment.

Points are application data only; this repository does not represent them as currency, stored value, securities, or redeemable money.

## Container

```bash
docker build -t sky-loyalty .
docker run --rm sky-loyalty demo
```

The runtime image executes as an unprivileged `app` user.

See `SECURITY.md` and `CHANGELOG.md` for boundaries and productization history.
