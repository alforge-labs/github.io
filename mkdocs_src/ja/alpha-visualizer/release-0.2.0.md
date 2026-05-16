---
title: alpha-visualizer v0.2.0 リリース — 同梱サンプルで即体験できる Web 可視化ツールに
description: alpha-visualizer v0.2.0 をリリースしました。OSS 同梱の合成サンプルデータ、ライブ実績ビュー、HMM レジーム可視化、CodeQL セキュリティ修正など、初回起動から探索の幅を広げる新機能を多数追加しています。
---

# alpha-visualizer v0.2.0 リリース — 同梱サンプルで即体験できる Web 可視化ツールに

> **公開日**: 2026 年 5 月 11 日 / **バージョン**: v0.2.0 / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/0.2.0/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.2.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v0.2.0 では、**インストール直後に「どんなことができるツールなのか」を 1 コマンドで体験できる** ようにすることを軸に据え、機能・運用・セキュリティの 3 面で大型のアップデートを行いました。

## ハイライト

### 1. 完全合成サンプルデータを同梱（`--use-bundled-samples`）

これまで alpha-visualizer は「`alpha-forge` でバックテストを回した結果」を見るためのツールだったため、まず `alpha-forge` で何か実行しないと画面が空っぽでした。v0.2.0 からは **法的に再配布フリーな合成データセット** が wheel に同梱されており、追加準備なしで全機能を体験できます。

```bash
pip install alpha-visualizer==0.2.0
vis serve --use-bundled-samples --no-open
# http://127.0.0.1:8000 を開く
```

同梱されるサンプルは、5 年分（1250 営業日）の合成 OHLCV × 教科書的な 8 戦略の総当たりで、**40 件のバックテスト + 2 件の WFO + 2 件の Grid 最適化 + 5 件の戦略アイデアメモ** を含みます。

| 銘柄 | 銘柄キャラクター | 戦略との典型的な相性 |
|---|---|---|
| `EQUITY_SYNTH` | 2008 風クラッシュ → 回復 → 軽い調整 | トレンド系が有効 |
| `INDEX_SYNTH` | 長期 calm → 2020 風 V 字回復 | 複合フィルタ系が有効 |
| `COMMODITY_SYNTH` | sideways → spike → blow-off → slow bleed | ブレイクアウト系が刺さる |
| `FX_SYNTH` | 全期間 mean-reverting（AR(1)） | 逆張り系が有効 |
| `CRYPTO_SYNTH` | bubble → crash × 2 + flash crash → recovery | トレンドフォロー + ブレイクアウト |

戦略 × 銘柄の相性マトリクスで意図的に分散させてあり、Browse 画面のソート・フィルタや、Compare 画面のヒートマップ、WFO の IS/OOS 安定性チャートが見栄えするよう調整しています。

データは Geometric Brownian Motion + Poisson ジャンプ + AR(1) で合成され、銘柄シンボルは必ず `_SYNTH` サフィックスを持つため、実銘柄との取り違えは発生しません。再生成スクリプト `samples/build_samples.py` は決定論的に動き、CI で `git diff --exit-code` をかけてバイト等価性を継続検証しています。

> 同梱戦略は SMA / RSI / MACD / Bollinger / ADX / Donchian といった **教科書的な指標の組み合わせのみ** です。HMM レジーム識別や MTF 最適化済みパラメータといった `alpha-forge` 本体の差別化要素は含まれません。

### 2. ライブ実績ビュー（Detail 画面）

`data/live/` 配下の **summaries / trades を読み込み、同期間のバックテストと並べて diff を表示** する Live タブを Detail 画面に追加しました（#57）。バックテストでは想定通りでも、実弾で運用したら勝率が大きく違う——という乖離を即座に確認できます。期間整合がずれている場合は自動で揃えて並べます。

### 3. HMM / レジーム背景帯

Equity Chart の背景に **HMM ステート（高ボラ / 中ボラ / 低ボラ等）を色帯で重ねる** ようになりました（#56）。さらに Risk タブに「レジーム別サマリーカード」を追加し、各レジームでの取引数・勝率・平均リターンを 1 画面で確認できます。`alpha-forge` 側で HMM レジームを推論した戦略を可視化する際にとくに有効です。

### 4. セキュリティと品質の底上げ

- **CodeQL のセキュリティアラート 14 件を解消**（#175）。`path-injection` / `log-injection` / SSRF 等の検出を全てクリア。
- `optimization_runs` テーブル欠落や SQLAlchemy `OperationalError` 発生時のレスポンスを 404 から 500 に変更。「リソース未存在 (404)」と「DB 障害 (500)」の意味論を分離（#106）。
- Browse 画面で `latest_*` フィールドが `undefined` の戦略でクラッシュする問題を修正（#23）。
- `alpha-forge` 側の DB ファイル名デフォルト変更（`backtest_results.db`）に追従（#177）。
- 非有限値の `best_metric` を null として返し、フロントは `—` で表示（#172）。

### 5. CI と開発体験

- **Lighthouse CI** で各 PR の Performance / Accessibility / Best-Practices を継続計測（#136、#162）。
- **E2E fixture drift check** と **OSS sample-alpha-forge drift check** で、テスト用フィクスチャと同梱サンプルの「再生成 → diff=0」を強制（#161、#178）。
- React 19 / react-router-dom 7 / Storybook 10 / Vite 8 など、フロントエンド主要依存を最新メジャーへ更新。

## アップグレード方法

既に PyPI 公開済みです。

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest        # プロジェクトに追加
uv tool install alpha-visualizer       # CLI として使う
```

`--use-bundled-samples` を使うのが最も簡単な動作確認方法です。`alpha-forge` プロジェクト側のデータを見る場合は従来通り：

```bash
vis serve --forge-dir /path/to/your/alpha-strategies
```

設定ファイル（`forge.yaml`）に変更はありません。既存の alpha-forge プロジェクトはそのまま動作します。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.2.0/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.2.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **インストール手順**: [alpha-visualizer / インストール](installation.md)
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)
- **設定**: [alpha-visualizer / 設定](configuration.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。
