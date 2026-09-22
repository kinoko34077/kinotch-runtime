# kinotch-api Second Pilot Design

Status: GO for design-only probe; implementation HOLD

## Why this is the next candidate

`kinotch-api` is materially different from `jev-audit`: it is TypeScript,
Hono/Cloudflare Workers based, and its primary boundary is HTTP plus Service
Bindings rather than a local CLI/MCP process. It therefore tests whether the
retained Action/Request/Error meanings are language- and Surface-neutral.

## Existing boundaries

| API concern | Existing owner | Pilot treatment |
|---|---|---|
| HTTP request and Hono context | Gateway / Hono | remain Project-owned |
| request ID | `request-id.js` middleware | remain Project-owned; map as metadata only |
| query/body validation | `validation.js` and route policy | remain Project-owned |
| auth | `authentication.js` | remain Project-owned |
| rate limit | `rate-limit.js` and Cloudflare bindings | remain Project-owned |
| Service Binding call | `services/proxy.js` | remain Project-owned |
| HTTP error envelope | `errors.js` and validation responses | compare with ActionError semantics |
| health/smoke/deploy | route, scripts, release gate | remain Project-owned |
| transform/compression domain | Text/Compression Workers | remain Project-owned |

## Limited Contract probe

Only the following meanings may be evaluated initially:

- Action ID: a language-neutral operation identifier, not automatic handler
  discovery.
- ActionRequest: validated operation input plus request ID metadata at an
  application boundary; never wrap the entire Hono `Context`.
- ActionError: a code/message/details concept that can map to the existing HTTP
  error envelope. HTTP status and request ID remain API adapter fields.
- ActionResult: evaluate only for a pure application/service operation. Do not
  force a Runtime result around an HTTP `Response`, Service Binding, headers,
  or deployment result.

The Python Runtime package must not be installed into this TypeScript Worker.
The first probe should be a small TypeScript representation or test fixture,
not a general TypeScript Runtime library.

## Candidate observation point

The first candidate is the `POST /v1/transform/batch` application boundary
because it has validated input, a stable operation name, a structured success
payload, and existing upstream error handling. The probe must remain below
HTTP presentation and above the Text Worker Service Binding. If that boundary
requires wrapping `Response`, headers, retries, rate limits, or Hono context,
stop and classify the ActionResult mapping as HOLD.

## Measurements

Compare the existing route path with the probe for:

- added/removed TypeScript lines and adapter lines;
- error mapping count and preservation of `error`, `message`, `details`,
  HTTP status, and request ID;
- request validation and Service Binding behavior;
- generated client and smoke output;
- dependency, build, dry-run, and deploy complexity;
- whether the API's existing response/fallback contract remains unchanged.

## Go / Hold gate

Proceed beyond design only if the probe centralizes a repeated meaning without
moving auth, rate limit, request ID, Service Binding, retry, compression,
Text Core, or deploy policy into Runtime. Hold the implementation if the
adapter is a wrapper-only layer, if HTTP `Response` must become `ActionResult`
data, or if existing API behavior must change to fit the Contract.

Cancellation, Progress, Resource, Artifact, RuntimeConfig, Logging,
`runtime.requires/provides`, and Surface Packs are explicitly out of scope.
