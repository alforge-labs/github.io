# forge live

Live trading event ingestion, trade conversion, and performance analysis.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge live list` | List strategies that have live trading records |
| `forge live events` | List raw trading events |
| `forge live convert-check` | Check readiness to convert raw events to trade records |
| `forge live import-events` | Generate and save trade records from fill / close events |
| `forge live trades` | List individual trade records for a strategy |
| `forge live summary` | Show live performance summary for a strategy |
| `forge live compare` | Compare the latest backtest run with live summary |
| `forge live doctor` | Check the setup status of live trading analysis |
| `forge live sync-events` | Sync event logs from VPS to local via rsync |

## Quick start

Typical flow: sync events → convert check → import → summary → backtest comparison.

```bash
forge live sync-events --help
forge live convert-check --help
forge live import-events --help
forge live summary --help
```

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/live.py`.*
