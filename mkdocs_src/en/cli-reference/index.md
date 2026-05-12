# CLI Reference

A complete catalog of every command group provided by the `forge` CLI. Detailed parameters and output examples for each group are documented on the per-group pages linked below.

## Core Command Groups

The commands you'll use most often in real strategy development. Each has a dedicated page.

| Group | Description | Details |
|-------|-------------|---------|
| **strategy** | Create, register, and manage strategy JSON | [strategy →](strategy.md) |
| **backtest** | Run backtests and analyze results | [backtest →](backtest.md) |
| **optimize** | Parameter optimization (Bayesian, grid, walk-forward) | [optimize →](optimize.md) |
| **explore** | Autonomous exploration loop (backtest → optimize → WFT) | — |
| **live** | Live trading analysis and records | [live →](live.md) |
| **pine** | Convert between strategy JSON and TradingView Pine Script | — |
| **journal** | Track run history, tags, and verdicts | [journal →](journal.md) |
| **idea** | Manage and search investment ideas | — |
| **data** | Historical / alternative / TradingView MCP data | [data →](data.md) |

## Auxiliary Groups

| Group | Subcommands | Description |
|---|---|---|
| **analyze** | `indicator` / `ml` / `pairs` | Strategy-analysis utilities |
| **system** | `init` / `auth` / `docs` | Operational utilities |

## All Commands at a Glance

Implementation-derived catalog covering every group and subcommand.

| Group | Subcommands |
|-------|-------------|
| backtest | `run` `batch` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `signal-count` `monte-carlo` |
| optimize | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` |
| strategy | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` |
| data | `fetch` `list` `trend` `update` `alt fetch` `alt list` `alt info` `tv-mcp <sub>` |
| journal | `list` `show` `runs` `compare` `tag` `note` `verdict` |
| live | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` |
| **explore** | **`run` `index` `import` `log` `status` `recommend` `coverage`** |
| pine | `generate` `preview` `import` |
| idea | `add` `list` `show` `status` `link` `tag` `note` `search` |
| **analyze** | `indicator list` `indicator show` `pairs scan` `pairs scan-all` `pairs build` `ml dataset build` `ml dataset feature-sets` `ml train` `ml models` `ml walk-forward` |
| **system** | `init` `auth login` `auth logout` `auth status` `auth check op` `docs list` `docs show` |

## Built-in Help

Every command supports `--help`.

```bash
forge --help                         # Top-level command list
forge backtest --help                # Subcommands of the backtest group
forge backtest run --help            # Detailed parameters for a specific subcommand
```

## Related Documentation

- [Getting Started](../getting-started.md) — Tutorial covering installation through your first backtest
- [Strategy Templates](../templates.md) — Bundled strategies overview
- [AI-Driven Strategy Exploration Workflow](../guides/ai-exploration-workflow.md) — Claude Code / Codex × AlphaForge

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/*.py`. This catalog must be kept in sync when CLI commands change. -->
