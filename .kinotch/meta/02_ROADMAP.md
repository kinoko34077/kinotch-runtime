# 02 — Roadmap

## Phase 0 — Repository Base v0.1系

目的: 個別差分と共通基盤の境界を実物として固定する。

含める:

- 共通 `AGENTS.md`
- `.kinotch/` 共通規約
- `project/` 個別領域
- Project Manifest
- Action / Result / Error / Progress / Resource / Surface Schema
- `knt` command router
- doctor / verify / base-check
- Current State / SPEC / ADRの最小骨格
- Base / Runtime構想のMeta資料

完了条件:

- 新規repoの開始点としてZIPをそのまま利用できる。
- 共通と個別の変更場所が迷わず判別できる。
- Baseファイルの意図しない変更を検出できる。

## Phase 1 — KiNoTch. Runtime Kernel v0.1

目的: 複数Surface / repoが共有する最小実装を切り出す。

初期候補:

- Action / ActionRequest / ActionContext
- ActionResult / ActionError
- Resource / Artifact
- Progress / Cancellation
- Config
- Filesystem
- Logging

注意:

- Domain処理は入れない。
- 言語横断では契約を優先し、巨大な共通libraryを無理に共有しない。

## Phase 2 — 代表repoで試験導入

最低3系統で検証する。

1. CLI + MCP: `jev-audit`系
2. Windows GUI + CLI: `SynTrail-LM`系
3. API / Web: `kinotch-api` / `standby-display`系

追加候補:

- Agent: `dev_agent`
- Local GUI/Web: `srt2subtitle`
- Library/Web: `IDS-Composit`

目的は「移行すること」ではなく、**Base / Runtimeの抽象が実際に簡素化になるか検証すること**。

## Phase 3 — Surface Pack

複数repoで再利用価値が確認できたものだけ追加する。

### CLI

- common options
- JSON output
- stdout / stderr
- exit code
- dry-run

### Windows

- native menu
- File / Folder picker
- Save / Save As
- D&D
- Progress
- Cancel
- Error dialog
- Reveal output

### MCP

- Action → Tool mapping
- schema validation
- working-directory/resource resolution
- structured error

### API

- validation
- error envelope
- request ID
- auth hook
- rate-limit hook
- smoke / health

## Phase 4 — Tooling

- `knt init`
- profile選択による初期化
- `knt migrate`
- generated artifact管理
- stale check
- より詳細なdoctor
- Base conformance report

## Phase 5 — 既存repoへの段階導入

全repoを一括書換えしない。

- 改修するrepoから順次適用
- project固有ロジックは無理に移動しない
- 複数repoで反復確認できた知識だけBase / Runtimeへ昇格
- 既存互換性を壊してまで形式統一しない

## Phase 6 — 安定化

必要性が実証された場合のみ進める。

- Base version migration policy
- Runtime version compatibility
- multi-language bindings
- generated docs / MCP / API descriptors
- project scaffolding高度化

Phase 6は必須到達点ではない。Base / Runtimeが十分単純なまま実用性を満たすなら、そこで止める。
