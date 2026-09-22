# SynTrail-LM Runtime Design Probe

Status: evaluation complete; design-only probe; no SynTrail-LM production code changed

Observed commit: `2326cf1f58f78a74aff28286a381e2161da19064` (`origin/main`)

The SynTrail-LM checkout used for this probe had user-owned dirty and
untracked files. It was not modified. Inspection and the baseline test run
used a separate detached worktree at the exact commit above.

## Actual repository shape

SynTrail-LM is a Rust 2024 crate with a CLI, a library, and feature-gated
Windows/desktop GUI binaries:

```text
Cargo.toml
src/lib.rs
src/main.rs
src/bin/syntrail_gui.rs
src/bin/syntrail_trainer.rs
src/trainer/
  dataset.rs
  adaptive.rs
  scheduler.rs
  splitter.rs
  state.rs
  supervised.rs
src/desktop/
src/persistence.rs
src/session.rs
tests/integration.rs
```

The trainer binary is the relevant long-running path. Its worker and GUI are
in `src/bin/syntrail_trainer.rs`; trainer data and resume state live in
`src/trainer/`; model snapshots and model files are handled by
`src/persistence.rs` and `src/app.rs`.

Baseline at the observed commit:

- `cargo test --locked`: 237 library tests + 185 integration tests passed
- no Runtime crate or Runtime dependency
- existing compiler warnings only; no test failure

## Existing progress flow

The trainer already has a worker-to-GUI `std::sync::mpsc` event channel.
`TrainerEvent` includes:

| Existing event | Existing meaning | GUI consumer |
|---|---|---|
| `BlockStarted` | block index, preview, source bytes done/total, pre-dpc and accuracy | initializes progress panel |
| `ExposureDone` | current repeat count | updates repeat count |
| `Checkpoint` | checkpoint/repeat, dpc, accuracy | updates checkpoint and metrics |
| `BlockDone` | block completion and repeats used | updates status message |
| `LevelChanged` | adaptive block level changed | updates level and status |
| `Analytics` | model analytics snapshot | updates analytics panel |
| `Completed` | terminal successful training with model ownership transfer | enters Completed state |
| `Error` / `SaveFailed` | failed operation or persistence failure | enters error/pause state |
| `Saved` / `Paused` / `Stopped` | persistence and lifecycle notifications | updates state and status |

The worker emits the events and the GUI drains them with `try_recv()` in
`poll_events()`. The existing progress state has meaningful `current` and
`total` values for source bytes, repeat/checkpoint values, stage-like event
names, messages, analytics, and terminal completed/failed states.

This is a real progress flow, but it is currently a private Trainer binary
protocol. The observed repository does not expose a generic progress producer
for another Surface, and no second consumer was found that shares this event
meaning.

### Progress decision: PARTIAL GO

The existing event flow is a natural observation of portable progress
semantics. It is not enough for a cross-repository or stable Contract because:

- the event enum is private to `syntrail_trainer`
- the event stream mixes progress, persistence, control, and terminal ownership
- the observed consumer is the Trainer GUI
- no adapter reduction or repeated cross-repo implementation was demonstrated

No production mapping or Rust Runtime crate is justified by this probe. A
test-only probe would duplicate a private enum rather than verify a shared
boundary, so it is deferred until a second consumer or public application
boundary exists.

## Existing pause / resume / stop flow

The worker has a private `TrainerCommand` channel with `Pause`, `Resume`,
`Stop`, `Save`, and `SaveAs` commands.

- `Pause` marks `TrainerStatus::Paused`, saves model and trainer state, emits
  `Paused` on success, and then blocks waiting for `Resume` or `Stop`.
- `Resume` returns the same worker to `Running`.
- `Stop` calls `save_and_exit`, performs the final save, emits `Stopped`, and
  transfers the latest in-memory model to the GUI.
- command-channel disconnection also takes the save-and-exit path.
- save failure can produce `ErrorPaused` for Pause or a terminal stopped path
  for checkpoint/stop failures.

`TrainerState` in `src/trainer/state.rs` is a resumable persistent state, not a
cancellation token. It includes block cursor, checkpoint, repeat count,
fingerprints, status, and checkpoint generation. Pause is resumable; Stop is a
terminal lifecycle operation with persistence; channel disconnection is a
transport/lifecycle failure. These meanings must remain distinct from process
kill or forced shutdown.

### Cancellation decision: REJECT direct mapping / REVISE Runtime candidate

The Python `CancellationToken.cancel()` / `throw_if_cancelled()` model cannot
represent SynTrail's pause/resume/stop distinction without losing domain state.
SynTrail-LM must not be changed to fit that API. The portable candidate may
eventually describe cooperative cancellation request, observation, and terminal
state, but the current Runtime cancellation Contract is not validated here.

No test-only mapping is added: there is no lossless one-to-one mapping from the
existing command/state machine to the current token API.

## Existing resource-like values

SynTrail uses concrete domain values rather than a generic Resource abstraction:

- `Dataset` loads a path, normalized text, and a fingerprint.
- `TrainerState` stores dataset/model paths and fingerprints to guard resume.
- model paths select JSON, STM, or SQLite persistence through existing save/load
  functions.
- file D&D and desktop dialogs classify concrete model and dataset file kinds.

These are input selection, validation, and persistence responsibilities. The
observed path-to-fingerprint behavior has no separate acquisition interface or
cross-Surface resource consumer.

### Resource decision: HOLD

Wrapping `PathBuf` / `Dataset` in a Runtime Resource and immediately unwrapping
it would add a type without reducing a shared decision. Model and dataset
handling stays in SynTrail-LM until another repository demonstrates the same
meaning and change reason.

## Existing artifact-like values

SynTrail produces several different classes of output:

- model files (`.stm`, `.json`, `.db` / `.sqlite`)
- trainer state (`<dataset>.syntrail-trainer.json`)
- checkpoint generations pairing model and trainer state
- session snapshots and history storage

The model file is a user-visible saved model. Trainer state is resumable
internal state. Checkpoint persistence is an internal consistency mechanism,
while session snapshots are storage records. The code intentionally keeps
these forms separate and validates fingerprints/generation pairing.

### Artifact decision: HOLD

The observed outputs do not share one lossless Artifact meaning. Treating
checkpoint state, cache/history, persistent resume state, and user-visible
model output as one Runtime Artifact would erase useful distinctions. No
artifact wrapper or Rust Runtime crate is justified.

## Other Contracts

- Action ID / Action Request: incidental to this Pilot; SynTrail's CLI command
  and Trainer command identifiers do not establish a new cross-language
  operation boundary.
- ActionResult: not observed as a natural boundary; do not wrap GUI or file
  operations merely to produce one.
- RuntimeConfig and Logging: excluded; no shared need was established.

## Design-probe result

| Contract | Decision | Evidence | Production action |
|---|---|---|---|
| Progress | PARTIAL GO | Existing worker event stream has real current/total/stage/terminal meanings | No code change; await a second consumer/public boundary |
| Cancellation | REJECT direct mapping / REVISE candidate | Pause, Resume, Stop, disconnect, and save failures have distinct lifecycle semantics | Do not port `CancellationToken` |
| Resource | HOLD | Concrete Dataset/path/fingerprint values, no generic acquisition boundary | Keep SynTrail-specific |
| Artifact | HOLD | Model output, resume state, checkpoint, and history have different consumers and durability meanings | Keep SynTrail-specific |

The result is not a Runtime integration. It is evidence that a narrow
portable progress vocabulary may be useful later, while the current
cancellation/resource/artifact abstractions need revision or deferral.

## Evaluation complete

### What worked

- The existing Trainer worker already has a concrete event stream with source
  progress, checkpoints, analytics, and terminal lifecycle events.
- The event meanings can be described without changing the Trainer domain or
  adding a Runtime dependency.
- The inspection exposed why Pause, Resume, Stop, disconnect, and persistence
  failure cannot be treated as one cancellation operation.
- Existing model output and trainer resume state are deliberately separated,
  so the probe did not force a false Artifact unification.

### What did not reduce complexity

- There is only a private Trainer event protocol and one observed GUI consumer;
  a new portable event adapter would currently duplicate the enum.
- A Runtime cancellation token would add conversion and erase the distinction
  between resumable Pause and terminal Stop.
- Resource and Artifact wrappers would package and immediately unwrap concrete
  paths, datasets, model files, or resume state.

### What remains unvalidated

- Progress semantics across a second consumer or a second heterogeneous
  repository.
- A portable cancellation lifecycle that can represent request, observation,
  pause/resume, terminal stop, and persistence failure without collapsing
  domain state.
- Any cross-repository Resource or Artifact meaning.

### Contract decisions

| Contract | Decision | Maturity consequence |
|---|---|---|
| Progress | PARTIAL GO | Keep as a semantic candidate; do not call it multi-repo-validated. |
| Cancellation | REVISE / direct mapping REJECTED | Keep Python implementation for its reference use, but revise portable lifecycle before reuse. |
| Resource | HOLD | No portable promotion. |
| Artifact | HOLD | No portable promotion; preserve persistence distinctions. |

No production Pilot, Rust Runtime crate, or Surface Pack follows from this
evidence. No Contract is promoted to `stable`.

### Next validation

The next useful evidence for Progress is a second real consumer or an
application boundary that is not the private Trainer GUI enum. Cancellation
requires a Runtime Contract revision first. Resource and Artifact remain
project-specific unless another repository demonstrates the same meaning and
change reason.

## Next validation

Do not create a Rust Runtime crate or Surface Pack from this design probe. A
future test-only Progress probe is justified only after a second consumer or a
public application operation exists. Cancellation requires a revised portable
lifecycle model before another implementation is asked to adopt it.
