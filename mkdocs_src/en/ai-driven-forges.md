# AI Agent Integration

Combining Claude Code, Codex, and similar AI coding agents with AlphaForge as the "brain" lets you autonomously drive **idea → implementation → backtest → optimization → validation → live tuning**. This page covers recommended agents, slash-command automation, three exploration scenarios, loop-mode considerations, and an end-to-end example.

!!! info "Prerequisite"
    The commands and flows shown here assume the `alpha-trade` monorepo (a combination of `alpha-forge` and `alpha-strategies`). **Binary** users should substitute internal commands like `op run --env-file=...` with `forge` directly.

## Why AI agents × AlphaForge

AlphaForge is designed so that **all configuration, strategies, and execution flow through JSON / YAML / CLI**. This means:

- AI agents can **generate, edit, and validate** strategy JSON
- Backtest and optimization results return as **structured data** an agent can analyze
- Slash commands let you replay the **same workflow** idempotently
- You can run **autonomous overnight exploration** without depending on rate limits or human time

The result: humans focus on "directional decisions" and "pass/fail judgment", while exploration and parameter tuning are delegated to the agent.

## Recommended coding agents

A comparison of agents that pair well with alpha-forge as of April 2026:

| Agent | Strengths | Rate / cost (rough) | Slash-command support |
|-------|-----------|---------------------|------------------------|
| **Claude Code** (recommended) | File-edit precision, long-running tasks, Sonnet/Opus mix | Subscription or API metered | ✅ Native `.claude/commands/*.md` |
| **Codex CLI** | Strong baseline, OpenAI models | API metered (e.g., GPT-5) | △ Custom prompts via config |
| **Cursor** | IDE integration, efficient interactive flow | Subscription | △ Composer / Rules workaround |
| **Aider** | OSS, multi-model, git integration | Model cost only | △ Manual `/<command>` aliases |

The rest of this page assumes **Claude Code**. With other agents, point them at `.claude/commands/*.md` to reproduce the same flow.

## Slash-command automation

`alpha-trade/.claude/commands/` defines **6 slash commands for AlphaForge integration**. Each composes `forge` CLI into idempotent exploration / tuning / data-update flows.

### Command catalog

| Command | Role | Main `forge` commands used |
|---------|------|---------------------------|
| [`/explore-strategies`](#explore-strategies) | One autonomous exploration cycle of an untried indicator × symbol | `strategy save` / `validate` / `backtest signal-count` / `backtest run` / `optimize run` / `optimize walk-forward` |
| [`/explore-strategies-loop`](#explore-strategies-loop) | Loop until rate limit | Repeated invocation of the above |
| [`/analyze-exploration`](#analyze-exploration) | Aggregate all exploration logs and recommend next candidates | (file scanning only; doesn't call `forge`) |
| [`/grid-tune`](#grid-tune) | Exhaustive grid tune + WFT validation + journal verdict | `optimize grid` / `optimize walk-forward` / `journal verdict` |
| [`/tune-live-strategies`](#tune-live-strategies) | Detect drift in live strategies and re-tune | `live list` / `live compare` / `optimize run` / `optimize walk-forward` |
| `/update-market-data` | Bulk incremental update of stored historical data | `forge data list` / `forge data update` |

---

### `/explore-strategies`

**Purpose**: Find a strategy meeting target metrics from `goals.yaml` (e.g., Sharpe ≥ 1.5) by trying **one untried indicator × symbol combination per cycle**.

**Steps (summary)**:

1. **Pre-flight**: Read `alpha-strategies/data/explorer/goals.yaml`, `explored_log.md`, and existing strategy JSON files; identify untried combinations
2. **Strategy generation**: Pick one indicator × symbol combo, generate the strategy JSON, and save under `data/strategies/<name>.json`
3. **Register → validate**: `forge strategy save` → `forge strategy validate` for logical consistency (rollback on failure)
4. **Signal count check**: `forge backtest signal-count <SYMBOL> --strategy <name> --json`; skip if `entry_signal_days = 0`
5. **Backtest**: `forge backtest run <SYMBOL> --strategy <name> --json`
6. **Optimize only when pre-filter passes**: `Sharpe ≥ 1.0 && MaxDD ≤ 25%` triggers `forge optimize run` + `forge optimize walk-forward --windows 5`
7. **Record outcome**: Append to `explored_log.md` and `reports/YYYY-MM-DD.md`. On failure, delete strategy JSON / DB entry / result JSON (idempotency)

**Idempotency**: `explored_log.md` is the checkpoint, so re-runs never re-explore the same combination.

---

### `/explore-strategies-loop`

**Purpose**: The looping form of `/explore-strategies`. Repeats **until rate limit** or **all combinations are exhausted**.

**Termination conditions**:

1. All `assets × candidate_indicators` combinations in `goals.yaml` are explored
2. Rate limit hit (the next `/explore-strategies-loop` resumes from `explored_log.md`)

**Operational tips**:

- Run overnight and inspect `reports/YYYY-MM-DD.md` in the morning
- Mid-session interruptions are safe — progress is flushed to `explored_log.md`
- Each iteration takes 30-60 seconds (varies with whether it advances to optimization)

---

### `/analyze-exploration`

**Purpose**: Aggregate all past exploration logs and **scientifically recommend** the next set of combinations to try.

**Processing**:

1. Read all of `explored_log.md` + `reports/*.md`
2. Build a **per-symbol performance table** (trials, max/avg Sharpe, min MaxDD, pass count)
3. Build a **per-indicator-set performance table** (trials, avg/max Sharpe, pass rate)
4. **Score untried combinations** (0–10):
    - Average Sharpe of similar indicators (+0–4)
    - Symbol with few trials = more room to explore (+0–2)
    - Indicator novelty (+0–2)
    - Listed in the previous run's recommendations (+2)
5. Save the report to `alpha-strategies/data/explorer/analysis/YYYY-MM-DD_HH-MM.md`

**Sample output (recommendations)**:

```yaml
candidates:
  - rank: 1
    asset: QQQ
    indicators: [HMM, BBANDS, RSI, MACD]
    score: 8.5
    rationale: "HMM × BBANDS shows high avg Sharpe; QQQ has few trials; MACD adds novelty."
    basis_sharpe: 1.32
    basis_maxdd: 18.4
    variant_of: multi_asset_hmm_bb_rsi_v1_qqq
```

---

### `/grid-tune`

**Purpose**: For an already registered strategy, **expand `optimizer_config.param_ranges` into a Cartesian grid** and run an exhaustive search; on pass, save automatically as `<name>_optimized`.

**Steps**:

1. Inspect the strategy: `forge strategy show <strategy_name>` to confirm `param_ranges` and grid size
2. Signal count check (mandatory): `forge backtest signal-count`
3. Capture baseline: `forge backtest run` to record the original strategy's Sharpe
4. **Exhaustive grid search**: `forge optimize grid <symbol> --strategy <name> --metric sharpe_ratio --top-k 20 --chunk-size 100 --max-memory-mb 4096 --min-trades 30 --save --save-format csv --yes`
5. Review Top-20 (overfitting smell, clustering of top trials)
6. Apply best: `forge optimize grid ... --top-k 1 --apply --yes`
7. **WFT validation**: `forge optimize walk-forward <symbol> --strategy <name>_optimized --windows 5`
8. **Decision**: If WFT mean Sharpe **exceeds the original strategy's Sharpe**, pass
    - Pass → `forge journal verdict <name>_optimized <run_id> pass`
    - Fail → `forge strategy delete <name>_optimized --force` + add a `note` to the original strategy's journal

**Memory / OOM guidance**:

- 1 symbol × 5 years × 1000-cell grid → `--chunk-size 100 --max-memory-mb 4096` runs without OOM
- Larger grids → drop to `--chunk-size 50 --max-memory-mb 2048`
- Coarsening `step` in `param_ranges` is also effective

---

### `/tune-live-strategies`

**Purpose**: For strategies running live, detect drift between live performance and backtest, and **automatically re-tune** the affected strategies.

**Steps**:

1. **Detect drift**: `forge live list` → for each strategy ID, run `forge live compare <strategy_id>` and pick those exceeding `live_tuning.sharpe_drift_threshold` in `goals.yaml`
2. **Re-optimize**: For each drifting strategy:
    - `forge optimize run <SYMBOL> --strategy <name> --metric sharpe_ratio --save`
    - `forge optimize walk-forward <SYMBOL> --strategy <name> --windows 5`
3. **Adoption decision**: Update `<name>_optimized.json` only if WFT mean Sharpe **improves**; keep current otherwise
4. Append the report to `alpha-strategies/data/explorer/reports/tuning-YYYY-MM-DD.md`

**Operational tips**:

- A weekly cron or manual periodic run is enough
- If drift persists for N consecutive weeks, consider rethinking the strategy (replace indicators, switch scenario)

---

## Three exploration scenarios

AI agent × AlphaForge usage falls into three categories based on **what you're starting from**.

### Scenario 1: Combinations from existing strategies / indicators

**Starting point**: Your existing strategy JSON files and the `forge indicator list` catalog.

**Typical flow**:

1. Tell Claude Code: "Take `forge strategy show multi_asset_hmm_bb_rsi_v1_qqq` as the base and add MACD to create a derivative."
2. The agent edits the JSON and creates `multi_asset_hmm_bb_rsi_macd_v1_qqq.json`
3. `forge strategy validate` → `forge strategy save` → `forge backtest run`
4. If Sharpe improves, run `forge optimize run` to fine-tune

**Tip**: With `/explore-strategies`, you can fully delegate combination selection through reporting to the agent.

### Scenario 2: Apply a TradingView Pine Script

**Starting point**: A public TradingView strategy or indicator (`.pine` file).

**Typical flow**:

1. Save an interesting Pine Script locally (`tv_<name>.pine`)
2. **Import**: `forge pine import tv_<name>.pine --id imported_v1`
3. Tell the agent: "Reorganize this strategy's `parameters` and `indicators`, and add an `optimizer_config`."
4. The agent reshapes the JSON and surfaces optimization targets
5. `forge backtest run` → `forge optimize run` to validate AlphaForge-style
6. If good, regenerate via `forge pine generate` and verify on TradingView

**Tip**: Bringing Pine Script logic into **JSON form** unlocks all of AlphaForge's analysis (optimize, WFT, Monte Carlo).

### Scenario 3: Mine forums / papers from the web

**Starting point**: X (Twitter), Reddit `/r/algotrading`, SSRN papers, QuantConnect / QuantStart articles.

**Typical flow**:

1. Hand Claude Code a **URL or PDF** and ask: "Extract the core logic of this strategy into `indicators` and `entry_conditions`."
2. The agent summarizes the article and drafts a strategy JSON
3. `forge strategy validate` to catch logical errors → fix
4. `forge backtest signal-count` to verify signal count (conditions not too restrictive)
5. `forge backtest run` → optimize as needed
6. Compare the article's claimed results vs the actual backtest (**often unreproducible**)

**Tip**: Paper strategies often fail to reproduce when "data period", "symbol", or "transaction costs" differ. Letting the agent **soberly compare** "claimed" vs "real" results acts as a reality filter.

---

## Loop operation and rate limit handling

### Using `/explore-strategies-loop`

```
> /explore-strategies-loop
```

That's it — the agent reads `goals.yaml` and consumes untried combinations one at a time. Since **one iteration = one strategy**, mid-session interruption is safe; the next start resumes from `explored_log.md`.

### Per-agent rate limits

| Agent | Main limit | Mitigation |
|-------|-----------|------------|
| Claude Code | 5-hour token window (plan-dependent) | Spread across night → morning → noon (3 windows) |
| Codex | RPM / TPM (per model) | Lower parallelism; serialize to one iteration at a time |
| Cursor | Monthly / daily request limit | Composer Agent is heavy; reserve for strategy generation |

### Parallelism considerations

`/explore-strategies-loop` assumes **serial execution** (the agents share `explored_log.md`). Running multiple agents in parallel breaks idempotency. To parallelize:

- Maintain separate `goals.yaml` files (different symbol sets) under separate directories
- Run `/explore-strategies-loop` per directory in separate agents

### Safety

- **Mid-stop**: Ctrl-C / Esc safely stops (`explored_log.md` is flushed continuously)
- **Journal backup**: When exploration stabilizes, commit `data/journal/` to git for audit trail
- **Cost cap**: Lower `strategies_per_run` in `goals.yaml` (e.g., 5) to bound token spend per run

---

## Analyzing exploration logs

### Log structure

Under `alpha-strategies/data/explorer/`:

```text
data/explorer/
├── goals.yaml                              # Target metrics and exploration scope
├── explored_log.md                         # Idempotent checkpoint of all explorations
├── reports/
│   ├── 2026-04-15.md                       # Daily run history (multiple runs appended)
│   └── tuning-2026-04-15.md                # /tune-live-strategies output
└── analysis/
    └── 2026-04-15_18-00.md                 # /analyze-exploration output
```

### Using `/analyze-exploration`

```
> /analyze-exploration
```

This produces:

- **Per-symbol** and **per-indicator-set** performance aggregations
- **Top-5 next-candidate recommendations** scored from untried combinations
- Trends and insights ("HMM × MACD is weak in the Bull regime", "SuperTrend is stable on commodities", etc.)

Reading this report before the next `/explore-strategies-loop` lets you do **scientific narrowing** instead of flailing.

---

## End-to-end example (explore → optimize → validate → live)

A worked example: validating and adopting "Add MACD to QQQ HMM × BB × RSI".

```bash
# 1. Record the idea (optional; can be linked later)
forge idea add "Add MACD to QQQ HMM×BB×RSI" \
  --type improvement --tag hmm --tag qqq

# 2. Try one cycle with /explore-strategies (inside Claude Code)
> /explore-strategies
# → Auto-generates strategy JSON; runs validate, signal-count, backtest
# → Sharpe=0.95 fails the pre-filter (requires Sharpe ≥ 1.0)

# 3. Try a derivative (ask the agent to tweak parameters)
> Reduce HMM n_components to 2 for the strategy above and retry
# → Agent generates the revised JSON, re-registers, and backtests (Sharpe=1.18 passes pre-filter)
# → Auto-runs optimize run + walk-forward
# → WFT mean Sharpe=1.32 passes

# 4. Run /grid-tune for exhaustive optimization
> /grid-tune multi_asset_hmm_bb_rsi_macd_v1_qqq QQQ
# → Grid Top-1 → apply → WFT validation reaches 1.45
# → Records pass via forge journal verdict

# 5. Sensitivity / overfitting check
forge optimize sensitivity \
  /path/to/data/results/optimize_multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized_20260415_103021.json
# → overall_robustness_score=0.82 (passes)

# 6. Final approval in journal
forge journal verdict multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized <run_id> pass
forge journal note multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized "OOS pass + sensitivity 0.82. Live candidate."

# 7. Generate Pine Script for TradingView
forge pine generate --strategy multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized --with-training-data

# 8. Begin live operation (deploy execution engine to VPS — out of scope here)
# ...

# 9. After a week, compare live vs backtest
forge live import-events multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized
forge live compare multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized

# 10. If drift is large, run /tune-live-strategies for auto re-tuning
> /tune-live-strategies
```

In this entire flow, **humans only judge in 3 places**:

1. Direction of the idea (add MACD to HMM × BB × RSI)
2. Top-20 review of grid-tune (sniff overfitting)
3. Decision to go live

Everything else runs autonomously through the agent.

---

## Related documentation

- [Getting Started](getting-started.md) — Tutorial through the first backtest
- [CLI Reference](cli-reference/index.md) — Every `forge` command parameter
- [Strategy Templates](templates.md) — Bundled strategies like HMM × BB × RSI

---

*Synced from: slash-command definitions in `alpha-trade/.claude/commands/{explore-strategies,explore-strategies-loop,analyze-exploration,grid-tune,tune-live-strategies,update-market-data}.md`. Agent comparison reflects April 2026.*
