# インストール

`alpha-visualizer` は PyPI で配布されています。Python 3.12 以上が必要です。

## 動作要件

| 項目 | バージョン |
|---|---|
| Python | 3.12 以上 |
| OS | macOS / Linux / Windows |
| ブラウザ | Chrome / Firefox / Safari / Edge の最新版 |

## uv（推奨）

[uv](https://docs.astral.sh/uv/) を使うと専用のツール環境にインストールでき、Python のバージョン競合を気にせず使えます。

```bash
uv tool install alpha-visualizer
```

uv 自体の導入が必要な場合は <https://docs.astral.sh/uv/getting-started/installation/> を参照してください。

## pip

通常の Python 環境にインストールする場合：

```bash
pip install alpha-visualizer
```

仮想環境内へのインストール例：

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install alpha-visualizer
```

## ソースから（開発者向け）

GitHub から clone してローカルで動作させる場合：

```bash
git clone https://github.com/alforge-labs/alpha-visualizer.git
cd alpha-visualizer
uv sync                            # Python 依存関係
cd frontend && npm install && npm run build && cd ..
uv run vis serve --forge-dir <path>
```

開発フローの詳細は [CONTRIBUTING.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/CONTRIBUTING.md) を参照してください。

## インストール確認

```bash
vis --version
```

正常にインストールされていれば、バージョン番号が表示されます。

## アップグレード

```bash
# uv
uv tool upgrade alpha-visualizer

# pip
pip install --upgrade alpha-visualizer
```

## アンインストール

```bash
# uv
uv tool uninstall alpha-visualizer

# pip
pip uninstall alpha-visualizer
```

## 次のステップ

- [機能詳細](features.md) で各画面の使い方を確認
- [設定](configuration.md) で CLI オプション・`forge.yaml` を確認
