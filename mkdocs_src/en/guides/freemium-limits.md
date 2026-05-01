# Freemium Limits

AlphaForge offers four plans: **Free, Monthly, Annual, and Lifetime**. The non-Free tiers (Lifetime / Annual / Monthly) are collectively referred to as **paid plans**. The Free plan caps the maximum data date passed to the evaluation engine (backtest / optimization) at **2023-12-31**. This page summarizes the behavior and how to verify it locally.

!!! note "Targeted commands"
    The limit is applied at the entry point of `forge backtest run` and `forge optimize` (`run` / `grid` / `walk-forward` / `cross-symbol`). Limits on data acquisition paths such as `forge data fetch` are handled separately.

## Plan structure

| Plan | Evaluation date limit | Notes |
|---|---|---|
| Free | Up to 2023-12-31 | Input data is automatically clipped at this date |
| Monthly | No limit | Monthly subscription. Latest data can be evaluated |
| Annual | No limit | Annual subscription. Latest data can be evaluated |
| Lifetime | No limit | One-time purchase. Latest data can be evaluated |

Internally, Lifetime / Annual / Monthly are all treated as the `lifetime` plan because they share the same "no-limit" behavior. Please refer to the landing page for the most up-to-date plan and pricing details.

## Behavior

### Free plan

- Input rows newer than 2023-12-31 are clipped automatically right before evaluation.
- The CLI's normal output displays a yellow Panel warning along with an upgrade hint pointing to a paid plan.
- `--json` output includes a structured `freemium_limit_notices` field.

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

No limits are applied; you can evaluate the latest data without clipping. The output does not include any `freemium_limit_notices` warnings.

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
