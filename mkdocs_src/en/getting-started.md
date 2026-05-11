# Getting Started

A complete onboarding guide — from installing AlphaForge CLI to reading your first backtest.

- The **10-minute Free-plan walkthrough** is at the top. No license purchase required.
- After that you'll find **detailed install instructions, Whop login, uninstall, and troubleshooting**.

---

## 10-Minute First Backtest on the Free Plan

!!! info "What the Free plan covers"
    - Backtesting & optimization ✅ (data capped at **2023-12-31**)
    - Optimization trials: up to **50 per run**
    - Pine Script export ❌ (paid plan required)

    See [Freemium Limits](guides/freemium-limits.md) for full details.

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

### Step 2 — Sign in with Whop (~1 min)

AlphaForge uses OAuth 2.0 PKCE authentication via your Whop account. The next command opens a browser automatically.

```bash
forge system auth login
```

After you complete the browser flow, credentials are cached at `$XDG_CONFIG_HOME/forge/credentials.json` (default `~/.config/forge/credentials.json`).

You can confirm the login state at any time:

```bash
forge system auth status
```

```
User ID         : user_abc123
Access token    : 2026-04-12 12:30 UTC (45 min remaining)
Last verified   : 2026-04-12 11:45 UTC (13 min ago)
Plan            : annual
```

!!! tip "Free plan works for the basics"
    Some features (e.g. Pine Script export) require a paid plan, but backtesting, optimization, and strategy management are available on Free.

### Step 3 — Prepare a strategy file (~2 min)

Create a `quickstart/` directory and save the sample strategy JSON.

```bash
mkdir quickstart && cd quickstart
```

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

### Step 4 — Run the backtest (~2 min)

Run a backtest within the Free plan's data range (up to 2023-12-31).

```bash
forge backtest run SPY \
  --strategy sma_cross_qs \
  --start 2019-01-01 \
  --end 2023-12-31
```

!!! note "Data is fetched automatically"
    On first run, `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` runs automatically. This may take a few seconds.

### Step 5 — Read the results (~3 min)

When complete, you'll see output like this.

!!! warning "Sample output"
    Actual numbers vary depending on the data fetched.

```
==> SPY 2019-01-01 → 2023-12-31 (1d)
   trades: 9   win_rate: 55.6%   profit_factor: 1.82
   total_return: +38.4%   cagr: +6.7%   sharpe: 0.88
   max_drawdown: -14.2%   exposure: 41.5%
   final_equity: $13,840  (initial: $10,000)
```

A quick read of the key metrics is below. For the full metric list, see [Reading the Results in detail](#reading-the-results-detailed) or the [CLI Reference](cli-reference/index.md).

| Metric | This run | What it means |
|--------|----------|---------------|
| **CAGR** | +6.7% | Annualized return (compound). Compare against S&P 500 (~10% avg). |
| **Sharpe** | 0.88 | Risk-adjusted return. **1.0+** is the target. Getting close! |
| **Max Drawdown** | -14.2% | Worst peak-to-trough drop. Staying under 20% makes it easier to stick with a strategy. |
| **Win Rate** | 55.6% | Percentage of winning trades. 40–60% is normal for trend-following. |
| **Profit Factor** | 1.82 | Total profit ÷ total loss. **1.5+** is solid. |
| **Trades** | 9 | Total trades in the period. Aim for **30+** for statistical reliability. |

### What to do next

| Goal | Where to go |
|------|-------------|
| Pick the next page based on your role | [Use Cases by Goal](usecases/index.md) |
| Optimize parameters | [optimize command](cli-reference/optimize.md) |
| Validate against overfitting | [End-to-End Workflow](guides/end-to-end-workflow.md) |
| Try complex strategy templates | [Strategy Templates](templates.md) |
| Connect to TradingView | [Pine Script Integration Guide](guides/tradingview-pine-integration.md) |
| Understand Free plan limits | [Freemium Limits](guides/freemium-limits.md) |

---

## Detailed Installation

### Requirements

- macOS 12 (Monterey) or later / Ubuntu 22.04 or later / Windows 11
- Internet access (for Whop login and the first data fetch)
- Paid plans only: a valid AlphaForge license key from the [pricing page](https://alforgelabs.com/en/index.html#pricing)

### Install procedure

=== "macOS / Linux"

    Run the following command in your terminal. The installer downloads the latest binary and places it in `/usr/local/bin`.

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    !!! tip "Custom install location"
        Set `INSTALL_DIR` to install elsewhere.

        ```bash
        INSTALL_DIR=~/.local/bin curl -sSL https://alforge-labs.github.io/install.sh | bash
        ```

=== "Windows"

    Run this in PowerShell. It installs the binary into `%USERPROFILE%\.forge\bin` and updates PATH automatically.

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

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

## Whop Login

AlphaForge uses OAuth 2.0 PKCE authentication with your Whop account. A one-time login is required for all plans.

### 1. Check installation

Confirm that the binary is available.

```bash
forge --version
```

### 2. Sign in with Whop

The command launches the OAuth flow in your browser.

```bash
forge system auth login
```

Credentials are cached at `$XDG_CONFIG_HOME/forge/credentials.json` (default `~/.config/forge/credentials.json`). Internet access is required.

### 3. Verify the login state

You can inspect the cached user ID and token expiry:

```bash
forge system auth status
```

### 4. Verify commands

Confirm that backtest commands are available.

```bash
forge backtest --help
```

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

    ```bash
    sudo rm /usr/local/bin/forge
    rm -rf ~/.forge
    ```

=== "Windows"

    ```powershell
    Remove-Item -Recurse $env:USERPROFILE\.forge
    # Manually remove %USERPROFILE%\.forge\bin from PATH
    ```

---

## Troubleshooting

| Symptom | Cause & Fix |
|---------|-------------|
| `command not found: forge` | Open a new terminal or run `source ~/.bashrc`. If that doesn't help, check your PATH. |
| `No data found for SPY` | Run `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` first. |
| `Free plan: date clipped to 2023-12-31` | Expected behavior. Data beyond the Free plan cap is automatically excluded. |
| `Strategy not found: sma_cross_qs` | Check that the `strategy_id` in your JSON is exactly `sma_cross_qs`. |
| Authentication error | Verify your network connection and rerun `forge system auth login`. Confirm your Whop membership is active. |
| macOS security warning | System Settings → Privacy & Security → click "Open forge". |

For other issues and detailed FAQ, see [`/en/install.html`](https://alforgelabs.com/en/install.html).

- For usage questions and conversations with other users, head to [GitHub Discussions](https://github.com/alforge-labs/alforge-labs.github.io/discussions).
- For individual support, contact [support@alforgelabs.com](mailto:support@alforgelabs.com).

---

## Next Steps

- [Use Cases by Goal](usecases/index.md) — Pick the most relevant next page based on your role (TradingView user / Python developer / Quant / Auto-trading / AI agent user)
- [CLI Reference](cli-reference/index.md) — Every `forge` command, parameters, and output format
- [Strategy Templates](templates.md) — Compound strategies like HMM × BB × RSI
- [AI-Driven Strategy Exploration Workflow](guides/ai-exploration-workflow.md) — Autonomous exploration with Claude Code / Codex × AlphaForge

---

<!-- Synced from: `en/install.html` (install / Whop login / troubleshooting). The backtest example follows the alpha-forge strategy JSON schema (based on `spy_sma_crossover_v1.json`). Issue #117 merged the former `quickstart.md` into this page. -->
