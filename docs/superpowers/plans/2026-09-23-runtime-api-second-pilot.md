# Runtime API Second Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Correct the post-Pilot ownership documents, record the real kinotch-api JavaScript boundaries, and run only the smallest evidence-based second-Pilot probe without forcing Runtime wrappers into the HTTP Gateway.

**Architecture:** Base remains frozen at v0.2.1 and only receives state/ownership documentation plus a refreshed protected index. Runtime remains Python v0.1.0 provisional and owns the maturity classification and Pilot records. kinotch-api is first observed through its existing JavaScript/Hono/Worker tests; no Python dependency, Surface Pack, ActionRegistry, or HTTP Response wrapper is introduced.

**Tech Stack:** PowerShell Base router, Markdown/JSON Runtime contracts, JavaScript ES Modules, Hono, Cloudflare Workers, Node test runner.

**Spec:** User-provided “KiNoTch. Runtime 第2Pilot着手・全体進行指示書” in the current task.

## Global Constraints

- Base version remains `0.2.1` unless Base Contract behavior changes.
- Runtime version remains `0.1.0` unless Contract behavior changes.
- `kinotch-api` remains JavaScript / ES Modules / Hono / Cloudflare Workers.
- Do not install the Python Runtime package into `kinotch-api`.
- Do not add ActionRegistry dispatch to the Gateway.
- Do not wrap HTTP `Response`, Hono `Context`, Service Binding, headers, or deployment results in `ActionResult`.
- Preserve existing public API error codes, status, message, details, request ID, headers, and Service Binding behavior.
- Do not change production code during the initial Design Probe.
- Commit and push each verified repository-level progress unit.

## Review Focus

- Base ownership text must not simultaneously call `.kinotch/schemas/` the Execution Contract canonical source and a compatibility copy; test with Base doctor/base-check/verify.
- ActionRegistry must remain a Python reference primitive while the cross-language candidate set excludes it; test by document assertions and Runtime verification.
- kinotch-api must be described as JavaScript and its actual file paths/flow must match source; test with the existing npm suite and source inspection.
- Lower-snake public API error codes must not be renamed to Runtime upper-snake codes; test existing API error responses before any probe.
- The Gateway proxy must not gain ActionResult/ActionRequest wrappers when its operation is only policy plus transport; test the current proxy and route behavior unchanged.

### Task 1: Synchronize Base post-Pilot state

**Files:**
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-repository-base/project/docs/CURRENT_STATE.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-repository-base/.kinotch/RUNTIME_INTEGRATION.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-repository-base/.kinotch/base-files.json`

- [ ] Update Base Pilot state to evaluated, keep Base v0.2.1, and separate Base-owned declarations from Runtime-owned execution semantics.
- [ ] Refresh the Base hash index from the repository root.
- [ ] Run `.kinotch/tests/run-tests.ps1`, `knt doctor`, `knt base-check`, and `knt verify`.
- [ ] Commit and push `docs: sync Base with evaluated Runtime Pilot`.

### Task 2: Correct Runtime maturity axes

**Files:**
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/SPEC.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/CONTRACT_MATURITY.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/CURRENT_STATE.md`

- [ ] Change SPEC status to `provisional — first Pilot evaluated; heterogeneous validation pending`.
- [ ] Add separate Python reference status and cross-language status columns/decisions.
- [ ] Keep ActionRegistry as a tested Python reference primitive but exclude it from the initial cross-language second-Pilot set.
- [ ] Set the next candidate set to Action ID, ActionRequest, and ActionError; keep ActionResult as an observation target.
- [ ] Run Runtime unit tests, doctor, and verify.
- [ ] Commit and push `docs: align post-Pilot Runtime status`.

### Task 3: Correct the kinotch-api Design Probe

**Files:**
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/PILOT_KINOTCH_API.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/INDEX.md`

- [ ] Replace the TypeScript description with JavaScript / ES Modules / Hono / Cloudflare Workers.
- [ ] Record the actual Gateway and Text Worker paths and request flow.
- [ ] Record Action ID, ActionRequest, ActionError, ActionResult, wrapper count, conversions, public-contract impact, and GO/PARTIAL GO/HOLD criteria.
- [ ] Keep the initial result as design-only; do not change kinotch-api production code.
- [ ] Run `npm test` and `npx wrangler deploy --dry-run` in kinotch-api, then Runtime verification.
- [ ] Commit and push `docs: correct kinotch-api second Pilot design`.

### Task 4: Record the Design Probe decision

**Files:**
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/PILOT_KINOTCH_API.md`
- Create: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/adr/0002-kinotch-api-design-probe.md`

- [ ] Decide GO/PARTIAL GO/HOLD from the observed boundaries and test evidence.
- [ ] If only Action ID and error semantics are natural, record PARTIAL GO and keep ActionRequest/ActionResult implementation on HOLD.
- [ ] Do not modify kinotch-api until the decision identifies a non-wrapper production or test-only probe.
- [ ] Run Runtime verification and commit/push `docs: record kinotch-api Runtime design probe`.

### Task 5: Reassess second-Pilot implementation scope

**Files:**
- Modify only if the decision is GO/PARTIAL GO: `C:/Users/kinok/Documents/Programs/kinotch-api/test/` or a narrowly scoped existing test file.
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/CONTRACT_MATURITY.md`
- Modify: `C:/Users/kinok/Documents/Programs/kinotch-runtime/project/docs/PILOT_KINOTCH_API.md`

- [ ] Implement no Runtime library and no Gateway wrapper unless a test proves a repeated cross-language meaning with unchanged public API.
- [ ] If no such boundary exists, leave kinotch-api unchanged and record HOLD as the correct outcome.
- [ ] Update maturity only to `multi-repo-validated` for meanings demonstrated naturally in both repositories; never declare stable from two Pilots alone.
- [ ] Run the complete relevant suites and commit/push only verified changes.
