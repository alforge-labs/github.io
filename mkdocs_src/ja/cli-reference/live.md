# forge live

ライブトレードのイベントログ取得、トレード変換、パフォーマンス分析を行うコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge live list` | live trading records が存在する戦略一覧を表示する |
| `forge live events` | raw event を一覧表示する |
| `forge live convert-check` | raw event から trades 変換 readiness を確認する |
| `forge live import-events` | fill / close event から trade records を生成して保存する |
| `forge live trades` | 戦略の個別取引レコードを一覧表示する |
| `forge live summary` | 戦略の live performance summary を表示する |
| `forge live compare` | 最新 backtest run と live summary を比較する |
| `forge live doctor` | live trading analysis の導入状態を確認する |
| `forge live sync-events` | VPS 上のイベントログをローカルに rsync で同期する |

## 当面の使い方

代表的なフロー: イベント同期 → 変換チェック → import → サマリ表示 → backtest 比較。

```bash
forge live sync-events --help
forge live convert-check --help
forge live import-events --help
forge live summary --help
```

---

*同期元: `alpha-forge/src/alpha_forge/commands/live.py` の Click decorator。*
