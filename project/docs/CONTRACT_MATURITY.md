# Runtime Contract Maturity Matrix

The matrix separates two decisions. `Reference implementation` describes the
Python v0.1 package and its unit-test status. `Cross-language Contract` asks
whether the same meaning should cross the Python/JavaScript boundary. A
`pilot-exercised` value was used by a real Runtime execution path; it is not
proof of reduced maintenance or stability. A JavaScript test-only observation
is recorded separately and does not promote a Contract to `multi-repo-validated`.

No Contract below is `stable`. The `jev-audit` Pilot alone cannot earn
`multi-repo-validated`.

| Contract | Reference implementation | Cross-language Contract | jev-audit evidence | Next Pilot | Decision |
|---|---|---|---|---|---|
| Action ID | implemented, unit-tested | candidate; JS test-only observation | `repo.audit` and `transform-batch` identifiers used | carry as operation identifier | KEEP |
| ActionRegistry | implemented, unit-tested | not required by API boundary | CLI/MCP register/execute `repo.audit` | do not introduce | Python KEEP / cross-language DEFER |
| ActionRequest | implemented, unit-tested | candidate, wrapper shape unvalidated | request envelope used | observe plain-object mapping only | KEEP candidate |
| ActionContext | implemented, unit-tested | not required as service bundle | empty context constructed only | exclude service bundle | REVISE |
| ActionResult | implemented, unit-tested | observation target only | wrapper carried `AuditReport` then unwrapped | do not wrap HTTP `Response` | REVISE / HOLD |
| ActionError | implemented, unit-tested | candidate; JS test-only observation | missing profile maps to `NOT_FOUND`; API keeps `invalid_texts` | compare fields without code-case rewrite | KEEP candidate |
| ActionErrorException | implemented, unit-tested | Python-specific | expected bridge errors use it | do not carry exception class | REVISE |
| CancellationToken | implemented, unit-tested | unvalidated | not exercised | exclude | DEFER |
| ProgressEvent | implemented, unit-tested | unvalidated | not exercised | exclude | DEFER |
| ProgressReporter | implemented, unit-tested | unvalidated | not exercised | exclude | DEFER |
| Resource | implemented, unit-tested | unvalidated | not exercised | exclude | DEFER |
| Artifact | implemented, unit-tested | unvalidated | not exercised | exclude | DEFER |
| RuntimeConfig | implemented, unit-tested | unvalidated | not used | exclude | DEFER |
| Logging boundary | implemented, unit-tested | unvalidated | incidental Runtime error log | exclude | DEFER |

## Interpretation

### Keep for the second-Pilot candidate set

`Action ID` and `ActionError` now have a test-only JavaScript observation in
addition to the Python Pilot. `ActionRequest` remains a semantic mapping only;
its implementation is on HOLD. Any observation must use plain objects or
existing values where possible; it must not require a new runtime library,
registry, framework adapter, or public API rename.

## Portable semantic candidates

The current portable candidate set is intentionally smaller than the Python
reference API:

| Meaning | Current position | Binding note |
|---|---|---|
| Operation identifier | candidate | Existing route or command identifiers may be reused; no new registry is required. |
| Operation input | candidate | Existing validated input may be used without a transport round-trip. |
| Request/correlation identifier | candidate | Host-provided request IDs may map to the meaning; field spelling is not fixed. |
| Error code | candidate | Non-empty stable identifier only; uppercase/lowercase is not portable policy. |
| Error message | candidate | Human-readable diagnostic meaning. |
| Error details | candidate | Structured diagnostics where the host already has them. |
| Retryability | unresolved optional candidate | Only when the host can determine the meaning without inventing provider policy. |

These meanings do not require a shared package or class hierarchy. The Python
reference names and field spelling are documented in
[PORTABLE_CONTRACT.md](PORTABLE_CONTRACT.md), but are not the portable source
of truth.

### Python reference only

`ActionRegistry` remains useful and tested in the Python reference kernel. It
is a dispatch implementation detail, however, and `kinotch-api` already has
Hono routing, `routePolicies`, and `registerRoute`. Adding a second registry
would create duplicate dispatch rather than a shared meaning.

### Revise or hold

`ActionContext` is not a cross-language service bundle yet. `ActionResult` is
an observation target only because the first Pilot immediately unwrapped the
domain payload, and the API Gateway returns an HTTP `Response`. The second
Pilot must not wrap that response merely to make the types look similar.
`ActionErrorException` remains a Python implementation mechanism rather than a
portable Contract.

### Defer

Cancellation, progress, resources, artifacts, configuration, and logging have
reference tests but no real heterogeneous-Pilot evidence yet. They are not
removed from the reference implementation and are not required by the API
probe. The SynTrail-LM design probe will inspect only the existing meanings of
Progress, cancellation lifecycle, Resource, and Artifact; it will not add a
Rust Runtime crate by default.

## SynTrail-LM design-probe evidence

The third Pilot inspected the exact SynTrail-LM `origin/main` commit
`2326cf1`. It was a design-only probe; no SynTrail-LM production code or Rust
Runtime crate was added.

| Contract | SynTrail evidence | Decision | Maturity effect |
|---|---|---|---|
| Progress | Private Trainer worker event stream with source bytes, checkpoints, analytics, and terminal events consumed by the GUI | PARTIAL GO | Keep as candidate; not multi-repo-validated |
| Cancellation | Pause/resume/stop/disconnect and save failure have distinct state-machine meanings | REVISE / direct mapping rejected | Current Python token remains reference-only; portable lifecycle unresolved |
| Resource | Concrete Dataset/path/fingerprint and file-kind handling; no generic acquisition boundary | HOLD | No promotion |
| Artifact | Model output, trainer resume state, checkpoint pairing, and history have different meanings | HOLD | No promotion |

The event stream was not copied into a test fixture because doing so would
duplicate a private implementation rather than exercise a shared boundary.
There is no evidence for a production adapter or Surface Pack.

## Maturity rule

`implemented` and `unit-tested` describe the reference package. A test-only
JavaScript observation is evidence of semantic compatibility, not a Runtime
integration. `multi-repo-validated` requires the same meaning and change reason
in both repositories through their real execution responsibilities. `stable`
additionally requires unresolved REVISE/HOLD concerns to be closed; the
the second or third Pilot alone does not grant it.
