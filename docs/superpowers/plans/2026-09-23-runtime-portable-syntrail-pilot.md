# Runtime Portable Contract整理・SynTrail-LM第3Pilot 実装計画

## 目的

Python Reference Runtimeの実装型と、異なる言語・Surfaceで成立する意味を分離する。そのうえで、SynTrail-LMの現行 `origin/main` を変更せずに実コード調査を行い、Progress / Cancellation / Resource / Artifact を必要な範囲だけ第3Pilotとして検証する。

## 方針

- Baseは原則freezeし、Portable Contractの詳細を複製しない。
- Runtimeを0.1.0のまま維持し、文書・test-only probeで証拠を集める。
- SynTrail-LMのdirtyなユーザー作業ツリーは触らず、確認対象は固定した `origin/main` とする。
- ActionRegistry / ActionErrorException / Python dataclass / Python例外APIをPortable Contractへ昇格させない。
- Progress / Cancellation / Resource / Artifactは、既存の意味・consumer・変更理由が自然に一致する場合だけGOとする。
- Rust Runtime crateとSurface Packは、反復する共通性が証明されるまで作らない。

## Tasks

1. Portable Contract文書・Contract Maturity・Runtime CURRENT_STATEを同期する。
2. Base CURRENT_STATEをRuntime所有範囲への参照だけに同期する。
3. SynTrail-LMの固定 `origin/main` を隔離環境で調査し、実際の構造・event/state・永続化・出力を記録する。
4. `PILOT_SYNTRAIL.md` とADRでContractごとのGO / PARTIAL GO / HOLD / REJECTを判定する。
5. 自然な対応があるContractだけtest-only probeを実施し、production codeは必要性が証明された場合に限り変更する。
6. Pilot評価とContract maturityを更新し、Surface Pack着手可否を明記する。
7. Runtime / Base / 必要なPilot repoを検証し、段階ごとにcommit・pushしてlocal HEADとremoteを確認する。
8. Roadmapの第4候補 `standby-display` を generated artifact / hash / stale
   checkのdesign-only Probeとして評価する。stale生成物は無断同期しない。
9. Roadmapの第5候補 `dev_agent` を exact `origin/v2/bootstrap` の隔離環境で
   AgentBackend / event / cancellation / artifact-reference境界として評価する。
10. 第4・第5候補で共通意味が繰り返された場合だけ、portable sub-contract候補を
    更新する。Surface Packやproduction integrationは別Gateで判定する。

## 完了条件

- Portable semanticsとPython implementation-specific primitivesが文書上分離されている。
- SynTrail-LMの実コードに基づき、Progress / Cancellation / Resource / Artifactを個別判定している。
- SynTrail-LMの既存DomainをRuntimeへ依存させていない。
- test-only probeまたはproduction Pilotの範囲と、着手しない範囲が明示されている。
- Runtime version 0.1.0、Base version 0.2.1を維持する判断が証拠と整合する。
- Self Test / Runtime tests / Pilot対象の検証結果、commit、push、CI状態を確認できる。
