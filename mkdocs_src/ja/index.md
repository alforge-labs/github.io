# AlphaForge ドキュメント

AlphaForge は、時系列バックテスト・ベイズ最適化・ウォークフォワード検証を一元化する **ローカル CLI** です。すべての処理がローカルマシン上で完結するため、戦略データ・取引履歴・API キーが外部サーバーに送信されることはありません。

本ドキュメントでは、インストールから戦略開発、AI コーディングエージェントとの連携までを順を追って解説します。

## こんな方に向いています

- バックテストフレームワーク（Backtrader、vectorbt 等）の代替を探しているエンジニア・クオンツリサーチャー
- 戦略 JSON を **コードとしてバージョン管理** したい開発者
- Claude Code や Codex などの AI エージェントと組み合わせて、戦略を **自律的に探索・最適化** したいユーザー
- ベイズ最適化・ウォークフォワード検証を **ワンコマンド** で済ませたい方

## 主な話題

- [はじめに](getting-started.md) — インストール、ライセンス認証、最初のバックテスト（Free プランで 10 分体験まで）
- [目的別ユースケース](usecases/index.md) — 自分の役割（TradingView ユーザー / Python 開発者 / クオンツ / 自動売買検討者 / AI エージェント利用者）から最適な次ページを選ぶ
- [CLI リファレンス](cli-reference/index.md) — `forge` コマンドの全パラメータと出力例
- [戦略テンプレート](templates.md) — HMM × BB × RSI などの組み合わせ戦略を実 JSON 付きで紹介
- [AI エージェント連携](ai-driven-forges.md) — Claude Code / Codex × AlphaForge による自律戦略開発の HOWTO
- [利用規約と免責事項](legal/disclaimers.md) — 免責事項・EULA・プライバシーポリシー

## 関連リンク

- [Alforge Labs 公式サイト](https://alforgelabs.com/ja/index.html) — 製品紹介とインストールガイド
- [チュートリアル](https://alforgelabs.com/ja/tutorial-strategy.html) — 戦略 JSON を作って動かす入門
- [サポート](mailto:support@alforgelabs.com) — 技術的なお問い合わせ
