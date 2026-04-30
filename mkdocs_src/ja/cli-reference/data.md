# forge data

ヒストリカルマーケットデータの取得・更新・参照を行うコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge data fetch` | ヒストリカルデータを取得して保存する |
| `forge data list` | 保存済みのヒストリカルデータ一覧を表示する |
| `forge data trend` | 保存済みデータから市場トレンドを判定する |
| `forge data update` | 保存済みの全ヒストリカルデータを最新状態まで一括で差分更新する |

## 当面の使い方

```bash
forge data fetch SPY --period 5y --interval 1d
forge data list
forge data update
```

詳細は `forge data <subcommand> --help` で確認できます。

---

*同期元: `alpha-forge/src/alpha_forge/commands/data.py` の Click decorator。*
