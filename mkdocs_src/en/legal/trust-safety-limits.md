# Trust, Safety, and Limits

This page summarizes what to review before purchasing, registering, or using AlphaForge. The source-of-truth legal pages are [Disclaimers](disclaimers.md), [Privacy Policy](privacy.md), and [EULA](eula.md). This guide is a plain-language purchase checklist that links back to those pages.

## Local execution and data handling

AlphaForge CLI is designed around local execution. Backtest settings, optimization parameters, strategy data, trade history, positions, local files, and usage logs normally stay on your machine and are not sent to Alforge Labs servers.

If you configure external data providers or broker APIs, those integrations communicate with the providers you choose. You are responsible for securing and managing API keys and brokerage credentials.

## What is sent during license activation

During license activation, only information required for license verification is sent to the external license service. When you run `forge license activate`, the license key, instance name, activation timestamp, and related activation details are sent.

Backtest settings, API keys, trade history, and strategy data are not sent for license activation. See the [Privacy Policy](privacy.md) for details.

## Not financial advice

AlphaForge is developer software for strategy research, backtesting, and optimization. It is not financial advice, trading signals, managed investing, or brokerage service.

Backtests, optimization outputs, and simulation results are based on historical data or hypothetical assumptions and do not guarantee future outcomes. You are solely responsible for trading decisions, instrument selection, parameter settings, position sizing, and execution.

## Limits of backtesting

Backtests cannot fully reproduce live-market conditions. The following factors can materially change live results.

- Slippage, fees, and spreads
- Latency, liquidity, and partial fills
- Data quality, missing records, and timezone differences
- Overfitting and curve fitting
- Taxes, regulation, margin, and liquidation risk

Do not treat validation results as live-performance expectations. Combine walk-forward analysis, realistic cost settings, out-of-sample checks, and small-scale live validation before relying on a strategy.

## Plan limits

AlphaForge has four plans: **Free / Monthly / Annual / Lifetime**. The Free plan limits data fetch and evaluation dates to **2023-12-31** and caps optimization at **50 trials**.

Monthly / Annual / Lifetime are paid plans and can use the latest data with unlimited trials. For the affected commands, JSON output fields, and local verification workflow, see [Freemium Limits](../guides/freemium-limits.md).

## Related pages

- [Disclaimers](disclaimers.md)
- [Privacy Policy](privacy.md)
- [EULA](eula.md)
- [Freemium Limits](../guides/freemium-limits.md)
