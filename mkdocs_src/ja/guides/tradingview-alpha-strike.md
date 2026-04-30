# TradingView と alpha-strike の連携

alpha-strike は TradingView のアラートを Webhook で受け取り、OANDA・moomoo 証券に自動発注します。

## 1. 環境変数の設定

`alpha-strike/.env` を作成して以下を設定します。

```bash
# 必須
WEBHOOK_PASSPHRASE=your-secret-passphrase   # 任意の秘密文字列

# OANDA 使用時
OANDA_API_KEY=your-personal-access-token
OANDA_ACCOUNT_ID=your-account-id
OANDA_ENV=PRACTICE    # 本番は LIVE

# moomoo 使用時
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRD_ENV=SIMULATE   # 本番は REAL
```

## 2. Webhook URL

!!! note "Webhook エンドポイント"
    TradingView のアラート Webhook URL に以下を設定します:
    `http://<your-server>:8080/webhook`

## 3. ペイロード仕様

TradingView のアラートメッセージに JSON を記述します。

```json
{
  "passphrase": "your-secret-passphrase",
  "broker": "oanda",
  "asset_class": "FX",
  "action": "buy",
  "ticker": "USDJPY",
  "quantity": 1000
}
```

| フィールド | 説明 | 値の例 |
|------|------|--------|
| `passphrase` | **必須** — `.env` の `WEBHOOK_PASSPHRASE` と一致させること | `"my-secret"` |
| `broker` | **必須** — 発注先の証券会社 | `"oanda"` / `"moomoo"` |
| `asset_class` | **必須** — アセットクラス | `"FX"` / `"COMMODITY"` / `"US"` / `"INDEX"` |
| `action` | **必須** — 注文方向 | `"buy"` / `"sell"` |
| `ticker` | **必須** — 銘柄コード（TradingView のシンボル名） | `"USDJPY"` / `"XAUUSD"` |
| `quantity` | **必須** — 注文数量（0 より大きい正の数） | `1000` / `0.1` |

## 4. ティッカーと OANDA instrument の対応

| asset_class | ticker 例 | OANDA instrument |
|---|---|---|
| FX | USDJPY | USD_JPY |
| COMMODITY | XAUUSD | XAU_USD |
| INDEX | NAS100 | NAS100_USD |
| US | AAPL | AAPL_USD |

## 5. 動作確認

```bash
# ヘルスチェック
curl http://localhost:8080/health
# → {"status":"ok"}

# テスト発注（PRACTICE / SIMULATE 環境で確認）
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"your-secret","broker":"oanda","asset_class":"FX","action":"buy","ticker":"USDJPY","quantity":1000}'
```
