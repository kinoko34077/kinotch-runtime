# ADR 0002: kinotch-api Second Pilot Design Probe

Status: accepted — PARTIAL GO for test-only semantics; production integration HOLD

## Context

`kinotch-api` is a JavaScript ES Modules Hono/Cloudflare Workers repository.
Its Gateway already has Hono routing, `routePolicies`, `registerRoute`, policy
middleware, request IDs, validation, rate limits, body limits, and a Service
Binding proxy. The Text Worker contains domain-nearer transformation logic but
still depends on Worker context, assets, request URL, and tokenizer services.

The Gateway therefore has a Policy + Transport Proxy boundary rather than a
pure Runtime application operation. The public API already uses lower-snake
error codes and must not be changed to match Python Runtime uppercase codes.

## Evidence

- Actual source paths and request flow are recorded in
  `project/docs/PILOT_KINOTCH_API.md`.
- The existing production path has zero Runtime dependencies, wrappers, and
  public-contract conversions.
- `npm test` completed with 150 tests: 149 passed and one intentional live
  compression test was skipped.
- `npx wrangler deploy --dry-run` completed successfully and listed the current
  Worker and Service Binding boundary.
- `routePolicies.transformBatch.id` is already `transform-batch` and matches
  the Runtime identifier syntax without a new registry or identifier scheme.
- Validation errors already expose `code`, `message`, and optional `details`,
  while HTTP status and request ID are adapter metadata.
- Wrapping `Response` as `ActionResult<Response>` would add a layer without
  centralizing an existing application result.
- The test-only probe uses the real `routePolicies.transformBatch.id` and
  `validateBatchBody()` values. It passes 2/2 targeted tests and leaves API
  production code unchanged.

## Decision

- PARTIAL GO for a test-only semantic probe of existing Action IDs and error
  fields.
- The test-only probe is compatibility evidence only; it does not promote the
  meanings to `multi-repo-validated` because no Runtime adapter executes inside
  the API.
- Preserve existing route Policy IDs such as `transform-batch` as operation
  identifiers; do not add ActionRegistry or automatic handler discovery.
- Preserve lower-snake public API error codes. Compare portable error meaning
  as `code`, `message`, `details`, and optional `retryable` without requiring a
  case conversion.
- HOLD production ActionRequest construction because the Gateway validates
  input and then forwards the original request bytes to the private Worker.
- HOLD ActionResult because the Gateway returns HTTP `Response` and no pure
  application result boundary was found without extracting or changing the
  Text Worker.
- HOLD ActionRegistry, Context service bundles, and unused Runtime modules.
- Do not add a Python dependency, JavaScript Runtime library, Surface Pack,
  deployment configuration, or production route layer.

## Consequences

The second Pilot has shown that two small meanings can be represented without
changing API behavior. It does not claim that the full Runtime is usable by an
HTTP proxy. ActionRequest and ActionResult remain unresolved, and Runtime
remains provisional. The test-only probe is evidence for semantic compatibility,
not `pilot-exercised`, `multi-repo-validated`, or `stable` Runtime integration.

## Next validation

The local test fixture/helper already maps an existing Policy ID and API
validation error to plain objects. Keep `kinotch-api` production code
unchanged. If a genuine application boundary is later found, reopen
ActionRequest or ActionResult separately with a new failing test; otherwise
move to the next heterogeneous candidate without adding a Surface Pack.
