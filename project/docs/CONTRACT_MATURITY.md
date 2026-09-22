# Runtime Contract Maturity Matrix

The matrix separates two decisions. `Reference implementation` describes the
Python v0.1 package and its unit-test status. `Cross-language Contract` asks
whether the same meaning should cross the Python/JavaScript boundary. A
`pilot-exercised` value was used by the real `jev-audit` path; it is not proof
of reduced maintenance or stability.

No Contract below is `stable`. The `jev-audit` Pilot alone cannot earn
`multi-repo-validated`.

| Contract | Reference implementation | Cross-language Contract | jev-audit evidence | Next Pilot | Decision |
|---|---|---|---|---|---|
| Action ID | implemented, unit-tested | candidate | `repo.audit` identifier used | carry as operation identifier | KEEP |
| ActionRegistry | implemented, unit-tested | not required by API boundary | CLI/MCP register/execute `repo.audit` | do not introduce | Python KEEP / cross-language DEFER |
| ActionRequest | implemented, unit-tested | candidate, wrapper shape unvalidated | request envelope used | observe plain-object mapping only | KEEP candidate |
| ActionContext | implemented, unit-tested | not required as service bundle | empty context constructed only | exclude service bundle | REVISE |
| ActionResult | implemented, unit-tested | observation target only | wrapper carried `AuditReport` then unwrapped | do not wrap HTTP `Response` | REVISE / HOLD |
| ActionError | implemented, unit-tested | candidate semantics | missing profile maps to `NOT_FOUND` | compare with API error fields | KEEP candidate |
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

`Action ID`, `ActionRequest`, and `ActionError` remain the only meanings to
observe across the Python/JavaScript boundary. The observation must use plain
objects or existing values where possible; it must not require a new runtime
library, registry, framework adapter, or public API rename.

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
reference tests but no real second-Pilot demand. They are not removed from the
reference implementation and are not required by the API probe.

## Maturity rule

`implemented` and `unit-tested` describe the reference package. A
cross-language meaning may become `pilot-exercised` only after the JavaScript
probe uses it naturally. `multi-repo-validated` requires the same meaning and
change reason in both repositories. `stable` additionally requires unresolved
REVISE/HOLD concerns to be closed; the second Pilot alone does not grant it.
