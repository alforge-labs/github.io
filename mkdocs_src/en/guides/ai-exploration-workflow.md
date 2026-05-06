# AI-Driven Strategy Exploration Workflow

Combining Claude Code, Codex, and similar AI coding agents with AlphaForge as the "brain" lets you autonomously drive **idea → implementation → backtest → optimization → validation → live tuning**.

!!! info "Prerequisite"
    The commands and flows shown here assume the `alpha-trade` monorepo (a combination of `alpha-forge` and `alpha-strategies`). **Binary** users should substitute internal commands like `op run --env-file=...` with `forge` directly.

## Why AI agents × AlphaForge

AlphaForge is designed so that **all configuration, strategies, and execution flow through JSON / YAML / CLI**. This means:

- AI agents can **generate, edit, and validate** strategy JSON
- Backtest and optimization results return as **structured data** an agent can analyze
- Slash commands let you replay the **same workflow** idempotently
- You can run **autonomous overnight exploration** without depending on rate limits or human time

The result: humans focus on "directional decisions" and "pass/fail judgment", while exploration and parameter tuning are delegated to the agent.

## Manual vs. AI-driven: when to use which

| Goal | Recommended flow |
|------|-----------------|
| Understand every step of AlphaForge | [End-to-End Strategy Development Workflow](end-to-end-workflow.md) (manual CLI) |
| Quickly explore new indicator × symbol combinations | This page (AI-driven autonomous exploration) |
| Already have a promising strategy and want to fine-tune | Start from Step 3 [`/grid-tune`](#step-3-grid-tune) |
| Monitor drift in live strategies | Step 4 [`/tune-live-strategies`](#step-4-tune-live-strategies) |

## Recommended coding agents

A comparison of agents that pair well with alpha-forge as of April 2026:

| Agent | Strengths | Rate / cost (rough) | Slash-command support |
|-------|-----------|---------------------|------------------------|
| **Claude Code** (recommended) | File-edit precision, long-running tasks, Sonnet/Opus mix | Subscription or API metered | ✅ Native `.claude/commands/*.md` |
| **Codex CLI** | Strong baseline, OpenAI models | API metered (e.g., GPT-5) | △ Custom prompts via config |
| **Cursor** | IDE integration, efficient interactive flow | Subscription | △ Composer / Rules workaround |
| **Aider** | OSS, multi-model, git integration | Model cost only | △ Manual `/<command>` aliases |

The rest of this page assumes **Claude Code**. With other agents, point them at `.claude/commands/*.md` to reproduce the same flow.

---

## Setting up Claude Code for unattended runs {#unattended-setup}

To run `/explore-strategies --runs 0` (or any long continuous run) without stopping for permission prompts, you need to pre-authorize the required operations in Claude Code's allow list. Without this, Claude Code will pause and ask for confirmation every time it encounters an unlisted operation.

Add the following patterns to `permissions.allow` in `.claude/settings.local.json` (your personal settings — gitignored):

```json
{
  "permissions": {
    "allow": [
      "Write(alpha-strategies/data/strategies/*.json)",
      "Bash(uv --directory alpha-forge run forge *)",
      "Bash(FORGE_CONFIG=* uv --directory alpha-forge run forge *)",
      "Bash(git -C */alpha-strategies add data/)",
      "Bash(git -C */alpha-strategies commit *)",
      "Bash(git -C */alpha-strategies push)",
      "Bash(rm */alpha-strategies/data/strategies/*.json)",
      "Bash(rm */data/strategies/*.json)"
    ]
  }
}
```

All paths are relative to `alpha-trade/` as the working root.

| Pattern | What it authorizes |
|---------|-------------------|
| `Write(alpha-strategies/data/strategies/*.json)` | Writing strategy JSON files (one per strategy) |
| `Bash(uv --directory alpha-forge run forge *)` | Direct forge execution |
| `Bash(FORGE_CONFIG=* uv --directory alpha-forge run forge *)` | Forge commands with any FORGE_CONFIG (relative or absolute) |
| `Bash(git -C */alpha-strategies add data/)` | Staging exploration results |
| `Bash(git -C */alpha-strategies commit *)` | Committing exploration results |
| `Bash(git -C */alpha-strategies push)` | Pushing to alpha-strategies |
| `Bash(rm */alpha-strategies/data/strategies/*.json)` | Deleting temp files for failed strategies |
| `Bash(rm */data/strategies/*.json)` | Same, handling different working directory contexts |

!!! note "About settings.local.json"
    `settings.local.json` is listed in `.gitignore` and is never shared with teammates. Each developer must configure it individually in their own environment. Do not add these entries to the tracked `settings.json`.

!!! tip "If you already have a permissions.allow section"
    Merge the new entries into your existing array — do not overwrite the entire file, or you will lose your existing permissions.

!!! info "Using 1Password"
    If you run forge via `op run`, add these patterns as well:
    ```json
    "Bash(op run --env-file=alpha-forge/.env.op -- uv --directory alpha-forge run forge *)",
    "Bash(FORCE_COLOR=* FORGE_CONFIG=* op run * uv --directory alpha-forge run forge explore run *)",
    "Bash(FORGE_CONFIG=* op run * uv --directory alpha-forge run forge strategy *)",
    "Bash(FORGE_CONFIG=* op run * uv --directory alpha-forge run forge data fetch *)",
    "Bash(FORGE_CONFIG=* op run * uv --directory alpha-forge run forge explore *)"
    ```

!!! warning "FORCE_COLOR=1 prefix is required"
    The `/explore-strategies` skill mandates that `forge backtest run` / `forge optimize run` / `forge optimize walk-forward` / `forge explore run` be prefixed with `FORCE_COLOR=1` so that progress bars render correctly ([alpha-forge issue #410](https://github.com/ysakae/alpha-forge/issues/410)). Because the command line begins with `FORCE_COLOR=1 `, it does not match existing patterns that start with `FORGE_CONFIG=...` and may trigger a permission prompt that blocks unattended runs. Add the following patterns:
    ```json
    "Bash(FORCE_COLOR=1 FORGE_CONFIG=* op run *)",
    "Bash(FORCE_COLOR=1 FORGE_CONFIG=* uv --directory alpha-forge run forge *)",
    "Bash(FORCE_COLOR=1 uv --directory alpha-forge run forge *)"
    ```

## Setting up Codex CLI for unattended runs {#codex-unattended-setup}

To run the same kind of long job with Codex CLI, configure the **approval policy** and **sandbox scope** instead of a command-by-command allow list like Claude Code's `permissions.allow`.

First, add an unattended profile to `~/.codex/config.toml`:

```toml
[profiles.alforge-labs-unattended]
approval_policy = "never"
sandbox_mode = "workspace-write"
```

Then start `codex exec` with that profile, pinning the working root and any additional writable directories:

```bash
codex exec \
  --profile alforge-labs-unattended \
  --cd /absolute/path/alpha-trade \
  --add-dir /absolute/path/alpha-trade/alpha-strategies \
  "Use the explore-strategies skill to explore the default goal with the equivalent of --runs 0."
```

Replace `/absolute/path/` with your actual path (e.g., `/Users/yourname/dev/alpha-trade`). If `--cd` points at the `alpha-trade` monorepo root, most operations already stay inside the workspace. Add `--add-dir` when your strategy JSON output lives in a separate worktree or an external `alpha-strategies` checkout.

| Setting / option | Purpose |
|------------------|---------|
| `approval_policy = "never"` | Prevent approval prompts during the run; failures are returned to Codex directly |
| `sandbox_mode = "workspace-write"` | Limit writes to the workspace and explicitly added directories |
| `--cd /.../alpha-trade` | Fix Codex's working root to the monorepo |
| `--add-dir /.../alpha-strategies` | Allow writes to a strategy JSON directory outside the working root |

!!! warning "Avoid full bypass by default"
    `--dangerously-bypass-approvals-and-sandbox` disables both approvals and sandboxing. Do not use it for normal local exploration unless you are running inside an externally isolated throwaway environment.

!!! tip "Prefetch data first"
    Codex's `workspace-write` sandbox may restrict network access depending on your environment. For symbols that need `forge data fetch` / `forge data update`, run `/update-market-data` or `forge data fetch <SYMBOL>` manually before starting the unattended run.

---

## Overall flow

```
Prepare: /update-market-data — bring data up to date
  ↓
Choose a starting point (pick one of 3 exploration scenarios)
  ↓
Step 1: /explore-strategies [--goal <name>] [--runs N]
  └─ Auto backtest → optimize → WFT for each symbol × indicator combo
     Pre-filter: Sharpe ≥ 1.0 AND MaxDD ≤ 25%
  ↓
Step 2: /analyze-exploration
  └─ Aggregate all logs; output next recommended candidates to recommendations.yaml
  ↓
Step 3: /grid-tune
  └─ Exhaustive grid search on promising strategies + WFT re-validation
  ↓
Step 4: /tune-live-strategies
  └─ Drift detection and re-tuning for live strategies
```

---

## Preparation: Fetch historical data

Before starting exploration, make sure the target symbol data is up to date.

```bash
# Bulk incremental update of stored data (binary: forge data update <SYMBOL>)
> /update-market-data
```

`/update-market-data` runs `forge data list` to find registered symbols and calls `forge data update` on each. For brand-new symbols, run `forge data fetch <SYMBOL>` manually first.

---

## Three exploration scenarios

AI agent × AlphaForge usage falls into three categories based on **what you're starting from**.

![AI-driven strategy exploration workflow](../assets/illustrations/ai-exploration-workflow/ai-exploration-workflow-en.png)

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

## Step 1: Exploration phase (`/explore-strategies`) {#step-1-explore}

**Purpose**: Find a strategy meeting target metrics from `goals/<goal_name>/goals.yaml` (e.g., Sharpe ≥ 1.5) by trying **untried indicator × symbol combinations**.

### Steps (summary)

1. **Pre-flight**: Read `goals/<goal_name>/goals.yaml`, `goals/<goal_name>/explored_log.md`, and existing strategy JSON files; identify untried combinations
2. **Strategy generation**: Pick one indicator × symbol combo, generate the strategy JSON, and save under `data/strategies/<name>.json`
3. **Register → validate**: `forge strategy save` → `forge strategy validate` for logical consistency (rollback on failure)
4. **Data fetch**: `forge data fetch <SYMBOL> --period 5y` (only if not already cached)
5. **Run the full pipeline in one command**: `forge explore run <SYMBOL> --strategy <name> --goal <goal_name> --json`
   Signal check → backtest → optimize → walk-forward → coverage update → DB registration — all in one step
6. **Record outcome**: Read `passed` / `skip_reason` from the output JSON, then append to `goals/<goal_name>/explored_log.md` and `goals/<goal_name>/reports/YYYY-MM-DD.md`. When `passed: false` and `cleanup_done: true`, strategy JSON and result JSON have already been removed automatically

```
> /explore-strategies                          # One run (default goal)
> /explore-strategies --goal stocks            # Specify goal
> /explore-strategies --runs 3                 # 3 runs in sequence
> /explore-strategies --goal crypto --runs 0   # Loop until rate limit or all combinations exhausted
```

### Pass/fail criteria

| Phase | Criterion |
|-------|-----------|
| Pre-filter | Sharpe ≥ 1.0 **AND** MaxDD ≤ 25% |
| WFT final pass | All-window mean WFT Sharpe ≥ `target_metrics.sharpe_ratio` in `goals/<goal_name>/goals.yaml` |

### Idempotency

`goals/<goal_name>/explored_log.md` acts as the checkpoint, so re-runs never re-explore the same combination within a goal. Safe to interrupt and resume at any time.

![Idempotency Check Flow](../assets/illustrations/ai-exploration-workflow/exploration-idempotency-flowchart-en.png)

### Continuous runs and rate limit handling

Use `--runs 0` to loop until a rate limit is hit or all combinations are exhausted.

| Agent | Main limit | Mitigation |
|-------|-----------|------------|
| Claude Code | 5-hour token window (plan-dependent) | Spread across night → morning → noon (3 windows) |
| Codex | RPM / TPM (per model) | Lower parallelism; serialize to one iteration at a time |
| Cursor | Monthly / daily request limit | Composer Agent is heavy; reserve for strategy generation |

!!! tip "Parallel execution with multiple goals"
    Goals are independent — each has its own `explored_log.md` under `goals/<name>/`. You can run different goals simultaneously in separate Claude Code sessions without conflicts. Backtest results are shared via `exploration.db`, so the same symbol × indicator combination is never backtested twice across goals.

### Health-check gate (auto-escalation on consecutive failures)

When running unattended with `--runs 0`, a scaffold bug or `goals.yaml` drift can quietly produce a loop where every trial fails. To catch this early, `/explore-strategies` invokes `forge explore health --strict` at the start of every iteration and inspects the most recent five trials (alpha-forge issue #408).

Trigger conditions and behavior:

- All last 5 trials failed **and** the scaffold transformed the requested indicators every time → `escalation: true`
- All last 5 trials share the same `indicator_combo` → `escalation: true`
- Fewer than 5 trials in the DB (shallow history) → observe-only, never blocks

When escalation fires the command exits with code `1`, and the skill stops the loop and surfaces `recommended_actions` to the human operator. See the [`forge explore health` reference](../cli-reference/other.md#forge-explore-health) for full details.

---

## Step 2: Analysis & narrowing down (`/analyze-exploration`) {#step-2-analyze}

**Purpose**: Aggregate all past exploration logs and **scientifically recommend** the next set of combinations to try.

```
> /analyze-exploration
```

### Processing

1. Read all of `goals/*/explored_log.md` + `goals/*/reports/*.md`
2. Build a **per-symbol performance table** (trials, max/avg Sharpe, min MaxDD, pass count)
3. Build a **per-indicator-set performance table** (trials, avg/max Sharpe, pass rate)
4. **Score untried combinations** (0–10):
    - Average Sharpe of similar indicators (+0–4)
    - Symbol with few trials = more room to explore (+0–2)
    - Indicator novelty (+0–2)
    - Listed in the previous run's recommendations (+2)
5. Save the report to `data/explorer/analysis/YYYY-MM-DD_HH-MM.md`
6. **Write top-5 candidates to `recommendations.yaml`** (read by the next `/explore-strategies`)

### Sample output (recommendations.yaml)

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

## Step 3: Precision tuning (`/grid-tune`) {#step-3-grid-tune}

**Purpose**: For a strategy that passed Step 1, **expand `optimizer_config.param_ranges` into a Cartesian grid** and run an exhaustive search; on pass, save automatically as `<name>_optimized`.

```
> /grid-tune <strategy_name> <SYMBOL>
```

### Steps

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

### Memory / OOM guidance

- 1 symbol × 5 years × 1,000-cell grid → `--chunk-size 100 --max-memory-mb 4096` runs without OOM
- Larger grids → drop to `--chunk-size 50 --max-memory-mb 2048`
- Coarsening `step` in `param_ranges` is also effective

---

## Step 4: Live monitoring (`/tune-live-strategies`) {#step-4-tune-live-strategies}

**Purpose**: For strategies running live, detect drift between live performance and backtest, and **automatically re-tune** the affected strategies.

```
> /tune-live-strategies
```

### Steps

1. **Detect drift**: `forge live list` → for each strategy ID, run `forge live compare <strategy_id>` and pick those exceeding `live_tuning.sharpe_drift_threshold` in `goals/<goal_name>/goals.yaml`
2. **Re-optimize**: For each drifting strategy:
    - `forge optimize run <SYMBOL> --strategy <name> --metric sharpe_ratio --save`
    - `forge optimize walk-forward <SYMBOL> --strategy <name> --windows 5`
3. **Adoption decision**: Update `<name>_optimized.json` only if WFT mean Sharpe **improves**; keep current otherwise
4. Append the report to `data/explorer/reports/tuning-YYYY-MM-DD.md`

A weekly cron or manual periodic run is sufficient. If drift persists for N consecutive weeks, consider rethinking the strategy (replace indicators, switch scenario).

---

## Key files

```text
alpha-strategies/data/explorer/
├── goals/
│   ├── default/                       # Default goal (used when --goal is omitted)
│   │   ├── goals.yaml                 # Target metrics and exploration scope
│   │   ├── explored_log.md            # Idempotent checkpoint for this goal
│   │   └── reports/
│   │       ├── YYYY-MM-DD.md          # /explore-strategies daily report
│   │       └── tuning-YYYY-MM-DD.md   # /tune-live-strategies report
│   ├── stocks/                        # US stocks / ETF goal
│   │   ├── goals.yaml
│   │   ├── explored_log.md
│   │   └── reports/
│   ├── commodities/                   # Commodities goal
│   │   └── ...
│   └── crypto/                        # Crypto goal
│       └── ...
├── exploration.db                     # Shared backtest result cache (all goals)
├── recommendations.yaml               # Next-candidate output from /analyze-exploration
└── analysis/
    └── YYYY-MM-DD_HH-MM.md           # /analyze-exploration output
```

**`goals/<goal_name>/goals.yaml`**: Defines target Sharpe, MaxDD, the set of symbols and indicator candidates, and `strategies_per_run` for each goal. Pass `--goal <name>` to `/explore-strategies` to select a goal; defaults to `goals/default/`.

**`goals/<goal_name>/explored_log.md`**: Checkpoint recording every combination tried within a goal. As long as this file exists, the same combination will never be re-explored for that goal.

**`exploration.db`**: Shared SQLite cache across all goals. If the same symbol × indicator combination has already been backtested by any goal, the cached result is reused — no duplicate backtest runs.

**`recommendations.yaml`**: Next-candidate output from `/analyze-exploration`. `/explore-strategies` reads this file and prioritizes high-scoring combinations.

---

## Why run WFT after optimization?

Each step requires a **Walk-Forward Test (WFT)** to prevent overfitting.

Evaluating only on the in-sample period (the data used for optimization) risks parameters that over-fit that historical data. WFT addresses this by:

1. Splitting the full period into multiple windows
2. Running "optimize → Out-of-Sample validation" in each window
3. Using the **OOS mean Sharpe** as the final evaluation metric

This design filters out strategies that perform well on past data but are unlikely to work going forward.

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

- [End-to-End Strategy Development Workflow](end-to-end-workflow.md) — Manual CLI walkthrough for every step
- [Getting Started](../getting-started.md) — Tutorial through the first backtest
- [CLI Reference](../cli-reference/index.md) — Every `forge` command parameter
- [Strategy Templates](../templates.md) — Bundled strategies like HMM × BB × RSI

---

<!-- Synced from: slash-command definitions in `alpha-trade/.claude/commands/{explore-strategies,analyze-exploration,grid-tune,tune-live-strategies,update-market-data}.md`. Agent comparison reflects April 2026. -->
