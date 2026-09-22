# Runtime Execution Contract

These files are the canonical Execution Contract definitions owned by
`kinotch-runtime`.

The Repository Base copy under `.kinotch/schemas/` is inherited validation
compatibility material. It is not an independently editable source of truth.
When Base validation needs an updated execution schema, the Runtime canonical
file must be reviewed first and the synchronization should be handled as a
separate, explicit change.

The v0.1 schemas cover the implemented result, error, progress, resource, and
artifact envelopes. `ActionRequest`, `ActionContext`, and cancellation remain
implemented Python reference values without standalone schemas until Pilot
evidence shows that a language-neutral schema is useful.

## Status

These schemas are provisional. They describe the current reference
implementation but are not a stable cross-repository contract until the
`jev-audit` Pilot is evaluated.
