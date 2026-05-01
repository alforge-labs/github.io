# Python Developers

For Python developers who want to manage strategy experiments with a CLI/JSON-first workflow.

## Why AlphaForge Fits Python Developers

- **Strategies are JSON** — declaratively manage parameters without writing boilerplate code
- **CLI supports structured output** — use `--json` flag to pipe results into your own scripts
- **Optuna-based optimization** — integrates naturally with the Python ecosystem
- **uv project structure** — coexists with your existing Python code in a monorepo

## Basic Usage

```bash
# Get backtest results as JSON and pipe to custom script
forge backtest run QQQ --strategy my_strategy --json | python analyze.py

# Optuna optimization (maximize Sharpe ratio)
forge optimize run QQQ --strategy my_strategy --trials 200 --objective sharpe

# Walk-forward validation
forge optimize walk-forward QQQ --strategy my_strategy --folds 5
```

## Managing Strategies as JSON

AlphaForge strategies are defined in JSON files — easy to version-control and diff.

```json
{
  "name": "my_strategy",
  "indicators": [
    { "id": "rsi", "period": 14 },
    { "id": "bbands", "period": 20 }
  ],
  "entry": { "rsi_lt": 30, "price_lt_lower_band": true },
  "exit": { "rsi_gt": 70 },
  "risk": { "max_position_size": 0.1 }
}
```

## Related Docs

- [End-to-End Strategy Development Workflow](../guides/end-to-end-workflow.md) — Full development cycle
- [Strategy Templates](../templates.md) — Complete JSON samples (copy-paste ready)
- [Strategy Gallery](../strategy-gallery.md) — Browse strategies by market and objective
- [CLI Reference](../cli-reference/index.md) — All commands in detail
