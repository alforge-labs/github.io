# CLI Reference

A complete catalog of every command group provided by the `forge` CLI. Detailed parameters and output examples for each group are documented on the per-group pages linked below.

!!! info "Scaffolded pages"
    Detailed references (parameters, output examples, error codes) for each group are being filled in incrementally via per-group issues. The "Subcommands" tables on this page are kept in sync with the implementation.

## Core Command Groups

The commands you'll use most often in real strategy development. Each has a dedicated page.

| Group | Description | Details |
|-------|-------------|---------|
| **backtest** | Run backtests and analyze results | [backtest →](backtest.md) |
| **optimize** | Parameter optimization (Bayesian, grid, walk-forward) | [optimize →](optimize.md) |
| **strategy** | Create, register, and manage strategy JSON | [strategy →](strategy.md) |
| **data** | Fetch and update historical data | [data →](data.md) |
| **journal** | Track run history, tags, and verdicts | [journal →](journal.md) |
| **live** | Live trading analysis and records | [live →](live.md) |

## Other Commands

Authentication, utilities, and supporting features are bundled on the [Other commands](other.md) page.

| Group | Description | Link |
|-------|-------------|------|
| **auth** | Whop OAuth login / logout and authentication status | [other#auth →](other.md#auth) |
| **init** | Initial project setup | [other#init →](other.md#init) |
| **pine** | Convert between strategy JSON and TradingView Pine Script | [other#pine →](other.md#pine) |
| **indicator** | List and inspect supported technical indicators | [other#indicator →](other.md#indicator) |
| **idea** | Manage and search investment ideas | [other#idea →](other.md#idea) |
| **altdata** | Fetch and manage alternative data (sentiment, etc.) | [other#altdata →](other.md#altdata) |
| **pairs** | Pair trading (cointegration tests) | [other#pairs →](other.md#pairs) |
| **ml** | ML dataset, model training & walk-forward validation (issue #512 Phase 1-2, 4) | [other#ml →](other.md#ml) |
| **docs** | Browse bundled documentation | [other#docs →](other.md#docs) |

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
