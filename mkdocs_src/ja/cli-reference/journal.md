# forge journal

戦略の実行履歴・スナップショット・タグ・判定を管理するコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge journal list` | ジャーナルが存在する戦略の一覧を表示する |
| `forge journal show` | 戦略の全履歴（スナップショット＋実行履歴）を表示する |
| `forge journal runs` | 実行結果をテーブル形式で一覧表示する |
| `forge journal compare` | 2 つの実行結果を比較表示する |
| `forge journal tag` | タグを追加・削除する |
| `forge journal note` | メモを追記する |
| `forge journal verdict` | 実行結果に判定（pass / fail / review）を記録する |

## 当面の使い方

```bash
forge journal list
forge journal show <strategy_id>
forge journal verdict <run_id> --status pass --note "OOS test passed"
```

詳細は `forge journal <subcommand> --help` で確認できます。

---

*同期元: `alpha-forge/src/alpha_forge/commands/journal.py` の Click decorator。*
