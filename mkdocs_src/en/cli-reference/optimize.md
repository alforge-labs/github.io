# forge optimize

Parameter optimization across Bayesian search (Optuna), grid search, and walk-forward optimization.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge optimize run` | Run parameter optimization using Optuna |
| `forge optimize cross-symbol` | Run cross-symbol optimization across multiple symbols |
| `forge optimize portfolio` | Search for optimal portfolio allocation weights using Optuna |
| `forge optimize multi-portfolio` | Optimize allocation weights with Optuna using per-asset strategies |
| `forge optimize walk-forward` | Run walk-forward optimization |
| `forge optimize apply` | Apply optimization results to a strategy and save |
| `forge optimize sensitivity` | Run sensitivity analysis on optimized parameters to assess overfitting risk |
| `forge optimize history` | List past optimization results in scoreboard format |
| `forge optimize grid` | Run a full Cartesian Grid Search over `optimizer_config.param_ranges` |

## Quick start

A typical workflow is Bayesian optimization → sensitivity analysis → apply.

```bash
forge optimize run --help
forge optimize sensitivity --help
forge optimize apply --help
```

For walk-forward analysis, see [Getting Started](../getting-started.md) and `forge optimize walk-forward --help`.

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/optimize.py`.*
