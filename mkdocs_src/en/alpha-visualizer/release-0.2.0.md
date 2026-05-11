---
title: alpha-visualizer v0.2.0 — Try the full web visualizer in one command
description: alpha-visualizer v0.2.0 is out. Highlights include a fully synthetic bundled sample dataset, a live-performance view, HMM regime overlays, and 14 CodeQL security fixes — designed to make first-run exploration painless.
---

# alpha-visualizer v0.2.0 — Try the full web visualizer in one command

> **Released**: May 11, 2026 / **Version**: v0.2.0 / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/0.2.0/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.2.0)

[alpha-visualizer](index.md) is a standalone OSS package that renders backtest results produced by `forge` in a web browser. v0.2.0 focuses on making **the very first run feel like a finished product** — you can see every screen end-to-end without producing any data of your own, alongside large security and quality improvements.

## Highlights

### 1. A fully synthetic sample dataset is now bundled (`--use-bundled-samples`)

Until v0.1.x, alpha-visualizer needed actual `forge` output to show anything meaningful — the screens were empty on a fresh install. From v0.2.0 onward, **a legally redistribution-free synthetic dataset ships inside the wheel**, so you can explore every feature with a single command:

```bash
pip install alpha-visualizer==0.2.0
vis serve --use-bundled-samples --no-open
# Open http://127.0.0.1:8000
```

The bundle contains 5 years (1250 business days) of synthetic OHLCV across 8 textbook strategies, producing **40 backtests + 2 WFO runs + 2 Grid search runs + 5 sample idea memos**.

| Symbol | Character | Strategy fit |
|---|---|---|
| `EQUITY_SYNTH` | 2008-style crash → recovery → mild correction | Trend-following strategies shine |
| `INDEX_SYNTH` | Long calm → 2020-style V-shaped recovery | Composite filter strategies work well |
| `COMMODITY_SYNTH` | Sideways → spike → blow-off → slow bleed | Breakout strategies dominate |
| `FX_SYNTH` | Mean-reverting throughout (AR(1)) | Reversion strategies prevail |
| `CRYPTO_SYNTH` | Bubble → crash × 2 + flash crash → recovery | Trend-following + breakout |

The strategy × symbol compatibility matrix is intentionally distributed so that the Browse table sort/filter, the Compare heatmap, and the WFO IS/OOS stability chart all look meaningful out of the box.

Prices are synthesized from Geometric Brownian Motion + Poisson jumps + AR(1). All symbol names carry the `_SYNTH` suffix so they cannot be confused with real tickers. The regeneration script `samples/build_samples.py` is deterministic, and CI runs `git diff --exit-code` on every PR to keep the bundle byte-identical.

> The bundled strategies are **textbook indicator combinations only** — SMA / RSI / MACD / Bollinger / ADX / Donchian. Proprietary differentiators in `forge` itself, such as HMM regime detection and MTF-optimized parameters, are intentionally excluded.

### 2. Live-performance view (Detail screen)

A new **Live tab** on the Detail screen reads `data/live/` summaries and trades and renders a period-aligned diff against the corresponding backtest (#57). If your backtest looked great but the live deployment is bleeding edge, the divergence shows up immediately. Period misalignment is normalized automatically.

### 3. HMM / regime overlays on the equity chart

The Equity Chart can now render **HMM states (high-vol / mid-vol / low-vol, etc.) as color bands behind the equity curve** (#56). The Risk tab gained a per-regime summary card too, breaking down trade counts, win rate, and average return for each regime in a single view. This pairs especially well with `forge`-side strategies that infer HMM regimes.

### 4. Security and quality lift

- **14 CodeQL alerts resolved** (#175): path-injection, log-injection, and SSRF detectors all clear.
- Distinguished "resource not found (404)" from "DB failure (500)" — responses on `optimization_runs` table absence or SQLAlchemy `OperationalError` now correctly return 500 instead of masquerading as 404 (#106).
- Fixed Browse-screen crash on strategies with `latest_*` fields undefined (#23).
- Caught up with `forge`'s default DB filename change to `backtest_results.db` (#177).
- Non-finite `best_metric` values are now returned as `null` and rendered as `—` in the UI (#172).

### 5. CI and developer experience

- **Lighthouse CI** continuously measures Performance / Accessibility / Best-Practices on every PR (#136, #162).
- **E2E fixture drift check** and **OSS sample-forge drift check** enforce that test fixtures and the bundled sample regenerate byte-identically — drift fails the PR (#161, #178).
- Major frontend dependencies bumped to React 19, react-router-dom 7, Storybook 10, Vite 8, etc.

## Upgrading

The package is on PyPI now:

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest         # add to a project
uv tool install alpha-visualizer        # install as a CLI tool
```

The easiest sanity check is `--use-bundled-samples`. To point at your own forge project, use the existing flag:

```bash
vis serve --forge-dir /path/to/your/alpha-strategies
```

No `forge.yaml` schema changes — existing forge projects continue to work unchanged.

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.2.0/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.2.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Installation guide**: [alpha-visualizer / Installation](installation.md)
- **Features**: [alpha-visualizer / Features](features.md)
- **Configuration**: [alpha-visualizer / Configuration](configuration.md)

Please report bugs and feature requests through [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
