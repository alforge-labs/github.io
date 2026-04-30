# Other Commands

Utility and management commands not covered by the [core groups](index.md#core-command-groups), bundled on a single page.

!!! info "Details TBD"
    Per-subcommand parameter, output, and error documentation will be filled in via a follow-up issue.

## license

Activate, deactivate, and check license status.

| Command | Description |
|---------|-------------|
| `forge license activate` | Activate a license key |
| `forge license deactivate` | Deactivate the license on this machine |
| `forge license status` | Show current license status |

For setup, see [Getting Started — License Activation](../getting-started.md#license-activation).

## login & logout

Authenticate with your Whop account.

| Command | Description |
|---------|-------------|
| `forge login` | Authenticate with Whop (opens a browser) |
| `forge logout` | Log out and remove credentials |

## init

```bash
forge init
```

A single command that performs initial project setup — scaffolds config files and prepares required directories.

## pine

Convert between strategy JSON and TradingView Pine Script v6.

| Command | Description |
|---------|-------------|
| `forge pine generate` | Generate Pine Script from strategy definition and write to file |
| `forge pine preview` | Preview generated Pine Script from strategy definition on stdout |
| `forge pine import` | Parse a Pine Script file and import it as a strategy definition |

## indicator

Browse supported technical indicators.

| Command | Description |
|---------|-------------|
| `forge indicator list` | Show list of supported indicators. With `FILTER_NAME`, only matching indicators are shown (case-insensitive) |
| `forge indicator show` | Show detailed information for a specific indicator (description, parameters, output, example) |

## idea

Manage, tag, and search investment ideas.

| Command | Description |
|---------|-------------|
| `forge idea add` | Add a new investment idea |
| `forge idea list` | List investment ideas |
| `forge idea show` | Show details of an idea |
| `forge idea status` | Update the status of an idea |
| `forge idea link` | Link a strategy or run record to an idea |
| `forge idea tag` | Manage tags for an idea |
| `forge idea note` | Append a note to an idea |
| `forge idea search` | Search investment ideas |
| `forge idea dashboard` | Launch the web dashboard (equivalent to `forge dashboard`) |

## altdata

Fetch and manage alternative data (sentiment, macro indicators, etc.).

| Command | Description |
|---------|-------------|
| `forge altdata fetch` | Fetch alternative data and save to storage |
| `forge altdata list` | Show list of stored alternative data |
| `forge altdata info` | Show details of a specified data source |

## pairs

Cointegration tests and spread series for pair trading.

| Command | Description |
|---------|-------------|
| `forge pairs scan` | Run cointegration test on two symbols (e.g. `forge pairs scan SPY QQQ`) |
| `forge pairs scan-all` | Scan all pairs in a watchlist for cointegration |
| `forge pairs build` | Compute spread series and save to `alt_data` (e.g. `forge pairs build --sym-a SPY --sym-b QQQ`) |

## dashboard

```bash
forge dashboard
```

A single command that starts the web dashboard (Ctrl+C to stop). Displays equity curves, drawdowns, Monte Carlo, WFO results, and more in the browser.

## docs

Browse bundled documentation, skills, and command references.

| Command | Description |
|---------|-------------|
| `forge docs list` | List available bundled documents |
| `forge docs show` | Show content of a bundled document |

---

*Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,dashboard,docs}.py`.*
