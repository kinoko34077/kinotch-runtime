# KiNoTch. Runtime

KiNoTch. Runtime v0.1 is the first small execution layer shared by KiNoTch. repositories.

It provides a dependency-free Python reference implementation for registered Actions, structured results and errors, progress, cancellation, resources, artifacts, configuration, and logging. It intentionally does not provide CLI, MCP, API, GUI, deployment, filesystem, or provider policy.

## Development

```powershell
python -m unittest discover -s project/tests -v
.\knt.cmd doctor
.\knt.cmd verify
```

The first integration Pilot is `jev-audit`. Its CLI/MCP live comparison is
complete, but the Contract remains provisional because one Python repository is
not enough for cross-repository stability. The `kinotch-api` design probe is
also complete as a test-only semantic probe; production Runtime integration is
on hold. The evidence is recorded in the Runtime documentation.

See [the specification](project/docs/SPEC.md) and [current state](project/docs/CURRENT_STATE.md).
