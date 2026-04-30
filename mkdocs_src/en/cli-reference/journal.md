# forge journal

Manage strategy execution history, snapshots, tags, and verdicts.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge journal list` | Show list of strategies that have a journal |
| `forge journal show` | Show full history (snapshots and runs) for a strategy |
| `forge journal runs` | Show run results in table format |
| `forge journal compare` | Compare two run results side by side |
| `forge journal tag` | Add or remove tags |
| `forge journal note` | Append a note |
| `forge journal verdict` | Record a verdict (pass / fail / review) for a run result |

## Quick start

```bash
forge journal list
forge journal show <strategy_id>
forge journal verdict <run_id> --status pass --note "OOS test passed"
```

For details, run `forge journal <subcommand> --help`.

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/journal.py`.*
