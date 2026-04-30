# forge data

Fetch, update, and inspect historical market data. Pulls OHLCV from configured providers (yfinance / moomoo / OANDA / Dukascopy) and caches it locally as Parquet.

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
| `--period` | option | `1y` | Fetch period (e.g. `1y`, `5y`, `6m`, `30d`) |
| `--interval` | option | `1d` | Bar interval (e.g. `1d`, `1h`, `5m`) |
| `--watchlist` | option | - | Watchlist file (one symbol per line; lines starting with `#` are comments) |
| `--force` | flag | false | Force re-fetch regardless of TTL |

You must provide either `SYMBOL` or `--watchlist`.

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

### Symbol notation examples

| Asset type | Examples |
|------------|----------|
| US stocks / ETFs | `AAPL`, `SPY`, `QQQ`, `NVDA` |
| FX (yfinance) | `USDJPY=X`, `EURUSD=X` |
| FX (OANDA) | `USD_JPY`, `EUR_USD` |
| Futures (yfinance) | `CL=F` (oil), `GC=F` (gold), `SI=F` (silver) |

Provider-specific symbol notation is documented in `alpha-forge/src/alpha_forge/data/providers/<provider>.py`.

---

## Common behavior

- **Storage format**: Parquet (`config.data.storage_path / <SYMBOL>_<interval>.parquet`)
- **TTL cache**: `fetch` skips when within `config.data.cache_ttl_hours`. Use `--force` to bypass
- **Provider resolution**: `get_data_fetcher(symbol=..., config=config)` selects a provider per the `data.providers` setting in `forge.yaml`
- **`FORGE_CONFIG`**: Storage path and provider settings are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: `0` on success; `click.ClickException` returns `1`; argument errors return Click's `2`

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/data.py`, the provider implementations under `alpha-forge/src/alpha_forge/data/providers/`, and provider notes in `alpha-forge/CLAUDE.md`. This page must be kept in sync when CLI arguments or providers change. -->
