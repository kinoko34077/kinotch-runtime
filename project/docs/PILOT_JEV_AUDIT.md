# jev-audit Pilot Report

Status: evaluation complete — Runtime remains provisional

## Scope

The first Pilot connects `jev-audit` to the Runtime through one optional
`repo.audit` Action. The existing Audit Core remains the implementation of
directory scanning, batching, Jev calls, and aggregation. CLI and MCP keep
their existing Surface code and call the same bridge entry point.

## Evidence

- Runtime Contract tests pass, including Action ID, Resource, Artifact,
  Result, and cancellation invariants.
- `jev-audit`'s existing 35 tests pass with the Runtime package absent; the
  bridge falls back to the existing direct Audit Core call.
- With the Runtime source on `PYTHONPATH`, the bridge test passes through the
  actual `ActionRegistry` and `repo.audit` handler without an external API
  call.
- A live Direct CLI run and a live Runtime CLI run both processed 14 files in
  2 batches, returned `review`, and exited 0. Both used `jev-1.13.0` and the
  same token counts; risk probabilities differed slightly between requests.
- A live MCP `audit_directory` call returned `CallToolResult` with
  `isError=false`, `review`, 14 files, and 2 batches through the Runtime
  bridge.
- An invalid profile kept exit code 2. The Runtime bridge mapped the expected
  missing-profile error to `NOT_FOUND` instead of exposing a traceback.
- The bridge is 83 lines and its focused regression test is 116 lines.
- The Pilot adds no CLI/MCP Surface Pack, plugin discovery, or Action Registry
  auto-binding.

## Boundary decisions

- Runtime installation is optional through the `pilot` extra. The default
  `jev-audit` installation remains unchanged.
- The bridge carries `AuditReport` as a domain payload inside the in-process
  Runtime result. It does not claim that arbitrary domain payloads are JSON
  serializable; the Runtime envelope contract keeps that responsibility with
  the caller.
- Expected input/configuration errors are mapped to structured `NOT_FOUND` or
  `INVALID_INPUT` errors inside the bridge. Unexpected provider or execution
  errors remain Runtime-redacted. CLI/MCP Surface error presentation is not
  standardized by this Pilot.

## What worked

- The Audit Core remained unchanged.
- CLI and MCP used one localized bridge while the default installation retained
  the legacy path.
- `ActionRequest`, `ActionRegistry`, and the `ActionError` mapping were usable
  without moving CLI/MCP policy into the Runtime kernel.
- Expected missing-profile input retained exit code 2 and became a structured
  `NOT_FOUND` error on the Runtime path.

## What did not reduce complexity

- CLI and MCP already shared the Audit Core before the Pilot; Runtime did not
  create that sharing.
- `ActionResult` was only a transparent in-process wrapper around an
  `AuditReport` domain object. It was unwrapped before CLI/MCP output and did
  not provide a shared serialized result envelope.
- `RuntimeConfig`, progress, cancellation, resources, artifacts, and logging
  were not needed by the actual audit path.
- The optional Git dependency and bridge add concepts without a measured LOC
  or maintenance reduction in this one repository.

## Contract decisions

See [CONTRACT_MATURITY.md](CONTRACT_MATURITY.md) and
[ADR 0001](adr/0001-jev-audit-pilot-contract-evaluation.md). No Contract is
promoted to `stable` or `multi-repo-validated` from this Pilot alone.

## Remaining validation

The live comparison used an operator-authorized `TYPESAFE_API_KEY` and sent the
selected `jev_audit` source files to TypeSafe. It covers CLI/MCP result shape,
exit codes, basic error mapping, and Runtime execution. It does not validate
Config, Progress, Cancellation, Resource, Artifact, or Logging semantics, and
does not prove that Runtime reduces maintenance work. Do not treat a GREEN
audit as a quality proof.

The Pilot must fail or revise the Runtime boundary if the adapter grows,
configuration becomes more complex, or CLI/MCP-specific behavior leaks into
the Kernel.
