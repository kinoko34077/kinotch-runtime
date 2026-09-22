# KiNoTch. Runtime v0.1 Contract Alignment and jev-audit Pilot Plan

## Goal

Make the Runtime v0.1 reference contract internally consistent and validate
the smallest useful integration in `jev-audit` without changing its Audit Core
or adding Surface Packs.

## Constraints

- Runtime remains provisional until Pilot evidence exists.
- Runtime owns canonical Execution Contract schemas under
  `project/contracts/execution/`.
- `.kinotch/**` remains inherited Base infrastructure and is not independently
  edited as a second source of truth.
- `jev-audit` Core, CLI output meaning, and MCP path/security behavior remain
  intact; only a thin adapter boundary may change.
- Every implementation slice is test-first, verified, committed, and pushed.

## Work order

1. Mark Runtime Contract status provisional and document ownership boundaries.
2. Move/copy Execution Contract schemas into Runtime-owned canonical paths and
   remove the declaration-only `runtime.health` Action.
3. Add failing tests for Action ID, Resource, Artifact, Result, and schema
   alignment; implement the smallest fixes.
4. Verify Runtime tests, Base doctor/verify, and Runtime GitHub Actions; commit
   the Pilot-ready Runtime state.
5. Inspect `jev-audit` baseline behavior and add a thin Runtime adapter used by
   both CLI and MCP, with tests proving the Audit Core remains untouched.
6. Measure adapter/config/error/result changes and record Pilot findings in the
   Runtime and `jev-audit` current-state documents.

## Non-goals

CLI/MCP/API/GUI Surface Packs, Action Registry auto-binding, plugin discovery,
`runtime.requires`/`provides`, authentication, retries, filesystem abstraction,
and deployment policy are outside this Pilot.
