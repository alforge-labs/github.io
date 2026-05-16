# alpha-forge pine

戦略 JSON と TradingView Pine Script v6 を相互変換します。

!!! warning "[有料プラン限定] Pine Script エクスポート"
    `alpha-forge pine generate` と `alpha-forge pine preview` は **有料プラン（Lifetime / Annual / Monthly）でのみ利用できます**。Trial プランで実行すると赤枠 Panel と購入ページ URL（[https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)）が表示され、終了コード `1` で完全停止します。ファイル出力も標準出力もされません。`alpha-forge pine import`（インポート機能）は対象外で、Trial プランでも継続利用できます。詳しくは [Trial 制限](../guides/trial-limits.md) を参照してください。

## alpha-forge pine generate `[有料プラン限定]`

戦略定義から Pine Script を生成し、`config.pinescript.output_path / <strategy_id>.pine` に保存します。**有料プラン（Lifetime / Annual / Monthly）限定**。

```bash
alpha-forge pine generate --strategy <ID> [--with-training-data]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--with-training-data` | フラグ | false | HMM インジケータがある場合、学習済みパラメータを Pine Script に埋め込む（データを自動フェッチ） |

サンプル出力（有料プラン）：

```text
✅ Pine Script が保存されました: output/pinescript/spy_sma_v1.pine
```

サンプル出力（Trial プラン・ハードブロック）：

```text
╭─────────────── 🔒 有料プラン限定機能 ───────────────╮
│ Pine Script エクスポートは有料プラン（Lifetime /    │
│ Annual / Monthly）のみ利用できます。                │
│ TradingView でのシームレスな運用を行うには…         │
│ アップグレード: https://alforgelabs.com/en/...      │
╰─────────────────────────────────────────────────────╯
```

## alpha-forge pine preview `[有料プラン限定]`

戦略定義から生成される Pine Script を標準出力でプレビューします（ファイル保存しない）。**有料プラン（Lifetime / Annual / Monthly）限定**。

```bash
alpha-forge pine preview --strategy <ID>
```

## alpha-forge pine import

Pine Script (`.pine`) をパースして戦略定義として取り込みます。

```bash
alpha-forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `PINE_FILE` | 引数（必須、ファイル必須） | `.pine` ファイルパス |
| `--id` | 必須 | 保存する戦略 ID |

パース失敗時は `エラー: Pine Script のパースに失敗しました - <details>` を出して標準エラーへ。

## alpha-forge pine verify

戦略から生成した Pine Script を **TradingView MCP server** で検証します（issue #523）。コンパイルチェックに加えて、Strategy Tester の集計値や個別トレードを alpha-forge のバックテスト結果と突き合わせて差異を検出できます。

```bash
alpha-forge pine verify --strategy <ID> [--check-mode <MODE>] [--mcp-server <CMD>] [--mcp-server-flavor <tradesdontlie|vinicius>] [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--check-mode` | choice | `compile_only` | `compile_only` / `metrics` / `signal` / `regime` |
| `--mcp-server` | オプション | - | MCP サーバーコマンド（省略時 `forge.yaml` の `tv_mcp.pine_verify.endpoint`） |
| `--mcp-server-flavor` | choice | `tradesdontlie` | `vinicius` は `oviniciusramosp/tradingview-mcp` フォーク。metrics/signal モードでは推奨 |
| `--mock` | フラグ | false | Mock MCP クライアント（PoC・CI 用） |
| `--symbol` / `--interval` | オプション | - | TV シンボル / インターバル（metrics / signal モードで必須） |
| `--auto-backtest` | フラグ | false | alpha-forge バックテストを内部で実行して比較する |
| `--backtest-result` | オプション | - | 比較対象 alpha-forge バックテスト結果（JSON パスまたは `run_id`） |
| `--metric-tolerance` | float | `0.10` | metrics モードの相対差許容（10%） |
| `--match-tolerance-seconds` | int | `60` | signal モードのトレード時刻許容差（秒） |
| `--min-match-rate` | float | `0.95` | signal モードの最低トレード一致率 |
| `--output` | ファイル | - | レポート Markdown 出力先 |

**check-mode**

| モード | 用途 |
|--------|------|
| `compile_only` | Pine Script の構文・コンパイルだけを検証（`tradesdontlie` で十分） |
| `metrics` | TV Strategy Tester の総合メトリクス（PF・勝率・トレード数等）と alpha-forge のメトリクスを比較。**`vinicius` 推奨**（`tradesdontlie` の `data_get_strategy_results` バグ回避） |
| `signal` | tradesdontlie: TV のトレードリストと alpha-forge の `trades` を時刻ベースで突合し一致率を算出。<br>vinicius: 時刻情報を返さないため **count-based 比較**（トレード件数のみで合否判定）に自動切替（issue #580） |
| `regime` | **未実装（保留中、issue #581）**。upstream MCP server に時系列 study tool が追加されたら着手予定。指定すると明示的エラーで停止 |

**実行例**

```bash
# コンパイル検証のみ（最速）
alpha-forge pine verify --strategy spy_sma_v1 --mcp-server "node /opt/tv-mcp/server.js"

# Strategy Tester 集計の比較（vinicius 推奨）
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md
```

検証ガイドの詳細は [TradingView との Pine Script 連携](../guides/tradingview-pine-integration.md) を参照してください。

---
