# KiNoTch. Base / Runtime Roadmap

この文書は共通層から参照する短いRoadmap Indexである。
背景・到達状態・判断基準・検証計画を含む詳細な設計Metaは [`../meta/README.md`](../meta/README.md) を参照する。

## Phase 0 — Repository Base v0.1系

- Base / Project境界
- 共通AGENTS
- Project Manifest
- Action / Surface Contract
- `knt` command router
- doctor / verify / base-check
- Spec / Current State / ADR骨格
- Base / Runtime設計Meta

## Phase 0.5 — Repository Base v0.2 Hardening

- Base自身のIdentityとSPEC / CURRENT_STATE
- `.kinotch/meta/` と `.kinotch/templates/project/` の分離
- Manifest / Action / Surface Schema validation
- Profile / path / command diagnostics
- Base self-test fixtures and runner
- Deterministic `base-refresh` and strict Base protection
- Runtime Contractの確定済み / 候補の分離

## Phase 1 — Runtime Kernel v0.1

- Action / Result / Error / Progress / Resourceの最小実装
- Config / filesystem / logging
- 言語別の薄いbinding方針

## Phase 2 — 代表repoで試験導入

- CLI + MCP: `jev-audit`
- Windows GUI + CLI: `SynTrail-LM`
- API / Web: `kinotch-api` / `standby-display`

## Phase 3 — Surface Pack

反復利用が確認できたものだけ追加する。

## Phase 4 — Tooling

- `knt init`
- `knt migrate`
- generated artifact / stale check
- 詳細doctor / conformance report

## Phase 5 — 既存repoへ段階導入

一括書換えを行わず、保守・改修のタイミングで適用する。

## Phase 6 — 必要時のみ安定化拡張

Version migration / multi-language binding / generated descriptors等は、実利用上必要になった場合のみ進める。
