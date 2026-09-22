# ADR 0001: jev-audit Pilot Contract Evaluation

Status: accepted for the provisional v0.1 line

## Context

The first Runtime Pilot connected `jev-audit` CLI and MCP through an optional
83-line bridge. The Audit Core was already shared by both Surfaces before the
Runtime was introduced, so Core sharing is not evidence of Runtime value.

## Evidence

- `jev-audit` baseline commit: `0943bb9`.
- Pilot production code changed only CLI/MCP imports, an 83-line bridge, and a
  three-line optional `pilot` dependency. Audit Core files were unchanged.
- The focused bridge regression file is 116 lines; the full Runtime-enabled
  jev-audit suite passed 37 tests.
- Direct CLI and Runtime CLI live runs both processed 14 files in 2 batches,
  returned `review`, and exited 0.
- Runtime MCP live call returned `isError=false`, `review`, 14 files, and 2
  batches.
- Invalid profile kept exit code 2 and mapped to `NOT_FOUND` on the Runtime
  path.
- `RuntimeConfig`, progress, cancellation, resources, artifacts, and logging
  were not needed by the audit path.
- `ActionResult.data` carried an `AuditReport` object and was unwrapped before
  existing CLI/MCP presentation; no shared serialized result envelope was
  demonstrated.

## Decision

- KEEP `ActionRegistry`, `ActionRequest`, `ActionError`, and Action ID
  validation as the limited next-Pilot candidate.
- REVISE `ActionContext`, `ActionResult`, and `ActionErrorException` before
  treating them as cross-repository stable meanings.
- DEFER Cancellation, Progress, Resource, Artifact, RuntimeConfig, and
  Logging from the next Pilot unless the target repository has a real need.
- REMOVE nothing from the reference implementation yet.
- Keep Runtime version `0.1.0` and status `provisional`.

## Consequences

The Runtime remains small and testable, but the `jev-audit` bridge is not
counted as proof that a shared execution framework reduced complexity. The
next Pilot must use only the retained meanings and must avoid forcing unused
Context services or a Python package into another language.

## Next validation

`kinotch-api` is GO for a design-only second-Pilot probe and HOLD for
implementation. Its existing request ID, validation, error envelope, HTTP
status, and Service Binding boundaries are real, but wrapping HTTP `Response`
objects in `ActionResult` may be unnatural. The design is recorded in
`PILOT_KINOTCH_API.md`; no API code or Surface Pack is changed by this ADR.
