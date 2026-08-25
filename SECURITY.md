# Security Policy

Sky Loyalty Core is an engineering-beta domain primitive. It is not an authentication, payment, accounting, or production security boundary.

Current controls include bounded identifiers and point values, duplicate transaction rejection, fail-closed validation, deterministic tests, dependency-free application code, warnings-as-errors compilation, and non-root container execution.

The repository does not provide authentication or authorization, durable audit history, tenant isolation, encryption at rest, promotion/fraud controls, distributed consistency, backup/restore, TLS termination, HA, or independent security certification. Integrators must add and verify those controls before exposing a loyalty service to untrusted users.

Do not treat loyalty points as cash, stored value, a security, or a financial account based on this implementation. Regulatory, accounting, tax, consumer-protection, and redemption policy are outside this repository.

Report suspected vulnerabilities privately through GitHub security reporting when available. Do not publish credentials or private customer data in public issues.
