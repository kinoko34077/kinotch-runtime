# ADR 0003: SynTrail-LM Runtime Pilot Evaluation

Status: Accepted for the current v0.1 provisional scope

## Context

The first two Pilots established a Python Runtime execution path and a
JavaScript semantic observation for operation identifiers and error values.
They did not validate Progress, Cancellation, Resource, or Artifact. SynTrail-LM
is a different Rust / Windows GUI / long-running Trainer repository and is a
useful place to inspect those meanings without assuming that the Python types
are portable.

The inspected SynTrail-LM source was exact `origin/main` commit
`2326cf1f58f78a74aff28286a381e2161da19064`. Its user worktree contained dirty
and untracked files, so the inspection and baseline tests used a separate
detached worktree. No SynTrail-LM source was changed.

## Evidence

- `cargo test --locked`: 237 library tests and 185 integration tests passed.
- `src/bin/syntrail_trainer.rs` has a private worker-to-GUI mpsc event stream
  with block, exposure, checkpoint, analytics, save, pause, stop, completion,
  and error events.
- The same file has a private command/state machine where Pause is resumable,
  Resume continues the worker, Stop saves and terminates, and channel
  disconnection takes a save-and-exit path.
- `src/trainer/state.rs` persists block cursor, repeat/checkpoint progress,
  fingerprints, status, and checkpoint generation for safe resume.
- `src/app.rs` / `src/persistence.rs` keep model files, trainer state,
  checkpoint pairing, and session snapshots as different persistence forms.
- No generic public Progress producer, Resource acquisition boundary, or
  Artifact result boundary was found.

## Decision

### KEEP as a narrow candidate

Progress semantics are kept as a candidate because SynTrail has real current,
total, stage, message, analytics, and terminal meanings in its existing event
flow. The result is PARTIAL GO, not a stable Contract: the producer is private
and the observed consumer is the Trainer GUI.

### REVISE / reject direct mapping

The Python `CancellationToken` API is not adopted as the portable model for
SynTrail. Pause, Resume, Stop, disconnect, and persistence failure are not
interchangeable. The portable cancellation lifecycle needs a revised semantic
model before another repository is asked to implement it.

### HOLD

Resource and Artifact remain unresolved. A Resource wrapper would package
concrete paths/datasets and an Artifact wrapper would collapse user-visible
model output, internal resume state, checkpoint pairing, and history. Keep
these meanings in SynTrail-LM until another repository demonstrates the same
boundary and change reason.

### No production integration

Do not add a Rust Runtime crate, portable event adapter, Surface Pack, or
production dependency to SynTrail-LM from this evidence. A test-only fixture
would duplicate a private enum and therefore would not validate a shared
boundary.

## Consequences

- Runtime remains `0.1.0` and provisional.
- Progress remains a candidate with design-observed evidence only; it is not
  `pilot-exercised` through a Runtime execution path or `multi-repo-validated`.
- Cancellation remains a Python reference implementation with a portable
  Contract revision required.
- Resource and Artifact are not promoted or removed from the Python reference
  package.
- Surface Packs and Rust bindings remain unstarted.

## Next validation

Progress needs a second consumer or public application operation before a
test-only or production mapping is justified. Cancellation needs a revised
portable lifecycle Contract. Resource and Artifact should be revisited only if
another heterogeneous repository presents the same meanings and maintenance
reason. Stable promotion remains gated by multiple repositories, repeated
semantics, shared change reasons, and no unresolved major REVISE/HOLD issue.
