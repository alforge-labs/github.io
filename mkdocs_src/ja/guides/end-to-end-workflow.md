# エンドツーエンド戦略開発ワークフロー

ヒストリカルデータの取得から自動発注までの典型的な開発フロー。Claude Code などのコーディングエージェントと組み合わせると、各ステップの自動化やパラメータ探索を高速化できます。

!!! note "前提"
    以下のコマンドはすべて `alpha-strategies/` ディレクトリから `FORGE_CONFIG=forge.yaml uv run` 付きで実行することを想定しています。

## 1. データ取得

対象シンボルのヒストリカルデータをローカルに保存します。

```bash
forge data fetch USDJPY
```

## 2. 戦略テンプレート作成

テンプレートから戦略 JSON の雛形を生成し、パラメータを編集してから登録します。

```bash
forge strategy create --template sma_crossover_v1 \
  --out data/strategies/usdjpy_sma_v1.json

# 生成された JSON の strategy_id とパラメータをエディタで編集してから登録
forge strategy save data/strategies/usdjpy_sma_v1.json
```

## 3. バックテスト実行

定義した戦略のパフォーマンスを過去データで検証します。

```bash
forge backtest run USDJPY --strategy usdjpy_sma_v1

# 結果のチャート URL を表示してブラウザで開く
forge backtest chart usdjpy_sma_v1 --open
```

## 4. パラメータ最適化

Optuna のベイズ最適化（TPE）で最適なパラメータを探索します。

```bash
forge optimize run USDJPY --strategy usdjpy_sma_v1 \
  --metric sharpe_ratio --trials 300 --save

# 保存された結果ファイル（optimize_usdjpy_sma_v1_<timestamp>.json）を新しい戦略として適用
forge optimize apply data/results/optimize_usdjpy_sma_v1_<timestamp>.json \
  --to-strategy usdjpy_sma_v1_optimized
```

## 5. ウォークフォワード検証

過学習を検出するため、訓練期間とテスト期間を分けた検証を行います。

```bash
forge optimize walk-forward USDJPY \
  --strategy usdjpy_sma_v1_optimized --windows 5

# 感度分析（最適化結果 JSON ファイルを指定）
forge optimize sensitivity data/results/optimize_usdjpy_sma_v1_<timestamp>.json
```

## 6. Pine Script 生成

TradingView 用のアラートスクリプトを自動生成します。

```bash
forge pine generate --strategy usdjpy_sma_v1_optimized
```

出力先: `output/pinescript/usdjpy_sma_v1_optimized.pine`

!!! tip "関連コマンド"
    各サブコマンドの完全なオプション一覧は [CLI リファレンス](../cli-reference/index.md) を参照してください。次のステップは [TradingView への Pine Script 反映](tradingview-pine-integration.md) です。

!!! tip "実際の出力サンプルを確認するには"
    各コマンドの出力フォーマットや、equity curve・最適化結果・Pine Script の具体例は [実行結果と成果物サンプル](output-examples.md) を参照してください。
