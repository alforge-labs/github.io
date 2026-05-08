# CLI リファレンス

`forge` コマンドが提供するすべてのコマンドグループの一覧です。各グループの詳細はリンク先の専用ページを参照してください。

!!! info "雛形ページについて"
    各コマンドグループの詳細リファレンス（パラメータ・出力例・エラーコード）は、本ページで網羅的に整理した上で、グループごとの個別 issue で順次充填中です。本ページの「サブコマンド一覧」は実装と一致するように維持されます。

## コアコマンドグループ

実戦略開発で頻繁に使うコマンド群です。それぞれ専用ページで詳述します。

| グループ | 説明 | 詳細 |
|---------|------|------|
| **backtest** | 戦略のバックテスト実行と結果分析 | [backtest →](backtest.md) |
| **optimize** | パラメータ最適化（ベイズ・グリッド・ウォークフォワード） | [optimize →](optimize.md) |
| **strategy** | 戦略 JSON の作成・登録・管理 | [strategy →](strategy.md) |
| **data** | ヒストリカルデータの取得・更新 | [data →](data.md) |
| **journal** | 実行履歴・タグ・判定の管理 | [journal →](journal.md) |
| **live** | ライブトレード分析と運用記録 | [live →](live.md) |

## その他のコマンド

ライセンス管理、ユーティリティ、補助機能などは [その他コマンド](other.md) ページにまとめています。

| グループ | 説明 | リンク |
|---------|------|------|
| **license** | ライセンスキーの認証・解除・状態確認 | [other#license →](other.md#license) |
| **login / logout** | Whop アカウント認証 | [other →](other.md) |
| **init** | プロジェクトの初期セットアップ | [other#init →](other.md#init) |
| **pine** | 戦略 JSON ↔ TradingView Pine Script 変換 | [other#pine →](other.md#pine) |
| **indicator** | 対応テクニカル指標の一覧と詳細 | [other#indicator →](other.md#indicator) |
| **idea** | 投資アイデアの管理・検索 | [other#idea →](other.md#idea) |
| **altdata** | 代替データ（センチメント等）の取得・管理 | [other#altdata →](other.md#altdata) |
| **pairs** | ペアトレード（コインテグレーション検定） | [other#pairs →](other.md#pairs) |
| **ml** | ML データセット作成・モデル管理（issue #512） | [other#ml →](other.md#ml) |
| **docs** | 同梱ドキュメントの参照 | [other#docs →](other.md#docs) |

## 全コマンド早見表

実装ベースで網羅した全 16 コマンドグループ × 約 83 サブコマンドの一覧です。

| グループ | サブコマンド |
|---------|-------------|
| backtest | `run` `batch` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `signal-count` `monte-carlo` |
| optimize | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` |
| strategy | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` |
| data | `fetch` `list` `trend` `update` |
| journal | `list` `show` `runs` `compare` `tag` `note` `verdict` |
| live | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` |
| **explore** | **`run` `index` `import` `log` `status` `recommend` `coverage`** |
| license | `activate` `deactivate` `status` |
| login / logout | `login` `logout` |
| init | （単一コマンド） |
| pine | `generate` `preview` `import` |
| indicator | `list` `show` |
| idea | `add` `list` `show` `status` `link` `tag` `note` `search` |
| altdata | `fetch` `list` `info` |
| pairs | `scan` `scan-all` `build` |
| **ml** | **`dataset build` `dataset feature-sets`**（issue #512 Phase 1） |
| docs | `list` `show` |

## 共通ヘルプ

すべてのコマンドで `--help` が利用可能です。

```bash
forge --help                         # トップレベルのコマンド一覧
forge backtest --help                # backtest グループのサブコマンド一覧
forge backtest run --help            # 個別サブコマンドのパラメータ詳細
```

## 関連ドキュメント

- [はじめに](../getting-started.md) — 最初のバックテスト実行までのチュートリアル
- [戦略テンプレート](../templates.md) — 同梱戦略の紹介
- [AI 駆動の戦略探索ワークフロー](../guides/ai-exploration-workflow.md) — Claude Code / Codex × AlphaForge

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/*.py` の Click decorator から抽出。バージョン更新時はこの一覧も追従が必要。 -->
