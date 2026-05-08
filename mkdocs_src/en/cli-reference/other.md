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
| [idea](#idea) | `add` `list` `show` `status` `link` `tag` `note` `search` | Track investment ideas |
| [altdata](#altdata) | `fetch` `list` `info` | Manage alternative data (sentiment, etc.) |
| [pairs](#pairs) | `scan` `scan-all` `build` | Pairs trading (cointegration) |
| [ml](#ml) | `dataset build` `dataset feature-sets` `train` `models` | ML dataset & model training (issue #512 Phase 1-2) |

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
| `result` | Show details of the latest trial saved in the exploration DB |
| `health` | Detect consecutive failures and scaffold fixation from recent trials (quality gate for unattended runs) |
| `recommend` | Write next-exploration candidates to `recommendations.yaml` |
| `coverage` | Update or view parameter coverage YAML |

### forge explore run

Runs validation → auto data fetch → backtest → optimize → walk-forward test (WFT) → coverage update → DB registration in a single command. Returns exit code 1 on failure (except `--dry-run` / `--pre-check`).  
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
| `--json` | Output result as JSON to stdout (**deprecated**: use `forge explore result show <id> --json` instead) | off |
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
| `skip_reason` | Reason for skip/failure: `validation_failed` / `no_signals` / `pre_filter_failed` / `wft_failed` / `pre_check_only` / `dry_run` / `null` |
| `cleanup_done` | `true` when strategy JSON and result JSON were automatically removed on failure |
| `entry_signals` | Number of days with long entry signal (set during `--pre-check`; may be `null` for backward compatibility) |

### forge explore result show

Display the latest exploration result for a strategy from the DB. Use this to inspect failure details after `forge explore run` exits with code 1.

```bash
forge explore result show <STRATEGY_ID> [--goal <GOAL>] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--goal` | Filter by goal name | — |
| `--json` | Output result as JSON to stdout | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

#### Examples

```bash
# Display latest result in human-readable format
forge explore result show gc_bb_hmm_rsi_v1

# Filter by goal and output as JSON (includes wft_diagnostics and more)
forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

Typical failure investigation flow after `forge explore run` returns exit code 1:

```bash
FORGE_CONFIG=forge.yaml forge explore run GC=F --strategy gc_bb_hmm_rsi_v1 --goal commodities
# exit code 1 → retrieve details from DB
FORGE_CONFIG=forge.yaml forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

The `--json` output includes `wft_diagnostics`, `pre_filter_diagnostics`, and `opt_metrics` fields.

#### pre_filter_diagnostics structure (issue #409)

When `skip_reason: "pre_filter_failed"`, the `pre_filter_diagnostics` field contains a
structured `{value, threshold, passed, gap}` object for each criterion so autonomous
exploration agents can decide programmatically which criterion failed and by how much.

```json
{
  "pre_filter_diagnostics": {
    "sharpe_ratio":      {"value": 0.716, "threshold": 1.0,  "passed": false, "gap": -0.284},
    "max_drawdown":      {"value": 1.66,  "threshold": 25.0, "passed": true,  "gap": 23.34},
    "trades":            {"value": 16,    "threshold": 30,   "passed": false, "gap": -14},
    "monthly_volume_usd":{"value": null,  "threshold": 0.0,  "passed": null,  "note": "not evaluated"},
    "verdict": "failed",
    "failed_criteria": ["sharpe_ratio", "trades"]
  }
}
```

| Field | Description |
|-------|-------------|
| `value` | Observed metric from the backtest (`monthly_volume_usd` is currently not computed, so `null`) |
| `threshold` | Threshold resolved from the `pre_filter` section of goals.yaml |
| `passed` | Whether the criterion is met (`null` means not evaluated) |
| `gap` | "value − threshold" (for `max_drawdown` it is "threshold − value"). Negative = shortfall, positive = headroom |
| `verdict` | `"passed"` if all criteria pass, otherwise `"failed"` |
| `failed_criteria` | Names of failed criteria in stable order: `sharpe_ratio` → `max_drawdown` → `trades` |

### forge explore health

Aggregate the most recent N trials and detect consecutive failures or scaffold fixation (issue #408). Designed to be invoked at the start of every iteration of the unattended `/explore-strategies --runs 0` loop, so structural failures (scaffold bugs, goals.yaml drift) can be caught early instead of burning runs forever.

```bash
forge explore health --goal <GOAL> [--last N] [--strict] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--goal` | Goal name to aggregate | `default` |
| `--last` | Number of recent trials to analyze | `5` |
| `--strict` | Exit with code `1` when `escalation: true` (used to break the unattended loop). Returns `0` when only `warning: true` (issue #467) | off |
| `--json` | Output result as JSON to stdout | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

#### Output JSON example

```json
{
  "goal": "default",
  "last_n": 5,
  "pass_rate": 0.0,
  "failure_breakdown": {"pre_filter_failed": 3, "no_signals": 2},
  "scaffold_transformation_rate": 1.0,
  "most_common_combo": "ATR+BB+RSI",
  "same_combo_streak": 5,
  "escalation": true,
  "warning": false,
  "escalation_type": "scaffold_degradation",
  "recommended_actions": [
    "Pass rate over the last 5 trials is 0%. Check pre_filter thresholds, target symbols, and candidate indicators in goals.yaml.",
    "All recent trials had their indicators transformed by the scaffold. Inspect the indicator filters in `alpha_forge.strategy.scaffold` (see alpha-forge issues #399 and #400)."
  ]
}
```

| Field | Description |
|-------|-------------|
| `last_n` | Actual number of trials analyzed (capped by DB row count when fewer than `--last` exist) |
| `pass_rate` | Ratio of trials with `passed=True` (0.0–1.0) |
| `failure_breakdown` | Failure counts grouped by `skip_reason` |
| `scaffold_transformation_rate` | Ratio of trials whose scaffold transformed the requested indicators (excluding the auto-added ATR-only case) |
| `same_combo_streak` | How many of the most recent trials share the same `indicator_combo` |
| `escalation` | `true` when `pass_rate==0` AND scaffold-related root cause (`scaffold_transformation_rate>=0.5` or mid-range). Hard-stop signal (issue #467) |
| `warning` | `true` when `pass_rate==0` AND `same_combo_streak==last_n` AND `scaffold_transformation_rate<=0.1` (only `agent_selection_bias`). Loop continues (exit 0) and the agent is expected to switch to a different indicator combo on the next run (issue #467) |
| `escalation_type` | Cause classification (issues #436 / #467): `"scaffold_degradation"` (escalation) / `"agent_selection_bias"` (warning) / `null` |
| `recommended_actions` | Human-facing remediation hints derived from the detected pattern |

#### Escalation rules

If the DB contains fewer than `--last` rows for the goal, the report stays observational (`escalation: false` and `warning: false` are both forced) and never blocks the loop. Once enough history accumulates, the report takes one of the following shapes:

- 0% pass rate and scaffold transformation rate `>= 50%` → `escalation: true` / `escalation_type: "scaffold_degradation"` (hard stop)
- 0% pass rate and all of the most recent N trials share the same `indicator_combo`:
  - scaffold transformation rate `<= 10%` → `warning: true` / `escalation: false` / `escalation_type: "agent_selection_bias"` (loop continues; downgraded to warning by issue #467 because the agent can resolve it by picking a different combo)
  - mid-range (10% < rate < 50%) → conservatively classified as `escalation: true` / `"scaffold_degradation"`

#### Use inside the unattended skill

```bash
# Run at the start of every iteration of /explore-strategies
FORGE_CONFIG=forge.yaml forge explore health \
  --goal default --last 5 --strict --json
# exit code 1 → surface recommended_actions to a human and break the loop
```

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

## ml

Machine-learning dataset and model training commands (issue #512 Phase 1-2). Trained joblib models can be referenced from the existing `ML_SIGNAL` indicator via `model_path` for inference.

### forge ml dataset build

Build a feature+forward-return-label parquet dataset from stored OHLCV.

```bash
forge ml dataset build EURUSD=X --feature-set default_v1 --label binary:24:0.005 --interval 1h
forge ml dataset build EURUSD=X --label ternary:24:0.005
forge ml dataset build EURUSD=X --label regression:5
forge ml dataset build EURUSD=X --label binary:24:0.005 --json
```

**Key options**

| Option | Description | Default |
|--------|-------------|---------|
| `--feature-set` | Built-in feature set name (see `forge ml dataset feature-sets`) | `default_v1` |
| `--label` | Label spec string (required) | — |
| `--interval` | Bar interval used to load OHLCV | `1d` |
| `--out` | Output parquet path | `<storage_path>/../ml_datasets/<symbol>_<feature_set>_<label_type>_<interval>.parquet` |
| `--keep-nan` | Keep rows containing NaN | False (drops them) |
| `--json` | Print summary as JSON | False |

**Label spec strings**

- `binary:<forward_n>:<threshold_pct>` — 1 if forward_return > threshold, else 0
- `ternary:<forward_n>:<threshold_pct>` — +1 above threshold, −1 below −threshold, 0 in between
- `regression:<forward_n>` — raw forward return as the label

The parquet file embeds symbol / interval / feature columns / label config as metadata so Phase 2 training can reproduce the exact pipeline from the file alone.

### forge ml dataset feature-sets

List available built-in feature sets.

```bash
forge ml dataset feature-sets
```

### forge ml train

Train a model from a Phase 1 dataset parquet and save joblib + metrics.json (issue #512 Phase 2).

```bash
forge ml train <DATASET.parquet> [OPTIONS]
```

**Key options**

| Option | Description | Default |
|--------|-------------|---------|
| `--model` | Model type (see `forge ml models`) | `logistic_regression` |
| `--test-ratio` | Tail fraction used as the test split (time-series order preserved) | `0.2` |
| `--random-state` | Random seed | `42` |
| `--params` | Extra model parameters as a JSON string | — |
| `--out` | Output joblib path | `<storage_path>/../ml_models/<dataset_stem>_<model>.joblib` |
| `--json` | Print summary as JSON | False |

**Supported models**

| Model | Task | Notes |
|-------|------|-------|
| `logistic_regression` | Classification | StandardScaler + LogisticRegression pipeline |
| `random_forest_classifier` | Classification | sklearn |
| `gradient_boosting_classifier` | Classification | sklearn |
| `xgboost_classifier` | Classification | optional (`uv add xgboost`) |
| `linear_regression` | Regression | StandardScaler + LinearRegression |
| `random_forest_regressor` | Regression | sklearn |
| `gradient_boosting_regressor` | Regression | sklearn |
| `xgboost_regressor` | Regression | optional (`uv add xgboost`) |

**Evaluation metrics**

- Classification: accuracy / precision / recall / f1 / auc (binary only). Weighted averages.
- Regression: mse / mae / rmse / r2

**Storage format**

- Model: joblib (sklearn-compatible API; `predict` / `predict_proba` callable from `ML_SIGNAL` indicator as is)
- Metrics: `<model>.joblib.metrics.json` (model_type / task / feature_columns / n_train / n_test / train_metrics / test_metrics / config / trained_at)

### forge ml models

List available model types (classification + regression).

```bash
forge ml models
```

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

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,docs}.py`. This page must be kept in sync when CLI arguments or commands change. -->
