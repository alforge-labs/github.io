# forge data

Fetch, update, and inspect historical market data.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge data fetch` | Fetch and save historical data |
| `forge data list` | List all stored historical datasets |
| `forge data trend` | Evaluate market trend from stored data |
| `forge data update` | Incrementally update all stored historical data to the latest |

## Quick start

```bash
forge data fetch SPY --period 5y --interval 1d
forge data list
forge data update
```

For details, run `forge data <subcommand> --help`.

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/data.py`.*
