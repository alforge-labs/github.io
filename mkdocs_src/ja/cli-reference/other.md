# その他コマンド

[コアコマンド](index.md) 以外の補助・管理用コマンド群を 1 ページにまとめています。

!!! info "詳細充填予定"
    各サブコマンドのパラメータ・出力例・エラーコードの詳細は別 issue で順次充填されます。

## license

ライセンスキーの認証・解除・状態確認を行うコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge license activate` | ライセンスキーをアクティベートする |
| `forge license deactivate` | このマシンのライセンスを解除する |
| `forge license status` | 現在のライセンス状態を表示する |

詳しい使い方は [はじめに](../getting-started.md) のライセンス認証セクションを参照。

## login と logout

Whop アカウントによる認証コマンド。

| コマンド | 説明 |
|---------|------|
| `forge login` | Whop で認証する（ブラウザが開きます） |
| `forge logout` | ログアウトして認証情報を削除する |

## init

```bash
forge init
```

プロジェクトの初期セットアップを行う単一コマンド。設定ファイルの雛形を作成し、必要なディレクトリを準備します。

## pine

戦略 JSON と TradingView Pine Script v6 を相互変換するコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge pine generate` | 戦略定義から Pine Script を生成してファイル出力する |
| `forge pine preview` | 戦略定義から生成される Pine Script を標準出力でプレビューする |
| `forge pine import` | Pine Script (.pine) をパースして戦略定義として取り込む |

## indicator

対応するテクニカル指標の一覧と詳細を表示するコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge indicator list` | 対応指標の一覧を表示する。`FILTER_NAME` を指定すると一致する指標のみ表示（大文字小文字区別なし） |
| `forge indicator show` | 指定したインジケーターの詳細（説明・パラメータ・出力・使用例）を表示する |

## idea

投資アイデアの管理・タグ付け・検索を行うコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge idea add` | 新しいアイデアを追加する |
| `forge idea list` | アイデアの一覧を表示する |
| `forge idea show` | アイデアの詳細を表示する |
| `forge idea status` | アイデアのステータスを更新する |
| `forge idea link` | アイデアに戦略または実行記録をリンクする |
| `forge idea tag` | アイデアのタグを管理する |
| `forge idea note` | アイデアにメモを追加する |
| `forge idea search` | アイデアを検索する |
| `forge idea dashboard` | Web ダッシュボードを起動する（`forge dashboard` と同等） |

## altdata

代替データ（センチメント、マクロ指標等）の取得・管理を行うコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge altdata fetch` | 代替データを取得してストレージに保存する |
| `forge altdata list` | 保存済みの代替データ一覧を表示する |
| `forge altdata info` | 指定したデータソースの詳細を表示する |

## pairs

ペアトレード戦略のためのコインテグレーション検定とスプレッド系列を扱うコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge pairs scan` | 2 銘柄のコインテグレーション検定を実行する（例: `forge pairs scan SPY QQQ`） |
| `forge pairs scan-all` | ウォッチリスト全銘柄の全ペアをスキャンしてコインテグレーション検定を行う |
| `forge pairs build` | スプレッド系列を計算して `alt_data` に保存する（例: `forge pairs build --sym-a SPY --sym-b QQQ`） |

## dashboard

```bash
forge dashboard
```

Web ダッシュボードを起動する単一コマンド（Ctrl+C で停止）。エクイティカーブ・ドローダウン・モンテカルロ・WFO 結果などをブラウザで閲覧可能。

## docs

同梱ドキュメント・スキル・コマンド参考資料を表示するコマンドグループ。

| コマンド | 説明 |
|---------|------|
| `forge docs list` | 利用可能なドキュメント一覧を表示する |
| `forge docs show` | ドキュメントの内容を表示する |

---

*同期元: `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,dashboard,docs}.py` の Click decorator。*
