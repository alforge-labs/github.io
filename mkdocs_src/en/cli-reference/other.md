# Other Commands

Utility and management commands not covered by the [core groups](index.md), bundled on a single page. Covers 10 groups and ~29 subcommands. Full parameter lists are also available via `forge <group> <subcommand> --help`.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual values depend on data and environment.

## Group quick reference

| Group | Subcommands | Purpose |
|-------|-------------|---------|
| [license](#license) | `activate` `deactivate` `status` | Activate, deactivate, check license |
| [login & logout](#login-and-logout) | `login` `logout` | Whop account auth |
| [init](#init) | (single command) | Initialize working directory |
| [pine](#pine) | `generate` `preview` `import` | Generate / import TradingView Pine Script |
| [indicator](#indicator) | `list` `show` | Browse supported technical indicators |
| [idea](#idea) | `add` `list` `show` `status` `link` `tag` `note` `search` `dashboard` | Track investment ideas |
| [altdata](#altdata) | `fetch` `list` `info` | Manage alternative data (sentiment, etc.) |
| [pairs](#pairs) | `scan` `scan-all` `build` | Pairs trading (cointegration) |
| [dashboard](#dashboard) | (single command) | Launch the web dashboard |
| [docs](#docs) | `list` `show` | Browse bundled documentation |

---

## license

Activate, deactivate, and check license status. For installation steps, see [Getting Started](../getting-started.md).

### forge license activate

Activate a license key.

```bash
forge license activate <KEY>
```

| Name | Kind | Description |
|------|------|-------------|
| `KEY` | argument (required) | License key (from your purchase email) |

On success, activation data is cached at `~/.forge/license.json`.

### forge license deactivate

Deactivate the license on this machine.

```bash
forge license deactivate
```

Use this when migrating to another machine.

### forge license status

Show current license status.

```bash
forge license status
```

Sample output:

```text
License key    : 1A2B3C4D...
Last validated : 2026-04-12 09:30 UTC (3 days ago)
Fingerprint    : match
Cache          : valid (within 3 days)
```

When unregistered: `[AlphaForge] License not registered`.

---

## login and logout

Authenticate with your Whop account.

### forge login

```bash
forge login
```

Opens a browser and runs the Whop authentication flow. No arguments or options.

### forge logout

```bash
forge logout
```

Logs out and removes local credentials. No arguments or options.

---

## init

Initialize the working directory: creates `forge.yaml`, data directories, documentation, and AI assistant integration files.

### Synopsis

```bash
forge init [OPTIONS]
```

### Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--force` / `-f` | flag | false | Overwrite existing files without confirmation |
| `--no-claude` | flag | false | Skip AI assistant integration files |

### Directories created

- `data/historical/`, `data/strategies/`, `data/results/`, `data/journal/`, `data/ideas/`, `output/pinescript/`

### AI integration files installed

| Destination | Contents |
|-------------|----------|
| `.claude/skills/` | Claude Code skills (forge-backtest, forge-analyze, forge-data) |
| `.claude/commands/` | Claude Code slash commands (explore-strategies, grid-tune, and 4 more) |
| `.agents/skills/` | Codex skills (explore-strategies, grid-tune, and 4 more) |

### Sample output

```text
AlphaForge: Initializing working directory...

[1/4] Config file
  ✓ forge.yaml

[2/4] Data directories
  ✓ data/historical/
  ✓ data/strategies/
  - exists: data/results/
  ...

[3/4] Documentation files
  ✓ docs/quick-start.en.md
  ✓ docs/user-guide.en.md
  ...

[4/4] AI assistant integration files
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

Done: 26 created, 0 skipped

Next steps:
  1. Edit forge.yaml to customize your settings
  2. Add the following to ~/.zshrc / ~/.bashrc:
     export FORGE_CONFIG=/path/to/forge.yaml
```

---

## explore {#explore}

Manage exploration pipeline state and run the full pipeline in one command. These commands are used internally by the AI agent skill `/explore-strategies`.

| Subcommand | Description |
|-----------|-------------|
| `run` | Run backtest → optimize → WFT → DB registration end-to-end (**main command**) |
| `index` | Build `exploration_index.yaml` from `explored_log.md` |
| `import` | Bulk-import a Markdown log into the exploration DB |
| `log` | Manually record an exploration trial to the DB |
| `status` | Show coverage map against a goal |
| `recommend` | Write next-exploration candidates to `recommendations.yaml` |
| `coverage` | Update or view parameter coverage YAML |

### forge explore run

Runs backtest → optimize → walk-forward test (WFT) → coverage update → DB registration in a single command.  
Called internally by the `/explore-strategies` agent skill.

```bash
forge explore run <SYMBOL> --strategy <NAME> --goal <GOAL> [--no-cleanup] [--dry-run] [--pre-check] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--strategy` | Strategy name (required) | — |
| `--goal` | Goal name — applies `pre_filter` / `target_metrics` from `goals.yaml` | `default` |
| `--no-cleanup` | Skip file / DB cleanup on failure (for debugging) | off |
| `--dry-run` | Print planned steps and exit without running | off |
| `--pre-check` | Run backtest only (default params), skip optimization and WFT (#321) | off |
| `--json` | Output result as JSON to stdout | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

#### Using `--pre-check`

Use for rapid screening during strategy design. Optimization and WFT are not executed.

```bash
forge explore run SPY --strategy my_rsi_v1 --pre-check
forge explore run SPY --strategy my_rsi_v1 --pre-check --json
```

Sample text output with `--pre-check`:

```
📊 Pre-check (backtest, default params)
  Sharpe:     0.821
  MaxDD:      19.9%
  Trades:     24 ⚠️ low (may be insufficient for WFT windows)
  Signals:    31
  Pre-filter: FAIL ❌

→ Optimization and WFT are skipped.
```

#### Output JSON example

```json
{
  "symbol": "SPY",
  "strategy_id": "spy_hmm_rsi_v3",
  "passed": false,
  "backtest": {
    "sharpe": 0.82,
    "max_dd": 19.9,
    "trades": 42
  },
  "pre_filter_pass": true,
  "wft_avg_sharpe": 1.12,
  "wft_target": 1.5,
  "skip_reason": "wft_failed",
  "cleanup_done": true,
  "entry_signals": 31
}
```

| Field | Description |
|-------|-------------|
| `passed` | `true` when WFT meets `target_metrics` |
| `skip_reason` | Reason for skip/failure: `no_signals` / `pre_filter_failed` / `wft_failed` / `pre_check_only` / `dry_run` / `null` |
| `cleanup_done` | `true` when strategy JSON and result JSON were automatically removed on failure |
| `entry_signals` | Number of days with long entry signal (set during `--pre-check`; may be `null` for backward compatibility) |

---

## pine

Convert between strategy JSON and TradingView Pine Script v6.

!!! warning "[Premium Only] Pine Script export"
    `forge pine generate` and `forge pine preview` are **available on paid plans only (Lifetime / Annual / Monthly)**. Running them on the Free plan displays a red Panel with a purchase URL ([https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)) and exits with code `1` — no file is written and no preview is printed. `forge pine import` (the import path) is unaffected and remains available on Free. See the [Freemium limits guide](../guides/freemium-limits.md) for details.

### forge pine generate `[Premium Only]`

Generate Pine Script from a strategy definition and write it to `config.pinescript.output_path / <strategy_id>.pine`. **Paid plans only.**

```bash
forge pine generate --strategy <ID> [--with-training-data]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | required | - | Strategy name |
| `--with-training-data` | flag | false | Embed trained HMM parameters into Pine Script if HMM indicator exists (auto-fetches data) |

Sample output (paid plan):

```text
✅ Pine Script saved: output/pinescript/spy_sma_v1.pine
```

Sample output (Free plan — hard block):

```text
╭─────────── 🔒 Premium-only feature ────────────╮
│ Pine Script export is available for paid plans │
│ (Lifetime / Annual / Monthly) only.            │
│ Upgrade your license to seamlessly run on …    │
│ Upgrade: https://alforgelabs.com/en/…          │
╰────────────────────────────────────────────────╯
```

### forge pine preview `[Premium Only]`

Preview generated Pine Script on stdout without writing to a file. **Paid plans only.**

```bash
forge pine preview --strategy <ID>
```

### forge pine import

Parse a Pine Script (`.pine`) and import it as a strategy definition.

```bash
forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| Name | Kind | Description |
|------|------|-------------|
| `PINE_FILE` | argument (required, file must exist) | Path to a `.pine` file |
| `--id` | required | Strategy ID to save as |

On parse failure: `Error: failed to parse Pine Script - <details>` (writes to stderr).

---

## indicator

Browse the catalog of 30+ technical indicators supported by `alpha-forge`.

### forge indicator list

List supported indicators. With `FILTER_NAME`, filter by case-insensitive substring.

```bash
forge indicator list [FILTER_NAME] [--detail]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `FILTER_NAME` | argument (optional) | - | Filter substring |
| `--detail` | flag | false | Show parameter names, defaults, and descriptions |

Sample output:

```text
Supported indicators (35):

  [Trend]         SMA  EMA  WMA  HMA  TEMA  MACD  ADX  SUPERTREND
  [Momentum]      RSI  STOCH  CCI  WILLR  ROC
  [Volatility]    ATR  BBANDS  KELTNER
  [Volume]        OBV  VWAP  CMF
  [Regime]        HMM
  [Other]         EXPR  ALTDATA

Details: forge indicator show <TYPE>
```

### forge indicator show

Show detailed information for a specific indicator (description, parameters, output, example).

```bash
forge indicator show <INDICATOR_TYPE>
```

| Name | Kind | Description |
|------|------|-------------|
| `INDICATOR_TYPE` | argument (required) | Indicator name (case-insensitive) |

Sample output:

```text
SMA — Simple Moving Average

Category: Trend

Parameters:
  Name                 Type     Default                Description
  length              int      14                    Period
  source              str      close                 Source column

Output: scalar time series

Example (JSON):
  {"id": "sma_20", "type": "SMA", "params": {"length": 20}, "source": "close"}
```

Unknown indicator names print `Error: '<TYPE>' is not a recognized indicator.` and exit with code `1`.

---

## idea

Record, tag, and search investment ideas. Stored as `ideas.json` under `config.ideas.ideas_path`.

### forge idea add

Add a new idea.

```bash
forge idea add <TITLE> --type <new_strategy|improvement> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `TITLE` | argument (required) | - | Idea title |
| `--type` | required (choice) | - | `new_strategy` / `improvement` |
| `--desc` | option | `""` | Description |
| `--tag` | repeatable | - | Tags |

Output: `Added: [<idea_id>] <title>`.

### forge idea list

List ideas.

```bash
forge idea list [--status <STATUS>] [--tag <TAG>] [--strategy <ID>]
```

| Name | Kind | Description |
|------|------|-------------|
| `--status` | choice | `backlog` / `in_progress` / `tested` / `archived` |
| `--tag` | repeatable | Tag AND filter |
| `--strategy` | option | Strategy ID filter |

### forge idea show

Show idea details.

```bash
forge idea show <IDEA_ID>
```

If not found: `Not found: <id>` and exit code `1`.

### forge idea status

Update an idea's status.

```bash
forge idea status <IDEA_ID> <backlog|in_progress|tested|archived>
```

Output: `Status updated: <title> → <status>`.

### forge idea link

Link a strategy or run to an idea.

```bash
forge idea link <IDEA_ID> --strategy <ID> [--run <RUN_ID>] [--note <TEXT>]
```

| Name | Kind | Description |
|------|------|-------------|
| `--strategy` | required | Target strategy ID |
| `--run` | option | Target `run_id` (when given, links to a specific run) |
| `--note` | option | Note for the link |

### forge idea tag

Add or remove tags. `--add` and `--remove` can be combined; one of them is required.

```bash
forge idea tag <IDEA_ID> [--add <TAG>] [--remove <TAG>]
```

### forge idea note

Append a note to an idea.

```bash
forge idea note <IDEA_ID> <TEXT>
```

### forge idea search

Full-text search ideas.

```bash
forge idea search [QUERY] [--status <STATUS>] [--tag <TAG>]
```

| Name | Kind | Description |
|------|------|-------------|
| `QUERY` | argument (optional) | Search query (matches title / description / notes) |
| `--status` | choice | Status filter |
| `--tag` | repeatable | Tag filter |

### forge idea dashboard

Launch the web dashboard (equivalent to `forge dashboard`).

```bash
forge idea dashboard [--port 8000] [--no-open]
```

See [`forge dashboard`](#dashboard) for details.

---

## altdata

Fetch and manage alternative data (sentiment, macro indicators, etc.). Stored under `config.data.alt_storage_path` and referenceable from strategy JSON via the `ALTDATA` indicator type.

### forge altdata fetch

```bash
forge altdata fetch <SOURCE_KEY> --start <YYYY-MM-DD> --end <YYYY-MM-DD>
```

| Name | Kind | Description |
|------|------|-------------|
| `SOURCE_KEY` | argument (required) | Provider-specific data source key |
| `--start` | required | Fetch start date |
| `--end` | required | Fetch end date |

Output: `✅ <SOURCE_KEY>: saved <N> rows`. Unregistered providers raise `ClickException`.

### forge altdata list

```bash
forge altdata list
```

Sample output:

```text
Stored alternative data count: 2
SOURCE_KEY                INTERVAL   ROWS         START           END
fear_greed_index          1d          1525   2020-01-01   2025-12-31
vix_termstructure         1d          1530   2020-01-01   2025-12-31
```

### forge altdata info

```bash
forge altdata info <SOURCE_KEY>
```

Shows source key, interval, row count, start / end dates, columns, file path, and file size. If data is missing, raises `ClickException`.

---

## pairs

Cointegration tests and spread series for pair trading. Uses the Engle–Granger test from `statsmodels`.

### forge pairs scan

Run a cointegration test on two symbols.

```bash
forge pairs scan <SYM_A> <SYM_B> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYM_A`, `SYM_B` | arguments (required) | - | Two symbols to test |
| `--method` | choice | `engle_granger` | Cointegration test method |
| `--pvalue` | float | `0.05` | p-value threshold for cointegration |
| `--interval` | option | `1d` | Timeframe |

Sample output:

```text
✅ Cointegrated
  Pair       : SPY / QQQ
  p_value    : 0.012345
  Threshold  : 0.05
  Test stat  : -3.5421
  Critical 5%: -2.8623
```

### forge pairs scan-all

Scan all pairs in a watchlist (top 20 displayed).

```bash
forge pairs scan-all --symbols-file <FILE> [--pvalue 0.05] [--interval 1d]
```

| Name | Kind | Description |
|------|------|-------------|
| `--symbols-file` | required (file) | Symbol list (one per line; `#` comments allowed) |
| `--pvalue` | float | p-value threshold (default 0.05) |

### forge pairs build

Compute spread series and save to the `alt_data` store (referenceable from strategy JSON via `ALTDATA`).

```bash
forge pairs build --sym-a <SYM> --sym-b <SYM> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--sym-a` | required | - | Symbol A (dependent variable) |
| `--sym-b` | required | - | Symbol B (independent variable) |
| `--interval` | option | `1d` | Timeframe |
| `--log-prices` / `--no-log-prices` | flag | `--log-prices` | Use log prices for the spread |
| `--output-id` | option | `<A>_<B>_spread` | `source_key` to save |

Sample output:

```text
Estimating hedge ratio... (SPY / QQQ)
  Hedge ratio: 0.823145
  OU half-life: 12.4 days
  Data points: 1530

✅ Spread saved: source_key='SPY_QQQ_spread'
   How to reference in strategy JSON:
   {"id": "spread", "type": "ALTDATA", "params": {"source_key": "SPY_QQQ_spread", "column": "spread"}}
```

When there is no mean reversion, the half-life is shown as `N/A (no mean reversion)`.

---

## dashboard

Start the web dashboard (FastAPI + uvicorn). Browse equity curves, drawdowns, Monte Carlo, WFO results, and more in the browser.

### Synopsis

```bash
forge dashboard [--port 8000] [--host 127.0.0.1] [--no-open]
```

### Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--port` | int | `8000` | Bind port |
| `--host` | option | `127.0.0.1` | Bind host |
| `--no-open` | flag | false | Do not open browser automatically |

Sample output:

```text
Starting dashboard: http://127.0.0.1:8000  (Ctrl+C to stop)
```

If `fastapi` / `uvicorn` are not installed, an instruction message is printed and the command exits (they are bundled when running `uv sync` after `forge.yaml` setup).

---

## docs

Browse the documentation, skills, and command references bundled with `alpha-forge`.

### forge docs list

```bash
forge docs list
```

List available bundled documents. `✓` / `✗` indicates whether each file exists.

### forge docs show

```bash
forge docs show <NAME>
```

| Name | Kind | Description |
|------|------|-------------|
| `NAME` | argument (required) | Document name (find with `forge docs list`) |

Print the document content to stdout. Unknown names display the available list and exit with code `1`.

---

## Common behavior

- **`FORGE_CONFIG`**: All paths (strategies, data, journal, ideas, alt_data, output) are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: success `0`; `click.UsageError` / argument violations `2`; `click.ClickException` `1`; per-command `SystemExit(1)` for specific errors
- **i18n**: All commands have both Japanese and English `--help` text (via `alpha_forge.i18n.L`)

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,dashboard,docs}.py`. This page must be kept in sync when CLI arguments or commands change. -->
