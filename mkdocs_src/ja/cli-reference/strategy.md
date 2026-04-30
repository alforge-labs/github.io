# forge strategy

戦略 JSON の作成・登録・検証・管理を行うコマンドグループ。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| `forge strategy list` | 登録済み戦略の一覧を表示する |
| `forge strategy create` | 組み込みテンプレートから JSON ファイルを作成する（Claude CLI 編集用） |
| `forge strategy save` | JSON ファイルからカスタム戦略をローカルに登録する |
| `forge strategy show` | 登録済みの戦略定義（JSON）を内容表示する |
| `forge strategy migrate` | 既存 JSON ファイルを DB にインポートする（`use_db: true` 時） |
| `forge strategy delete` | 登録済み戦略を DB から削除する |
| `forge strategy validate` | 戦略の論理整合性チェックを実行する（`--symbol` 指定で動的チェックも） |

## 当面の使い方

ワークフロー: テンプレート選択 → 編集 → 保存 → 検証 → バックテスト。

```bash
forge strategy create --help
forge strategy save --help
forge strategy validate --help
```

戦略 JSON 自体の構造仕様は [戦略テンプレート](../templates.md) を参照してください。

---

*同期元: `alpha-forge/src/alpha_forge/commands/strategy.py` の Click decorator。*
