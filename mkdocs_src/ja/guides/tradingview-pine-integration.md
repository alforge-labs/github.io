# TradingView への Pine Script 反映

`forge pine generate` で生成した `.pine` ファイルを TradingView に貼り付けてアラートを設定します。

## 1. Pine エディタを開く

TradingView でチャートを開き、画面下部の「Pine エディタ」タブをクリックします。

## 2. スクリプトを貼り付ける

生成した `.pine` ファイルの内容をエディタに貼り付け、「スクリプトを追加」（▶ ボタン）をクリックします。

## 3. アラートを設定する

チャート右上のベルアイコン（アラート）→「アラートを追加」をクリック。

- **条件**: 追加したスクリプト名を選択
- **Webhook URL**: チェックを入れ、alpha-strike のエンドポイントを入力
- **メッセージ**: 後述の JSON ペイロードを入力（[alpha-strike 連携ガイド](tradingview-alpha-strike.md) 参照）

## 4. アラートメッセージのヒント

Pine Script 内でシグナル変数（例: `longSignal`）を定義しておくと、アラートの条件設定が簡単になります。

```pinescript
// Pine Script 内でのアラート定義例
longSignal = ta.crossover(ema_fast, ema_slow)
shortSignal = ta.crossunder(ema_fast, ema_slow)
alertcondition(longSignal, title="Long Entry", message="long")
```

!!! tip "次のステップ"
    Webhook 受信側の設定は [TradingView と alpha-strike の連携](tradingview-alpha-strike.md) を参照してください。
