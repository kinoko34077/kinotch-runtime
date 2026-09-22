# Portable Contract

Status: provisional semantic candidate — not stable

This document describes meanings that may be represented by more than one
language or Surface. It does not make the Python reference package's class
names, field spelling, exception types, or dispatch APIs cross-language
requirements.

The maturity and pilot decision for each item remain in
[CONTRACT_MATURITY.md](CONTRACT_MATURITY.md). This document defines the
semantic boundary; it does not promote an untested candidate to a stable
Contract.

## Portable operation identity

An operation can be identified by a non-empty, stable identifier that is
independent of its transport Surface. An existing route policy or command ID
may serve this purpose when it already identifies an application operation.

The portable meaning is an operation identifier. The spelling and shape of a
binding field are not fixed here. For example, a Python binding may use
`action_id`, while a JavaScript binding may use `operationId` or an existing
policy `id`. A second registry is not required when the host already has a
correct dispatch mechanism.

## Portable request semantics

A request-like value may carry:

- operation identifier
- operation input
- request or correlation identifier, when the host has one

These are meanings, not a required wrapper class. The portable candidate does
not require an HTTP request, framework Context, raw body bytes, or a conversion
back to a transport representation. If a wrapper only packages a value and is
immediately unwrapped, it is not evidence of a useful Runtime boundary.

The Python reference representation is:

```text
ActionRequest(action_id, input, request_id)
```

It is a binding example, not a cross-language field-name contract.

## Portable error semantics

A structured operation error may carry:

- `code`: a non-empty stable identifier; case convention is not fixed
- `message`: human-readable diagnostic text
- `details`: structured diagnostic data, when useful
- `retryable`: optional retryability meaning when the host can determine it

HTTP status, response headers, request ID presentation, MCP error framing,
and CLI exit codes remain Surface or host responsibilities.

The portable candidate does not require uppercase codes. The Python reference
binding may continue to use `INVALID_INPUT`, `NOT_FOUND`, `CANCELLED`, and
`INTERNAL_ERROR`; an API binding may preserve an existing public code such as
`invalid_profile` or `upstream_timeout`. A mapping that only changes case is
not by itself a reason to add a Runtime layer.

## Python reference-only primitives

The following remain useful in the Python reference implementation but are not
portable Contract requirements:

| Python primitive | Portable status | Reason |
|---|---|---|
| `ActionRegistry` | implementation-specific | Dispatch already belongs to the host; a second registry can duplicate routing. |
| `ActionErrorException` | implementation-specific | Python exception-to-result conversion mechanism. |
| Python dataclass forms | implementation-specific | Bindings may use plain objects, structs, records, or other native values. |
| `CancellationToken.cancel()` / `throw_if_cancelled()` | implementation-specific | Cooperative cancellation meaning must not prescribe a Python API. |

## Unresolved semantics

These concepts exist in the Python reference package but are not portable
until another repository demonstrates the same meaning and change reason:

- `ActionResult`
- `ActionContext`
- Progress events and reporters
- cancellation lifecycle
- Resource
- Artifact
- RuntimeConfig
- logging boundary

In particular, a domain's pause/resume/stop state machine must not be reduced
to a cancellation token without evidence that the states and terminal
semantics are equivalent.

## Version and ownership

This semantic separation does not change Runtime version `0.1.0`. Execution
Contract definitions remain canonical in `project/contracts/execution/`.
The Repository Base owns repository structure and compatibility validation; it
does not duplicate the Portable Contract. Any Base-side execution schemas are
compatibility copies and require explicit review before synchronization.
