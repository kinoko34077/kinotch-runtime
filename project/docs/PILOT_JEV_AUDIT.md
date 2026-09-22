# jev-audit Pilot Report

Status: live CLI/MCP comparison complete — Contract evaluation pending

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
- A live Direct CLI run and a live Runtime CLI run both processed 14 files in
  2 batches, returned `review`, and exited 0. Both used `jev-1.13.0` and the
  same token counts; risk probabilities differed slightly between requests.
- A live MCP `audit_directory` call returned `CallToolResult` with
  `isError=false`, `review`, 14 files, and 2 batches through the Runtime
  bridge.
- An invalid profile kept exit code 2. The Runtime bridge mapped the expected
  missing-profile error to `NOT_FOUND` instead of exposing a traceback.
- The bridge is 83 lines and its focused regression test is 103 lines.
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

## Remaining evaluation

The live comparison used an operator-authorized `TYPESAFE_API_KEY` and sent
the selected `jev_audit` source files to TypeSafe. The current evidence covers
CLI/MCP result shape, exit codes, basic error mapping, and Runtime execution.
It does not prove that the Runtime reduces maintenance work. Compare adapter
size, config mapping, dependency/install cost, and repeated change reasons
before declaring a stable cross-repository Contract. Do not treat a GREEN
audit as a quality proof.

The Pilot must fail or revise the Runtime boundary if the adapter grows,
configuration becomes more complex, or CLI/MCP-specific behavior leaks into
the Kernel.
