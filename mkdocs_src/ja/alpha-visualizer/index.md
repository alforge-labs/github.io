# alpha-visualizer

**alpha-visualizer** は、AlphaForge（`forge`）が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。`forge` 本体に依存せず `backtest_results.db`（SQLite）と戦略 JSON を直接読み取るため、`forge` を未インストールの環境でも動作します。

![Browse 画面](assets/browse.png){ loading=lazy }

## できること

- 登録済み戦略の一覧・検索・複数選択
- バックテスト結果の Equity / Drawdown / 取引履歴・ベンチマーク指標可視化
- 複数戦略の比較（指標の横断ビュー、Pearson 相関ヒートマップ）
- 最適化結果（WFO 合成エクイティカーブ・Grid 結果）の可視化
- ライブ実績とバックテストの期間整合 diff
- 探索アイデアの状態管理
- ダーク/ライトテーマ・日英バイリンガル UI
- CSV / PNG エクスポート、URL 共有

## ドキュメント構成

| ページ | 内容 |
|---|---|
| [インストール](installation.md) | uv / pip / ソースからの 3 通りのインストール手順 |
| [機能詳細](features.md) | Browse / Detail / Compare / Optimize / Live / Ideas の各画面解説 |
| [設定](configuration.md) | CLI オプション・`forge.yaml` ・データパス仕様 |
| [FAQ・トラブルシューティング](faq.md) | よくある問題と対処法 |

## ライセンスとリポジトリ

- **License**: MIT
- **GitHub**: <https://github.com/alforge-labs/alpha-visualizer>
- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **行動規範**: [Contributor Covenant v2.1](https://github.com/alforge-labs/alpha-visualizer/blob/main/CODE_OF_CONDUCT.md)

`forge` 本体は商用ライセンスですが、`alpha-visualizer` は OSS として独立して開発されています。
