# KiNoTch. Runtime v0.1 Specification

Status: provisional — first five Pilot/design probes evaluated; stable Contract validation pending

This document describes the implemented Python reference contract. It is not
yet a stable cross-repository contract: the `jev-audit` execution Pilot and
subsequent heterogeneous design/semantic probes are recorded, but no shared
meaning has cleared all maturity gates. Contract decisions remain provisional
until the same meaning and change reason are validated across repositories.

## Purpose

KiNoTch. Runtime is the execution layer shared by KiNoTch. repositories. v0.1 is a small Python reference implementation for executing registered Actions and representing their common result, error, progress, resource, artifact, configuration, cancellation, and logging values.

The Runtime owns execution semantics. Repository Base owns project structure, manifest, profiles, surfaces, and Runtime version references. The Python types in this repository are a reference binding; the semantic candidates that may cross language boundaries are described separately in [Portable Contract](PORTABLE_CONTRACT.md).

The Runtime repository owns the canonical Execution Contract definitions under
`project/contracts/execution/`. Any matching schemas inherited under
`.kinotch/schemas/` are Base-side validation compatibility copies; they are not
independently editable sources of truth.

## v0.1 scope

Defined and implemented in this repository:

- `ActionRegistry` and callable Action registration
- `ActionRequest` and `ActionContext`
- `ActionResult` and extensible `ActionError`
- `ProgressEvent` and callback-based progress reporting
- `Resource` and `Artifact` value objects
- `CancellationToken`
- `RuntimeConfig` mapping access
- standard-library logging adapter

Out of scope:

- CLI, MCP, API, Agent, and Windows GUI Surface Packs
- filesystem abstraction and external transport
- package-specific deployment policy
- authentication, retries, rate limiting, or provider orchestration
- modification of `jev-audit` or any Pilot repository

## Execution contract

An Action is a callable with the shape:

```text
(ActionRequest, ActionContext) -> ActionResult
```

The registry returns a failed result with `NOT_FOUND` for an unknown Action. An Action may return a result, raise `ActionErrorException`, or raise an unexpected exception. The Runtime converts the first two to structured results and converts an unexpected exception to `INTERNAL_ERROR` without exposing a traceback in the result payload.

`CancellationToken` is cooperative. The Runtime does not forcibly interrupt Python code; an Action checks `throw_if_cancelled()` at safe points.

## Error and result rules

Error codes are extensible uppercase identifiers matching `^[A-Z][A-Z0-9_]*$`. v0.1 recommends `INVALID_INPUT`, `NOT_FOUND`, `CANCELLED`, and `INTERNAL_ERROR` but does not make the list a closed enum.

`ActionResult` has one of `success`, `partial`, `failed`, or `cancelled` status.
Failed and cancelled results require a structured error. Success results do not
require an error; the treatment of an error on partial results remains
provisional until Pilot evidence exists. The result envelope and Runtime-owned
metadata serialize to JSON-compatible values. Payload values supplied by
Actions or callers must be JSON-compatible when serialization is required.

## Portable boundary

Operation identity and the minimum request/error meanings are currently
portable candidates, not stable cross-language requirements. Field spelling,
Python exception classes, registry dispatch, and the `CancellationToken` API
remain implementation-specific. `ActionResult`, progress, cancellation,
resources, and artifacts remain unresolved until heterogeneous Pilot evidence
shows that they preserve meaning without wrapper-only conversion. See the
[Contract Maturity Matrix](CONTRACT_MATURITY.md) for per-item decisions.

## Configuration and logging

`RuntimeConfig` is a read-only view over a caller-provided mapping. It does not read environment variables implicitly and never logs values. `to_dict()` is a raw representation and is not a redacted secret-safe view; callers must protect any secret values they place in configuration. Logging uses Python's standard library and leaves handler/format policy to the host application.

## Compatibility

Python 3.10+. The core package has no third-party runtime dependency. JSON
serialization of the Runtime envelope uses only standard-library-compatible
values. Domain payloads are the caller's responsibility and are not recursively
validated by v0.1.

The inherited `.kinotch/tests/run-tests.ps1` suite tests the Base repository's own identity and is not the Runtime project's test entry. Runtime verification uses the project command in `project/project.json`; Base self-tests remain owned by `kinotch-repository-base`.

## Acceptance criteria

1. A caller can register and execute a named Action.
2. Unknown Actions return a structured `NOT_FOUND` result.
3. Action errors preserve code, message, details, and retryability.
4. Unexpected Action failures become `INTERNAL_ERROR` results without traceback leakage.
5. Cancellation is cooperative and returns `cancelled` with `CANCELLED`.
6. Progress events can be delivered to a caller callback.
7. Resource and Artifact values serialize deterministically to JSON-compatible mappings.
8. Config reads are explicit and missing required values fail clearly.
9. Runtime core tests run without third-party packages.
10. Runtime remains independent of CLI/MCP/API/GUI adapters.
