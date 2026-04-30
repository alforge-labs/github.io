# End-to-End Strategy Development Workflow

A typical flow from raw data to live execution. This pairs naturally with a coding agent (e.g. Claude Code) for automated parameter exploration and strategy generation.

!!! note "Prerequisite"
    All commands below assume you are running from `alpha-strategies/` with `FORGE_CONFIG=forge.yaml uv run` prepended.

## 1. Fetch historical data

Save historical OHLCV data for a target symbol locally.

```bash
forge data fetch USDJPY
```

## 2. Create a strategy from a template

Generate a JSON scaffold, edit parameters, and register it.

```bash
forge strategy create --template ema_crossover \
  --id usdjpy_ema_v1 \
  --out data/strategies/usdjpy_ema_v1.json

# Edit the JSON, then register
forge strategy save data/strategies/usdjpy_ema_v1.json
```

## 3. Run a backtest

Validate the strategy against historical data.

```bash
forge backtest run USDJPY --strategy usdjpy_ema_v1

# Visual equity curve
forge backtest chart USDJPY --strategy usdjpy_ema_v1
```

## 4. Optimize parameters

Bayesian search with Optuna (TPE), then apply the best result.

```bash
forge optimize run USDJPY --strategy usdjpy_ema_v1 \
  --metric sharpe_ratio --trials 300 --save

forge optimize apply data/results/usdjpy_ema_v1_opt.json \
  --to-strategy usdjpy_ema_v1_optimized
```

## 5. Walk-forward validation

Detect overfitting with out-of-sample testing.

```bash
forge optimize walk-forward USDJPY \
  --strategy usdjpy_ema_v1_optimized --windows 5

# Confirm parameter robustness
forge optimize sensitivity USDJPY \
  --strategy usdjpy_ema_v1_optimized
```

## 6. Generate Pine Script

Export a TradingView alert script from the optimized strategy.

```bash
forge pine generate --strategy usdjpy_ema_v1_optimized
```

Output: `output/pinescript/usdjpy_ema_v1_optimized.pine`

!!! tip "Related commands"
    See [CLI Reference](../cli-reference/index.md) for the complete option lists. Next step: [Bringing Pine Scripts into TradingView](tradingview-pine-integration.md).
