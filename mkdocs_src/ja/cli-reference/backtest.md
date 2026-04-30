# forge backtest

戦略のバックテスト実行と関連分析を行うコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge backtest run` | バックテストを実行する |
| `forge backtest batch` | 複数の戦略 JSON を並列バックテストする |
| `forge backtest diagnose` | 戦略のパフォーマンス問題を自動診断する |
| `forge backtest list` | 保存済みのバックテスト結果一覧を表示する |
| `forge backtest report` | 保存済みのバックテスト結果を表示する |
| `forge backtest migrate` | 既存の JSON レポートファイルを DB にインポートする |
| `forge backtest compare` | 複数戦略を同一シンボル・期間で並べてバックテスト比較する |
| `forge backtest portfolio` | 複数銘柄のポートフォリオバックテストを実行する |
| `forge backtest chart` | ダッシュボードの URL を表示してチャートへ誘導する |
| `forge backtest signal-count` | エントリー条件のシグナル発生件数を高速チェック（vectorbt スキップ） |
| `forge backtest monte-carlo` | 既存のバックテスト結果からモンテカルロシミュレーションを実行する |

## 当面の使い方

最も基本的な使い方は [はじめに#最初のバックテスト](../getting-started.md#最初のバックテスト) を参照してください。詳細パラメータは `forge backtest <subcommand> --help` で確認できます。

```bash
forge backtest run --help
forge backtest compare --help
```

---

*同期元: `alpha-forge/src/alpha_forge/commands/backtest.py` の Click decorator。*
