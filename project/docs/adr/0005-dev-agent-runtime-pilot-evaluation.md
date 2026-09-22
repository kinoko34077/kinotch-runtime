# ADR 0005: dev_agent Runtime Pilot Evaluation

Status: Accepted for the current v0.1 provisional scope

## Context

The fifth roadmap candidate is the Python `dev_agent` v2 Operation/Agent
system. It already has durable Task and Worker state, provider/resource
authority, AgentBackend dispatch, ordered event persistence, explicit
cancellation, and reconciliation for uncertain external effects. The probe
must not replace those boundaries with a simpler Runtime wrapper.

The inspected ref was exact `origin/v2/bootstrap` commit
`4c47007212552c59e1f2a4edc22e0cb7dd721b74`. The user's dirty main worktree
was not modified. No Provider request, credential, or source content was sent.

## Evidence

- `AgentBackendRequest`, `AgentBackendSession`, `AgentBackendEvent`, and
  `AgentBackendResult` form a typed local adapter boundary.
- `AgentBackendArtifactReference` bounds artifact ID/URI/kind/hash/size but
  explicitly does not grant access, verification, or authority.
- `AgentBackendDispatcher` requires task/scope/authority/lease/budget/
  approval/privacy/capability evidence, persists effect intent, deduplicates
  events, and represents unknown outcomes as explicit reconciliation.
- `OperationService.cancel_task()` owns durable Task cancellation, while
  `OperationService.stop()` can request Worker shutdown; backend cancellation
  is a separate external effect.
- `ResourceLedger` owns quota, budget, privacy, qualification, health, repair,
  and routing decisions.
- The fresh v2 test invocation reached 100% progress without a completion
  summary and was interrupted; this probe therefore does not claim a fresh
  passing exit code. Repository-documented prior baseline evidence remains
  separate.

## Decision

### PARTIAL GO: narrow artifact-reference meaning

Keep the identity-versus-authority distinction as a candidate semantic:

- a bounded identity/reference can name an output
- optional hash/size/kind metadata can support correlation
- access, verification, and authority remain external responsibilities

This is not a promotion of the Runtime `Artifact` value object, not a schema
change, and not a package request. One Agent implementation is insufficient
for `multi-repo-validated` or `stable`.

### HOLD / REVISE other Runtime mappings

AgentBackend request/event/result semantics are Agent-specific because they are
coupled to task identity, scope, authority, durable effects, and reconciliation.
The current Runtime cancellation token cannot express the same lifecycle.
ResourceLedger is an authority boundary, not a portable Resource value. Do not
introduce ActionRegistry, ActionResult, CancellationToken, Resource, or a
Surface Pack into `dev_agent`.

### No test-only or production integration

Existing AgentBackend tests already exercise the local contract. Copying the
private meanings into a Runtime fixture would not validate cross-repository
reuse, so no test-only probe or production change is added.

## Consequences

- Runtime remains `0.1.0` and provisional.
- Artifact reference is recorded as a narrow PARTIAL GO candidate only.
- Cancellation remains REVISE; Resource authority remains Agent-specific.
- No Python binding changes, external dependency, Surface Pack, or
  dev_agent production edit is made.

## Next validation

Compare artifact-reference semantics with another real consumer that also
separates identity from access/verification authority. Revise cancellation
semantics independently before asking another repository to implement them.
Stable promotion requires repeated meaning, shared change reason, and no major
unresolved REVISE/HOLD boundary.
