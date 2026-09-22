# Runtime Contract Maturity Matrix

The matrix separates implementation from evidence. `pilot-exercised` means a
real `jev-audit` execution path used the value. It does not mean the Contract
reduced complexity or is stable. No Contract below is `multi-repo-validated` or
`stable`.

| Contract | Implemented | Unit-tested | jev-audit Pilot | Maturity | Decision |
|---|---|---|---|---|---|
| ActionRegistry | yes | yes | CLI and MCP register/execute `repo.audit` | pilot-exercised | KEEP |
| ActionRequest | yes | yes | `repo.audit` request envelope used | pilot-exercised | KEEP |
| ActionContext | yes | yes | empty context constructed only | pilot-exercised, incidental | REVISE |
| ActionResult | yes | yes | success wrapper carries `AuditReport` | pilot-exercised | REVISE |
| ActionError | yes | yes | missing profile maps to `NOT_FOUND` | pilot-exercised | KEEP |
| ActionErrorException | yes | yes | expected bridge errors use it | pilot-exercised | REVISE |
| CancellationToken | yes | yes | not exercised | unit-tested | DEFER |
| ProgressEvent | yes | yes | not exercised | unit-tested | DEFER |
| ProgressReporter | yes | yes | not exercised | unit-tested | DEFER |
| Resource | yes | yes | not exercised | unit-tested | DEFER |
| Artifact | yes | yes | not exercised | unit-tested | DEFER |
| RuntimeConfig | yes | yes | not used; no config mapping | unit-tested | DEFER |
| Logging boundary | yes | yes | incidental Runtime error log only | unit-tested | DEFER |

## Interpretation

### KEEP

`ActionRegistry`, `ActionRequest`, `ActionError`, and Action ID validation are
small enough to carry into the next design probe. They were exercised without
changing the Audit Core, but they are not yet `pilot-validated`: the Pilot did
not demonstrate a measurable reduction in maintenance work.

### REVISE

`ActionResult` currently accepts arbitrary domain data and is immediately
unwrapped by the `jev-audit` bridge. The envelope is therefore a candidate,
not a proven shared output format. `ActionContext` was constructed but its
configuration, progress, cancellation, and logger services were unused.
`ActionErrorException` is useful inside the Python kernel, but its Python
exception shape should not be treated as a cross-language Contract.

### DEFER

Cancellation, progress, resources, artifacts, configuration, and logging have
unit tests but no real Pilot demand. They remain available in the reference
implementation without being required by the next Pilot.

### REMOVE

No Contract is removed in this evaluation. The evidence supports shrinking the
next Pilot surface, not deleting tested reference values before a second
heterogeneous validation.

## Maturity rule

The Runtime remains `provisional`. `pilot-exercised` is the highest status
earned by the `jev-audit` Pilot. `pilot-validated` requires evidence that the
existing repository became simpler or had a common change reason centralized;
`stable` additionally requires the same meaning in at least one heterogeneous
repository.
