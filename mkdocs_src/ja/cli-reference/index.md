# CLI リファレンス

`forge` コマンドが提供するすべてのコマンドグループの一覧です。各グループの詳細はリンク先の専用ページを参照してください。

!!! info "コマンド階層整理 (alpha-forge #610 / #644)"
    商用リリースに向けて、トップレベル 17 個並列だった構造を **論理的なグループ**に再編しました（#610）。続いて #644 で旧トップレベル alias を撤去済みのため、**現在は新階層のみが有効** です。旧名を呼ぶスクリプト等が残っていれば、下記「旧コマンド → 新コマンドの対応」表を参照して置換してください。

## コアコマンドグループ

実戦略開発で頻繁に使うコマンド群です。それぞれ専用ページで詳述します。

| グループ | 説明 | 詳細 |
|---------|------|------|
| **strategy** | 戦略 JSON の作成・登録・管理 | [strategy →](strategy.md) |
| **backtest** | 戦略のバックテスト実行と結果分析 | [backtest →](backtest.md) |
| **optimize** | パラメータ最適化（ベイズ・グリッド・ウォークフォワード） | [optimize →](optimize.md) |
| **explore** | 自律探索ループ（バックテスト → 最適化 → WFT） | — |
| **live** | ライブトレード分析と運用記録 | [live →](live.md) |
| **pine** | 戦略 JSON ↔ TradingView Pine Script 変換 | — |
| **journal** | 実行履歴・タグ・判定の管理 | [journal →](journal.md) |
| **idea** | 投資アイデアの管理・検索 | — |
| **data** | ヒストリカル・代替データ・TV MCP データ取得 | [data →](data.md) |

## 補助グループ（D1 #610 で新設）

| 新グループ | サブコマンド | 説明 |
|---|---|---|
| **analyze** | `indicator` / `ml` / `pairs` | 戦略構築の分析ツール群（旧トップレベルから集約） |
| **system** | `init` / `auth` / `docs` | 運用ユーティリティ（旧トップレベルから集約） |

## 旧コマンド → 新コマンドの対応（撤去済み）

旧トップレベル alias は #644 で **撤去済み** です。旧名のまま呼ぶと `Error: No such command ...` で失敗するため、次の対応で完全に置き換えてください。

| 旧コマンド（撤去済み） | 新コマンド |
|---|---|
| `forge altdata <sub>` | `forge data alt <sub>` |
| `forge tv <sub>` | `forge data tv-mcp <sub>` |
| `forge indicator <sub>` | `forge analyze indicator <sub>` |
| `forge ml <sub>` | `forge analyze ml <sub>` |
| `forge pairs <sub>` | `forge analyze pairs <sub>` |
| `forge init` | `forge system init` |
| `forge auth <sub>` | `forge system auth <sub>` |
| `forge docs <sub>` | `forge system docs <sub>` |

## 全コマンド早見表

実装ベースで網羅した全コマンドグループ × サブコマンドの一覧です。

| グループ | サブコマンド |
|---------|-------------|
| backtest | `run` `batch` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `signal-count` `monte-carlo` |
| optimize | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` |
| strategy | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` |
| data | `fetch` `list` `trend` `update` `alt fetch` `alt list` `alt info` `tv-mcp <sub>` |
| journal | `list` `show` `runs` `compare` `tag` `note` `verdict` |
| live | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` |
| **explore** | **`run` `index` `import` `log` `status` `recommend` `coverage`** |
| pine | `generate` `preview` `import` |
| idea | `add` `list` `show` `status` `link` `tag` `note` `search` |
| **analyze** | `indicator list` `indicator show` `pairs scan` `pairs scan-all` `pairs build` `ml dataset build` `ml dataset feature-sets` `ml train` `ml models` `ml walk-forward` |
| **system** | `init` `auth login` `auth logout` `auth status` `auth check op` `docs list` `docs show` |

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
