# Getting Started

Install AlphaForge CLI, activate your license, and run your first backtest in about five minutes.

## Requirements

- macOS 12 (Monterey) or later / Ubuntu 22.04 or later / Windows 11
- Internet access for license activation
- A valid AlphaForge license key from the [pricing page](https://alforgelabs.com/en/index.html#pricing)

## Install

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

## License Activation

### 1. Check installation

Confirm that the binary is available.

```bash
forge --version
```

### 2. Activate your license

Use the license key from your purchase email.

```bash
forge license activate <YOUR_LICENSE_KEY>
```

Activation data is cached at `~/.forge/license.json`. Internet access is required.

### 3. Verify commands

Confirm that backtest commands are available.

```bash
forge backtest --help
```

## Your First Backtest

We'll use the simplest possible strategy — a **golden cross / death cross** between SMA(10) and SMA(50).

### Step 1: Create a strategy JSON

Create `my_first_strategy.json` in any directory (e.g., `strategies/`).

```json
{
  "strategy_id": "my_first_strategy",
  "name": "SMA Crossover Example",
  "version": "1.0.0",
  "description": "Long when SMA(10) > SMA(50) (golden cross / death cross)",
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

### Step 2: Run the backtest

```bash
forge backtest run SPY --strategy my_first_strategy --json
```

### Step 3: Sample output

!!! warning "Sample output"
    The output below is illustrative. Actual numbers depend on the data and environment at run time.

```text
==> SPY 2018-01-01 → 2025-12-31 (1d)
   trades: 14   win_rate: 50.0%   profit_factor: 1.74
   total_return: +52.3%   cagr: +5.4%   sharpe: 0.92
   max_drawdown: -16.8%   exposure: 38.2%
   final_equity: $15,230  (initial: $10,000)
```

## Reading the Results

The six metrics you'll look at first. For the full metric list, see the [CLI Reference](cli-reference/index.md) and [Strategy Templates](templates.md).

| Metric | Meaning | Rule of thumb |
|--------|---------|---------------|
| **CAGR** | Compound annual growth rate | Compare against the market benchmark (S&P 500: ~10%). Positive but below market = limited edge. |
| **Sharpe Ratio** | Risk-adjusted return | ≥ 1.0 is "usable", ≥ 1.5 is good, ≥ 2.0 is top-tier. Negative is out. |
| **Max Drawdown** | Largest peak-to-trough equity drop | Shallower is better. Beyond −20% becomes psychologically hard to keep trading. |
| **Win Rate** | Share of profitable trades | ~50% is typical. Trend-following: 30–40%. Mean-reversion: 60–70%. |
| **Profit Factor** | Gross profit ÷ gross loss | ≥ 1.5 is good, ≥ 2.0 is excellent. < 1.0 means net loss. |
| **Total Trades** | Number of trades over the test period | Aim for 30+ for statistical significance. Too few suggests overfitting risk. |

!!! info "What to try next"
    - Parameter optimization: [`forge optimize run`](cli-reference/optimize.md) for Optuna Bayesian search
    - Walk-forward validation: [`forge optimize walk-forward`](cli-reference/optimize.md) to detect overfitting
    - Strategy templates: try [HMM × BB × RSI and others](templates.md)

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

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `command not found: forge` | Open a new terminal or run `source ~/.bashrc`. |
| License activation error | Check your network and remove any extra whitespace from the key. |
| macOS security warning | System Settings → Privacy & Security → click "Open forge". |

For other issues and detailed FAQ, see [`/en/install.html`](https://alforgelabs.com/en/install.html). If the problem persists, contact [support@alforgelabs.com](mailto:support@alforgelabs.com).

## Next Steps

- [CLI Reference](cli-reference/index.md) — Every `forge` command, parameters, and output format
- [Strategy Templates](templates.md) — Compound strategies like HMM × BB × RSI
- [AI Agent Integration](ai-driven-forges.md) — Autonomous exploration with Claude Code / Codex × AlphaForge

---

*Synced from: `en/install.html` (install / license activation / troubleshooting). The backtest example follows the alpha-forge strategy JSON schema (based on `spy_sma_crossover_v1.json`).*
