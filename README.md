# alforge-labs.github.io

Alforge Labs のランディングページ（静的サイト）。

## 概要

- アルゴリズム取引システム「AlphaTrade」の公開向けホームページ
- 日英バイリンガル対応（ページ内でトグル切替）
- ダーク / ライトテーマ対応
- ビルドツール不要の純粋な HTML + React（CDN 経由）構成

## ファイル構成

```
alforge-labs/
├── index.html              # エントリポイント（CSS / テーマトークン含む）
├── homepage-copy.jsx       # 日英コピーテキスト（window.COPY）
├── homepage-components.jsx # 再利用 UI コンポーネント
└── homepage-app.jsx        # ページ全体のレイアウトと状態管理
```

## ローカル確認

```bash
# 任意の HTTP サーバーで開く（ファイルを直接開くと Babel が動作しない場合あり）
npx serve .
# または
python3 -m http.server 8080
```

## デプロイ

GitHub Pages に自動デプロイされます（`alforge-labs/alforge-labs.github.io` リポジトリの `main` ブランチ）。  
このディレクトリの変更を push すると反映されます。

## 掲載コンテンツ

- **Hero**: キャッチコピー・バックテスト実績スタッツ
- **Products**: forge / strategies / strike の 3 プロダクト紹介
- **Performance**: GC=F（金先物）HMM+BB+RSI 戦略の 10 年バックテスト結果
- **Roadmap**: 2025 Q1 〜 2027 の開発マイルストーン
- **FAQ**: よくある質問
- **Follow CTA**: X（旧 Twitter）@alforge_bot へ誘導

## コミュニティ

- [GitHub Discussions](https://github.com/alforge-labs/alforge-labs.github.io/discussions) — 質問・アイデア・戦略共有のコミュニティ（日英両対応）
