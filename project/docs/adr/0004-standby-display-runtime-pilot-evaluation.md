# ADR 0004: standby-display Runtime Pilot Evaluation

Status: Accepted for the current v0.1 provisional scope

## Context

The fourth roadmap candidate is a Web/PWA repository with modern and legacy
browser Surfaces, generated clients from `kinotch-api`, recorded hashes, a
stale check, and a release asset builder. The question is whether its
generated-artifact integrity boundary is a Runtime Artifact or a reusable
execution Contract.

The inspected source was exact `origin/main` commit
`2be070ed8ff878c1d3f526e07ddce0b0f21cdfbf`. No source or generated file was
changed.

## Evidence

- `scripts/tools/sync-text-client.mjs` compares canonical generator output,
  generated headers, and recorded SHA-256 values.
- Standalone-checkout tests verify the vendored files without the source repo,
  reject tampering, and reject an explicitly missing canonical source.
- `tools/build-assets.mjs` clears and rebuilds `dist/` with path-safety checks.
- The native-permission test invocation stopped at the intended stale check for
  `vendor/text-transform.mjs`; no generated sync or deploy was performed.
- Browser fallback, service-worker cache, Cloudflare deploy, and release gate
  behavior remain project-owned.

## Decision

### HOLD Runtime Artifact

Generated vendor files, recorded hashes, and `dist/` are build/integrity
artifacts, not results returned by a Runtime Action. The source repository,
consumer repository, and deployment policy are explicit authorities. Adding a
Runtime wrapper would create a second authority and would not reduce a shared
change reason.

### Keep project-specific error and resource handling

Source paths, vendor paths, stale output, and build errors remain local to the
Web/build boundary. HTTP/API, service-worker, legacy-browser, and deployment
semantics are not Runtime Surface Packs.

### No repair from this ADR

The observed stale check is evidence that the gate works. It is not permission
to overwrite generated files during a Runtime contract evaluation.

## Consequences

- No Runtime dependency, Artifact adapter, Surface Pack, or standby-display
  production change is added.
- A future common tooling/conformance candidate requires a second repository
  with the same source-owned generated-artifact and stale-check change reason.
- The Runtime Artifact value object remains provisional and unresolved.

## Next validation

Only compare the narrow source→generated→hash→stale meaning with another real
consumer. Keep it separate from execution Artifact semantics unless both
boundaries demonstrate the same consumer and change reason.
