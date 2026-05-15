# End-to-End Strategy Development Workflow

A typical flow from raw data to live execution. This pairs naturally with a coding agent (e.g. Claude Code) for automated parameter exploration and strategy generation.

![AlphaForge 6-Step Technical Workflow](../assets/illustrations/alphaforge-technical-workflow-en.png)

!!! note "Prerequisite"
    This page assumes you have installed `forge` (binary) per [Getting Started](../getting-started.md) and have run `forge system init` in your working directory (so `forge.yaml` and `data/` exist). All commands invoke `forge` directly from the working directory.

    If you're working inside the alpha-trade developer monorepo, prepend `FORGE_CONFIG=forge.yaml uv --directory alpha-forge run forge ...` to each command.

## 1. Fetch historical data

Save historical OHLCV data for a target symbol locally.

```bash
forge data fetch 'USDJPY=X'
```

!!! warning "Symbol naming for FX / Futures / Crypto"
    yfinance (the default provider) requires fixed suffixes per asset class.

    | Asset class | Examples |
    |---|---|
    | US stocks / ETFs | `SPY`, `AAPL`, `QQQ` |
    | FX | `USDJPY=X`, `EURUSD=X`, `GBPJPY=X` (always `=X`) |
    | Futures | `CL=F` (WTI), `GC=F` (Gold), `ES=F` (S&P) |
    | Crypto | `BTC-USD`, `ETH-USD` (hyphen) |

    Quote symbols containing shell metachars (e.g., `'USDJPY=X'`).

## 2. Create a strategy from a template

Generate a JSON scaffold, edit parameters, and register it.

```bash
forge strategy create --template sma_crossover_v1 \
  --out data/strategies/usdjpy_sma_v1.json
```

!!! info "Three fields you should always edit in the JSON"
    The generated JSON inherits the template's defaults, so edit at minimum:

    1. `strategy_id`: leaving it as `sma_crossover_v1` collides with the built-in template. Change it to a unique value (e.g. `usdjpy_sma_v1`).
    2. `name`: a human-readable label.
    3. `target_symbols`: defaults to `[]`. Either set the symbol list (e.g. `["USDJPY=X"]`) or pass it on each `forge backtest run <SYMBOL>`.

    If you plan to optimize, also fill in `optimizer_config.param_ranges`. (It works even when null, but explicit ranges are easier to reproduce.)

Then save it to the strategy DB.

```bash
forge strategy save data/strategies/usdjpy_sma_v1.json
```

!!! tip "Skip DB registration with `--strategy-file`"
    Both `forge backtest run` and `forge optimize run` accept `--strategy-file <path>`, which loads JSON directly without DB registration — handy during rapid iteration.

## 3. Run a backtest

Validate the strategy against historical data.

```bash
forge backtest run 'USDJPY=X' --strategy usdjpy_sma_v1

# Show the chart URL and open it in your browser
forge backtest chart usdjpy_sma_v1 --open
```

## 4. Optimize parameters

Bayesian search with Optuna (TPE), then apply the best result.

```bash
forge optimize run 'USDJPY=X' --strategy usdjpy_sma_v1 \
  --metric sharpe_ratio --trials 300 --save

# Apply the saved result file (optimize_usdjpy_sma_v1_<timestamp>.json) as a new strategy
forge optimize apply data/results/optimize_usdjpy_sma_v1_<timestamp>.json \
  --to-strategy usdjpy_sma_v1_optimized
```

!!! note "When the best score is `-inf`"
    Every trial returned NaN. Common causes: the optimization range is too narrow, or the period has too few trades. Re-check `optimizer_config.param_ranges` and widen the data range.

## 5. Walk-forward validation

Detect overfitting with out-of-sample testing.

```bash
forge optimize walk-forward 'USDJPY=X' \
  --strategy usdjpy_sma_v1_optimized --windows 5

# Sensitivity analysis (point at the optimization result JSON file)
forge optimize sensitivity data/results/optimize_usdjpy_sma_v1_<timestamp>.json
```

!!! warning "When all WFT windows show `OOS 0 trades`"
    Short data periods leave each window without any trades. For FX / 1d, aim for ~5 years (~1,250 rows). Either fetch a longer history (`forge data fetch '<SYM>' --period 5y`) or coarsen with `--windows 2`.

## 6. Generate Pine Script

Export a TradingView alert script from the optimized strategy.

```bash
forge pine generate --strategy usdjpy_sma_v1_optimized
```

Output: `output/pinescript/usdjpy_sma_v1_optimized.pine`

!!! tip "Related commands"
    See [CLI Reference](../cli-reference/index.md) for the complete option lists. Next step: [Bringing Pine Scripts into TradingView](tradingview-pine-integration.md).

!!! tip "See actual output samples"
    For output formats, equity curve examples, optimization results, and Pine Script samples, see [Output Examples](output-examples.md).
