# forge strategy

戦略 JSON の作成・登録・検証・管理を行うコマンドグループ。組み込みテンプレートからの雛形作成、ローカル登録、表示、JSON → DB 移行、削除、論理整合性チェック（静的・動的）まで一通り扱います。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`forge strategy list`](#forge-strategy-list) | 登録済み戦略の一覧を表示する |
| [`forge strategy create`](#forge-strategy-create) | 組み込みテンプレートから JSON ファイルを作成する |
| [`forge strategy save`](#forge-strategy-save) | JSON ファイルからカスタム戦略を登録する |
| [`forge strategy show`](#forge-strategy-show) | 登録済みの戦略定義（JSON）を表示する |
| [`forge strategy migrate`](#forge-strategy-migrate) | 既存 JSON ファイルを DB にインポートする |
| [`forge strategy delete`](#forge-strategy-delete) | 登録済み戦略を DB から削除する |
| [`forge strategy purge`](#forge-strategy-purge) | 戦略 JSON・関連結果・DB エントリを 1 コマンドで完全削除する |
| [`forge strategy validate`](#forge-strategy-validate) | 戦略の論理整合性チェックを実行する |
| [`forge strategy signals`](#forge-strategy-signals) | エントリーシグナル数を軽量集計する |

---

## forge strategy list

登録済み戦略の一覧を表示する。`config.strategies.use_db` が true なら DB から、false ならファイルベースのストアから取得します。

### 構文

```bash
forge strategy list
```

### 引数とオプション

なし。

### サンプル出力

```text
ID                                       名前                           バージョン  タイムフレーム
------------------------------------------------------------------------------------------
spy_sma_crossover_v1                     SMA Golden/Death Cross SPY v1  1.0.0       1d
qqq_hmm_macd_ema_rsi_v1                  QQQ HMM × MACD × EMA × RSI v1  1.0.0       1d
gc_hmm_macd_ema_v1                       GC HMM × MACD × EMA v1         1.0.0       1d
```

戦略が 1 件もない場合：

```text
登録済み戦略はありません。
```

---

## forge strategy create

組み込みテンプレートから戦略 JSON ファイルを作成します。**戦略レジストリには登録されません**。編集してから [`forge strategy save`](#forge-strategy-save) で登録する流れです。

### 構文

```bash
forge strategy create --template <NAME> --out <FILE>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--template` | 必須 | - | ベースとするテンプレート名 |
| `--out` | 必須 | - | 出力先の JSON ファイルパス |

### 利用可能なテンプレート

`alpha-forge` に同梱されている組み込みテンプレート（`alpha-forge/src/alpha_forge/strategy/templates.py` の `_TEMPLATE_REGISTRY` 由来）:

| 名前 | 概要 |
|------|------|
| `sma_crossover_v1` | 短期 SMA × 長期 SMA のゴールデン／デッドクロス |
| `rsi_reversion_v1` | RSI の売られ過ぎ／買われ過ぎを利用した逆張り |
| `macd_crossover_v1` | MACD ライン × シグナルラインのクロスオーバー |
| `bbands_breakout_v1` | ボリンジャーバンドの上限ブレイクアウト |
| `range_reversion_v1` | レンジ相場での平均回帰 |
| `supertrend_adx_v1` | SuperTrend + ADX のトレンドフォロー |
| `ema_adx_macd_v1` | EMA + ADX + MACD の複合トレンド戦略 |
| `hmm_range_pure_v1` | HMM レジーム検出を併用したレンジ純粋系 |
| `hmm_anomaly_v1` | HMM レジームによる異常検知系 |
| `macd_reversal_v1` | MACD ベースの転換点リバーサル |
| `grid_bot_template` | グリッドボット用テンプレート |
| `connors_rsi2_v1` | **Connors RSI-2 平均回帰戦略**（issue #475 / Phase 2）。Larry Connors の "Short-Term Trading Strategies That Work" から移植、SMA(200) 上で RSI(2) < 10 ロング・SMA(5) クロスで利確。SPY/QQQ で 70-85% 勝率実証だが**株式 1d 用のため FX 1h 適用には period 再スケール推奨** |
| `donchian_turtle_v1` | **Donchian Channel Breakout（Turtle 系）**（issue #475 / Phase 2）。Richard Dennis "Turtle Trading Rules" から移植、20 期間高値ブレイクで long・10 期間安値クロスで exit、ATR 併記。先物・株式 1d で勝率 45% 実証だが**長期足用のため FX 1h 適用には length 再スケール推奨** |
| `kama_rsi_v1` | **KAMA + RSI レジーム適応戦略**（issue #475 / Phase 2）。Perry Kaufman "New Trading Systems and Methods" (2013) から移植。KAMA がトレンド/レンジを自動判定 + RSI 過熱反転。**FX 1h 検証: MDD 46-76%（前 2 候補より改善）も CAGR マイナス** |
| `tsi_reversion_v1` | **TSI 平均回帰戦略**（issue #475 / Phase 2）。Daniel Requejo (2024) SSRN paper "Efficacy of a Mean Reversion Trading Strategy Using TSI" から移植。TSI ±25 極値 + シグナル線クロスで反転狙い。SPY/QQQ で実証。**FX 1h 検証: MDD 82-97%・CAGR マイナス** |
| `connors_rsi2_fx1h_v1` | **Connors RSI-2 FX 1h バリアント**（issue #480）。元 SMA(200)/SMA(5) → SMA(480)/SMA(24) に再スケール。FX 1h 検証: trades 350+ も MDD 99-100% で破綻 |
| `donchian_turtle_fx1h_v1` | **Donchian Turtle FX 1h バリアント**（issue #480）。length 20/10 → 120/60 に再スケール。FX 1h 検証: 通貨により MDD 13-96% と分散大 |
| `kama_rsi_fx1h_v1` | **KAMA + RSI FX 1h バリアント**（issue #480）。length 10/slow 30 → 48/120 に再スケール。🎯 **EURUSD で CAGR +0.54%・MDD 7.95% を達成**（4 通貨中唯一プラス転換）|
| `tsi_reversion_fx1h_v1` | **TSI Reversion FX 1h バリアント**（issue #480）。fast/slow/signal を 13/25/13 → 48/120/48 に再スケール。FX 1h 検証: trades 0-4（過剰絞り込み）|
| `kama_rsi_fx1h_v2` | **KAMA+RSI FX 1h・RSI 緩和版**（issue #482）。v1 の RSI 35/65 → 45/55 に。FX 1h 検証: trades 215+（v1 の 35 倍）も MDD 93-99% で破綻 |
| `kama_rsi_fx1h_v3` | **KAMA+RSI FX 1h・KAMA 短縮版**（issue #482）。length 48/slow 120 → 24/60。FX 1h 検証: trades 2-9（v1 同等）/ MDD 8-36%・CAGR マイナス |
| `kama_rsi_mtf_v1` | **KAMA+RSI+4h トレンドフィルタ MTF 版**（issue #484）。`kama_rsi_fx1h_v1` に 4h EMA(50) を AND で追加し、上位タイムフレームのトレンドと一致する 1h エントリーのみ許可。4h 系列はエンジンが 1h データから自動 resample するため追加データ取得は不要 |
| `donchian_turtle_mtf_v1` | **Donchian Turtle+4h トレンドフィルタ MTF 版**（issue #484）。`donchian_turtle_fx1h_v1` に 4h EMA(50) を AND で追加。上昇トレンド中は long のみ・下降中は short のみ許可で trend-following のドローダウン抑制を狙う |
| `kama_rsi_mtf_atr_v1` | **KAMA+RSI+4h トレンド+ATR SL MTF 版**（issue #486）。`kama_rsi_mtf_v1` に ATR(14) × 2 倍のエントリー時固定 SL（`lock_on_entry=true`）を追加。少 trades のまま勝率改善と CAGR + を狙う |
| `kama_rsi_mtf_atr_v2` | **KAMA exit 除外版**（issue #489）。v1 の `close < kama` exit が ATR SL より先に発動して死活していた問題を修正し、exit を RSI（利確）+ ATR SL（ハードストップ）の 2 軸へ単純化。KAMA は entry トレンドフィルタ専念 |

### サンプル出力

```text
✅ 戦略テンプレート 'sma_crossover_v1' から JSON ファイルを作成しました: my_strategy.json
```

### 主なエラー

| 状況 | 動作 |
|------|------|
| 未知のテンプレート名 | `ValueError: 未知のテンプレート名です: <name>。利用可能: ...` を送出 |

---

## forge strategy save

JSON ファイルからカスタム戦略を **戦略レジストリに登録** します。`config.journal.auto_record` が true の場合、Journal にスナップショットも記録されます。

### 構文

```bash
forge strategy save <FILE_PATH> [--force]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `FILE_PATH` | 引数（必須） | - | 戦略 JSON ファイルパス |
| `--force` | フラグ | false | 同一 ID が存在する場合に上書きする |

### サンプル出力

```text
✅ カスタム戦略 'my_strategy_v1' を登録しました
```

`--force` で上書きした場合：

```text
✅ カスタム戦略 'my_strategy_v1' を上書き登録しました
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 指定されたファイルが見つかりません - <path>` | ファイル未存在 | パスを確認 |
| `エラー: <DuplicateStrategyError>` | 同 ID が既に登録済み | `--force` で上書きするか、JSON の `strategy_id` を変更 |

---

## forge strategy show

登録済みの戦略 JSON を整形して標準出力に表示します。

### 構文

```bash
forge strategy show <STRATEGY_ID>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 表示する戦略 ID |

### サンプル出力

```text
=== spy_sma_crossover_v1 ===
{
  "strategy_id": "spy_sma_crossover_v1",
  "name": "SMA Golden/Death Cross SPY v1",
  "version": "1.0.0",
  ...
}
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 戦略 '<id>' が見つかりません` | ID 不正 | `forge strategy list` で確認 |

---

## forge strategy migrate

`config.strategies.path` 配下の既存 JSON ファイルを **DB（SQLite）にインポート** します。`use_db: true` の運用に切り替える際に使用します。

### 構文

```bash
forge strategy migrate [--dry-run] [--force]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--dry-run` | フラグ | false | 実際には書き込まずに確認のみ |
| `--force` | フラグ | false | 重複 ID は最後のファイルで上書き |

### 前提条件

`config.strategies.use_db` が **true** であることが必要です。`forge.yaml`（`FORGE_CONFIG`）で：

```yaml
strategies:
  use_db: true
```

### サンプル出力

```text
⚠️  重複 strategy_id を検出:
  spy_sma_crossover_v1:
    - spy_sma_crossover_v1.json
    - spy_sma_crossover_v1_optimized.json

--force を付けて再実行すると、最後のファイルで上書きします。
```

`--force --dry-run` 指定時：

```text
[dry-run] 12 件を DB に登録予定（実際には書き込みません）
```

通常実行時：

```text
  スキップ (broken_v1.json): パースエラー - <詳細>
  スキップ (legacy_v1): 重複のため登録しませんでした

✅ 完了: 10 件登録, 2 件スキップ
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: strategies.use_db が false です。forge.yaml に use_db: true を設定してください` | DB 無効 | `forge.yaml` を更新して再実行 |
| `移行対象の JSON ファイルが見つかりません。` | `strategies.path` が空 | パス・配置を確認 |

---

## forge strategy delete

登録済み戦略を DB / レジストリから削除します。`--with-results` を付けると関連ファイル（最適化済み戦略・バックテスト結果・最適化結果 JSON）も一括削除します。Journal は保持されます。

### 構文

```bash
forge strategy delete <STRATEGY_ID> [--force] [--with-results]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 削除する戦略 ID |
| `--force` | フラグ | false | 確認プロンプトなしで削除 |
| `--with-results` | フラグ | false | 関連ファイル（`<id>_optimized.json`、`<id>_report.json`、`optimize_<id>_*.json`）も一括削除 |

### `--with-results` で削除対象になるファイル

- `strategies.path / <id>_optimized.json`
- `report.output_path / <id>_report.json`
- `report.output_path / optimize_<id>_*.json`（複数あれば全て）

`<id>.journal.json` は **保持** されます。

### recommendations.yaml の自動クリーンアップ（issue #454）

戦略削除時に `data/explorer/recommendations.yaml` 上の該当エントリも自動的に削除されます（rank は詰め直されます）。auto-relax で生成された推薦戦略を削除しても、stale な推薦が残って `forge explore run` が `StrategyNotFoundError` で停止することはありません。

なお、`forge explore recommend show` 実行時には DB 存在チェックが走り、過去に取り残された stale エントリも自動的に prune されます。

### サンプル出力

```text
削除対象: my_strategy_v1

  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (保持)

続行しますか？ [y/N]: y
✅ 戦略 'my_strategy_v1' を削除しました
ファイルを削除しました: 3件
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 戦略 '<id>' が見つかりません` | ID 不正 | `forge strategy list` で確認 |
| `キャンセルしました` | 確認プロンプトで No | `--force` を付けるか、改めて承認 |

---

## forge strategy purge

戦略 JSON・関連ファイル（`_optimized.json`、`_report.json`、`optimize_<id>_*.json`）・DB エントリを **1 コマンドで完全削除** します。従来の `rm <strategy>.json && rm <strategy>_report.json && forge strategy delete <id> --force` の 3 ステップが 1 コマンドになります。Journal ファイル（`<id>.journal.json`）は保持されます。

### 構文

```bash
forge strategy purge <STRATEGY_ID> [--dry-run]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 完全削除する戦略 ID |
| `--dry-run` | フラグ | false | 削除対象ファイルの一覧表示のみ。実ファイルは削除しない |

### サンプル出力

`--dry-run`：

```text
[dry-run] 削除対象:
  - data/strategies/my_strategy_v1.json
  - data/strategies/my_strategy_v1_optimized.json
  - data/results/my_strategy_v1_report.json
  - data/results/optimize_my_strategy_v1_20260415_103021.json
  - DB エントリ: my_strategy_v1
  ※ data/journal/my_strategy_v1.journal.json は保持
```

通常実行：

```text
削除対象: my_strategy_v1

  ✓ data/strategies/my_strategy_v1.json
  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (保持)

続行しますか？ [y/N]: y
✅ 戦略 'my_strategy_v1' を完全削除しました
```

存在しないファイルは警告のみで処理を続行します（エラーで停止しません）。

### `delete --with-results` との違い

| 観点 | `delete --with-results` | `purge` |
|------|-------------------------|---------|
| 戦略 JSON 本体 | 残す | 削除 |
| `<id>_optimized.json` | 削除 | 削除 |
| `<id>_report.json` | 削除 | 削除 |
| `optimize_<id>_*.json` | 削除 | 削除 |
| Journal | 保持 | 保持 |
| DB エントリ | 削除 | 削除 |

戦略を「完全に消したい」ときは `purge`、戦略 JSON を残して結果ファイルだけ片付けたいときは `delete --with-results` を使います。

---

## forge strategy validate

戦略の **論理整合性チェック** を実行します。`--symbol` を指定すると **動的チェック**（実データ上のシグナル件数・条件相関）も実施します。`STRATEGY_ID` に `.json` 拡張子のパスを渡すと、レジストリ未登録の JSON を直接検証できます。

### 構文

```bash
forge strategy validate <STRATEGY_ID|FILE.json> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID または `.json` ファイルパス |
| `--symbol` | オプション | - | 動的チェック用シンボル（指定で動的チェック有効化） |
| `--period` | オプション | `1y` | データ取得期間 |
| `--min-signals` | int | `30` | 最小シグナル件数閾値（下回ると警告） |
| `--corr-threshold` | float | `0.9` | 相関係数の警告閾値 |
| `--json` | フラグ | false | JSON 形式で出力 |

### 静的チェックの内容

レジストリの `StrategyValidator` が `symbol` 未指定時に行うチェック（実装ベース）：

- `strategy_id` / `name` / `version` / `timeframe` などの必須フィールド
- `indicators[]` の `id` 重複チェック・参照解決
- `entry_conditions` / `exit_conditions` の参照先 ID が存在するか
- 条件式（`left` / `op` / `right`）の構文と型整合性
- `risk_management` の値域（パーセント、レバレッジなど）
- `regime_config` の `indicator_id` 解決
- `optimizer_config.param_ranges` のキーが `parameters` または指標 `params` に対応

### `--symbol` 指定時の動的チェック

実データを取得し、軽量バックテストでシグナル統計を取ります：

- 期間中のエントリーシグナル件数（`min_signals` 未満なら警告）
- 各リーフ条件（leaf condition）の `True` 日数とパーセント
- 条件間の相関係数（`corr_threshold` 超で警告）

### サンプル出力（テキスト）

```text
戦略: spy_sma_crossover_v1  [OK]

[動的チェック]
  シンボル: SPY  期間: 1y  総日数: 252
  エントリーシグナル: 87 日
  条件別 True 日数:
    sma_fast > sma_slow: 142 日 (56.3%)
    rsi < 70: 198 日 (78.6%)

✓ 問題は検出されませんでした
```

エラー検出時：

```text
戦略: my_v1  [NG]

[エラー]
  ✗ [E_INDICATOR_REF] 条件式の参照先 'sma_fast' が indicators に存在しません
    → indicators 配列に { "id": "sma_fast", "type": "SMA", ... } を追加してください

[警告]
  ⚠ [W_LOW_SIGNALS] エントリーシグナルが少なすぎます: 12 日（閾値 30）
    → 条件を緩めるか、データ期間を延ばしてください

  [相関分析]
    ⚠ rsi < 70 × close > sma_fast: 0.94
      → 高相関の条件を片方除去するか、独立性のある別条件に置き換えてください
```

### サンプル出力（`--json`）

```json
{
  "strategy_id": "my_v1",
  "ok": false,
  "static_errors": [
    {"code": "E_INDICATOR_REF", "message": "...", "suggestion": "..."}
  ],
  "static_warnings": [],
  "signal_stats": {
    "symbol": "SPY",
    "period": "1y",
    "total_days": 252,
    "entry_signal_days": 12,
    ...
  },
  "dynamic_warnings": [...],
  "correlations": [...]
}
```

### 終了コード

- `result.ok = true` → `0`
- `result.ok = false`（エラー検出）→ `1`

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 指定されたファイルが見つかりません - <path>` | `.json` 指定時に未存在 | パスを確認 |

---

## forge strategy signals

最適化・WFT を実行せず、デフォルトパラメータでエントリーシグナル数・推定取引数・WFT 窓カバレッジを素早く集計します（#321）。

```bash
forge strategy signals <SYMBOL> --strategy <NAME> [--period <PERIOD>] [--json]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--strategy` | 戦略名（必須） | — |
| `--period` | データ期間 | `5y` |
| `--json` | JSON 形式で出力する | off |

#### 出力例（テキスト）

```
📊 シグナル集計: my_rsi_v1 / SPY (5y)
  ロングシグナル: 45 日
  推定取引数:     38
  年平均取引数:   7.6
  WFT 窓カバレッジ: 低 (5-10 取引/窓)
```

#### 出力 JSON の例

```json
{
  "strategy_id": "my_rsi_v1",
  "symbol": "SPY",
  "period": "5y",
  "total_days": 1260,
  "long_signals": 45,
  "short_signals": 0,
  "estimated_trades": 38,
  "avg_per_year": 7.6,
  "wft_window_coverage": "低 (5-10 取引/窓)"
}
```

| フィールド | 説明 |
|-----------|------|
| `long_signals` | ロングエントリーシグナルが立った日数 |
| `estimated_trades` | 連続シグナルをブロック単位でカウントした推定取引数 |
| `avg_per_year` | 年平均取引数 |
| `wft_window_coverage` | WFT 窓あたりの推定取引数に基づくカバレッジ判定 |

---

## 共通の挙動

- **ストレージ**: `config.strategies.use_db` が true なら `SQLiteStrategyRepository`、false ならファイルベース。`forge.yaml` で切り替え。
- **保存先**: `config.strategies.path`（戦略 JSON）、`config.report.output_path`（バックテスト・最適化結果）、`config.journal.journal_path`（ジャーナル）。
- **Journal 連携**: `config.journal.auto_record` が true の場合、`save` 実行時に Journal スナップショットが自動記録される。
- **`FORGE_CONFIG`**: 上記すべてのパスは環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる。
- **終了コード**: 通常 `0`、`validate` でエラー検出時 `1`、エラー出力（ファイル不存在など）は通常 `1`、引数エラーは Click が `2` を返す。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/strategy.py` の Click decorator と `alpha-forge/src/alpha_forge/strategy/templates.py` の `_TEMPLATE_REGISTRY`。alpha-forge 側で引数追加・テンプレート追加があった場合、本ページも追従更新が必要。 -->
