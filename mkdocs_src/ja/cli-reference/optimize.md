# forge optimize

ベイズ最適化（Optuna）・グリッドサーチ・ウォークフォワード最適化など、戦略パラメータの探索と感度分析を行うコマンドグループ。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`forge optimize run`](#forge-optimize-run) | Optuna によるパラメータ最適化を実行する |
| [`forge optimize cross-symbol`](#forge-optimize-cross-symbol) | 複数銘柄に対するクロスシンボル最適化を実行する |
| [`forge optimize portfolio`](#forge-optimize-portfolio) | ポートフォリオの最適配分ウェイトを Optuna で探索する |
| [`forge optimize multi-portfolio`](#forge-optimize-multi-portfolio) | 銘柄別戦略のウェイトを Optuna で最適化する |
| [`forge optimize walk-forward`](#forge-optimize-walk-forward) | ウォークフォワード最適化を実行する |
| [`forge optimize apply`](#forge-optimize-apply) | 最適化結果を戦略に適用して保存する |
| [`forge optimize sensitivity`](#forge-optimize-sensitivity) | 最適化済みパラメータの感度分析を行う |
| [`forge optimize history`](#forge-optimize-history) | 過去の最適化結果をスコアボード形式で一覧表示 |
| [`forge optimize grid`](#forge-optimize-grid) | `optimizer_config.param_ranges` の網羅 Grid Search |

---

## forge optimize run

Optuna による単一銘柄のパラメータ最適化（TPE）。`--objective` を 2 つ以上指定すると NSGAII による多目的最適化に切り替わります。

### 構文

```bash
forge optimize run <SYMBOL> --strategy <ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（必須） | - | 銘柄シンボル |
| `--strategy` | 必須 | - | 戦略名 |
| `--metric` | オプション | `sharpe_ratio` | 最適化対象の指標 |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |
| `--save` | フラグ | false | 結果をファイルに保存 |
| `--min-trades` | int | - | 最低取引数制約を上書き（`optimizer_config` / 設定より優先） |
| `--trials` | int | - | Optuna トライアル数を上書き |
| `--apply` | フラグ | false | 最適化後にベストパラメータを戦略に適用して保存 |
| `--yes` / `-y` | フラグ | false | `--apply` の確認プロンプトをスキップ |
| `--start` | オプション | - | 最適化期間の開始日 `YYYY-MM-DD` |
| `--end` | オプション | - | 最適化期間の終了日 `YYYY-MM-DD` |
| `--max-drawdown` | float | - | 最大ドローダウン制約（%）。超過トライアルをペナルティ除外 |
| `--objective` | 複数指定可 | - | 多目的最適化の目標（例: `sharpe_ratio_maximize`、`max_drawdown_pct_minimize`） |

`--max-drawdown` と `--objective` は同時指定できません。

### サンプル出力（テキスト）

```text
✅ 最適化完了
ベストスコア (sharpe_ratio): 1.32
ベストパラメータ: {'fast_period': 12, 'slow_period': 50}
DB 保存: run_id=opt_20260415_103021
✅ 最適化結果を保存しました: data/results/optimize_my_v1_20260415_103021.json
```

`--apply` 指定時：

```text
⚠️  元戦略 'my_v1' のパラメータを最適化結果で上書きします。続行しますか？ [y/N]: y
✅ ベストパラメータを 'my_v1' に適用して保存しました
```

### サンプル出力（`--json`）

```json
{
  "best_metric": 1.32,
  "best_params": { "fast_period": 12, "slow_period": 50 }
}
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `--start の形式が不正です (YYYY-MM-DD)` | 日付形式不正 | `2024-01-15` 形式で指定 |
| `--start <date> 以降のデータが存在しません` | データ不足 | `forge data fetch <SYM>` でデータ拡張 |
| `--max-drawdown と --objective は同時に指定できません。` | 両方指定 | どちらか一方を選択 |
| `キャンセルしました。` | `--apply` 確認で No | `--yes` を付けるか、改めて承認 |

---

## forge optimize cross-symbol

複数銘柄で同じ戦略を最適化し、銘柄横断で頑健なパラメータを探索する（集計方式: 平均 / 中央値 / 最小）。

### 構文

```bash
forge optimize cross-symbol <SYM1> [SYM2 ...] --strategy <ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOLS` | 引数（必須、複数） | - | 銘柄シンボルのスペース区切り |
| `--strategy` | 必須 | - | 戦略名 |
| `--metric` | オプション | `sharpe_ratio` | 最適化対象の指標 |
| `--aggregation` | オプション | `mean` | スコア集計方法（`mean` / `median` / `min`） |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |
| `--save` | フラグ | false | 結果をファイルに保存 |

### サンプル出力

```text
クロスシンボル最適化を実行中: SPY, QQQ, IWM x sma_v1 (target=sharpe_ratio, agg=mean)
✅ クロスシンボル最適化完了
総合スコア (mean of sharpe_ratio): 1.20
ベストパラメータ: {'fast_period': 15, 'slow_period': 60}
個別銘柄スコア:
  - SPY: 1.32
  - QQQ: 1.18
  - IWM: 1.10
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `警告: <SYM> のデータ読み込みに失敗しました` | データ未取得 | `forge data fetch <SYM>` |
| `エラー: 有効なデータを持つ銘柄がありません` | 全銘柄データ未取得 | データ取得後に再実行 |

---

## forge optimize portfolio

単一戦略を複数銘柄に適用したときの **配分ウェイト** を Optuna で最適化する。

### 構文

```bash
forge optimize portfolio <SYM1> [SYM2 ...] --strategy <ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOLS` | 引数（必須、複数） | - | 銘柄シンボルのスペース区切り |
| `--strategy` | 必須 | - | 戦略名 |
| `--metric` | オプション | `sharpe_ratio` | 最適化対象の指標 |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |
| `--save` | フラグ | false | 結果をファイルに保存 |

### サンプル出力

```text
ポートフォリオウェイト最適化を実行中: AAPL, MSFT, GOOGL x tech_basket_v1 (target=sharpe_ratio)
✅ ウェイト最適化完了
ベストスコア (sharpe_ratio): 1.45
最適ウェイト:
  - AAPL: 38.0%
  - MSFT: 42.0%
  - GOOGL: 20.0%
```

### サンプル出力（`--json`）

```json
{
  "best_weights": { "AAPL": 0.38, "MSFT": 0.42, "GOOGL": 0.20 },
  "best_metric": 1.45,
  "portfolio_metrics": { "cagr_pct": 14.2, "sharpe_ratio": 1.45, "max_drawdown_pct": -18.0 }
}
```

---

## forge optimize multi-portfolio

各銘柄に **個別の戦略** を割り当て、配分ウェイトを Optuna で最適化する。

### 構文

```bash
forge optimize multi-portfolio <SYMBOL:STRATEGY> [<SYMBOL:STRATEGY> ...] [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL_STRATEGY_PAIRS` | 引数（必須、複数） | - | `SYMBOL:STRATEGY_NAME` 形式のペア |
| `--metric` | オプション | `cagr_pct` | 最適化対象の指標 |
| `--trials` | int | `200` | Optuna トライアル数 |
| `--save` | フラグ | false | 結果を JSON ファイルに保存 |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |

### サンプル出力

```text
マルチポートフォリオウェイト最適化を実行中: GC=F, NVDA (target=cagr_pct, trials=200)
✅ マルチポートフォリオ最適化完了
ベストスコア (cagr_pct): 18.5234
最適ウェイト:
  - GC=F: 55.0%
  - NVDA: 45.0%
ポートフォリオメトリクス:
  CAGR:         18.52%
  Sharpe:       1.38
  Max Drawdown: -22.10%
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `引数の形式が不正です: '<pair>'` | `SYMBOL:STRATEGY_NAME` 形式違反 | `GC=F:gc_optimized` のようにコロン区切り |
| `有効なシンボル・戦略ペアが1つも存在しません。` | 全ペアでロード失敗 | データ取得・戦略 ID を確認 |

---

## forge optimize walk-forward

時系列を `--windows` 個の連続ウィンドウに分割し、各ウィンドウで IS（イン・サンプル）最適化 → OOS（アウト・オブ・サンプル）評価を繰り返して、過学習耐性を計測する。

### 構文

```bash
forge optimize walk-forward <SYMBOL> --strategy <ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（必須） | - | 銘柄シンボル |
| `--strategy` | 必須 | - | 戦略名 |
| `--metric` | オプション | `sharpe_ratio` | 最適化対象の指標 |
| `--windows` | int | `5` | ウィンドウ数 |

### サンプル出力

```text
ウォークフォワード最適化を実行中: SPY x sma_v1 (5ウィンドウ)
✅ ウォークフォワード完了
Window     IS Score  OOS Score  ベストパラメータ
-----------------------------------------------------------------
1            1.4523     1.1024  {'fast': 10, 'slow': 50}
2            1.6210     0.8932  {'fast': 12, 'slow': 55}
⚠️  Window 3 スキップ: OOS 期間のトレード数が 0 件（統計的に無効）
4            1.3120     1.0521  {'fast': 14, 'slow': 60}
5            1.5240     0.9810  {'fast': 11, 'slow': 50}
平均 OOS sharpe_ratio: 0.987（4/5 有効ウィンドウ）
```

すべてのウィンドウが無効な場合：

```text
⚠️  有効なウィンドウが 0 件でした（5 ウィンドウ中）。 データ量またはウィンドウ数を調整してください。
```

---

## forge optimize apply

`forge optimize run` などで保存された結果 JSON を読み込み、`best_params` を戦略に適用して **`<id>_optimized`** として保存する。

### 構文

```bash
forge optimize apply <RESULT_FILE> --to-strategy <ID> [--yes]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `RESULT_FILE` | 引数（必須、ファイル必須） | - | 最適化結果 JSON ファイル |
| `--to-strategy` | 必須 | - | 適用先の戦略名 |
| `--yes` / `-y` | フラグ | false | 確認プロンプトをスキップ |

### サンプル出力

```text
戦略: my_v1
適用パラメータ: {'fast_period': 12, 'slow_period': 50}
このパラメータを戦略に適用しますか？ [y/N]: y
✅ 最適化パラメータを適用しました: strategy_id=my_v1_optimized
適用後パラメータ: {'fast_period': 12, 'slow_period': 50}
```

`--to-strategy` の戦略 ID に `_optimized` サフィックスが付き、新規戦略として保存されます。元戦略は変更されません。

---

## forge optimize sensitivity

最適化済みパラメータの周辺をスイープし、わずかなパラメータ変動でメトリクスがどれだけ変わるかを評価する。過学習リスクの定量化に使用。

### 構文

```bash
forge optimize sensitivity <RESULT_FILE> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `RESULT_FILE` | 引数（必須、ファイル必須） | - | 最適化結果 JSON ファイル |
| `--strategy` | オプション | `result_file` から自動 | 戦略名 |
| `--metric` | オプション | `result_file` から自動 | 評価指標 |
| `--steps` | int | `3` | 最良値の前後にテストするステップ数 |
| `--threshold` | float | `0.8` | ロバスト判定の閾値比率 |
| `--symbol` | オプション | `result_file` から自動 | データを取得する銘柄 |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |
| `--save` | フラグ | false | 結果をファイルに保存 |

### サンプル出力

```text
感度分析を実行中: my_v1 x SPY (metric=sharpe_ratio, steps=±3)

=== 感度分析結果: my_v1 ===
ベストスコア (sharpe_ratio): 1.4523
総合ロバスト性スコア: 78.45%

パラメータ                       最良値   ロバスト性  スコア推移
----------------------------------------------------------------------
fast_period                          12      82.1%  1.20 1.32 1.42 1.45 1.40 1.31 1.18
slow_period                          50      75.3%  1.05 1.21 1.38 1.45 1.39 1.18 0.97
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: --strategy を指定してください` | 結果ファイルから戦略名取得不可 | `--strategy <ID>` を明示 |
| `エラー: --symbol を指定してください` | 結果ファイルから銘柄取得不可 | `--symbol <SYM>` を明示 |

---

## forge optimize history

ある戦略について、過去に保存された `optimize_<strategy>_*.json` および `optimize_cross_<strategy>_*.json` を読み込んで一覧表示する。

### 構文

```bash
forge optimize history --strategy <ID> [OPTIONS]
```

### オプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--json` | フラグ | false | 結果を JSON 形式で標準出力 |
| `--sort` | choice | `score` | ソート順（`score` / `date`） |

### サンプル出力

```text
=== 最適化履歴: my_v1 (3 件) ===

日時              シンボル     指標            スコア  主要パラメータ
────────────────────────────────────────────────────────────────────────────────
20260415_103021   SPY          sharpe_ratio    1.4523  fast_period=12, slow_period=50
20260410_181522   SPY          sharpe_ratio    1.3210  fast_period=14, slow_period=55
20260401_092030   SPY          sharpe_ratio    1.1850  fast_period=10, slow_period=45

Best: sharpe_ratio=1.4523  (20260415_103021)
      パラメータ: {'fast_period': 12, 'slow_period': 50}
```

履歴ファイルが見つからない場合：

```text
最適化履歴がありません: my_v1
  検索パス: data/results/optimize_my_v1_*.json
```

---

## forge optimize grid

`optimizer_config.param_ranges` の全パラメータ組み合わせ（直積）を網羅的にバックテストする Grid Search。Optuna のサンプリングを使わず、全探索した上で Top-K を表示・保存する。

### 構文

```bash
forge optimize grid <SYMBOL> --strategy <ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（必須） | - | 銘柄シンボル |
| `--strategy` | 必須 | - | 戦略名 |
| `--metric` | オプション | `sharpe_ratio` | ソート基準のメトリクス |
| `--top-k` | int | `20` | 表示・保存する上位件数 |
| `--chunk-size` | int | `100` | `ChunkedGridRunner` のチャンクサイズ |
| `--max-memory-mb` | float | - | RSS 監視閾値（MB） |
| `--max-trials` | int | `10000` | Grid サイズがこれを超えたら確認プロンプト |
| `--save` | フラグ | false | 結果 DataFrame を保存 |
| `--save-format` | choice | `csv` | 保存フォーマット（`csv` / `parquet` / `json`） |
| `--apply` | フラグ | false | ベストパラメータを戦略に適用 |
| `--yes` / `-y` | フラグ | false | 確認プロンプトをスキップ |
| `--start` | オプション | - | 期間フィルタ開始日 `YYYY-MM-DD` |
| `--end` | オプション | - | 期間フィルタ終了日 `YYYY-MM-DD` |
| `--min-trades` | int | - | 最低取引数で trial 除外 |
| `--max-drawdown` | float | - | MDD 上限で trial 除外 |
| `--json` | フラグ | false | Top-K を JSON で出力 |

### サンプル出力

```text
Grid size: 1500 trials (chunk_size=100, max_memory_mb=None)
Grid size 12000 exceeds --max-trials 10000. Continue? [y/N]: y
... (バックテスト実行) ...

=== Grid Search Top-20: my_v1 / SPY (metric=sharpe_ratio) ===
fast_period  slow_period   sharpe_ratio   max_drawdown_pct   n_trades
-----------------------------------------------------------------------
         12           50           1.45              -16.8         18
         14           55           1.41              -17.2         16
         ...
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `optimizer_config が定義されていません` | 戦略 JSON に `optimizer_config` 無し | 戦略 JSON に `optimizer_config.param_ranges` を追加 |
| `param_ranges が空です` | `param_ranges` が空 dict | パラメータ範囲を 1 つ以上定義 |
| `指定された --metric '<name>' が結果に含まれていません` | メトリクス名タイポ等 | `sharpe_ratio` などの実装値を使用 |
| `制約を満たす trial がありません` | `--min-trades` / `--max-drawdown` で全除外 | 制約を緩和 |

---

## 共通の挙動

- **保存先**: `--save` 指定時、`config.report.output_path` 配下に `optimize_<strategy>_<timestamp>.json` 形式で保存。クロスシンボルは `optimize_cross_*`、ポートフォリオは `optimize_portfolio_*` などプレフィックスが変わります。
- **DB 保存**: `forge optimize run` は `--save` の有無にかかわらず常時 `SQLiteOptimizationResultRepository` に記録します（`run_id` を返却）。
- **Journal 連携**: `config.journal.auto_record` が true の場合、最適化実行は Journal にも自動記録されます。
- **`FORGE_CONFIG`**: 戦略・データ・結果の保管場所は環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まります。
- **終了コード**: 通常 `0`、`click.ClickException` で `1`、`click.UsageError` で `2`、`click.Abort` で `1`。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/optimize.py` の Click decorator から抽出。alpha-forge 側で引数追加・変更があった場合、本ページも追従更新が必要。 -->
