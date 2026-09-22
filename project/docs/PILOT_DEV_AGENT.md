# dev_agent Runtime Design Probe

Status: evaluation complete; design-only probe; no dev_agent production code changed

Observed ref: `origin/v2/bootstrap` at
`4c47007212552c59e1f2a4edc22e0cb7dd721b74`.

The checked-out `dev_agent` main worktree had user-owned modifications. It was
not changed. Inspection used a detached worktree at the exact ref above. No
provider request, API key, or external source content was sent during this
probe.

## Actual architecture

The v2 branch is a Python Agent/Operation system whose boundaries are already
more specific than the Runtime v0.1 reference kernel:

```text
CLI
  -> OperationService
  -> durable SQLite StateStore + DurableQueue + WorkerRunner
  -> Controller / ProviderDispatcher / ResourceLedger
  -> intelligence, tools, security, recovery, DevFarm, AgentBackend
```

The domain protocol includes durable `Task`, `Step`, `ModelRequest`,
`ModelResponse`, `ToolResult`, and `Event` values. Task states include queued,
planning, ready, running, waiting dependency/approval/reconciliation,
blocked quota/budget, completed, failed, and cancelled.

The `AgentBackend` protocol in `src/dev_agent/backends/protocol.py` is already a
thin adapter boundary:

- `AgentBackendRequest` carries task/objective/scope/input artifact references,
  session correlation, sensitivity, and metadata.
- `AgentBackendSession` carries the backend session identity and status.
- `AgentBackendEvent` carries session, sequence, event type, optional status,
  and payload.
- `AgentBackendResult` carries terminal/non-terminal status, output artifact
  names, reconciliation metadata, external session ID, and artifact references.
- `AgentBackend.cancel()` is an explicit backend request; `result()` and
  `events()` remain separate observations.
- discovery/reconciliation is explicit and is not called implicitly by the
  dispatcher.

`AgentBackendDispatcher` validates task state, sensitivity, scope, authority,
lease admission, budget admission, approval, privacy, and capabilities before
calling a backend. It persists effect intent and event sequence, deduplicates
events, and turns unknown external outcomes into an explicit reconciliation
boundary. These are authority and durability responsibilities, not generic
Runtime result decoration.

## Contract observations

| Candidate | Existing meaning | Decision |
|---|---|---|
| Operation ID | task ID, dispatch ID, client session key, and effect key each have different authority meanings | HOLD; no direct Action ID mapping |
| Request | backend request has input/objective plus scope, sensitivity, session, and metadata | PARTIAL GO observation; implementation remains HOLD |
| Error | OperationError and dispatch errors are projected with status, authority, unknown, and reconciliation semantics | REVISE/HOLD; not a simple code/message wrapper |
| Event / Progress | ordered backend event sequence with status/payload is durable and deduplicated | PARTIAL GO observation; not a generic progress adapter |
| Cancellation | backend cancel request, task cancel, worker stop, unknown outcome, and reconciliation are distinct | REVISE; current Runtime token is insufficient |
| Resource | ResourceLedger owns quota, budget, privacy, qualification, health, repair, and routing | REJECT as portable Runtime Resource; Agent authority remains local |
| Artifact reference | bounded artifact ID/URI/kind/hash/size metadata explicitly does not grant access or verification | PARTIAL GO for a narrow reference meaning; full Artifact remains HOLD |
| Config / Logging | operation/provider/resource policy and audit boundaries are host-owned | OUT OF SCOPE |

## Artifact-reference observation

`AgentBackendArtifactReference` is the strongest portable candidate in this
probe. It separates a bounded identity/reference from access, verification, and
authority. The explicit distinction is valuable:

- `artifact_id` identifies a result reference
- `uri` locates or names it without granting access
- `kind` is a structural category
- optional `sha256` and `size_bytes` provide bounded metadata
- existing DevFarm, Host Verification, and artifact authorities remain owners

This is narrower than the Runtime `Artifact` value object. It does not prove
that a shared package or schema is needed, and it does not unify Agent
artifacts with browser generated files or SynTrail persistence.

### Artifact reference decision: PARTIAL GO / no implementation

Keep the meaning as a candidate for a future portable *reference* sub-contract.
Do not change Runtime schemas, add a package, or introduce an adapter in
`dev_agent` from one observation. The authority disclaimer is part of the
meaning and must not be lost in a simpler wrapper.

## Cancellation and error boundary

`OperationService.cancel_task()` changes durable Task state and queue state
without constructing a configured Provider. `OperationService.stop()` requests
worker loop shutdown and can also stop a task. Separately,
`AgentBackendDispatcher.cancel()` forwards cancellation to an external session;
transport failure becomes UNKNOWN and requires explicit reconciliation. A
single `CancellationToken` or `ActionError` conversion would erase these
different owners and outcomes.

### Cancellation decision: REVISE

Keep the Python/Agent-specific lifecycle. Revise the portable candidate only
after a model can express request, observed cancellation, terminal outcome,
unknown external effect, and explicit reconciliation without forcing a domain
to collapse its state machine.

## Probe verification boundary

The repository's `docs/CURRENT_STATE.md` records a prior v2 baseline of
`1475 passed, 1 skipped`. A fresh `python -m pytest tests/v2 -q` invocation in
the detached worktree reached 100% test progress but did not emit a completion
summary; it was interrupted after the process failed to exit. Therefore this
probe does not claim a fresh passing test exit code. No external Provider or
credential path was used.

## Design-probe result

The fifth Pilot is a design observation, not Runtime integration:

- AgentBackend request/event/result/reference semantics are already owned by
  `dev_agent` and protected by its authority boundaries.
- Artifact reference is a narrow candidate, but not yet multi-repo-validated.
- Cancellation must be revised; the Runtime token cannot be imposed.
- Resource, budget, provider, approval, lease, and reconciliation remain
  Agent-specific.
- No test-only fixture is added because the existing AgentBackend tests already
  exercise the local contract, while a copied Runtime fixture would validate
  neither authority nor cross-repo reuse.
- No production code, Runtime dependency, Rust/JS binding, or Surface Pack is
  added.

## Next validation

Compare the artifact-reference meaning against a second repository only if it
also separates reference identity from access/verification authority. Before
any portable cancellation work, define the lifecycle semantics independently
of Python token methods. Do not promote AgentBackend itself to a Runtime
Surface Pack.
