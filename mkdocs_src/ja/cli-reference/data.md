# forge data

ヒストリカルマーケットデータの取得・更新・参照を行うコマンドグループ。プロバイダー（yfinance / moomoo / OANDA / Dukascopy / TradingView MCP）から OHLCV を取得し、Parquet 形式でローカルキャッシュします。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`forge data fetch`](#forge-data-fetch) | ヒストリカルデータを取得して保存する |
| [`forge data list`](#forge-data-list) | 保存済みのヒストリカルデータ一覧を表示する |
| [`forge data trend`](#forge-data-trend) | 保存済みデータから市場トレンドを判定する |
| [`forge data update`](#forge-data-update) | 保存済みの全ヒストリカルデータを最新状態まで一括で差分更新する |

---

## forge data fetch

指定銘柄またはウォッチリストの OHLCV をプロバイダーから取得し、Parquet 形式で `config.data.storage_path` に保存します。デフォルトでは `config.data.cache_ttl_hours` 内のキャッシュを再利用し、`--force` で強制再取得できます。

### 構文

```bash
forge data fetch [SYMBOL] [OPTIONS]
forge data fetch --watchlist <FILE> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（任意） | - | 銘柄シンボル。`--watchlist` と排他 |
| `--period` | オプション | `1y` | 取得期間（例: `1y`、`5y`、`6m`、`30d`、`max`） |
| `--interval` | オプション | `1d` | 時間足（例: `1d`、`1h`、`5m`） |
| `--watchlist` | オプション | - | 複数銘柄リストファイル（行ごとに 1 銘柄、`#` 始まりはコメント） |
| `--force` | フラグ | false | TTL に関わらず強制的に再取得 |
| `--provider` | choice | - | データソースを明示指定（`yfinance` / `moomoo` / `tv_mcp`）。省略時は `forge.yaml` の `data.providers` 設定で自動解決 |
| `--mcp-server` | オプション | - | `--provider tv_mcp` 用 MCP サーバーコマンド（例: `node /opt/tv-mcp/server.js`）。省略時は `forge.yaml` の `data.providers.tv_mcp.endpoint` |
| `--mcp-server-flavor` | choice | - | `--provider tv_mcp` 用 MCP server 系統（`tradesdontlie` / `vinicius`）。CLI 指定が `forge.yaml` より優先 |

`SYMBOL` も `--watchlist` も指定しないとエラーになります。`--provider tv_mcp` を指定しても `endpoint` が解決できない場合はエラーで停止します。

### サンプル出力（単一シンボル）

```text
データの取得を開始します: SPY (period=5y, interval=1d)
SPY のデータを取得し保存しました (1258 lines)
```

キャッシュ有効時：

```text
キャッシュが有効です: SPY (TTL: 24h) — スキップ。強制取得は --force を使用してください。
```

### サンプル出力（ウォッチリスト）

```text
3 銘柄のデータ取得を開始します...
  [SPY] 取得中...
  [SPY] 完了: 1258 行
  [QQQ] キャッシュが有効です (TTL: 24h) — スキップ
  [AAPL] 取得中...
  [AAPL] エラー: <詳細>
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: symbol または --watchlist を指定してください。` | 引数未指定 | `SYMBOL` または `--watchlist <FILE>` を渡す |
| `エラー: ウォッチリストファイルが見つかりません - <path>` | パス誤り | パスを確認 |
| `[<SYM>] エラー: <details>` | プロバイダー側のエラー（ネットワーク、認証、シンボル不正等） | プロバイダー設定や `forge.yaml` を確認 |

---

## forge data list

保存済みデータセットの一覧を表示します。

### 構文

```bash
forge data list
```

### 引数とオプション

なし。

### サンプル出力

```text
保存済みデータ件数: 3
- SPY (1d): 2018-01-02 から 2025-12-31 (2014 rows)
- QQQ (1d): 2018-01-02 から 2025-12-31 (2014 rows)
- USDJPY=X (1d): 2020-01-01 から 2025-12-31 (1530 rows)
```

データが 1 件もない場合：

```text
保存済みデータ件数: 0
```

---

## forge data trend

保存済みデータから市場トレンドシグナル（強気・弱気・中立など）を生成します。`--symbols` 未指定時は `DEFAULT_TREND_SYMBOLS`（主要日米セット）を使用。

### 構文

```bash
forge data trend [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--symbols` | オプション | デフォルト主要日米セット | カンマ区切りの判定対象シンボル |
| `--watchlist` | オプション | - | 判定対象シンボルのリストファイル |
| `--interval` | オプション | `1d` | 時間足 |
| `--as-of` | オプション | - | この日付以前の足で判定（`YYYY-MM-DD`） |
| `--json` | フラグ | false | JSON で出力 |

`--symbols` と `--watchlist` の両方を指定した場合、`--watchlist` が優先されます。

### サンプル出力（テキスト）

```text
SPY: BULLISH - 50EMA > 200EMA, momentum positive
QQQ: BULLISH - 50EMA > 200EMA, momentum positive
^N225: NEUTRAL - mixed signals
USDJPY=X: BEARISH - 50EMA < 200EMA
```

### サンプル出力（`--json`）

```json
{
  "source": "alpha-forge:data:trend",
  "interval": "1d",
  "as_of": "2025-12-31",
  "signals": [
    {"symbol": "SPY", "label": "BULLISH", "summary": "50EMA > 200EMA, momentum positive", ...},
    {"symbol": "QQQ", "label": "BULLISH", "summary": "...", ...}
  ]
}
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `ウォッチリストファイルが見つかりません - <path>` | パス誤り | パスを確認 |

---

## forge data update

`forge data list` で見えるすべての保存済みデータについて、最終取得日から **本日まで差分取得** します。既に最新のデータはスキップ。

### 構文

```bash
forge data update
```

### 引数とオプション

なし。

### サンプル出力

```text
全 3 件のデータ更新を開始します...
  [Update] SPY (1d) を 2025-12-15 から現在まで取得します...
    - 12 行のデータを追加・更新しました。
  [Skip] QQQ (1d): すでに最新 (2025-12-31) です。
  [Update] USDJPY=X (1d) を 2025-12-20 から現在まで取得します...
    - 新しいデータはありませんでした。
1 件のデータを更新完了しました。
```

データが 1 件もない場合：

```text
保存済みのデータがありません。
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `[Skip] <SYM> (<interval>): 有効な最終取得日がありません。` | メタデータ破損や空ファイル | `forge data fetch <SYM> --force` で再取得 |
| `- エラーが発生しました: <details>` | プロバイダー側のエラー | エラー内容に応じて対処 |

---

## データソース対応表

`forge.yaml` の `data.providers` 設定で銘柄・interval ごとにプロバイダーを切替できます（`alpha-forge` 同梱の実装）。

| プロバイダー | 主な対応資産 | 認証 | period 上限の目安 | interval の目安 |
|------------|------------|------|------------------|----------------|
| **yfinance** | 株 / ETF / FX / 先物 | 不要 | `max`（`1d` で 数十年）、`1h` で 約 2 年、`5m` で 約 60 日 | `1d`、`1h`、`30m`、`15m`、`5m`、`1m` |
| **moomoo** | 株 / ETF（米・香港・本土） | 要 OpenD ローカル接続 | プロバイダー仕様 | `1d`、`1h`、`5m` ほか |
| **OANDA** | FX | 要 API キー | プロバイダー仕様 | `1d`、`H1`、`M5` ほか |
| **Dukascopy** | FX 超長期 | 不要（CSV ダウンロード） | 数十年 | `1d`、`1h`、`5m` |
| **tv_mcp** | TradingView 上で表示できる全銘柄（株・ETF・FX・先物・暗号通貨等） | 要 TradingView Desktop（`--remote-debugging-port=9222`）+ MCP server 起動 | TradingView 仕様（`1d` で数十年、`1h` で十年以上が可能） | TradingView の interval 表記（`D`、`60`、`5` 等）に正規化される |

### TradingView MCP プロバイダー（`tv_mcp`、issue #576）

`--provider tv_mcp` を指定すると、TradingView Desktop に接続した MCP server から OHLCV を取得します。yfinance の period 上限（`5y` 程度）を超える長期データの取得を主目的としています。

- **前提**: TradingView Desktop を `--remote-debugging-port=9222` で起動し、`tradesdontlie/tradingview-mcp` または `oviniciusramosp/tradingview-mcp`（vinicius fork）を別プロセスで起動しておく
- **範囲スライド**: 1 リクエスト 500 bars 上限を内部で自動分割し、`--period max` でも複数チャンクを連結する（上限は `data.providers.tv_mcp.max_chunks`）
- **flavor**: `data_get_ohlcv` は両系共通で動作。OHLCV のみ用途なら既定の `tradesdontlie` で十分
- **設定例**（`forge.yaml`）:

```yaml
data:
  providers:
    stock_provider: tv_mcp     # 株 / ETF を tv_mcp で取得
    fx_provider: tv_mcp        # FX も tv_mcp で取得
    enable_fallback: true      # tv_mcp 失敗時 yfinance へフォールバック
    tv_mcp:
      endpoint: "node /opt/tv-mcp/server.js"
      flavor: tradesdontlie    # OHLCV 用途なら tradesdontlie で OK
      max_bars_per_call: 500   # MCP 上限
      max_chunks: 200          # 範囲スライド時のチャンク上限
      timeout_seconds: 120
```

実行例：

```bash
# CLI で endpoint を直接指定して fetch
forge data fetch SPY --provider tv_mcp --mcp-server "node /opt/tv-mcp/server.js" --period max

# forge.yaml の設定を利用（CLI から endpoint を省略）
forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d
```

### シンボル表記の例

| 資産タイプ | 例 |
|----------|------|
| 米国株 / ETF | `AAPL`、`SPY`、`QQQ`、`NVDA` |
| 為替（yfinance） | `USDJPY=X`、`EURUSD=X` |
| 為替（OANDA） | `USD_JPY`、`EUR_USD` |
| 先物（yfinance） | `CL=F`（原油）、`GC=F`（金）、`SI=F`（銀） |
| TradingView MCP | TradingView 表記そのまま（`AAPL`、`USDJPY`、`OANDA:EURUSD`、`COMEX:GC1!` 等） |

プロバイダー固有のシンボル表記は `alpha-forge/src/alpha_forge/data/providers/<provider>.py` を参照してください。

---

## 共通の挙動

- **保存形式**: Parquet（`config.data.storage_path / <SYMBOL>_<interval>.parquet`）
- **TTL キャッシュ**: `config.data.cache_ttl_hours` 内なら `fetch` はスキップ。`--force` でバイパス可能
- **プロバイダー解決**: `get_data_fetcher(symbol=..., config=config)` がシンボルから `forge.yaml` の `data.providers` 設定でプロバイダーを選択
- **`FORGE_CONFIG`**: 保存先・プロバイダー設定は環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **終了コード**: 通常 `0`、`click.ClickException` で `1`、引数エラーは Click が `2` を返す
- **Free プラン制限**: Free プランでは取得時にも `end` が `2023-12-31` に強制キャップされ、`forge data update` で保有最終日が 2023-12-31 以降のアイテムはスキップされます。詳細は [フリーミアム制限](../guides/freemium-limits.md) を参照。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/data.py` の Click decorator、`alpha-forge/src/alpha_forge/data/providers/` のプロバイダー実装、`alpha-forge/CLAUDE.md` のプロバイダー記述。alpha-forge 側で引数追加・プロバイダー追加があった場合、本ページも追従更新が必要。 -->
