# Getting Started

A complete onboarding guide — from installing AlphaForge CLI to reading your first backtest.

- The **~10-minute Trial walkthrough** (no Whop registration required) is at the top. Just install and start using the CLI immediately.
- After that you'll find **detailed install instructions, paid-plan login (Lifetime / Annual / Monthly), uninstall, and troubleshooting**.

!!! info "Glossary (terms used on this page)"
    | Term | Meaning |
    |---|---|
    | **AlphaForge** | The CLI product that runs backtests, parameter optimization, and Pine Script export from a strategy JSON (this tool itself). |
    | **`alpha-forge` command** | The CLI executable name for AlphaForge. Renamed from `forge` to `alpha-forge` in v0.5.0. |
    | **Trial plan** | The default mode immediately after install. **No email, no account, no signup required.** Data is capped at 2023-12-31 in exchange for access to nearly every feature except Pine Script export. |
    | **Paid plan** | Lifetime / Annual / Monthly. Removes the data date cap and the optimization-trial limit, and enables Pine Script export. |
    | **Whop** | The external billing & license-management platform AlphaForge uses (whop.com). You only create a Whop account when purchasing a paid plan (Google / GitHub SSO also work). |
    | **OAuth 2.0 PKCE login** | After buying a paid plan, `alpha-forge system auth login` opens your browser, you log in to Whop, and an access token is saved to `~/.config/forge/credentials.json`. |

---

## ~10-Minute First Backtest on the Trial Plan

!!! info "What the Trial plan covers (no Whop registration)"
    - Backtesting & optimization ✅ (data capped at **2023-12-31**)
    - Optimization trials: up to **50 per run**
    - Pine Script export ❌ (a paid plan is required)

    See [Trial Limits](guides/trial-limits.md) for full details.

!!! tip "Starting on a paid plan"
    Prefer to begin directly on a paid plan (Lifetime / Annual / Monthly)? Buy it from the [purchase page](https://whop.com/alforge-labs/alphaforge/). You can also upgrade from Trial later. See [Trial Limits](guides/trial-limits.md) for the per-plan feature matrix.

### Step 1 — Install (~2 min)

=== "macOS / Linux"

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    After installation, **open a new terminal** before continuing.

=== "Windows"

    Run in PowerShell (no admin rights needed).

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    After installation, **open a new terminal** before continuing.

Verify the installation.

```bash
forge --version
```

```
AlphaForge CLI v1.x.x
```

If you see a version number, you're ready. For manual installation or custom install paths, see [Detailed Installation](#detailed-installation).

!!! note "Download the latest binary directly"
    Prefer a manual setup over the installer? Grab the per-platform binaries (`forge-macos-arm64` / `forge-linux-x64` / `forge-windows-x64.exe`, etc.) from [GitHub Releases (latest)](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest). See "Detailed Installation → Manual Install" later on this page for placement and PATH details.

!!! info "The Trial plan works without Whop registration"
    From the moment installation finishes, the CLI runs immediately as the Trial plan. Whop OAuth login is **only needed when you purchase a paid plan (Lifetime / Annual / Monthly)**; Trial usage requires nothing additional. See the "Paid-plan login" section later on this page for the upgrade flow.

### Step 2 — Initialize the working directory and prepare a strategy file (~2 min)

Create a `quickstart/` directory and run `forge system init` to bootstrap it. This drops in `forge.yaml` (configuring strategy/data/result paths) plus subdirectories like `data/`.

```bash
mkdir quickstart && cd quickstart
forge system init
```

!!! info "`forge system init` is required"
    Without `forge.yaml`, the strategy DB location, data store, and result output paths are unresolved, so the next `forge backtest run` will fail with `FileNotFoundError`. The default invocation (no `--force`) is sufficient for quickstart.

Save the following as `sma_cross.json`.

```json
{
  "strategy_id": "sma_cross_qs",
  "name": "SMA Crossover Quickstart",
  "version": "1.0.0",
  "description": "SMA(10)/SMA(50) golden-cross strategy (quickstart sample)",
  "target_symbols": ["SPY"],
  "asset_type": "stock",
  "timeframe": "1d",
  "indicators": [
    { "id": "sma_fast", "type": "SMA", "params": { "length": 10 }, "source": "close" },
    { "id": "sma_slow", "type": "SMA", "params": { "length": 50 }, "source": "close" }
  ],
  "entry_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": ">", "right": "sma_slow" }]
    }
  },
  "exit_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": "<", "right": "sma_slow" }]
    }
  },
  "risk_management": {
    "position_size_pct": 10.0,
    "position_sizing_method": "fixed",
    "max_positions": 1,
    "leverage": 1.0
  }
}
```

### Step 3 — Register the strategy and run the backtest (~2 min)

Register `sma_cross.json` (from Step 2) with AlphaForge (the strategy DB).

```bash
forge strategy save sma_cross.json
```

```
✅ Registered custom strategy 'sma_cross_qs'
```

!!! tip "Run a backtest directly from a JSON file (`--strategy-file`)"
    To skip DB registration, you can pass `--strategy-file sma_cross.json` instead of `--strategy`. The quickstart uses the registered form, but `--strategy-file` is handy for fast edit-and-run cycles.

Run a backtest within the Trial plan's data range (up to 2023-12-31).

```bash
forge backtest run SPY \
  --strategy sma_cross_qs \
  --start 2019-01-01 \
  --end 2023-12-31
```

!!! note "Automatic data fetching"
    With `forge.yaml` in place (because you ran `forge system init` in Step 2), the symbol's historical data is fetched automatically on first run. If it fails, run `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` manually and retry.

### Step 4 — Read the results (~3 min)

When complete, you'll see output like this.

!!! warning "**Your numbers will not match this** (sample output)"
    The figures below were measured with **alpha-forge v0.4.0** against **SPY 1d
    data fetched via yfinance on 2026-05-15**. The backtest engine and internal
    metrics evolve continuously, and yfinance also adjusts splits/dividends/CA
    backfills over time, so **the literal numbers printed in this doc drift across
    versions** (finding F-103b). Don't expect to reproduce `4.74%` on your machine —
    use this only as a reference for **label structure and order-of-magnitude
    intuition**. For deterministic regression tests, capture
    `forge backtest run --json` snapshots and diff them against your own baseline.
    The CLI label table below maps Japanese CLI labels to conventional English metric names.

```
Running backtest: SPY x sma_cross_qs  (2019-01-01 → 2023-12-29, 1258 bars)
⚠️  Backtest done   signal-quality score: 0.48/1.0  (0.4–0.7: caution, more validation suggested)
⚠️  Warning: too few trades (trades=15, ≥ 30 recommended)
    → Fewer than 30 trades is statistically noisy and may be filtered out by
      optimization / WFT pre_filter. Consider widening the data period
      (`--start` to go further back).
Total Return: 4.74%   CAGR: 0.93%
SR: 0.85   Sortino: -2.86   Calmar: 0.52
MDD: 1.79%   Length: 71d   Recovery: 154d
PF: 4.01   Win%: 35.7%   avgWin: 10.39%   avgLoss: -1.72%
Trades: 15   AvgHold: 56.8d(57bar)   Max: 218.0d(218bar)
Win-rate CI(90%): 17.8% - 54.8%
📊 View charts via `alpha-vis serve` (result ID: sma_cross_qs_report)
DB save: run_id=<uuid>
💾 Result file: data/results/optimize_sma_cross_qs_<timestamp>.json  ← only with --save
```

A quick read of the key metrics is below. For the full metric list, see [Reading the Results in detail](#reading-the-results-detailed) or the [CLI Reference](cli-reference/index.md).

| CLI label | Conventional name | What it means |
|---|---|---|
| **CAGR** | CAGR (annualized return) | Compare against S&P 500 (~10% avg). A positive CAGR that still trails the market means limited added value. |
| **SR** | Sharpe Ratio | Risk-adjusted return. **1.0+** is the target. |
| **MDD** | Max Drawdown | Worst peak-to-trough drop. Staying under 20% makes it easier to stick with a strategy. |
| **Win%** | Win Rate | Percentage of winning trades. 40–60% is normal for trend-following. |
| **PF** | Profit Factor | Total profit ÷ total loss. **1.5+** is solid. |
| **Trades** | Total trades | Aim for **30+** for statistical reliability; 15 triggers the warning in the sample output. |

!!! note "Additional metrics printed by the CLI"
    Beyond the six core metrics above, the CLI also prints supporting metrics.

    | CLI label | Conventional name | What it means |
    |---|---|---|
    | **Signal quality score** | — | A 0.0–1.0 score from alpha-forge's internal statistical validity check on the trade signal. **≥0.7 = reliable, 0.4–0.7 = caution, <0.4 = reference only**. |
    | **Sortino** | Sortino Ratio | Sharpe variant that only penalizes downside volatility. For the same Sharpe, a higher Sortino means smaller risk on the way down. Negative values indicate negative returns relative to downside risk. |
    | **Calmar** | Calmar Ratio | `CAGR ÷ |MDD|`. Annualized return normalized by max drawdown. **≥0.5 acceptable, >1.0 strong**. |
    | **Length / Recovery** | Drawdown duration / Recovery | Days from MDD peak to trough / from trough back to a new peak. Longer recovery means longer capital lock-up. |
    | **avgWin / avgLoss** | Avg Win / Avg Loss | Average winning trade % and average losing trade %. `avgWin ÷ |avgLoss|` is the payoff ratio; **≥2.0** is healthy for trend-following. |
    | **AvgHold / Max** | Avg Hold / Max Hold | Average and maximum position-holding length in days. Compare with the timeframe (1d, 1h, etc.) — large divergences from the strategy's intended horizon are a red flag. |
    | **Win streak / Loss streak** | Max consecutive wins / losses | Longest winning / losing run. Long losing streaks raise the psychological cost of running the strategy live. |
    | **Win-rate CI(90%)** | Win Rate 90% CI | 90% confidence interval for the win rate. A wide CI (e.g. `17.8% – 54.8%`) means too few trades to pin down the true win rate; **30+ trades** narrows it considerably. |

!!! tip "Visualize the results in your browser"
    The `📊 View charts via vis serve` line at the end of the output points at the separate [alpha-visualizer](alpha-visualizer/installation.md) dashboard. Install with:

    ```bash
    uv tool install alpha-visualizer   # using uv
    pip install alpha-visualizer       # using pip
    ```

    Run `vis serve` inside the `quickstart/` directory and your browser opens the dashboard (default: <http://127.0.0.1:8000>).

    macOS ships a standard `/usr/bin/vis` command, so when plain `vis` is hijacked, use the absolute path `~/.local/bin/vis serve` (uv tool layout) or `~/.local/share/uv/tools/alpha-visualizer/bin/vis serve`.

### What to do next

| Goal | Where to go |
|------|-------------|
| Pick the next page based on your role | [Use Cases by Goal](usecases/index.md) |
| Optimize parameters | [optimize command](cli-reference/optimize.md) |
| Validate against overfitting | [End-to-End Workflow](guides/end-to-end-workflow.md) |
| Try complex strategy templates | [Strategy Templates](templates.md) |
| Connect to TradingView | [Pine Script Integration Guide](guides/tradingview-pine-integration.md) |
| Understand Trial plan limits | [Trial Limits](guides/trial-limits.md) |

---

## Detailed Installation

### Requirements

- macOS 12 (Monterey) or later / Ubuntu 22.04 or later / Windows 11
- Internet access (for the first data fetch, or for paid-plan authentication)
- **A Whop account is not required for the Trial plan.** Only purchase a [paid plan](https://whop.com/alforge-labs/alphaforge/) (Lifetime / Annual / Monthly) if you want to lift the Trial limits.

### Install procedure

=== "macOS / Linux"

    Run the following command in your terminal. The installer extracts the latest binary bundle (`forge.dist`) into `~/.local/share/alpha-forge/` and symlinks the executable as `~/.local/bin/forge`.

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    The default install location is `~/.local/bin` (user-local, no sudo required). During install, you'll be asked `Install to system-wide /usr/local/bin instead? (requires sudo) [y/N]:`. Press Enter or `n` to keep the default, or `y` to install system-wide to `/usr/local/bin` (which will prompt for sudo).

    !!! tip "Non-interactive install (`INSTALL_DIR` env var)"

        For CI, Dockerfiles, or any environment where the interactive prompt can't be answered, set `INSTALL_DIR` to choose the symlink directory directly. The prompt is then skipped entirely.

        ```bash
        # Pin to ~/.local/bin without any prompt
        INSTALL_DIR=~/.local/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)

        # Custom directory (must be writable)
        INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)
        ```

        The `forge.dist` bundle is extracted under `<dirname of INSTALL_DIR>/share/alpha-forge/` (e.g. `INSTALL_DIR=/opt/forge/bin` → `/opt/forge/share/alpha-forge/`). Pass the same `INSTALL_DIR` to `uninstall.sh` when removing.

    !!! tip "Display language (`FORGE_INSTALL_LOCALE` env var)"

        The installer auto-detects language from `LANG` / `LC_ALL` (Japanese for `ja*`, English otherwise). To force a specific language, set `FORGE_INSTALL_LOCALE=ja|en`. `uninstall.sh` honors the same variable.

        ```bash
        # Force English output regardless of LANG
        FORGE_INSTALL_LOCALE=en bash <(curl -sSL https://alforge-labs.github.io/install.sh)
        ```

    !!! tip "Paid-plan login (optional)"

        Right after install, the CLI runs in Trial mode without any Whop login. Run the following command only after you purchase a paid plan (Lifetime / Annual / Monthly):

        ```bash
        forge system auth login
        ```

=== "Windows"

    Run this in PowerShell (no administrator rights required). It extracts the bundled binary set (`forge.dist\`) into `%LOCALAPPDATA%\Programs\alpha-forge\` and adds the sibling `forge.cmd` launcher to your User PATH.

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    If a legacy install (`$HOME\bin\forge.exe` or `C:\Program Files\forge\forge.exe`) is detected, it is removed after confirmation and replaced with the new layout. To preview what the installer would do without touching the filesystem, run with `-DryRun`:

    ```powershell
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/install.ps1))) -DryRun
    ```

    !!! tip "Display language"
        The installer auto-detects from Windows display language (`CurrentUICulture`). To force a specific language, set `$env:FORGE_INSTALL_LOCALE = "en"` (or `"ja"`) before `irm | iex`.

    !!! tip "New terminal"
        Open a new terminal window after installation before continuing.

=== "Manual"

    1. Download the binary for your platform from [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest).

    2. **macOS / Linux**: make it executable and move it to a directory on your PATH.

        ```bash
        chmod +x forge-macos-arm64
        sudo mv forge-macos-arm64 /usr/local/bin/forge
        ```

    3. **Windows**: place the binary in any folder and add that folder to PATH.

---

## Paid-plan Login

The CLI runs **immediately as the Trial plan with no Whop registration**. You only need this section once you've **purchased a paid plan (Lifetime / Annual / Monthly)**, which lifts the data date cap, the optimization trial cap, and the Pine Script export block.

!!! info "Happy with the Trial plan?"
    If the Trial limits (data through 2023-12-31, 50 optimization trials, Pine output blocked) cover your use case, you can skip this section and keep running backtests/optimizations. `forge system auth login` is not required for Trial usage.

### 1. Purchase a paid plan

Open the [purchase page](https://whop.com/alforge-labs/alphaforge/) in your browser, sign up to Whop (email / GitHub / Google), and complete checkout for Lifetime, Annual, or Monthly.

### 2. Authenticate with Whop OAuth from forge

After the purchase finishes, run the command below in your terminal. It launches a browser and walks you through Whop's OAuth 2.0 PKCE flow.

```bash
forge system auth login
```

Credentials are cached at `$XDG_CONFIG_HOME/forge/credentials.json` (default `~/.config/forge/credentials.json`). Internet access is required.

### 3. Verify the login state

Inspect the cached user ID, token expiry, and plan tier:

```bash
forge system auth status
```

```
User ID         : user_abc123
Access token    : 2026-05-13 12:30 UTC (45 min remaining)
Last verified   : 2026-05-13 11:45 UTC (13 min ago)
Plan            : Paid (Lifetime)
```

`Plan: Paid (Lifetime)` confirms a successful paid-plan activation. Due to an implementation holdover, the CLI also shows `Paid (Lifetime)` for Annual and Monthly subscribers (Whop OAuth treats all paid tiers as a single "customer" access level). Without Whop registration the plan field reads `Plan: Free (Trial)` (Trial mode).

### 4. Confirm the unlock

Verify that a paid-plan-only feature (Pine Script export) now works:

```bash
forge pine generate --strategy sma_cross_qs
```

If the red "Premium-only feature" Panel does **not** appear and a `.pine` file is generated, the paid plan is fully active.

---

## Reading the Results (Detailed)

The six metrics you'll look at first. For the full metric list, see the [CLI Reference](cli-reference/index.md) and [Strategy Templates](templates.md).

| Metric | Meaning | Rule of thumb |
|--------|---------|---------------|
| **CAGR** | Compound annual growth rate | Compare against the market benchmark (S&P 500: ~10%). Positive but below market = limited edge. |
| **Sharpe Ratio** | Risk-adjusted return | ≥ 1.0 is "usable", ≥ 1.5 is good, ≥ 2.0 is top-tier. Negative is out. |
| **Max Drawdown** | Largest peak-to-trough equity drop | Shallower is better. Beyond −20% becomes psychologically hard to keep trading. |
| **Win Rate** | Share of profitable trades | ~50% is typical. Trend-following: 30–40%. Mean-reversion: 60–70%. |
| **Profit Factor** | Gross profit ÷ gross loss | ≥ 1.5 is good, ≥ 2.0 is excellent. < 1.0 means net loss. |
| **Total Trades** | Number of trades over the test period | Aim for 30+ for statistical significance. Too few suggests overfitting risk. |

![Max Drawdown time-series chart](assets/illustrations/concepts/metrics-max-drawdown-chart.png)

![Sharpe Ratio concept diagram](assets/illustrations/concepts/metrics-sharpe-ratio-concept.png)

![Win Rate and Profit Factor relationship](assets/illustrations/concepts/metrics-win-rate-profit-factor.png)

!!! info "What to try next"
    - Parameter optimization: [`forge optimize run`](cli-reference/optimize.md) for Optuna Bayesian search
    - Walk-forward validation: [`forge optimize walk-forward`](cli-reference/optimize.md) to detect overfitting
    - Strategy templates: try [HMM × BB × RSI and others](templates.md)

---

## Uninstall

=== "macOS / Linux"

    Run the official uninstaller. It removes the `forge` symlink, the entire `forge.dist/` directory (~1,100 bundled library files), and the PATH line that was appended to your shell rc.

    ```bash
    bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
    ```

    Your credentials (`~/.config/forge/credentials.json`) are **kept by default**. This is intentional: if you reinstall later, you can skip `forge system auth login` and the install will pick up your existing Whop OAuth session.

    !!! tip "Full wipe (delete credentials and EULA acceptance too)"

        ```bash
        bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge
        ```

        `--purge` additionally removes `~/.config/forge/` (Whop OAuth token + EULA state) and the legacy `~/.forge/` path if it exists.

    !!! info "Preview before deleting"

        ```bash
        bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --dry-run
        ```

        Shows exactly which paths would be removed without touching anything.

    !!! tip "Uninstall from a custom path (`INSTALL_DIR` env var)"

        If you installed via `INSTALL_DIR=...`, pass the same value to the uninstaller so it can locate the symlink:

        ```bash
        INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
        ```

        Without it, both `~/.local/bin` and `/usr/local/bin` are auto-discovered.

    **What is NOT removed:**

    - Your **project working directories** created by `forge system init` (`forge.yaml`, `data/`, etc.) — these are your data
    - Shared parent directories like `~/.local/share/` and `~/.config/` (used by other apps)

=== "Windows"

    Run the official uninstaller. It removes both the new layout (`%LOCALAPPDATA%\Programs\alpha-forge\`) and any legacy layouts (`$HOME\bin\forge.exe` / `C:\Program Files\forge\forge.exe`), and cleans up the matching User PATH entries.

    ```powershell
    irm https://alforge-labs.github.io/uninstall.ps1 | iex
    ```

    Authentication cache (`~\.config\forge\credentials.json`) is preserved by default. Pass `-Purge` to delete it as well:

    ```powershell
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/uninstall.ps1))) -Yes -Purge
    ```

---

## Troubleshooting

| Symptom | Cause & Fix |
|---------|-------------|
| `command not found: forge` | Open a new terminal or run `source ~/.bashrc`. If that doesn't help, check your PATH. |
| `Strategy 'sma_cross_qs' not found` / `戦略 'sma_cross_qs' が見つかりません` | Run `forge strategy save sma_cross.json` first to register the strategy in the DB. Or pass the JSON directly via `forge backtest run SPY --strategy-file sma_cross.json --start ...`. |
| `FileNotFoundError: data not found: SPY (1d)` / `No data found for SPY` | Auto-fetch only works when `forge.yaml` exists. Run `forge system init` (Step 2) first, or fetch manually with `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` and retry. |
| `Failed to fetch data: symbol=USDJPY` (404) | yfinance requires fixed suffixes per asset class: FX `USDJPY=X` / `EURUSD=X` / `GBPJPY=X`, futures `CL=F`, crypto `BTC-USD`. Quote symbols containing `=` (e.g., `'USDJPY=X'`). |
| `vis: serve: No such file or directory` / `vis: illegal option` | macOS ships a built-in `/usr/bin/vis` that wins on `$PATH`. Run with the absolute path `~/.local/bin/vis serve` (uv tool) or `~/.local/share/uv/tools/alpha-visualizer/bin/vis serve`. |
| `Trial plan: date clipped to 2023-12-31` | Expected behavior. Data beyond the Trial plan cap is automatically excluded. Purchase a paid plan (Lifetime / Annual / Monthly) to lift the cap. |
| Authentication error | Verify your network connection and rerun `forge system auth login`. Confirm your Whop membership is active. |
| macOS security warning | System Settings → Privacy & Security → click "Open forge". |

For other issues and detailed FAQ, see [`/en/install.html`](https://alforgelabs.com/en/install.html).

- For usage questions and conversations with other users, head to [GitHub Discussions](https://github.com/alforge-labs/alforge-labs.github.io/discussions).
- For individual support, contact [support@alforgelabs.com](mailto:support@alforgelabs.com).

---

## Next Steps

- [Visualize results — alpha-visualizer](alpha-visualizer/installation.md) — OSS package that renders forge's backtest results in your browser (`uv tool install alpha-visualizer` / `pip install alpha-visualizer`)
- [Use Cases by Goal](usecases/index.md) — Pick the most relevant next page based on your role (TradingView user / Python developer / Quant / Auto-trading / AI agent user)
- [CLI Reference](cli-reference/index.md) — Every `forge` command, parameters, and output format
- [Strategy Templates](templates.md) — Compound strategies like HMM × BB × RSI
- [AI-Driven Strategy Exploration Workflow](guides/ai-exploration-workflow.md) — Autonomous exploration with Claude Code / Codex × AlphaForge

---

<!-- Synced from: `en/install.html` (install / Whop login / troubleshooting). The backtest example follows the alpha-forge strategy JSON schema (based on `spy_sma_crossover_v1.json`). Issue #117 merged the former `quickstart.md` into this page. -->
