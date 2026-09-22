# standby-display Runtime Design Probe

Status: evaluation complete; design-only probe; no standby-display production code changed

Observed commit: `2be070ed8ff878c1d3f526e07ddce0b0f21cdfbf` (`origin/main`)

## Actual boundary

`standby-display` is a browser/PWA project with a modern module path and an
ES5 legacy path. Its common runtime is browser and Web/PWA-specific:

- `bootstrap.js` and `modern-entry.mjs` select the modern or legacy path.
- `scripts/` owns clock state, settings, rendering, services, and fallback.
- `legacy/` preserves an old-device-compatible implementation.
- `service-worker.js` owns cache strategy and offline asset behavior.
- `tools/build-assets.mjs` creates `dist/` from a fixed set of browser assets.
- Cloudflare Workers Builds and `npm run verify` are the release boundary.

The repository also consumes generated client artifacts from the sibling
`kinotch-api` repository. `scripts/tools/sync-text-client.mjs` treats the API
checkout as canonical when available and synchronizes:

```text
kinotch-api generator
  -> vendor/text-transform.mjs
  -> vendor/kanji-fallback.mjs
  -> recorded .sha256 files
```

When the canonical source is unavailable, `--check` verifies the generated
header and recorded hashes. A source-aware check compares generated content and
hashes. An explicit missing source fails instead of silently downgrading the
check. `tools/build-assets.mjs` separately clears and rebuilds `dist/` with
path-safety checks.

## Existing verification evidence

The project tests already cover:

- generated client presence and stale check
- standalone checkout verification without the source repository
- tampered generated client hash rejection
- explicit missing canonical source rejection
- release verify/build/deploy command composition
- service-worker precache of modern and legacy assets

The native-permission `npm test` invocation at this observed checkout stopped
at the pretest stale check:

```text
Vendor text client is stale: vendor\\text-transform.mjs
Run `npm run sync:text-client` and review the generated client/fallback diff and hashes.
```

The earlier sandbox invocation stopped before Node startup with the known
Windows `EPERM lstat C:\\Users\\kinok` environment limitation. The stale
result is a useful boundary observation, not permission to overwrite generated
files. No sync or production deployment was performed.

## Artifact and ownership observation

The generated vendor modules, recorded hashes, and `dist/` contents are real
artifacts, but their meaning is:

- source ownership and generator compatibility
- stale/tamper detection
- browser distribution assembly
- service-worker cache completeness

They are not execution results returned by a Runtime Action. The source repo,
consumer repo, and release/deploy policy are explicit project boundaries.

### Artifact decision: HOLD for Runtime

The generated-file/hash relationship is a potential future tooling or Base
conformance pattern, but this Pilot does not validate the Runtime `Artifact`
value object. A Runtime wrapper would add a second authority around an already
working generated-source and release gate. Keep the boundary in
`standby-display` and `kinotch-api`.

## Other Contract observations

- No independent Action ID or ActionRequest boundary exists for the generated
  synchronization; the command is a build/tooling operation.
- Error behavior is a project/tooling CLI boundary. It should not be rewritten
  into the Runtime ActionError merely to normalize text.
- `--source`, sibling repository paths, vendor paths, and `dist/` are concrete
  build resources, not evidence for a portable Runtime Resource abstraction.
- Service-worker caching, modern/legacy fallback, and Cloudflare deployment are
  Surface/deployment responsibilities and remain project-owned.

## Design-probe result

| Contract | Decision | Evidence | Action |
|---|---|---|---|
| Generated artifact / hash | HOLD | Existing source→vendor→hash→stale gate is already explicit | No Runtime adapter; keep Project tooling |
| Resource | HOLD | Concrete repo/file paths and build inputs | No Runtime Resource wrapper |
| Action / Request | HOLD | No application operation boundary in the sync tool | No mapping |
| Error | HOLD | Existing check output is build/dependency-specific | Preserve local error semantics |
| Service-worker / legacy Surface | OUT OF SCOPE | Browser compatibility and offline cache behavior | No Surface Pack |

No production Pilot, Runtime dependency, or Surface Pack follows from this
probe. The stale failure is kept as observed evidence and is not repaired by
this Runtime task.

## Next validation

Only revisit this boundary if a second repository has the same source-owned
generated artifact and stale-check change reason. If that happens, evaluate a
narrow tooling/conformance contract separately from Runtime execution
`Artifact` semantics.
