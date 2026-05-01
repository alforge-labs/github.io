# AI Agent Users

For those who want to automate strategy exploration by combining Claude Code or other AI coding agents with AlphaForge.

AlphaForge is designed so that **all operations complete via CLI/JSON/YAML**, making it highly compatible with AI agents.

## Why AlphaForge Works Well with AI Agents

- AI agents can **generate, edit, and validate** strategy JSON files
- Backtest and optimization results return as **structured JSON**, enabling automated analysis
- Slash commands let you run the same workflow **idempotently, as many times as needed**
- Enables **autonomous overnight exploration** independent of human working hours

## Key Slash Commands (Claude Code)

| Command | Role |
|---------|------|
| `/explore-strategies` | Autonomous exploration of one untried indicator × symbol combination |
| `/explore-strategies-loop` | Continuous exploration until rate limit |
| `/analyze-exploration` | Aggregate all exploration logs and output next recommended candidates |
| `/grid-tune` | Exhaustive grid tuning of existing strategy + WFT validation |
| `/tune-live-strategies` | Drift analysis and re-tuning of live strategies |
| `/update-market-data` | Incremental update of historical data |

## Full Documentation

For the complete AI agent integration reference (recommended agent comparison, one-cycle example, loop operation notes), see:

→ **[AI Agent Integration (full details)](../ai-driven-forges.md)**
