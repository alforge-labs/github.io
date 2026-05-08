# forge strategy

Create, register, validate, and manage strategy JSON definitions. Covers scaffolding from built-in templates, local registration, viewing, JSON → DB migration, deletion, and logical consistency checks (static + dynamic).

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual numbers depend on the data and environment.

## Subcommands

| Command | Description |
|---------|-------------|
| [`forge strategy list`](#forge-strategy-list) | List all registered strategies |
| [`forge strategy create`](#forge-strategy-create) | Create a JSON file from a built-in template |
| [`forge strategy save`](#forge-strategy-save) | Register a custom strategy from a JSON file |
| [`forge strategy show`](#forge-strategy-show) | Display the definition (JSON) of a registered strategy |
| [`forge strategy migrate`](#forge-strategy-migrate) | Import existing JSON files into the DB |
| [`forge strategy delete`](#forge-strategy-delete) | Delete a registered strategy from the DB |
| [`forge strategy purge`](#forge-strategy-purge) | Purge the strategy JSON, related results, and DB entry in a single command |
| [`forge strategy validate`](#forge-strategy-validate) | Validate strategy logical consistency |
| [`forge strategy signals`](#forge-strategy-signals) | Count entry signals for a strategy |

---

## forge strategy list

List all registered strategies. When `config.strategies.use_db` is true, reads from the DB; otherwise from the file-based store.

### Synopsis

```bash
forge strategy list
```

### Arguments and options

None.

### Sample output

```text
ID                                       Name                           Version    Timeframe
------------------------------------------------------------------------------------------
spy_sma_crossover_v1                     SMA Golden/Death Cross SPY v1  1.0.0      1d
qqq_hmm_macd_ema_rsi_v1                  QQQ HMM × MACD × EMA × RSI v1  1.0.0      1d
gc_hmm_macd_ema_v1                       GC HMM × MACD × EMA v1         1.0.0      1d
```

When no strategies are registered:

```text
No registered strategies found.
```

---

## forge strategy create

Create a strategy JSON file from a built-in template. **Does not register the strategy** — edit the file and then call [`forge strategy save`](#forge-strategy-save).

### Synopsis

```bash
forge strategy create --template <NAME> --out <FILE>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--template` | required | - | Built-in template name to use as base |
| `--out` | required | - | Output JSON file path |

### Available templates

Built-in templates from `alpha-forge/src/alpha_forge/strategy/templates.py` (`_TEMPLATE_REGISTRY`):

| Name | Description |
|------|-------------|
| `sma_crossover_v1` | Short SMA × long SMA golden / death cross |
| `rsi_reversion_v1` | Mean reversion using RSI overbought / oversold |
| `macd_crossover_v1` | MACD line × signal line crossover |
| `bbands_breakout_v1` | Bollinger Bands upper-band breakout |
| `range_reversion_v1` | Range-bound mean reversion |
| `supertrend_adx_v1` | Trend-following with SuperTrend + ADX |
| `ema_adx_macd_v1` | Composite trend strategy with EMA + ADX + MACD |
| `hmm_range_pure_v1` | Range-pure with HMM regime detection |
| `hmm_anomaly_v1` | Anomaly detection via HMM regime |
| `macd_reversal_v1` | MACD-based turning-point reversal |
| `grid_bot_template` | Grid bot template |
| `connors_rsi2_v1` | **Connors RSI-2 mean reversion** (issue #475 Phase 2). Ported from Larry Connors "Short-Term Trading Strategies That Work". Long when SMA(200) up + RSI(2) < 10, exit on SMA(5) cross-up. 70-85% win rate verified on SPY/QQQ (**Note: designed for daily equities; FX 1h adoption requires SMA period re-scaling**) |
| `donchian_turtle_v1` | **Donchian Channel Breakout (Turtle)** (issue #475 Phase 2). Ported from Richard Dennis "Turtle Trading Rules". Long on 20-period high break, exit on 10-period low cross-down. 45% win rate verified on daily futures/equities (**Note: designed for daily timeframes; FX 1h adoption requires length re-scaling**) |
| `kama_rsi_v1` | **KAMA + RSI regime-adaptive** (issue #475 Phase 2). Ported from Perry Kaufman "New Trading Systems and Methods" (2013). KAMA auto-detects trend/range; RSI captures overbought/oversold. **FX 1h validation: MDD 46-76% (better than prior two) but CAGR still negative** |
| `tsi_reversion_v1` | **TSI Mean Reversion** (issue #475 Phase 2). Ported from Daniel Requejo (2024) SSRN paper "Efficacy of a Mean Reversion Trading Strategy Using TSI". Long when TSI < -25 + signal cross-up, short when TSI > +25 + cross-down. Verified on SPY/QQQ. **FX 1h validation: MDD 82-97% with negative CAGR** |
| `connors_rsi2_fx1h_v1` | **Connors RSI-2 FX 1h variant** (issue #480). SMA(200)/SMA(5) re-scaled to SMA(480)/SMA(24). FX 1h validation: trades 350+ but MDD 99-100% (still broken) |
| `donchian_turtle_fx1h_v1` | **Donchian Turtle FX 1h variant** (issue #480). length 20/10 re-scaled to 120/60. FX 1h validation: MDD 13-96% (large variance) |
| `kama_rsi_fx1h_v1` | **KAMA + RSI FX 1h variant** (issue #480). length 10/slow 30 → 48/120 re-scaled. 🎯 **EURUSD reached CAGR +0.54% / MDD 7.95%** (only positive CAGR across 4 pairs) |
| `tsi_reversion_fx1h_v1` | **TSI Reversion FX 1h variant** (issue #480). fast/slow/signal re-scaled from 13/25/13 to 48/120/48. FX 1h validation: trades 0-4 (over-filtered) |
| `kama_rsi_fx1h_v2` | **KAMA+RSI FX 1h, RSI loose** (issue #482). v1 RSI 35/65 → 45/55. FX 1h validation: trades 215+ (~35× of v1) but MDD 93-99% (over-relaxed) |
| `kama_rsi_fx1h_v3` | **KAMA+RSI FX 1h, fast KAMA** (issue #482). length 48/slow 120 → 24/60. FX 1h validation: trades 2-9 / MDD 8-36% / CAGR negative |
| `kama_rsi_mtf_v1` | **KAMA+RSI + 4h trend filter MTF variant** (issue #484). Adds a 4h EMA(50) AND filter to `kama_rsi_fx1h_v1`, allowing 1h entries only when the higher timeframe trend agrees. The engine resamples 4h series from 1h data automatically — no extra fetch required |
| `donchian_turtle_mtf_v1` | **Donchian Turtle + 4h trend filter MTF variant** (issue #484). Adds a 4h EMA(50) AND filter to `donchian_turtle_fx1h_v1`. Long-only in uptrends and short-only in downtrends to suppress trend-following drawdowns |
| `kama_rsi_mtf_atr_v1` | **KAMA + RSI + 4h trend + ATR SL MTF variant** (issue #486). Adds an ATR(14) × 2 entry-locked stop loss (`lock_on_entry=true`) to `kama_rsi_mtf_v1`. Aims to improve win rate and CAGR while keeping low trade count |
| `kama_rsi_mtf_atr_v2` | **KAMA-exit-removed variant** (issue #489). Fixes v1's dead ATR SL by removing `close < kama` from exits, simplifying to RSI (take profit) + ATR SL (hard stop). KAMA is used purely as an entry trend filter |
| `kama_rsi_mtf_trail_v1` | **True trailing-SL variant** (issue #488). Replaces v2's fixed ATR SL with `risk_management.trailing_stop_pct=1.0`, enabling vectorbt's `sl_trail=True` for a true "ratchet up only" trailing stop |

### Sample output

```text
✅ Created JSON file from template 'sma_crossover_v1': my_strategy.json
```

### Common errors

| Situation | Behavior |
|-----------|----------|
| Unknown template name | Raises `ValueError: Unknown template name: <name>. Available: ...` |

---

## forge strategy save

Register a custom strategy in the **strategy registry** from a JSON file. When `config.journal.auto_record` is true, a Journal snapshot is also recorded.

### Synopsis

```bash
forge strategy save <FILE_PATH> [--force]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `FILE_PATH` | argument (required) | - | Strategy JSON file path |
| `--force` | flag | false | Overwrite if a strategy with the same ID already exists |

### Sample output

```text
✅ Strategy 'my_strategy_v1' registered
```

When overwritten with `--force`:

```text
✅ Strategy 'my_strategy_v1' overwritten
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: file not found - <path>` | File missing | Verify the path |
| `Error: <DuplicateStrategyError>` | Same ID already registered | Use `--force`, or change `strategy_id` in the JSON |

---

## forge strategy show

Pretty-print a registered strategy JSON to stdout.

### Synopsis

```bash
forge strategy show <STRATEGY_ID>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to display |

### Sample output

```text
=== spy_sma_crossover_v1 ===
{
  "strategy_id": "spy_sma_crossover_v1",
  "name": "SMA Golden/Death Cross SPY v1",
  "version": "1.0.0",
  ...
}
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategy '<id>' not found` | Invalid ID | Verify with `forge strategy list` |

---

## forge strategy migrate

Import existing JSON files under `config.strategies.path` into the **DB (SQLite)**. Use this when switching to the `use_db: true` operation mode.

### Synopsis

```bash
forge strategy migrate [--dry-run] [--force]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--dry-run` | flag | false | Preview only, no writes |
| `--force` | flag | false | Overwrite duplicate IDs with the last file |

### Prerequisite

`config.strategies.use_db` must be **true**. In `forge.yaml` (`FORGE_CONFIG`):

```yaml
strategies:
  use_db: true
```

### Sample output

```text
⚠️  Duplicate strategy_id detected:
  spy_sma_crossover_v1:
    - spy_sma_crossover_v1.json
    - spy_sma_crossover_v1_optimized.json

Re-run with --force to overwrite with the last file.
```

With `--force --dry-run`:

```text
[dry-run] 12 strategies would be registered (no writes performed)
```

Normal run:

```text
  Skip (broken_v1.json): parse error - <details>
  Skip (legacy_v1): duplicate, not registered

✅ Done: 10 registered, 2 skipped
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategies.use_db is false. Set use_db: true in forge.yaml` | DB disabled | Update `forge.yaml` and retry |
| `No JSON files found for migration.` | `strategies.path` is empty | Verify path / file placement |

---

## forge strategy delete

Delete a registered strategy from the DB / registry. With `--with-results`, also deletes related files (optimized strategy, backtest results, optimization results). Journal files are always kept.

### Synopsis

```bash
forge strategy delete <STRATEGY_ID> [--force] [--with-results]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to delete |
| `--force` | flag | false | Skip confirmation prompt |
| `--with-results` | flag | false | Also delete related files (`<id>_optimized.json`, `<id>_report.json`, `optimize_<id>_*.json`) |

### Files removed by `--with-results`

- `strategies.path / <id>_optimized.json`
- `report.output_path / <id>_report.json`
- `report.output_path / optimize_<id>_*.json` (all matching files)

`<id>.journal.json` is **kept**.

### Automatic cleanup of recommendations.yaml (issue #454)

When a strategy is deleted, any matching entry in `data/explorer/recommendations.yaml` is automatically removed (ranks are renumbered). Deleting an auto-relax recommendation will not leave a stale entry that causes `forge explore run` to fail with `StrategyNotFoundError`.

In addition, `forge explore recommend show` performs a DB existence check at display time and auto-prunes any stale entries left over from previous runs.

### Sample output

```text
To delete: my_strategy_v1

  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (kept)

Continue? [y/N]: y
✅ Strategy 'my_strategy_v1' deleted
Files deleted: 3
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategy '<id>' not found` | Invalid ID | Verify with `forge strategy list` |
| `Cancelled` | Declined the prompt | Use `--force` or re-confirm |

---

## forge strategy purge

Purge the strategy JSON, related files (`_optimized.json`, `_report.json`, `optimize_<id>_*.json`), and DB entry **in a single command**. Replaces the previous three-step `rm <strategy>.json && rm <strategy>_report.json && forge strategy delete <id> --force` workflow. Journal files (`<id>.journal.json`) are preserved.

### Synopsis

```bash
forge strategy purge <STRATEGY_ID> [--dry-run]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to purge completely |
| `--dry-run` | flag | false | Only list the files that would be deleted; do not actually delete them |

### Sample output

`--dry-run`:

```text
[dry-run] Targets:
  - data/strategies/my_strategy_v1.json
  - data/strategies/my_strategy_v1_optimized.json
  - data/results/my_strategy_v1_report.json
  - data/results/optimize_my_strategy_v1_20260415_103021.json
  - DB entry: my_strategy_v1
  Note: data/journal/my_strategy_v1.journal.json is preserved
```

Normal run:

```text
Targets: my_strategy_v1

  ✓ data/strategies/my_strategy_v1.json
  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (preserved)

Continue? [y/N]: y
✅ Strategy 'my_strategy_v1' has been purged
```

Missing files are reported as warnings only and do not abort the command.

### Differences vs. `delete --with-results`

| Aspect | `delete --with-results` | `purge` |
|--------|-------------------------|---------|
| Strategy JSON | Kept | Deleted |
| `<id>_optimized.json` | Deleted | Deleted |
| `<id>_report.json` | Deleted | Deleted |
| `optimize_<id>_*.json` | Deleted | Deleted |
| Journal | Preserved | Preserved |
| DB entry | Deleted | Deleted |

Use `purge` to wipe a strategy completely; use `delete --with-results` when you want to keep the strategy JSON but clean up related result files.

---

## forge strategy validate

Run **logical consistency checks** on a strategy. With `--symbol`, also runs **dynamic checks** (signal counts and condition correlation on real data). Pass a `.json` path as `STRATEGY_ID` to validate an unregistered file directly.

### Synopsis

```bash
forge strategy validate <STRATEGY_ID|FILE.json> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID, or a `.json` file path |
| `--symbol` | option | - | Symbol for dynamic checks (enables dynamic phase) |
| `--period` | option | `1y` | Data period |
| `--min-signals` | int | `30` | Min signal count threshold (warning if below) |
| `--corr-threshold` | float | `0.9` | Correlation warning threshold |
| `--json` | flag | false | Output as JSON |

### Static checks

What `StrategyValidator` checks when `--symbol` is not given (implementation-based):

- Required fields: `strategy_id` / `name` / `version` / `timeframe`
- `indicators[]`: ID uniqueness, reference resolution
- `entry_conditions` / `exit_conditions`: referenced IDs exist
- Condition expressions (`left` / `op` / `right`): syntax and type integrity
- `risk_management`: value ranges (percentages, leverage)
- `regime_config.indicator_id` resolves to a real indicator
- `optimizer_config.param_ranges` keys map to either `parameters` or an indicator `params`

### Dynamic checks (with `--symbol`)

Loads real data and runs a lightweight backtest to gather signal statistics:

- Entry signal count over the period (warns if below `min_signals`)
- True-day count and percentage of each leaf condition
- Pairwise correlation of conditions (warns above `corr_threshold`)

### Sample output (text)

```text
Strategy: spy_sma_crossover_v1  [OK]

[DYNAMIC CHECKS]
  Symbol: SPY  Period: 1y  Total days: 252
  Entry signals: 87 days
  Condition True days:
    sma_fast > sma_slow: 142 days (56.3%)
    rsi < 70: 198 days (78.6%)

✓ No issues detected
```

When errors are detected:

```text
Strategy: my_v1  [NG]

[ERRORS]
  ✗ [E_INDICATOR_REF] Reference 'sma_fast' in condition does not exist in indicators
    → Add { "id": "sma_fast", "type": "SMA", ... } to the indicators array

[WARNINGS]
  ⚠ [W_LOW_SIGNALS] Too few entry signals: 12 days (threshold 30)
    → Loosen the conditions or extend the data period

  [CORRELATION]
    ⚠ rsi < 70 × close > sma_fast: 0.94
      → Drop one of the highly correlated conditions, or replace with an independent one
```

### Sample output (`--json`)

```json
{
  "strategy_id": "my_v1",
  "ok": false,
  "static_errors": [
    {"code": "E_INDICATOR_REF", "message": "...", "suggestion": "..."}
  ],
  "static_warnings": [],
  "signal_stats": {
    "symbol": "SPY",
    "period": "1y",
    "total_days": 252,
    "entry_signal_days": 12,
    ...
  },
  "dynamic_warnings": [...],
  "correlations": [...]
}
```

### Exit codes

- `result.ok = true` → `0`
- `result.ok = false` (errors detected) → `1`

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: file not found - <path>` | `.json` path not found | Verify the path |

---

## forge strategy signals

Count entry signals, estimated trades, and WFT window coverage without running optimization or WFT (#321).

```bash
forge strategy signals <SYMBOL> --strategy <NAME> [--period <PERIOD>] [--json]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--strategy` | Strategy name (required) | — |
| `--period` | Historical data period | `5y` |
| `--json` | Output as JSON | off |

#### Text output example

```
📊 Signal Summary: my_rsi_v1 / SPY (5y)
  Long signals:      45 days
  Estimated trades:  38
  Avg trades/year:   7.6
  WFT coverage:      low (5-10 trades/window)
```

#### JSON output example

```json
{
  "strategy_id": "my_rsi_v1",
  "symbol": "SPY",
  "period": "5y",
  "total_days": 1260,
  "long_signals": 45,
  "short_signals": 0,
  "estimated_trades": 38,
  "avg_per_year": 7.6,
  "wft_window_coverage": "low (5-10 trades/window)"
}
```

| Field | Description |
|-------|-------------|
| `long_signals` | Number of days with long entry signal |
| `estimated_trades` | Estimated trades (counted as signal blocks) |
| `avg_per_year` | Average trades per year |
| `wft_window_coverage` | Coverage assessment based on trades per WFT window |

---

## Common behavior

- **Storage**: When `config.strategies.use_db` is true, uses `SQLiteStrategyRepository`; otherwise file-based. Switch via `forge.yaml`.
- **Locations**: `config.strategies.path` (strategy JSON), `config.report.output_path` (backtest / optimization results), `config.journal.journal_path` (journal).
- **Journal integration**: When `config.journal.auto_record` is true, `save` automatically records a journal snapshot.
- **`FORGE_CONFIG`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable.
- **Exit codes**: `0` on success; `validate` returns `1` when errors are detected; argument errors return Click's `2`; runtime errors typically `1`.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/strategy.py` and `_TEMPLATE_REGISTRY` in `alpha-forge/src/alpha_forge/strategy/templates.py`. This page must be kept in sync when CLI arguments or templates change. -->
