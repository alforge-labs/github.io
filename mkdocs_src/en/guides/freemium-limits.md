# Freemium Limits

AlphaForge offers four plans: **Free, Monthly, Annual, and Lifetime**. The non-Free tiers (Lifetime / Annual / Monthly) are collectively referred to as **paid plans**. The Free plan caps the maximum data date passed to the evaluation engine (backtest / optimization) at **2023-12-31**, and the optimization trial count at **50 trials**. This page summarizes the behavior and how to verify it locally.

!!! note "Targeted commands"
    The limit is applied on the following paths.
    - **Data fetch**: `forge data fetch` / `forge data update` / `forge pine generate --with-training-data` / strategy external-symbol auto-fetch (`merge_external_symbols`)
    - **Evaluation engine entry**: `forge backtest run` / `forge optimize` (`run` / `grid` / `walk-forward` / `cross-symbol`)
    - **Optimization trial count**: `forge optimize run` / `cross-symbol` / `portfolio` / `multi-portfolio` / `walk-forward` / `grid`
    - **Pine Script export (hard block)**: `forge pine generate` / `forge pine preview` (`forge pine import` is unaffected)

    Both fetch and evaluation paths share **2023-12-31** as the cap, and the optimization paths share **50 trials** as the cap. Pine Script export is **fully blocked** on the Free plan.

## Plan structure

| Plan | Fetch / evaluation date limit | Optimization trial count | Notes |
|---|---|---|---|
| Free | Up to 2023-12-31 | Up to 50 trials | Fetch end is capped at 2023-12-31, and the evaluation engine entry clips to the same date. **Pine Script export is fully blocked.** |
| Monthly | No limit | No limit | Monthly subscription. Latest data with unlimited trials. Pine Script export enabled. |
| Annual | No limit | No limit | Annual subscription. Latest data with unlimited trials. Pine Script export enabled. |
| Lifetime | No limit | No limit | One-time purchase. Latest data with unlimited trials. Pine Script export enabled. |

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

#### Optimization trial count (`forge optimize` family)
- `forge optimize run / cross-symbol / portfolio / multi-portfolio / walk-forward / grid` cap the trial count at **50** on the Free plan. The command does not error out — it continues with the capped value.
- `forge optimize grid` randomly samples 50 combinations using a fixed seed (reproducible) when the full Cartesian product exceeds 50. This preserves the representative coverage of the search space (vs. naively slicing the first 50).
- `forge optimize walk-forward` calls optimization per window internally, but the CLI deduplicates the notice and surfaces it once.
- `forge optimize multi-portfolio` aligns the displayed trial count with the effective value (50) so display/execution/JSON are consistent.
- `forge optimize apply` / `history` / `sensitivity` are out of scope (no trial concept).
- The CLI's normal output displays a yellow Panel warning.
- `--json` output `freemium_limit_notices` uses `code = "free_tier_optimization_trial_capped"`. For grid, the JSON also contains `total_trials` (full Cartesian size) and `executed_trials` (capped sample size, 50).

Optimization trial cap `freemium_limit_notices` example:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_optimization_trial_capped",
      "message": "Freeプランでは最適化のトライアル数が50回に制限されています。無制限の最適化を行うには有料プラン（Lifetime / Annual / Monthly）が必要です。",
      "original_value": 1000,
      "applied_value": 50
    }
  ]
}
```

#### Pine Script export (`forge pine generate` / `forge pine preview`)

- On the Free plan, both commands are **hard-blocked**: they halt immediately, and neither write a file nor print to stdout.
- Exit code is `1`, and a red Panel is shown with the purchase URL ([https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)).
- The structured `freemium_limit_notices` `code` is `free_tier_pine_export_blocked` (`original_value` / `applied_value` are `null`).
- `forge pine import` is the import path and remains available on the Free plan.

Pine Script hard-block sample (Free plan, CLI):
```text
╭─────────── 🔒 Premium-only feature ────────────╮
│ Pine Script export is available for paid plans │
│ (Lifetime / Annual / Monthly) only.            │
│ Upgrade your license to seamlessly run on …    │
│ Upgrade: https://alforgelabs.com/en/index.html#pricing │
╰────────────────────────────────────────────────╯
```

Pine Script hard-block `freemium_limit_notices` example:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_pine_export_blocked",
      "message": "Pine Script エクスポートは有料プラン（Lifetime / Annual / Monthly）のみ利用できます。",
      "original_value": null,
      "applied_value": null
    }
  ]
}
```

### Paid plans (Lifetime / Annual / Monthly)

No limits are applied; you can fetch and evaluate the latest data with unlimited trials, and Pine Script export is fully unlocked. The output does not include any `freemium_limit_notices` warnings.

## How to unlock the limits

To unlock the limits, upgrade to a **paid plan** (Lifetime, Annual, or Monthly). Manually trimming a CSV to 2023-12-31 and re-running will produce the same result, because the clip is always enforced at the evaluation engine boundary.

- Upgrade to a paid plan: pick Monthly, Annual, or Lifetime from the AlphaForge sales page.
- If a Whop membership is not reflected in the auth cache, re-run `forge auth login`.

## Related pages

- [Trust, Safety, and Limits](../legal/trust-safety-limits.md)
- [Disclaimers](../legal/disclaimers.md)
- [Privacy Policy](../legal/privacy.md)
