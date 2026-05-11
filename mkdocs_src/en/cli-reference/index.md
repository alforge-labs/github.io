# CLI Reference

A complete catalog of every command group provided by the `forge` CLI. Detailed parameters and output examples for each group are documented on the per-group pages linked below.

!!! info "Command hierarchy reorganization (alpha-forge #610)"
    The top-level was reorganized from a flat 17-command layout into a **logical group hierarchy** ahead of the commercial release. **Old command names still work**, but migration to the new hierarchy is recommended. See [Legacy → New mapping](#legacy-to-new-command-mapping) below.

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

## Auxiliary Groups (added in D1 #610)

| New Group | Subcommands | Description |
|---|---|---|
| **analyze** | `indicator` / `ml` / `pairs` | Strategy-analysis utilities (consolidates former top-level commands) |
| **system** | `init` / `auth` / `docs` | Operational utilities (consolidates former top-level commands) |

## Legacy to New Command Mapping

Old names remain callable but migrating to the new hierarchy is recommended (a `DeprecationWarning` will be shown in a future release).

| Legacy Command | New Command |
|---|---|
| `forge altdata <sub>` | `forge data alt <sub>` |
| `forge tv <sub>` | `forge data tv-mcp <sub>` |
| `forge indicator <sub>` | `forge analyze indicator <sub>` |
| `forge ml <sub>` | `forge analyze ml <sub>` |
| `forge pairs <sub>` | `forge analyze pairs <sub>` |
| `forge init` | `forge system init` |
| `forge auth <sub>` | `forge system auth <sub>` |
| `forge docs <sub>` | `forge system docs <sub>` |

## All Commands at a Glance

Implementation-derived catalog covering all 15 groups and ~75 subcommands.

| Group | Subcommands |
|-------|-------------|
| backtest | `run` `batch` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `signal-count` `monte-carlo` |
| optimize | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` |
| strategy | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` |
| data | `fetch` `list` `trend` `update` |
| journal | `list` `show` `runs` `compare` `tag` `note` `verdict` |
| live | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` |
| auth | `login` `logout` `status` `check op` |
| init | (single command) |
| pine | `generate` `preview` `import` |
| indicator | `list` `show` |
| idea | `add` `list` `show` `status` `link` `tag` `note` `search` |
| altdata | `fetch` `list` `info` |
| pairs | `scan` `scan-all` `build` |
| **ml** | **`dataset build` `dataset feature-sets` `train` `models` `walk-forward`** (issue #512 Phase 1-2, 4) |
| docs | `list` `show` |

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
