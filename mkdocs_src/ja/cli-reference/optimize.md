# forge optimize

ベイズ最適化（Optuna）・グリッドサーチ・ウォークフォワード最適化など、戦略パラメータの探索を行うコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge optimize run` | Optuna によるパラメータ最適化を実行する |
| `forge optimize cross-symbol` | 複数銘柄に対するクロスシンボル最適化を実行する |
| `forge optimize portfolio` | ポートフォリオの最適配分ウェイトを Optuna で探索する |
| `forge optimize multi-portfolio` | 各アセットに独自の戦略を指定し、配分ウェイトを Optuna で最適化する |
| `forge optimize walk-forward` | ウォークフォワード最適化を実行する |
| `forge optimize apply` | 最適化結果を戦略に適用して保存する |
| `forge optimize sensitivity` | 最適化済みパラメータの感度分析を実行して過学習リスクを評価する |
| `forge optimize history` | 過去の最適化結果をスコアボード形式で一覧表示する |
| `forge optimize grid` | `optimizer_config.param_ranges` を網羅する Grid Search を実行する |

## 当面の使い方

代表的なフローはベイズ最適化 → 感度分析 → 適用です。

```bash
forge optimize run --help
forge optimize sensitivity --help
forge optimize apply --help
```

ウォークフォワード分析については [はじめに](../getting-started.md) と `forge optimize walk-forward --help` を参照。

---

*同期元: `alpha-forge/src/alpha_forge/commands/optimize.py` の Click decorator。*
