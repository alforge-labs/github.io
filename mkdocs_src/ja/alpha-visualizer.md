# alpha-visualizer

**alpha-visualizer** は AlphaForge（`forge`）のバックテスト結果を Web ブラウザで確認できる独立パッケージです。`forge` 本体を軽量に保つため、可視化機能を分離して提供しています。

## インストール

```bash
uv tool install alpha-visualizer
```

または pip 環境の場合：

```bash
pip install alpha-visualizer
```

インストール確認：

```bash
vis --version
```

## vis serve

Web ダッシュボードを起動します。

```bash
vis serve [OPTIONS]
```

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `--forge-dir DIRECTORY` | `.`（カレントディレクトリ） | `forge` の出力 DB が置かれているディレクトリ |
| `--host TEXT` | `127.0.0.1` | バインドするホスト名 |
| `--port INTEGER` | `8000` | ポート番号 |
| `--no-open` | — | ブラウザを自動で開かない |

### 基本的な使い方

`alpha-strategies/` など、`forge` を実行するディレクトリ（`data/results/forge.db` が存在する場所）で起動します。

```bash
# alpha-strategies/ に移動してそのまま起動
cd ~/dev/alpha-strategies
vis serve
```

ブラウザで **http://127.0.0.1:8000** が自動で開きます。`Ctrl+C` でサーバーを停止します。

### forge-dir を指定する場合

```bash
# パスを明示して起動
vis serve --forge-dir ~/dev/alpha-strategies

# ポート・ホストを変更
vis serve --forge-dir ~/dev/alpha-strategies --port 9000

# リモートからアクセスできるようにバインド
vis serve --host 0.0.0.0 --port 8000

# ブラウザを自動で開かない
vis serve --no-open
```

## forge との連携

`vis serve` が読み取るファイル構造は `forge` の出力ディレクトリと一致しています。

```
<forge-dir>/
├── data/
│   ├── results/
│   │   └── forge.db         ← バックテスト・最適化結果 DB
│   ├── strategies/
│   │   └── *.json           ← 戦略 JSON ファイル
│   └── ideas/
│       └── ideas.json       ← アイデア一覧
```

`forge backtest run` や `forge optimize run` を実行するたびに `forge.db` が更新されます。ダッシュボードをリロードすると最新の結果が反映されます。

## ダッシュボード画面

| 画面 | 内容 |
|------|------|
| **戦略一覧** | 登録済み戦略と最新バックテスト結果のサマリ |
| **戦略詳細** | パラメータ・バックテスト結果一覧・最適化履歴グラフ |
| **バックテスト詳細** | エクイティカーブ・IS/OOS グラフ・指標カード・トレード一覧 |
| **比較画面** | 複数戦略の横断比較 |
| **WFO 画面** | ウォークフォーワード最適化のウィンドウ別結果 |
| **アイデア一覧** | アイデア一覧（status フィルタ可能） |

## ヘルプ

```bash
vis --help
vis serve --help
```
