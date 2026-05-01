# Freemium Limits

AlphaForge offers four plans: **Free, Monthly, Annual, and Lifetime**. The non-Free tiers (Lifetime / Annual / Monthly) are collectively referred to as **paid plans**. The Free plan caps the maximum data date passed to the evaluation engine (backtest / optimization) at **2023-12-31**. This page summarizes the behavior and how to verify it locally.

!!! note "Targeted commands"
    The limit is applied on the following paths.
    - **Data fetch**: `forge data fetch` / `forge data update` / `forge pine generate --with-training-data` / strategy external-symbol auto-fetch (`merge_external_symbols`)
    - **Evaluation engine entry**: `forge backtest run` / `forge optimize` (`run` / `grid` / `walk-forward` / `cross-symbol`)

    Both fetch and evaluation paths share **2023-12-31** as the cap.

## Plan structure

| Plan | Fetch / evaluation date limit | Notes |
|---|---|---|
| Free | Up to 2023-12-31 | Fetch end is capped at 2023-12-31, and the evaluation engine entry clips to the same date |
| Monthly | No limit | Monthly subscription. Latest data can be fetched and evaluated |
| Annual | No limit | Annual subscription. Latest data can be fetched and evaluated |
| Lifetime | No limit | One-time purchase. Latest data can be fetched and evaluated |

Internally, Lifetime / Annual / Monthly are all treated as the `lifetime` plan because they share the same "no-limit" behavior. Please refer to the landing page for the most up-to-date plan and pricing details.

## Behavior

### Free plan

#### Data fetch (`forge data fetch` / `forge data update` / `forge pine generate --with-training-data` / external-symbol auto-fetch)
- The `end` argument (whether explicitly passed or falling back to `today`) is capped at 2023-12-31 if it would otherwise exceed it.
- `forge data update` skips items whose stored `end` is on or after 2023-12-31 with a "Free plan limit prevents fetching data after 2023-12-31" message.
- The CLI's normal output displays a yellow Panel warning along with an upgrade hint pointing to a paid plan.
- `--json` output includes a structured `freemium_limit_notices` field with `code = "free_tier_data_fetch_clipped"`.

#### Evaluation engine entry (`forge backtest run` / `forge optimize`)
- Input rows newer than 2023-12-31 are clipped automatically right before evaluation. This serves as a safety net when external CSV files are loaded directly (the fetch path normally clips them in advance).
- The CLI's normal output displays a yellow Panel warning.
- `--json` output `freemium_limit_notices` uses `code = "free_tier_evaluation_date_clipped"`.

Fetch-time `freemium_limit_notices` example:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_data_fetch_clipped",
      "message": "Freeプランでは2023-12-31までのデータのみ取得できます。最新データを取得するには有料プラン（Lifetime / Annual / Monthly）が必要です。",
      "original_value": "2025-06-30",
      "applied_value": "2023-12-31"
    }
  ]
}
```

Evaluation-time `freemium_limit_notices` example:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_evaluation_date_clipped",
      "message": "Freeプランでは2023-12-31までのデータのみ評価できます。最新データで評価するには有料プラン（Lifetime / Annual / Monthly）が必要です。",
      "original_value": "2025-01-15",
      "applied_value": "2023-12-31"
    }
  ]
}
```

### Paid plans (Lifetime / Annual / Monthly)

No limits are applied; you can fetch and evaluate the latest data without clipping. The output does not include any `freemium_limit_notices` warnings.

## Override for development and verification

To validate plan-specific behavior locally, set the `ALPHA_FORGE_PLAN` environment variable.

```bash
ALPHA_FORGE_PLAN=free uv run forge backtest run AAPL --strategy sma_crossover_v1
ALPHA_FORGE_PLAN=lifetime uv run forge backtest run AAPL --strategy sma_crossover_v1
ALPHA_FORGE_PLAN=dev uv run forge backtest run AAPL --strategy sma_crossover_v1
```

| Value | Purpose |
|---|---|
| `free` | Forces the Free plan limits |
| `lifetime` | Treats the session as a paid plan (Lifetime / Annual / Monthly) — no limits |
| `dev` | Development plan paired with the EULA-skip path. Unavailable in distributed builds. |

When `ALPHA_FORGE_PLAN` is unset, AlphaForge uses the plan resolved from the auth cache (Whop membership info). Setting `ALPHA_FORGE_DEV_SKIP_LICENSE=1` enables the `dev` plan with EULA-skip; note that `dev` is distinct from the paid plans.

## How to remove the limit

The only supported way to lift the limit is to obtain a **paid plan** (Lifetime, Annual, or Monthly). Manually trimming a CSV to 2023-12-31 and re-running will produce the same result, because the clip is always enforced at the evaluation engine boundary.

- Purchase a paid plan: pick Monthly, Annual, or Lifetime from the AlphaForge sales page.
- If a Whop membership is not reflected in the auth cache, re-run `forge auth login`.
