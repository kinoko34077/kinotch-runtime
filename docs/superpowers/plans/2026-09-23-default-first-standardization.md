# KiNoTch. Default-First Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Establish the Default-first boundary and provide a safe, profile-aware `knt init` foundation without moving Domain behavior into Base or Runtime.

**Architecture:** Repository Base owns the canonical four-layer policy, the default-state schema, and the initialization router. A generated Project records selected Default Packs as `DEFAULT`, `OVERRIDE`, or `DISABLED`; the router never rewrites an existing Project. Runtime documentation references the Base policy and keeps Portable Contract maturity independent from Default adoption.

**Tech Stack:** PowerShell 5.1/7-compatible router, dependency-free JSON Schema subset, Markdown, JSON, Python documentation-only Runtime repository.

**Spec:** User-provided `KiNoTch. Repository Default-First Standardization Specification v0.1`.

## Global Constraints

- Keep L1 Hard Base and L3 Portable Semantic Contract ownership separate.
- Default Pack behavior must be overrideable or disableable per Project.
- Do not add Domain algorithms, public API compatibility rules, persistent Domain formats, Surface Pack libraries, or Runtime language bindings.
- Preserve Windows PowerShell 5.1 compatibility and deterministic generated output.
- Do not overwrite an existing `project/project.json` during `knt init`.
- Keep Base v0.2.1 and Runtime v0.1.0 unless a Contract behavior changes.

## Review Focus

- Repeated `--profile` arguments must produce one deterministic profile/module/surface union; test with CLI + MCP.
- `knt init` must refuse an initialized Project and never overwrite files; test against the Base itself.
- Default state values outside `DEFAULT`, `OVERRIDE`, and `DISABLED` must fail `doctor`; test an invalid fixture.
- A generated Project must pass `doctor` immediately; test all generated paths and registries.
- Existing single-profile manifests must continue to pass unchanged; run the full Base self-test and Runtime suite.

### Task 1: Canonical Default-first policy and roadmap split

**Files:**
- Create: `kinotch-repository-base/.kinotch/meta/06_DEFAULT_FIRST_STANDARD.md`
- Modify: `kinotch-repository-base/.kinotch/meta/README.md`
- Modify: `kinotch-repository-base/.kinotch/meta/02_ROADMAP.md`
- Modify: `kinotch-repository-base/.kinotch/README_BASE.md`
- Modify: `kinotch-repository-base/project/docs/CURRENT_STATE.md`

- [ ] Record the four layers, three Default states, Q1-Q4 decision rule, Default Pack scope, and `knt init`/`migrate` safety rule in the new canonical document.
- [ ] Link the document from Meta and Base README without copying the full policy into Runtime docs.
- [ ] Split the roadmap into Phase 2A Portable Contract validation and Phase 2B Default extraction, then keep Phase 3/4 independent.
- [ ] Update Base Current State to describe the Default-first foundation as the next implementation line.
- [ ] Run `git diff --check` and commit the Base documentation as `docs: define Default-first repository standard`.

### Task 2: Default state schema and profile-aware initialization

**Files:**
- Create: `kinotch-repository-base/.kinotch/schemas/defaults.schema.json`
- Create: `kinotch-repository-base/.kinotch/templates/project/defaults.json`
- Create: `kinotch-repository-base/.kinotch/templates/project/src/README.md`
- Create: `kinotch-repository-base/.kinotch/templates/project/tests/README.md`
- Modify: `kinotch-repository-base/.kinotch/schemas/project.schema.json`
- Modify: `kinotch-repository-base/.kinotch/scripts/knt.ps1`
- Modify: `kinotch-repository-base/.kinotch/templates/project/project.json`
- Modify: `kinotch-repository-base/.kinotch/tests/run-tests.ps1`

- [ ] Add a failing self-test for multi-profile `init`, refusal on an existing manifest, invalid Default state rejection, and generated-project doctor success.
- [ ] Run the focused self-test and observe failure from the missing `init` path/schema integration.
- [ ] Add optional `profiles` to the Project schema while retaining required primary `profile` for compatibility.
- [ ] Add the Default state schema and make `doctor` validate a declared `paths.defaults` file.
- [ ] Implement `knt init` with repeated `--profile`, `windows` alias support, deterministic profile union, safe refusal on existing `project/project.json`, and template-to-root/project mapping.
- [ ] Make `doctor` evaluate all selected profiles and union their recommended modules/surfaces without breaking single-profile manifests.
- [ ] Run the focused self-test, then the complete Base self-test and `doctor`/`verify`.
- [ ] Refresh Base index, rerun `base-check`, commit as `feat: add safe Default-first project initialization`, and push.

### Task 3: Runtime responsibility synchronization

**Files:**
- Modify: `kinotch-runtime/project/docs/SPEC.md`
- Modify: `kinotch-runtime/project/docs/PORTABLE_CONTRACT.md`
- Modify: `kinotch-runtime/project/docs/CURRENT_STATE.md`
- Modify: `kinotch-runtime/project/docs/INDEX.md`

- [ ] Add a short reference to the Base Default-first policy and state that Default adoption does not promote a Portable Contract.
- [ ] Record that Surface/Tool Defaults are host/project-overridable and that Runtime remains responsible only for execution semantics.
- [ ] Update Runtime Current State and index to show the parallel Default Pack path.
- [ ] Run Runtime unit tests, `knt doctor`, `knt verify`, and `git diff --check`.
- [ ] Commit as `docs: separate Runtime Contracts from Default adoption` and push.

### Task 4: Final gate and remote verification

- [ ] Run Base self-tests, `knt doctor`, `knt base-check`, and `knt verify`.
- [ ] Run Runtime unit tests, `knt doctor`, and `knt verify`.
- [ ] Confirm both working trees are clean and compare local HEAD with remote branches.
- [ ] Confirm CI success for the latest Base and Runtime pushes.
- [ ] Record any external CI/network limitation without claiming a pass that was not observed.
