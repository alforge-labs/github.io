# forge data

Fetch, update, and inspect historical market data. Pulls OHLCV from configured providers (yfinance / moomoo / OANDA / Dukascopy / TradingView MCP) and caches it locally as Parquet.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual numbers depend on the data and environment.

## Subcommands

| Command | Description |
|---------|-------------|
| [`forge data fetch`](#forge-data-fetch) | Fetch and save historical data |
| [`forge data list`](#forge-data-list) | List all stored historical datasets |
| [`forge data trend`](#forge-data-trend) | Evaluate market trend from stored data |
| [`forge data update`](#forge-data-update) | Incrementally update all stored historical data to the latest |

---

## forge data fetch

Fetch OHLCV for a symbol or watchlist and save it as Parquet under `config.data.storage_path`. By default, cache within `config.data.cache_ttl_hours` is reused; use `--force` to bypass.

### Synopsis

```bash
forge data fetch [SYMBOL] [OPTIONS]
forge data fetch --watchlist <FILE> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (optional) | - | Symbol. Mutually exclusive with `--watchlist` |
| `--period` | option | `1y` | Fetch period (e.g. `1y`, `5y`, `6m`, `30d`, `max`) |
| `--interval` | option | `1d` | Bar interval (e.g. `1d`, `1h`, `5m`) |
| `--watchlist` | option | - | Watchlist file (one symbol per line; lines starting with `#` are comments) |
| `--force` | flag | false | Force re-fetch regardless of TTL |
| `--provider` | choice | - | Explicit provider override (`yfinance` / `moomoo` / `tv_mcp`). Falls back to `data.providers` in `forge.yaml` when omitted |
| `--mcp-server` | option | - | MCP server command for `--provider tv_mcp` (e.g. `node /opt/tv-mcp/server.js`). Falls back to `data.providers.tv_mcp.endpoint` in `forge.yaml` |
| `--mcp-server-flavor` | choice | - | MCP server flavor for `--provider tv_mcp` (`tradesdontlie` / `vinicius`). CLI value takes precedence over `forge.yaml` |

You must provide either `SYMBOL` or `--watchlist`. With `--provider tv_mcp`, the command fails fast if no `endpoint` can be resolved.

### Sample output (single symbol)

```text
Fetching data: SPY (period=5y, interval=1d)
Fetched and saved data for SPY (1258 lines)
```

When the cache is valid:

```text
Cache is valid: SPY (TTL: 24h) — skipped. Use --force to re-fetch.
```

### Sample output (watchlist)

```text
Fetching data for 3 symbols...
  [SPY] Fetching...
  [SPY] Done: 1258 rows
  [QQQ] Cache is valid (TTL: 24h) — skipped
  [AAPL] Fetching...
  [AAPL] Error: <details>
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: specify a symbol or --watchlist.` | Neither given | Pass `SYMBOL` or `--watchlist <FILE>` |
| `Error: watchlist file not found - <path>` | Bad path | Verify the path |
| `[<SYM>] Error: <details>` | Provider error (network, auth, invalid symbol, etc.) | Check provider settings or `forge.yaml` |

---

## forge data list

List all stored datasets.

### Synopsis

```bash
forge data list
```

### Arguments and options

None.

### Sample output

```text
Stored data count: 3
- SPY (1d): 2018-01-02 to 2025-12-31 (2014 rows)
- QQQ (1d): 2018-01-02 to 2025-12-31 (2014 rows)
- USDJPY=X (1d): 2020-01-01 to 2025-12-31 (1530 rows)
```

When no data is stored:

```text
Stored data count: 0
```

---

## forge data trend

Generate market trend signals (bullish / bearish / neutral and similar) from stored data. When `--symbols` is not provided, `DEFAULT_TREND_SYMBOLS` (a major JP/US set) is used.

### Synopsis

```bash
forge data trend [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--symbols` | option | major JP/US default set | Comma-separated symbols to evaluate |
| `--watchlist` | option | - | Watchlist file with one symbol per line |
| `--interval` | option | `1d` | Bar interval |
| `--as-of` | option | - | Evaluate using bars up to this date (`YYYY-MM-DD`) |
| `--json` | flag | false | Output as JSON |

When both `--symbols` and `--watchlist` are given, `--watchlist` takes precedence.

### Sample output (text)

```text
SPY: BULLISH - 50EMA > 200EMA, momentum positive
QQQ: BULLISH - 50EMA > 200EMA, momentum positive
^N225: NEUTRAL - mixed signals
USDJPY=X: BEARISH - 50EMA < 200EMA
```

### Sample output (`--json`)

```json
{
  "source": "alpha-forge:data:trend",
  "interval": "1d",
  "as_of": "2025-12-31",
  "signals": [
    {"symbol": "SPY", "label": "BULLISH", "summary": "50EMA > 200EMA, momentum positive", ...},
    {"symbol": "QQQ", "label": "BULLISH", "summary": "...", ...}
  ]
}
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Watchlist file not found - <path>` | Bad path | Verify the path |

---

## forge data update

For every dataset visible via `forge data list`, fetch the **incremental delta** from the last cached date up to today. Already up-to-date datasets are skipped.

### Synopsis

```bash
forge data update
```

### Arguments and options

None.

### Sample output

```text
Starting update for 3 datasets...
  [Update] Fetching SPY (1d) from 2025-12-15 to now...
    - Added/updated 12 rows.
  [Skip] QQQ (1d): already up to date (2025-12-31).
  [Update] Fetching USDJPY=X (1d) from 2025-12-20 to now...
    - No new data available.
Update complete: 1 datasets updated.
```

When no data is stored:

```text
No stored data found.
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `[Skip] <SYM> (<interval>): no valid last fetch date.` | Corrupted metadata or empty file | Re-fetch with `forge data fetch <SYM> --force` |
| `- Error: <details>` | Provider error | Address per the message |

---

## Provider matrix

`forge.yaml`'s `data.providers` setting routes symbols / intervals to specific providers (the `alpha-forge` bundled implementations).

| Provider | Main asset coverage | Auth | Period limit (rough) | Intervals (rough) |
|----------|-------------------|------|----------------------|-------------------|
| **yfinance** | Stocks / ETFs / FX / Futures | None | `max` (decades for `1d`); `1h` ≈ 2 years; `5m` ≈ 60 days | `1d`, `1h`, `30m`, `15m`, `5m`, `1m` |
| **moomoo** | Stocks / ETFs (US, HK, A-share) | Local OpenD connection required | Provider-specific | `1d`, `1h`, `5m`, etc. |
| **OANDA** | FX | API key required | Provider-specific | `1d`, `H1`, `M5`, etc. |
| **Dukascopy** | Long-history FX | None (CSV download) | Decades | `1d`, `1h`, `5m` |
| **tv_mcp** | Anything visible on TradingView (stocks, ETFs, FX, futures, crypto, etc.) | Requires TradingView Desktop launched with `--remote-debugging-port=9222` and a running MCP server | TradingView's own (decades on `1d`, 10+ years on `1h`) | TradingView interval names (`D`, `60`, `5`, etc.) — input is normalized internally |

### TradingView MCP provider (`tv_mcp`, issue #576)

`--provider tv_mcp` pulls OHLCV through an MCP server attached to TradingView Desktop. This is mainly useful when you need history beyond yfinance's ~5y limit.

- **Prerequisites**: launch TradingView Desktop with `--remote-debugging-port=9222`, then start `tradesdontlie/tradingview-mcp` or `oviniciusramosp/tradingview-mcp` (the vinicius fork) in a separate process.
- **Range sliding**: a single MCP request returns at most 500 bars; alpha-forge transparently slides the visible range and concatenates chunks (cap: `data.providers.tv_mcp.max_chunks`). `--period max` works.
- **Flavor**: `data_get_ohlcv` works on both flavors. For OHLCV-only use, the default `tradesdontlie` is sufficient.
- **`forge.yaml` example**:

```yaml
data:
  providers:
    stock_provider: tv_mcp     # use tv_mcp for stocks / ETFs
    fx_provider: tv_mcp        # also for FX
    enable_fallback: true      # fall back to yfinance on tv_mcp failure
    tv_mcp:
      endpoint: "node /opt/tv-mcp/server.js"
      flavor: tradesdontlie    # tradesdontlie is fine for OHLCV
      max_bars_per_call: 500   # MCP-side cap
      max_chunks: 200          # safeguard for range sliding
      timeout_seconds: 120
```

Examples:

```bash
# pass the endpoint via CLI
forge data fetch SPY --provider tv_mcp --mcp-server "node /opt/tv-mcp/server.js" --period max

# rely on forge.yaml (no --mcp-server needed)
forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d
```

#### Subcommand: `forge data tv-mcp check` (issue #674)

Verifies that the TV MCP data provider server is reachable. The `/explore-strategies` skill runs this automatically at the start of each run for goals where `exploration.data_provider_override.{stock|fx}: tv_mcp` is configured.

```bash
# Default (ping with symbol=BATS:SPY)
forge data tv-mcp check

# JSON output (for automation)
forge data tv-mcp check --json

# Different symbol (FX)
forge data tv-mcp check --symbol OANDA:USDJPY

# Pass the endpoint via CLI
forge data tv-mcp check --mcp-server "node /opt/tv-mcp/server.js"
```

| Option | Default | Description |
|--------|---------|-------------|
| `--mcp-server <command>` | `data.providers.tv_mcp.endpoint` from `forge.yaml` | MCP server command |
| `--symbol <symbol>` | `BATS:SPY` | Symbol used for the ping |
| `--json` | false | Output as JSON |

**Exit code**: `0` = session valid, `2` = endpoint missing / TV Desktop not running / MCP server connection failed. When `/explore-strategies` detects exit `2`, the loop is stopped and a "TV MCP auth error stop" line is appended to `<goal_dir>/explored_log.md` (no auto-launch / no retry).

### `auto` routing (issue #583, Phase 1.5e-δ)

Setting `stock_provider` / `fx_provider` to `auto` makes alpha-forge classify each symbol into an asset type and pick the provider through the new `auto_routing` table. Useful when a single `forge data fetch <SYM>` should choose different providers depending on the symbol.

```yaml
data:
  providers:
    stock_provider: auto
    fx_provider: auto
    auto_routing:
      stock: tv_mcp      # US / JP equities → TV MCP (long history)
      etf: tv_mcp
      fx: oanda          # FX → OANDA
      commodity: yfinance
      crypto: yfinance
      index: yfinance
    tv_mcp:
      endpoint: "node /opt/tv-mcp/server.js"
      flavor: tradesdontlie
    oanda:
      access_token: ${OANDA_ACCESS_TOKEN}
      account_id: ${OANDA_ACCOUNT_ID}
```

Asset-type classification is delegated to `alpha_forge.data.symbols.detect_asset_type`:

| Type | Example detection rule |
|------|------------------------|
| `fx` | `USDJPY=X` / `EUR/USD` / `USD_JPY` |
| `index` | `^GSPC`, `^VIX`, `^NDX` (leading `^`) |
| `commodity` | `GC=F`, `CL=F`, `SI=F` (trailing `=F`) |
| `crypto` | `BTC-USD`, `ETH-USDT`, `ADA-BTC` |
| `etf` | Matches the built-in known-ETF list (`SPY`, `QQQ`, etc.) |
| `stock` | Everything else |

If `auto_routing` has no entry for the resolved asset type, alpha-forge errors out explicitly (it does **not** silently fall back to `yfinance`).

### Symbol notation examples

| Asset type | Examples |
|------------|----------|
| US stocks / ETFs | `AAPL`, `SPY`, `QQQ`, `NVDA` |
| FX (yfinance) | `USDJPY=X`, `EURUSD=X` |
| FX (OANDA) | `USD_JPY`, `EUR_USD` |
| Futures (yfinance) | `CL=F` (oil), `GC=F` (gold), `SI=F` (silver) |
| TradingView MCP | TradingView's own notation (`AAPL`, `USDJPY`, `OANDA:EURUSD`, `COMEX:GC1!`, etc.) |

Provider-specific symbol notation is documented in `alpha-forge/src/alpha_forge/data/providers/<provider>.py`.

---

## Common behavior

- **Storage format**: Parquet (`config.data.storage_path / <SYMBOL>_<interval>.parquet`)
- **TTL cache**: `fetch` skips when within `config.data.cache_ttl_hours`. Use `--force` to bypass
- **Provider resolution**: `get_data_fetcher(symbol=..., config=config)` selects a provider per the `data.providers` setting in `forge.yaml`
- **`FORGE_CONFIG`**: Storage path and provider settings are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: `0` on success; `click.ClickException` returns `1`; argument errors return Click's `2`
- **Free plan limit**: On the Free plan, the fetch `end` is also capped at `2023-12-31`, and `forge data update` skips items whose stored end is on or after 2023-12-31. See [Freemium Limits](../guides/freemium-limits.md) for details.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/data.py`, the provider implementations under `alpha-forge/src/alpha_forge/data/providers/`, and provider notes in `alpha-forge/CLAUDE.md`. This page must be kept in sync when CLI arguments or providers change. -->
