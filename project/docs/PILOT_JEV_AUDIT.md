# jev-audit Pilot Report

Status: preparation complete — live Jev validation pending

## Scope

The first Pilot connects `jev-audit` to the Runtime through one optional
`repo.audit` Action. The existing Audit Core remains the implementation of
directory scanning, batching, Jev calls, and aggregation. CLI and MCP keep
their existing Surface code and call the same bridge entry point.

## Validated locally

- Runtime Contract tests pass, including Action ID, Resource, Artifact,
  Result, and cancellation invariants.
- `jev-audit`'s existing 35 tests pass with the Runtime package absent; the
  bridge falls back to the existing direct Audit Core call.
- With the Runtime source on `PYTHONPATH`, the bridge test passes through the
  actual `ActionRegistry` and `repo.audit` handler without an external API
  call.
- The bridge is 65 lines and its focused regression test is 78 lines.
- The Pilot adds no CLI/MCP Surface Pack, plugin discovery, or Action Registry
  auto-binding.

## Boundary decisions

- Runtime installation is optional through the `pilot` extra. The default
  `jev-audit` installation remains unchanged.
- The bridge carries `AuditReport` as a domain payload inside the in-process
  Runtime result. It does not claim that arbitrary domain payloads are JSON
  serializable; the Runtime envelope contract keeps that responsibility with
  the caller.
- Runtime errors remain structured inside the bridge and are raised at the
  existing application boundary; CLI/MCP Surface error presentation is not
  standardized by this Pilot.

## Pending live evaluation

A live Jev audit has not been run in this preparation phase because it would
send repository content to the external TypeSafe service and requires an
operator-authorized `TYPESAFE_API_KEY`. Before doing so, compare the existing
direct path and the Runtime path for CLI JSON output, exit codes, error
handling, MCP results, config mapping, added dependencies, and adapter
complexity. Do not treat a GREEN audit as a quality proof.

The Pilot must fail or revise the Runtime boundary if the adapter grows,
configuration becomes more complex, or CLI/MCP-specific behavior leaks into
the Kernel.
