# alpha-visualizer

**alpha-visualizer** is a standalone package that lets you explore AlphaForge (`forge`) backtest results in a web browser. It is distributed separately to keep the `forge` binary lean.

## Installation

```bash
uv tool install alpha-visualizer
```

Or with pip:

```bash
pip install alpha-visualizer
```

Verify the installation:

```bash
vis --version
```

## vis serve

Starts the web dashboard.

```bash
vis serve [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--forge-dir DIRECTORY` | `.` (current directory) | Directory containing forge's output DBs |
| `--host TEXT` | `127.0.0.1` | Host to bind to |
| `--port INTEGER` | `8000` | Port number |
| `--no-open` | — | Do not open the browser automatically |

### Basic usage

Run `vis serve` from the directory where `forge` is executed (the one containing `data/results/forge.db`).

```bash
# Run from your alpha-strategies directory
cd ~/dev/alpha-strategies
vis serve
```

The browser opens **http://127.0.0.1:8000** automatically. Press `Ctrl+C` to stop the server.

### Specifying forge-dir explicitly

```bash
# Point to your strategies directory
vis serve --forge-dir ~/dev/alpha-strategies

# Change port
vis serve --forge-dir ~/dev/alpha-strategies --port 9000

# Bind to all interfaces (for remote access)
vis serve --host 0.0.0.0 --port 8000

# Suppress automatic browser launch
vis serve --no-open
```

## Integration with forge

`vis serve` reads the same file structure that `forge` produces.

```
<forge-dir>/
├── data/
│   ├── results/
│   │   └── forge.db         ← backtest & optimization results DB
│   ├── strategies/
│   │   └── *.json           ← strategy JSON files
│   └── ideas/
│       └── ideas.json       ← idea list
```

Every `forge backtest run` or `forge optimize run` updates `forge.db`. Reload the dashboard to see the latest results.

## Dashboard screens

| Screen | Content |
|--------|---------|
| **Strategy List** | Registered strategies with latest backtest summary |
| **Strategy Detail** | Parameters, backtest results list, optimization history graph |
| **Backtest Detail** | Equity curve, IS/OOS graph, metric cards, trade table |
| **Compare** | Side-by-side comparison of multiple strategies |
| **WFO** | Walk-forward optimization window results |
| **Ideas** | Idea list (filterable by status) |

## Help

```bash
vis --help
vis serve --help
```
