# TradingView への Pine Script 反映

`forge pine generate` で生成した `.pine` ファイルを TradingView に貼り付けてアラートを設定します。

## 1. Pine エディタを開く

TradingView でチャートを開き、画面下部の「Pine エディタ」タブをクリックします。

## 2. スクリプトを貼り付ける

生成した `.pine` ファイルの内容をエディタに貼り付け、「スクリプトを追加」（▶ ボタン）をクリックします。

## 3. アラートを設定する

チャート右上のベルアイコン（アラート）→「アラートを追加」をクリック。

- **条件**: 追加したスクリプト名を選択
- **Webhook URL**: チェックを入れ、alpha-strike のエンドポイントを入力
- **メッセージ**: 後述の JSON ペイロードを入力（[alpha-strike 連携ガイド](tradingview-alpha-strike.md) 参照）

## 4. アラートメッセージのヒント

Pine Script 内でシグナル変数（例: `longSignal`）を定義しておくと、アラートの条件設定が簡単になります。

```pinescript
// Pine Script 内でのアラート定義例
longSignal = ta.crossover(ema_fast, ema_slow)
shortSignal = ta.crossunder(ema_fast, ema_slow)
alertcondition(longSignal, title="Long Entry", message="long")
```

!!! tip "次のステップ"
    Webhook 受信側の設定は [TradingView と alpha-strike の連携](tradingview-alpha-strike.md) を参照してください。

---

## 5. Pine Script を MCP server で検証する（issue #523）

`forge pine verify` を使うと、生成した Pine Script を **TradingView Desktop + サードパーティ MCP server** に投げて検証できます。コンパイル可否だけでなく、Strategy Tester のメトリクスや個別トレードを alpha-forge のバックテストと比較し、Pine 変換の正確性を機械的に確認できます。

### 5.1 前提セットアップ

1. TradingView Desktop を `--remote-debugging-port=9222` で起動
2. サードパーティ MCP server を別プロセスで起動：
   - `tradesdontlie/tradingview-mcp` — コンパイル検証・チャート操作向け
   - `oviniciusramosp/tradingview-mcp`（vinicius fork）— Strategy Tester 集計に強い。`metrics` / `signal` モードでは **こちら推奨**
3. `forge.yaml` でエンドポイントと flavor を設定：

```yaml
tv_mcp:
  pine_verify:
    enabled: true
    endpoint: "node /opt/tv-mcp/server.js"
    runtime: node
    flavor: vinicius     # metrics/signal を使うなら vinicius
    timeout_seconds: 60
```

### 5.2 verify モード一覧

| モード | 検証内容 | 推奨 flavor |
|--------|---------|-------------|
| `compile_only` | Pine Script の構文・コンパイルだけ | `tradesdontlie` で十分 |
| `metrics` | TV Strategy Tester の集計（PF・勝率・トレード数等）と alpha-forge のメトリクスを比較 | **`vinicius`**（`tradesdontlie` には `data_get_strategy_results` バグあり） |
| `signal` | tradesdontlie: TV のトレードリストを alpha-forge `trades` と時刻ベースで突合し一致率を算出。<br>vinicius: 時刻情報を返さないため **count-based 比較**（件数のみ）に自動切替（issue #580） | `tradesdontlie`（時刻照合が必要なら） / `vinicius`（件数だけで十分なら） |
| `regime` | HMM 状態列の比較（Phase 1.5c-γ 以降、実装中） | — |

### 5.3 ワークフロー

```bash
# 1. コンパイル可否のみ確認（最速）
forge pine verify --strategy spy_sma_v1 \
  --mcp-server "node /opt/tv-mcp/server.js"

# 2. Strategy Tester メトリクス比較（vinicius 推奨）
forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md

# 3. トレード単位で時刻一致を見る（誤差±60 秒、95% 一致を要求）
forge pine verify --strategy spy_sma_v1 \
  --check-mode signal \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --match-tolerance-seconds 60 \
  --min-match-rate 0.95
```

### 5.4 期間ミスマッチを避けるヒント

`metrics` モードで `total_trades` の差が大きいときは、データ期間のミスマッチ（yfinance ~5 年 vs TradingView 数十年）が原因のことが多いです。長期バックテストを TV 側に揃えたい場合は、データ取得を TradingView MCP に切り替えてください：

```bash
forge data fetch SPY --provider tv_mcp \
  --mcp-server "node /opt/tv-mcp/server.js" --period max
```

詳細は [`forge data` コマンドリファレンス](../cli-reference/data.md#tradingview-mcp-tv_mcpissue-576) を参照してください。

### 5.5 出力レポート

`--output reports/xxx.md` を指定すると、Markdown レポートに以下が含まれます：

- 戦略 ID と検証モード
- 比較メトリクス表（alpha-forge ↔ TradingView）
- 不一致の検出（許容誤差を超えた項目）
- 判定（PASS / FAIL）と推奨アクション

`forge journal report --with-chart --symbol SPY --interval D` と組み合わせると、戦略履歴 + 検証結果 + TV チャート画像を 1 ページで確認できます。
