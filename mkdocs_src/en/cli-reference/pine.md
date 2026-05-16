# alpha-forge pine

Convert between strategy JSON and TradingView Pine Script v6.

!!! warning "[Paid plans only] Pine Script export"
    `alpha-forge pine generate` and `alpha-forge pine preview` are **available on the paid plans only (Lifetime / Annual / Monthly)**. Running them on the Trial plan displays a red Panel with a purchase URL ([https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)) and exits with code `1` — no file is written and no preview is printed. `alpha-forge pine import` (the import path) is unaffected and remains available on Trial. See the [Trial limits guide](../guides/trial-limits.md) for details.

## alpha-forge pine generate `[Paid plans only]`

Generate Pine Script from a strategy definition and write it to `config.pinescript.output_path / <strategy_id>.pine`. **Paid plans only (Lifetime / Annual / Monthly).**

```bash
alpha-forge pine generate --strategy <ID> [--with-training-data]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | required | - | Strategy name |
| `--with-training-data` | flag | false | Embed trained HMM parameters into Pine Script if HMM indicator exists (auto-fetches data) |

Sample output (paid plan):

```text
✅ Pine Script saved: output/pinescript/spy_sma_v1.pine
```

Sample output (Trial plan — hard block):

```text
╭──────────── 🔒 Premium-only feature ─────────────╮
│ Pine Script export is available for paid plans   │
│ only (Lifetime / Annual / Monthly).              │
│ Upgrade your license to seamlessly run on …      │
│ Upgrade: https://alforgelabs.com/en/…            │
╰──────────────────────────────────────────────────╯
```

## alpha-forge pine preview `[Paid plans only]`

Preview generated Pine Script on stdout without writing to a file. **Paid plans only (Lifetime / Annual / Monthly).**

```bash
alpha-forge pine preview --strategy <ID>
```

## alpha-forge pine import

Parse a Pine Script (`.pine`) and import it as a strategy definition.

```bash
alpha-forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| Name | Kind | Description |
|------|------|-------------|
| `PINE_FILE` | argument (required, file must exist) | Path to a `.pine` file |
| `--id` | required | Strategy ID to save as |

On parse failure: `Error: failed to parse Pine Script - <details>` (writes to stderr).

## alpha-forge pine verify

Verify the Pine Script generated from a strategy via a **TradingView MCP server** (issue #523). Beyond compile checks, it can compare the Strategy Tester aggregate metrics or the per-trade list against the matching alpha-forge backtest result.

```bash
alpha-forge pine verify --strategy <ID> [--check-mode <MODE>] [--mcp-server <CMD>] [--mcp-server-flavor <tradesdontlie|vinicius>] [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | required | - | Strategy name |
| `--check-mode` | choice | `compile_only` | `compile_only` / `metrics` / `signal` / `regime` |
| `--mcp-server` | option | - | MCP server command (defaults to `tv_mcp.pine_verify.endpoint` in `forge.yaml`) |
| `--mcp-server-flavor` | choice | `tradesdontlie` | `vinicius` is the `oviniciusramosp/tradingview-mcp` fork; recommended for metrics / signal modes |
| `--mock` | flag | false | Use the mock MCP client (PoC / CI) |
| `--symbol` / `--interval` | option | - | TV symbol / interval (required for metrics / signal modes) |
| `--auto-backtest` | flag | false | Run the alpha-forge backtest internally for comparison |
| `--backtest-result` | option | - | alpha-forge backtest result for comparison (JSON path or `run_id`) |
| `--metric-tolerance` | float | `0.10` | Relative tolerance for metrics mode (10%) |
| `--match-tolerance-seconds` | int | `60` | Trade-time tolerance for signal mode (seconds) |
| `--min-match-rate` | float | `0.95` | Minimum trade match rate for signal mode |
| `--output` | file | - | Markdown report destination |

**check-mode**

| Mode | Purpose |
|------|---------|
| `compile_only` | Validate Pine Script syntax / compilation only (`tradesdontlie` is fine) |
| `metrics` | Compare TV Strategy Tester aggregate metrics (PF, win rate, total trades, etc.) against alpha-forge metrics. **`vinicius` recommended** (avoids the `data_get_strategy_results` bug in `tradesdontlie`) |
| `signal` | tradesdontlie: match TV trade list to alpha-forge `trades` by entry time and compute a match rate.<br>vinicius: returns no timestamps, so the comparison auto-switches to **count-based** (totals only, issue #580) |
| `regime` | **Not implemented (parked, issue #581)**. Pending upstream MCP server support for a time-series study tool. Selecting it fails fast with an explicit error. |

**Examples**

```bash
# Compile-only verification (fastest)
alpha-forge pine verify --strategy spy_sma_v1 --mcp-server "node /opt/tv-mcp/server.js"

# Strategy Tester metrics comparison (vinicius recommended)
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md
```

For the verification workflow walkthrough, see [Bringing Pine Scripts into TradingView](../guides/tradingview-pine-integration.md).

---
