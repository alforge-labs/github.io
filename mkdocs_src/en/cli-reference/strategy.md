# forge strategy

Create, register, validate, and manage strategy JSON definitions.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## Subcommands

| Command | Description |
|---------|-------------|
| `forge strategy list` | List all registered strategies |
| `forge strategy create` | Create a JSON file from a built-in template (for Claude CLI editing) |
| `forge strategy save` | Register a custom strategy from a JSON file |
| `forge strategy show` | Display the definition (JSON) of a registered strategy |
| `forge strategy migrate` | Import existing JSON files into the DB (requires `use_db: true`) |
| `forge strategy delete` | Delete a registered strategy from the DB |
| `forge strategy validate` | Validate strategy logical consistency (add `--symbol` for dynamic checks) |

## Quick start

Workflow: pick a template → edit → save → validate → backtest.

```bash
forge strategy create --help
forge strategy save --help
forge strategy validate --help
```

For the strategy JSON schema itself, see [Strategy Templates](../templates.md).

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/strategy.py`.*
