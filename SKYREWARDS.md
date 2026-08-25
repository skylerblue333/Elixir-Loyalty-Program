# SkyRewards — Wave 2 Slot #80

**Lane:** 02  
**Status:** engineering beta / deterministic reward-policy core.

SkyRewards adds a bounded reward-policy layer on top of the existing `SkyLoyalty` ledger. Callers define a map of event types to positive point awards. The module validates those rules, quotes configured awards, derives a deterministic transaction ID from each caller-supplied event ID, and applies the award through `SkyLoyalty.apply/5`.

## Integration contract

A typical SKYCOIN4444 composition is:

`verified application event -> SkyRewards policy -> SkyLoyalty ledger`

The upstream application remains responsible for authenticating the actor and proving that the event really occurred. SkyRewards deliberately returns `external_event_verified: false` and `monetary_value_assigned: false`. It does not infer cash value, payment status, eligibility, or legal entitlement.

Duplicate event IDs deterministically resolve to the same loyalty transaction ID, allowing the existing ledger's duplicate-transaction protection to reject repeated awards.

## Bounded behavior

- at most 100 configured event types;
- event types are bounded to 48 safe identifier characters;
- member/event IDs are bounded to 64 safe identifier characters;
- reward amounts are positive integers capped at 1,000,000 points per event;
- resulting balances remain subject to the existing SkyLoyalty one-billion-point ceiling.

## Security and product boundaries

This module does not connect to payment providers, merchants, identity providers, course systems, or external loyalty partners. It does not verify purchases/events, move money, assign monetary value, persist balances, enforce account ownership, detect fraud, provide tax/accounting treatment, or establish production deployment.

Consumers must authenticate and authorize reward creation, validate event provenance, persist the ledger durably if required, protect replay/idempotency keys across deployments, and independently define any business/legal meaning of points.
