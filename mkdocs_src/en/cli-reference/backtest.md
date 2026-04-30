# forge backtest

Run backtests and analyze results.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge backtest run` | Run a backtest for the given symbol and strategy |
| `forge backtest batch` | Run parallel backtests for multiple strategy JSON files |
| `forge backtest diagnose` | Automatically diagnose performance issues in a strategy |
| `forge backtest list` | Show saved backtest results |
| `forge backtest report` | Display a saved backtest result |
| `forge backtest migrate` | Import existing JSON report files into the database |
| `forge backtest compare` | Compare multiple strategies side by side on the same symbol and period |
| `forge backtest portfolio` | Run a portfolio backtest across multiple symbols |
| `forge backtest chart` | Display dashboard URL to navigate to charts |
| `forge backtest signal-count` | Fast signal count check without running the full backtest |
| `forge backtest monte-carlo` | Run a Monte Carlo simulation from an existing backtest result |

## Quick start

The most basic usage is covered in [Getting Started — Your First Backtest](../getting-started.md#your-first-backtest). For detailed parameters, run `forge backtest <subcommand> --help`.

```bash
forge backtest run --help
forge backtest compare --help
```

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/backtest.py`.*
