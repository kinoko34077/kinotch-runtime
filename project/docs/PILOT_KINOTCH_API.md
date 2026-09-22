# kinotch-api Second Pilot Design Probe

Status: design probe prepared; implementation HOLD pending the boundary decision

## Purpose

`kinotch-api` is the heterogeneous check for the first Pilot's remaining
meanings. It is JavaScript using ES Modules, the Node test runner, Hono, and
Cloudflare Workers. It is not a TypeScript project and must not install the
Python `kinotch-runtime` package.

The probe asks whether Action ID, ActionRequest, and ActionError retain a
useful meaning at an HTTP/Worker boundary without changing the existing public
API. ActionResult is an observation target only.

## Actual repository structure

The current Gateway and Text Worker boundaries are:

```text
src/index.js
  request-id middleware
  observability middleware
  CORS middleware
  ↓
src/routes/api.js
  registerRoute()
  ↓
src/middleware/guard.js
  route policy
    ├ authentication
    ├ rate limit
    ├ body limit
    └ validation
  ↓
src/services/proxy.js
  ↓
Cloudflare Service Binding
  ↓
src/text-transform-worker.js
```

The relevant source files are:

- `src/index.js`
- `src/middleware/request-id.js`
- `src/middleware/errors.js`
- `src/middleware/authentication.js`
- `src/middleware/rate-limit.js`
- `src/middleware/body-limit.js`
- `src/middleware/validation.js`
- `src/middleware/guard.js`
- `src/policies/routes.js`
- `src/routes/api.js`
- `src/services/proxy.js`
- `src/text-transform-worker.js`

## Actual request flow

For `POST /v1/transform/batch`, the existing path is:

```text
POST /v1/transform/batch
  ↓
routePolicies.transformBatch
  ↓
policyMiddleware()
  ├ method check
  ├ rate limit checks
  ├ body byte limit
  └ validateRequest()
       ├ parse JSON from request bytes
       ├ validateBatchBody()
       ├ c.set("validatedBody", body)
       └ c.set("requestBodyBytes", bytes)
  ↓
proxyToWorker()
  ├ preserve original request body bytes
  ├ attach X-Request-ID
  ├ apply timeout and AbortController
  ├ call Service Binding
  ├ allowlist response headers
  └ map upstream status
  ↓
TEXT_TRANSFORM Worker
```

The Gateway route is therefore Policy + Transport Proxy, not an independent
application operation. The Text Worker contains the domain-nearer path:

```text
parse body
  → validate text(s) and profile
  → selectStages()
  → compileRuntimePlan()
  → transformText()
  → result object
  → HTTP JSON Response
```

That Worker path still depends on Hono context, `env`, `ASSETS`, request URL,
and tokenizer loading. No pure `transformBatch(input, dependencies) → result`
boundary has been extracted for this probe.

## Runtime boundary mapping

### Action ID

The existing `routePolicies` already provide stable IDs such as
`transform-batch`, `semantic-compression`, `ruby-parse`, and `health`. The
current Runtime identifier syntax `^[a-z0-9_.-]+$` accepts them. The probe
must use an existing Policy ID as an operation identifier if needed; it must
not invent `text.transform.batch`, add a new registry, or equate an HTTP path
with an execution handler.

This is the strongest cross-language candidate because the value already
exists, is used for policy selection, and has no required Runtime dependency.

### ActionRequest

The semantic mapping is possible:

```text
ActionRequest.action_id  ← route policy id
ActionRequest.input      ← validatedBody
ActionRequest.request_id ← c.get("requestId")
```

The production Gateway must not construct this wrapper merely to turn
`validatedBody` back into the original raw bytes that `proxyToWorker()` sends
to the private Worker. The wrapper is therefore a test-only observation unless
an application boundary is found below the transport proxy.

The probe must not wrap Hono `Context`, `Request`, `Response`, headers, env, or
Service Binding handles.

### ActionError

The existing API error shape is already close in meaning:

```json
{
  "status": 400,
  "code": "invalid_profile",
  "message": "...",
  "details": {}
}
```

`validation.js` produces the error fields; `errorResponse()` adds the
HTTP-facing body and `requestId`. `errors.js` handles Gateway/upstream errors
and `proxy.js` maps timeout, unavailable, and upstream failure conditions.

The public API uses lower-snake codes including `invalid_json`, `invalid_text`,
`invalid_texts`, `invalid_profile`, `payload_too_large`, `rate_limited`,
`upstream_unavailable`, `upstream_timeout`, and `upstream_failure`. Runtime v0.1
currently recommends upper-snake codes such as `INVALID_INPUT`, `NOT_FOUND`,
and `INTERNAL_ERROR`.

The probe must not rename the public API codes. It must compare these options:

1. A portable error value with `code`, `message`, `details`, and optional
   `retryable`, while the host chooses its code spelling.
2. Runtime internal codes plus a serialization mapping to lower-snake API
   codes, with the mapping cost measured rather than assumed away.
3. No Runtime `ActionError` implementation in the API, because the existing
   API error contract already owns this boundary.

HTTP status and `requestId` remain API adapter metadata. A code-case rewrite
alone is not evidence of shared meaning.

### ActionResult

The Gateway currently returns `Response` from `proxyToWorker()`. Wrapping that
as `ActionResult<Response>` would add a layer without moving a common
application result or error boundary. The Text Worker returns structured JSON,
but its transformation flow remains coupled to Worker services and Hono.

ActionResult is therefore HOLD for production integration. It may be observed
in a test only if a pure application result already exists; this probe must
not create one just to satisfy the Runtime shape.

## Responsibility that remains in kinotch-api

The following stay Project-owned and are out of Runtime scope:

- Hono Context, HTTP method/path/status, HTTP `Response`, and headers
- CORS and request ID generation/propagation
- authentication, rate limiting, and body byte limits
- query/body validation and public lower-snake error codes
- Service Binding calls and Cloudflare bindings
- upstream timeout, `Retry-After`, response header allowlist, and status mapping
- deploy, rollback, smoke, generated clients, and release policy
- Text Core, compression core, tokenizer, `ASSETS`, and Worker-specific config

## Design Probe accounting

The current production path has zero Runtime wrappers, zero Runtime
dependencies, and zero public-contract conversions. The candidate mappings
would add, if implemented:

| Candidate | Existing meaning | New wrapper/conversion | Public API impact |
|---|---|---|---|
| Action ID | `routePolicies.*.id` | none | none |
| ActionRequest | validated body + request ID | one plain object in a test or application boundary | none if test-only |
| ActionError | API error object | one field-shape comparison; code-case mapping is optional | must remain unchanged |
| ActionResult | HTTP Response / Worker JSON | Response wrapper would be added | risk of changed headers/status/body |

The existing Gateway already has one dispatch path through Hono and
`registerRoute()`. Adding ActionRegistry would create a second dispatcher. The
first probe must not add it.

## GO / PARTIAL GO / HOLD gate

### GO

Use only if multiple meanings can be observed naturally, duplicate change
reasons are centralized, the public API stays unchanged, and the added adapter
is smaller than the repeated responsibility it replaces.

### PARTIAL GO

The current strongest result is PARTIAL GO for Action ID and an error-semantics
comparison. ActionRequest is a semantic mapping but implementation is HOLD if
it only wraps validated input before the Gateway serializes the original raw
body. ActionResult remains HOLD unless an existing pure application result is
found without wrapping `Response`.

### HOLD

HOLD the Runtime implementation when the result is a second dispatch layer,
case conversion only, Context/Response wrapping, adapter-only code, new
dependency, or any public API behavior change. A HOLD is a valid scope result:
Runtime may be useful for local Python Action execution while being unsuitable
for this HTTP proxy boundary.

## Initial decision before production changes

Design-only probe: **PARTIAL GO for Action ID and error semantics; HOLD for
ActionRegistry, ActionRequest implementation, ActionResult, and all unused
Runtime services.**

No `kinotch-api` production code, dependency, Surface Pack, or deployment
configuration is changed by this document. A later test-only probe may compare
the existing error object to a portable plain-object shape, but it must first
preserve status, code, message, details, request ID, headers, and Service
Binding behavior.
