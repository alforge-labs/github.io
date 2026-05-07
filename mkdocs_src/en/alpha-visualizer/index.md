# alpha-visualizer

**alpha-visualizer** is a standalone OSS package that visualizes AlphaForge (`forge`) backtest results in your web browser. It reads `forge.db` (SQLite) and strategy JSON files directly, so it works on hosts without `forge` installed.

![Browse view](assets/browse.png){ loading=lazy }

## What you can do

- Browse, search, and multi-select your strategy library
- Inspect equity / drawdown / trade history with benchmark metrics (alpha, beta, IR, correlation)
- Compare strategies side-by-side, including a Pearson correlation heatmap
- Visualize Walk-Forward composite equity and Grid optimization results
- Reconcile live trading against backtest with period-aligned diff
- Track exploration ideas with status and tag filters
- Toggle dark/light theme and Japanese/English UI
- Export CSV / PNG, share state via URL

## Documentation map

| Page | Contents |
|---|---|
| [Installation](installation.md) | uv / pip / from source — three installation paths |
| [Features](features.md) | Browse / Detail / Compare / Optimize / Live / Ideas walkthroughs |
| [Configuration](configuration.md) | CLI options, `forge.yaml`, data path resolution |
| [FAQ & Troubleshooting](faq.md) | Common issues and fixes |

## License & repository

- **License**: MIT
- **GitHub**: <https://github.com/alforge-labs/alpha-visualizer>
- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **Code of Conduct**: [Contributor Covenant v2.1](https://github.com/alforge-labs/alpha-visualizer/blob/main/CODE_OF_CONDUCT.en.md)

`forge` itself is commercial, but `alpha-visualizer` is developed independently as open source.
