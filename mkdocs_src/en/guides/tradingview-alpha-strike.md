# TradingView × alpha-strike Integration

alpha-strike receives TradingView webhook alerts and forwards orders to OANDA or moomoo brokers.

## 1. Configure environment variables

Create `alpha-strike/.env` with the following:

```bash
# Required
WEBHOOK_PASSPHRASE=your-secret-passphrase

# OANDA
OANDA_API_KEY=your-personal-access-token
OANDA_ACCOUNT_ID=your-account-id
OANDA_ENV=PRACTICE    # or LIVE

# moomoo
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRD_ENV=SIMULATE   # or REAL
```

## 2. Webhook URL

!!! note "Webhook endpoint"
    Set the TradingView alert Webhook URL to:
    `http://<your-server>:8080/webhook`

## 3. Payload format

Use the following JSON in the TradingView alert message:

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

| Field | Description | Example |
|------|-------------|---------|
| `passphrase` | **Required** — Must match `WEBHOOK_PASSPHRASE` in `.env` | `"my-secret"` |
| `broker` | **Required** — Target broker | `"oanda"` / `"moomoo"` |
| `asset_class` | **Required** — Asset class | `"FX"` / `"COMMODITY"` / `"US"` / `"INDEX"` |
| `action` | **Required** — Order direction | `"buy"` / `"sell"` |
| `ticker` | **Required** — Symbol (TradingView notation) | `"USDJPY"` / `"XAUUSD"` |
| `quantity` | **Required** — Order size (positive number) | `1000` / `0.1` |

## 4. Ticker to OANDA instrument mapping

| asset_class | ticker | OANDA instrument |
|---|---|---|
| FX | USDJPY | USD_JPY |
| COMMODITY | XAUUSD | XAU_USD |
| INDEX | NAS100 | NAS100_USD |
| US | AAPL | AAPL_USD |

## 5. Verify connectivity

```bash
# Health check
curl http://localhost:8080/health
# → {"status":"ok"}

# Test order (use PRACTICE / SIMULATE environment)
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"your-secret","broker":"oanda","asset_class":"FX","action":"buy","ticker":"USDJPY","quantity":1000}'
```
