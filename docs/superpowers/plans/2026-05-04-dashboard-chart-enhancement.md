---
render_with_liquid: false
---
# ダッシュボード可視化強化 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** alpha-forge ダッシュボードに6つの新チャートを追加し、タブを再編成してUXを改善する。

**Architecture:** ハイブリッド型（アプローチC）。バックエンド（alpha-forge）に `daily_returns`・`buy_hold_equity` の2フィールドを追加し、ローリングSharpe等の計算はフロントエンド（visualizer）で行う。状態管理は React Context API、チャートはカスタムSVGで実装。

**Tech Stack:** Python/FastAPI（バックエンド）、React 19 + TypeScript + Vite（フロントエンド）、pytest（バックエンドテスト）、`uv run tsc --noEmit`（フロントエンド型チェック）

**作業ディレクトリ:** `alpha-forge/` でバックエンド、`alpha-forge/visualizer/` でフロントエンド

---

## ファイルマップ

### 新規作成
| ファイル | 役割 |
|---|---|
| `visualizer/src/contexts/DashboardContext.tsx` | 期間選択・クロスハイライトのグローバル状態 |
| `visualizer/src/constants/metricDefinitions.ts` | ツールチップ用指標定義 |
| `visualizer/src/components/MetricsSummaryBar.tsx` | 固定ヘッダー（Sharpe/CAGR/MDD等） |
| `visualizer/src/components/charts/BenchmarkChart.tsx` | 戦略vsベンチマーク折れ線 |
| `visualizer/src/components/charts/RollingMetricsChart.tsx` | ローリングSharpe時系列 |
| `visualizer/src/components/charts/ReturnDistributionChart.tsx` | 日次リターン分布ヒストグラム |
| `visualizer/src/components/charts/WeekdayPerformanceChart.tsx` | 曜日別平均リターン棒グラフ |
| `visualizer/src/components/charts/DrawdownDetailChart.tsx` | ドローダウンTOP5横棒グラフ |
| `visualizer/src/components/charts/VaRChart.tsx` | VaR/CVaRテール可視化 |

### 変更
| ファイル | 変更内容 |
|---|---|
| `src/alpha_forge/backtest/report.py` | buy_hold_curve を DB 保存に追加 |
| `src/alpha_forge/dashboard/routers/results.py` | daily_returns・buy_hold_equity を返す |
| `tests/test_dashboard/test_results.py` | 新フィールドのテスト追加 |
| `visualizer/src/api/types.ts` | BacktestDetail・BacktestMetrics 型拡張 |
| `visualizer/src/screens/BacktestScreen.tsx` | タブ再編成・Provider・MetricsSummaryBar |
| `visualizer/src/components/metrics/MetricsGrid.tsx` | ツールチップ追加 |
| `visualizer/src/components/charts/EquityChart.tsx` | highlightedDateRange 受信 |
| `visualizer/src/components/charts/MAEMFEScatter.tsx` | クロスハイライト連動 |
| `visualizer/src/screens/CompareScreen.tsx` | エクイティ重ね合わせ・分布比較 |

---

## Task 1: バックエンド — daily_returns をAPIレスポンスに追加

**Files:**
- Modify: `alpha-forge/src/alpha_forge/dashboard/routers/results.py`
- Test: `alpha-forge/tests/test_dashboard/test_results.py`

- [ ] **Step 1: 失敗するテストを書く**

`tests/test_dashboard/test_results.py` の `TestResultsDetailEndpoint` クラスに追記：

```python
def test_daily_returns_フィールドが返る(self, tmp_path: Path) -> None:
    from alpha_forge.backtest.db_repository import SQLiteBacktestResultRepository
    app, config = _make_app(tmp_path)
    db_path = config.report.output_path / config.report.db_filename
    db_path.parent.mkdir(parents=True, exist_ok=True)
    repo = SQLiteBacktestResultRepository(db_path)
    run_id = repo.save({
        "strategy_id": "s1",
        "symbol": "AAPL",
        "run_at": "2026-05-04T00:00:00+00:00",
        "metrics": {"sharpe_ratio": 1.0, "total_return_pct": 10.0,
                    "max_drawdown_pct": -5.0, "total_trades": 5},
        "equity_curve": [
            {"date": "2024-01-01", "value": 100.0},
            {"date": "2024-01-02", "value": 102.0},
            {"date": "2024-01-03", "value": 101.0},
        ],
    })
    client = TestClient(app)
    data = client.get(f"/api/results/{run_id}").json()
    assert "daily_returns" in data
    assert len(data["daily_returns"]) == 2          # equity 3点 → returns 2点
    assert abs(data["daily_returns"][0] - 2.0) < 0.01   # (102-100)/100*100 = 2.0
    assert abs(data["daily_returns"][1] - (-0.98)) < 0.01  # (101-102)/102*100 ≈ -0.98
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
uv run pytest tests/test_dashboard/test_results.py::TestResultsDetailEndpoint::test_daily_returns_フィールドが返る -v
```

期待: `FAILED` — `assert "daily_returns" in data`

- [ ] **Step 3: ヘルパー関数と _shape_detail() への追加を実装**

`src/alpha_forge/dashboard/routers/results.py` の `_compute_drawdown()` 関数の後に追加：

```python
def _compute_daily_returns(values: list[float]) -> list[float]:
    if len(values) < 2:
        return []
    return [
        round((values[i] - values[i - 1]) / values[i - 1] * 100.0, 6)
        if values[i - 1] != 0.0
        else 0.0
        for i in range(1, len(values))
    ]
```

`_shape_detail()` の `return {` ブロックに `"daily_returns": _compute_daily_returns(values),` を追加（`"drawdown": drawdown,` の次の行）。

- [ ] **Step 4: テストを実行してパスを確認**

```bash
uv run pytest tests/test_dashboard/test_results.py::TestResultsDetailEndpoint::test_daily_returns_フィールドが返る -v
```

期待: `PASSED`

- [ ] **Step 5: 既存テストが壊れていないことを確認**

```bash
uv run pytest tests/test_dashboard/test_results.py -v
```

全テスト `PASSED`

- [ ] **Step 6: コミット**

```bash
git add src/alpha_forge/dashboard/routers/results.py tests/test_dashboard/test_results.py
git commit -m "feat: APIレスポンスに daily_returns フィールドを追加"
```

---

## Task 2: バックエンド — buy_hold_equity をDB保存・APIで返す

**Files:**
- Modify: `alpha-forge/src/alpha_forge/backtest/report.py`
- Modify: `alpha-forge/src/alpha_forge/dashboard/routers/results.py`
- Test: `alpha-forge/tests/test_dashboard/test_results.py`

- [ ] **Step 1: 失敗するテストを書く**

`tests/test_dashboard/test_results.py` に追加（`_save_result()` を拡張して `buy_hold_curve` を保存できるようにする）：

```python
def test_buy_hold_equity_フィールドが返る(self, tmp_path: Path) -> None:
    from alpha_forge.backtest.db_repository import SQLiteBacktestResultRepository
    app, config = _make_app(tmp_path)
    db_path = config.report.output_path / config.report.db_filename
    db_path.parent.mkdir(parents=True, exist_ok=True)
    repo = SQLiteBacktestResultRepository(db_path)
    run_id = repo.save({
        "strategy_id": "s1",
        "symbol": "AAPL",
        "run_at": "2026-05-04T00:00:00+00:00",
        "metrics": {"sharpe_ratio": 1.0, "total_return_pct": 10.0,
                    "max_drawdown_pct": -5.0, "total_trades": 5},
        "equity_curve": [
            {"date": "2024-01-01", "value": 100.0},
            {"date": "2024-12-31", "value": 110.0},
        ],
        "buy_hold_curve": [
            {"date": "2024-01-01", "value": 150.0},
            {"date": "2024-12-31", "value": 165.0},
        ],
    })
    client = TestClient(app)
    data = client.get(f"/api/results/{run_id}").json()
    assert "buy_hold_equity" in data
    assert len(data["buy_hold_equity"]) == 2
    assert abs(data["buy_hold_equity"][0] - 100.0) < 0.01   # 正規化: 150/150*100
    assert abs(data["buy_hold_equity"][1] - 110.0) < 0.01   # 165/150*100
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
uv run pytest tests/test_dashboard/test_results.py::TestResultsDetailEndpoint::test_buy_hold_equity_フィールドが返る -v
```

期待: `FAILED`

- [ ] **Step 3: results.py にヘルパーと _shape_detail() への追加を実装**

`_compute_daily_returns()` の後に追加：

```python
def _compute_buy_hold_equity(record: dict[str, Any]) -> list[float]:
    raw = record.get("buy_hold_curve")
    if not raw or not isinstance(raw, list):
        return []
    if isinstance(raw[0], dict):
        vals = [float(item.get("value", 0.0)) for item in raw]
    else:
        vals = [float(v) for v in raw]
    if not vals or vals[0] == 0.0:
        return []
    base = vals[0]
    return [round(v / base * 100.0, 4) for v in vals]
```

`_shape_detail()` の `return {` ブロックに追加：

```python
"buy_hold_equity": _compute_buy_hold_equity(record),
```

- [ ] **Step 4: report.py に buy_hold_curve の保存を追加**

`report.py` のエクイティカーブ抽出ブロック（`equity_curve = ...` の後）に追加：

```python
# Buy&Hold エクイティカーブの計算（portfolio.close から原資産価格を使用）
buy_hold_curve = None
if portfolio is not None and self.config.include_equity_curve:
    try:
        close = portfolio.close
        if close is not None and len(close) > 0:
            init_cash = float(portfolio.init_cash)
            init_price = float(close.iloc[0])
            if init_price != 0.0:
                buy_hold_curve = [
                    {
                        "date": str(idx.date()),
                        "value": round(float(v / init_price * init_cash), 4),
                    }
                    for idx, v in close.items()
                ]
                report_data["buy_hold_curve"] = buy_hold_curve
    except Exception:
        pass  # buy_hold計算失敗はバックテスト結果を妨げない
```

`repo.save(...)` の辞書に `"buy_hold_curve": buy_hold_curve,` を追加。

- [ ] **Step 5: テストを実行してパスを確認**

```bash
uv run pytest tests/test_dashboard/test_results.py -v
```

全テスト `PASSED`

- [ ] **Step 6: コミット**

```bash
git add src/alpha_forge/backtest/report.py src/alpha_forge/dashboard/routers/results.py tests/test_dashboard/test_results.py
git commit -m "feat: buy_hold_equity をDB保存・APIレスポンスに追加"
```

---

## Task 3: フロントエンド型定義の更新

**Files:**
- Modify: `alpha-forge/visualizer/src/api/types.ts`

- [ ] **Step 1: BacktestDetail と BacktestMetrics を拡張**

`visualizer/src/api/types.ts` の `BacktestMetrics` に追加：

```typescript
  skewness?: number
  excess_kurtosis?: number
```

`BacktestDetail` の `equity` フィールドを変更：

```typescript
  equity: { dates: string[]; values: number[]; benchmark?: number[] }
  daily_returns: number[]
  buy_hold_equity: number[]
```

`deflated_sharpe` の型を拡張：

```typescript
  deflated_sharpe?: {
    probabilistic_sr: number
    deflated_sr: number
    n_trials: number
    skewness?: number
    excess_kurtosis?: number
  }
```

- [ ] **Step 2: 型チェックを実行**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer
npx tsc --noEmit
```

期待: エラーなし

- [ ] **Step 3: コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/api/types.ts
git commit -m "feat: BacktestDetail に daily_returns・buy_hold_equity 型を追加"
```

---

## Task 4: DashboardContext の実装

**Files:**
- Create: `alpha-forge/visualizer/src/contexts/DashboardContext.tsx`

- [ ] **Step 1: DashboardContext を作成**

```tsx
import { createContext, useContext, useState } from 'react'

export const RANGES = ['1M', '3M', '6M', '1Y', '2Y', 'ALL'] as const
export type SelectedRange = (typeof RANGES)[number]

export const RANGE_N: Record<SelectedRange, number> = {
  '1M': 21, '3M': 63, '6M': 126, '1Y': 252, '2Y': 504, ALL: Number.POSITIVE_INFINITY,
}

interface DateRange { start: string; end: string }

interface DashboardContextValue {
  selectedRange: SelectedRange
  setSelectedRange: (r: SelectedRange) => void
  highlightedTradeId: string | null
  setHighlightedTradeId: (id: string | null) => void
  highlightedDateRange: DateRange | null
  setHighlightedDateRange: (r: DateRange | null) => void
}

const DashboardContext = createContext<DashboardContextValue | null>(null)

export function DashboardProvider({ children }: { children: React.ReactNode }) {
  const [selectedRange, setSelectedRange] = useState<SelectedRange>('ALL')
  const [highlightedTradeId, setHighlightedTradeId] = useState<string | null>(null)
  const [highlightedDateRange, setHighlightedDateRange] = useState<DateRange | null>(null)

  return (
    <DashboardContext.Provider value={{
      selectedRange, setSelectedRange,
      highlightedTradeId, setHighlightedTradeId,
      highlightedDateRange, setHighlightedDateRange,
    }}>
      {children}
    </DashboardContext.Provider>
  )
}

export function useDashboard(): DashboardContextValue {
  const ctx = useContext(DashboardContext)
  if (!ctx) throw new Error('useDashboard must be used within DashboardProvider')
  return ctx
}
```

- [ ] **Step 2: 型チェック**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer
npx tsc --noEmit
```

- [ ] **Step 3: コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/contexts/DashboardContext.tsx
git commit -m "feat: DashboardContext で期間選択・クロスハイライト状態を管理"
```

---

## Task 5: metricDefinitions と MetricsSummaryBar

**Files:**
- Create: `alpha-forge/visualizer/src/constants/metricDefinitions.ts`
- Create: `alpha-forge/visualizer/src/components/MetricsSummaryBar.tsx`

- [ ] **Step 1: metricDefinitions.ts を作成**

```typescript
export interface MetricDef {
  label: string
  labelEn: string
  description: string
  descriptionEn: string
  formula?: string
}

export const METRIC_DEFINITIONS: Record<string, MetricDef> = {
  sharpe_ratio: {
    label: 'Sharpe Ratio',
    labelEn: 'Sharpe Ratio',
    description: 'リスク調整後リターン。超過リターンをリターンの標準偏差で割った値。1.0以上が目安。',
    descriptionEn: 'Risk-adjusted return. Excess return divided by return std dev. Above 1.0 is good.',
    formula: '(Rp − Rf) / σp × √252',
  },
  cagr_pct: {
    label: 'CAGR',
    labelEn: 'CAGR',
    description: '年率換算リターン（複利）。',
    descriptionEn: 'Compound Annual Growth Rate.',
    formula: '(最終値 / 初期値)^(1/年数) − 1',
  },
  max_drawdown_pct: {
    label: 'Max DD',
    labelEn: 'Max DD',
    description: '最大ドローダウン。ピークからの最大下落率。',
    descriptionEn: 'Maximum peak-to-trough decline.',
  },
  win_rate_pct: {
    label: 'Win%',
    labelEn: 'Win%',
    description: '勝率。プラスで終了したトレードの割合。',
    descriptionEn: 'Percentage of profitable trades.',
  },
  profit_factor: {
    label: 'PF',
    labelEn: 'PF',
    description: 'プロフィットファクター。総利益 / 総損失。1.0超が必要条件。',
    descriptionEn: 'Gross profit / gross loss. Must be above 1.0.',
  },
  total_trades: {
    label: 'Trades',
    labelEn: 'Trades',
    description: '総トレード数。',
    descriptionEn: 'Total number of trades.',
  },
}
```

- [ ] **Step 2: MetricsSummaryBar.tsx を作成**

```tsx
import { useState } from 'react'
import type { BacktestMetrics } from '../api/types'
import type { Lang } from '../i18n/strings'
import { makeL } from '../i18n/strings'
import { METRIC_DEFINITIONS } from '../constants/metricDefinitions'

interface Props {
  metrics: BacktestMetrics
  lang: Lang
}

interface TooltipState { key: string; x: number; y: number }

export function MetricsSummaryBar({ metrics, lang }: Props) {
  const [tip, setTip] = useState<TooltipState | null>(null)
  const L = makeL(lang)

  const items: { key: keyof BacktestMetrics; suffix: string; decimals: number }[] = [
    { key: 'sharpe_ratio', suffix: '', decimals: 2 },
    { key: 'cagr_pct', suffix: '%', decimals: 1 },
    { key: 'max_drawdown_pct', suffix: '%', decimals: 1 },
    { key: 'win_rate_pct', suffix: '%', decimals: 1 },
    { key: 'profit_factor', suffix: '', decimals: 2 },
    { key: 'total_trades', suffix: '', decimals: 0 },
  ]

  return (
    <div style={{
      display: 'flex', gap: 8, flexWrap: 'wrap', padding: '8px 0 16px',
      borderBottom: '1px solid var(--border)', marginBottom: 16, position: 'relative',
    }}>
      {items.map(({ key, suffix, decimals }) => {
        const def = METRIC_DEFINITIONS[key]
        const val = metrics[key] as number | undefined
        const display = val == null ? '—' : val.toFixed(decimals) + suffix
        return (
          <div key={key} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'flex-start',
            background: 'var(--surface)', borderRadius: 6, padding: '6px 12px',
            border: '1px solid var(--border)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text3)' }}>
                {L(def?.label ?? key, def?.labelEn ?? key)}
              </span>
              <span
                style={{ fontSize: 10, color: 'var(--text3)', cursor: 'pointer', opacity: 0.6 }}
                onMouseEnter={e => {
                  const rect = (e.target as HTMLElement).getBoundingClientRect()
                  setTip({ key, x: rect.left, y: rect.bottom + 4 })
                }}
                onMouseLeave={() => setTip(null)}
              >ⓘ</span>
            </div>
            <span style={{ fontFamily: 'var(--mono)', fontSize: 15, color: 'var(--text)', fontWeight: 600 }}>
              {display}
            </span>
          </div>
        )
      })}
      {tip && (() => {
        const def = METRIC_DEFINITIONS[tip.key]
        if (!def) return null
        return (
          <div style={{
            position: 'fixed', left: tip.x, top: tip.y, zIndex: 100,
            background: 'var(--surface)', border: '1px solid var(--border)',
            borderRadius: 6, padding: '8px 12px', maxWidth: 280,
            boxShadow: '0 4px 16px rgba(0,0,0,0.4)',
          }}>
            <div style={{ fontSize: 11, color: 'var(--text)', marginBottom: 4 }}>
              {L(def.description, def.descriptionEn)}
            </div>
            {def.formula && (
              <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--text3)' }}>
                {def.formula}
              </div>
            )}
          </div>
        )
      })()}
    </div>
  )
}
```

- [ ] **Step 3: 型チェック**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
```

- [ ] **Step 4: コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/constants/metricDefinitions.ts visualizer/src/components/MetricsSummaryBar.tsx
git commit -m "feat: MetricsSummaryBar とメトリクスツールチップ定義を追加"
```

---

## Task 6: BenchmarkChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/BenchmarkChart.tsx`

- [ ] **Step 1: BenchmarkChart.tsx を作成**

```tsx
import { useMemo, useState } from 'react'
import { useDashboard, RANGES, RANGE_N } from '../../contexts/DashboardContext'
import type { Lang } from '../../i18n/strings'
import { makeL } from '../../i18n/strings'

export interface EquityDataset {
  label: string
  values: number[]
  dates: string[]
  color: string
}

interface Props {
  datasets: EquityDataset[]
  compact?: boolean
  lang: Lang
}

interface Tooltip { x: number; y: number; date: string; vals: { label: string; v: number; color: string }[] }

export function BenchmarkChart({ datasets, compact = false, lang }: Props) {
  const { selectedRange, setSelectedRange } = useDashboard()
  const [tooltip, setTooltip] = useState<Tooltip | null>(null)
  const L = makeL(lang)

  const W = 800, H = compact ? 180 : 252
  const P = { l: 58, r: 20, t: 16, b: compact ? 24 : 32 }
  const pW = W - P.l - P.r
  const pH = H - P.t - P.b

  const sliced = useMemo(() => {
    if (datasets.length === 0) return []
    const n = datasets[0].values.length
    const bars = Math.min(RANGE_N[selectedRange], n)
    const s = Math.max(0, n - bars)
    return datasets.map(ds => {
      const vals = ds.values.slice(s)
      const base = vals[0] ?? 1
      return { ...ds, values: vals.map(v => (base === 0 ? 0 : (v / base) * 100)), dates: ds.dates.slice(s) }
    })
  }, [datasets, selectedRange])

  const allVals = sliced.flatMap(ds => ds.values).filter(Number.isFinite)
  const minV = Math.min(...allVals, 95)
  const maxV = Math.max(...allVals, 105)
  const span = maxV - minV || 1

  function toX(i: number, len: number) { return P.l + (i / Math.max(len - 1, 1)) * pW }
  function toY(v: number) { return P.t + pH - ((v - minV) / span) * pH }

  function makePath(vals: number[]) {
    return vals.map((v, i) => `${i === 0 ? 'M' : 'L'}${toX(i, vals.length).toFixed(1)},${toY(v).toFixed(1)}`).join(' ')
  }

  const dates = sliced[0]?.dates ?? []
  const len = sliced[0]?.values.length ?? 0

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 4, marginBottom: 6 }}>
        {RANGES.map(r => (
          <button key={r} onClick={() => setSelectedRange(r)} style={{
            height: 22, padding: '0 8px', borderRadius: 4, cursor: 'pointer',
            fontFamily: 'var(--mono)', fontSize: 11,
            background: selectedRange === r ? 'var(--accent-bg)' : 'var(--surface)',
            border: selectedRange === r ? '1px solid var(--accent-glow)' : '1px solid var(--border)',
            color: selectedRange === r ? 'var(--accent)' : 'var(--text2)',
          }}>{r}</button>
        ))}
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', display: 'block' }}
        onMouseMove={e => {
          const rect = (e.currentTarget as SVGElement).getBoundingClientRect()
          const mx = (e.clientX - rect.left) * (W / rect.width)
          const i = Math.round(((mx - P.l) / pW) * Math.max(len - 1, 1))
          const ci = Math.max(0, Math.min(len - 1, i))
          setTooltip({
            x: toX(ci, len), y: P.t,
            date: dates[ci] ?? '',
            vals: sliced.map(ds => ({ label: ds.label, v: ds.values[ci] ?? 0, color: ds.color })),
          })
        }}
        onMouseLeave={() => setTooltip(null)}
      >
        {/* Y軸グリッド */}
        {[0, 0.25, 0.5, 0.75, 1].map(t => {
          const yv = minV + t * span
          const y = toY(yv)
          return (
            <g key={t}>
              <line x1={P.l} x2={P.l + pW} y1={y} y2={y} stroke="var(--border)" strokeWidth={0.5} />
              <text x={P.l - 4} y={y + 4} textAnchor="end" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">
                {yv.toFixed(0)}
              </text>
            </g>
          )
        })}
        {/* 100ライン */}
        <line x1={P.l} x2={P.l + pW} y1={toY(100)} y2={toY(100)} stroke="var(--text3)" strokeWidth={0.5} strokeDasharray="4,4" />
        {/* データ系列 */}
        {sliced.map(ds => (
          <path key={ds.label} d={makePath(ds.values)} fill="none" stroke={ds.color} strokeWidth={1.5} />
        ))}
        {/* ツールチップ縦線 */}
        {tooltip && <line x1={tooltip.x} x2={tooltip.x} y1={P.t} y2={P.t + pH} stroke="var(--text3)" strokeWidth={0.5} />}
        {/* X軸ラベル */}
        {len > 1 && [0, Math.floor(len / 2), len - 1].map(i => (
          <text key={i} x={toX(i, len)} y={H - 4} textAnchor="middle" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">
            {(dates[i] ?? '').slice(0, 7)}
          </text>
        ))}
      </svg>
      {/* 凡例 */}
      <div style={{ display: 'flex', gap: 16, marginTop: 4 }}>
        {sliced.map(ds => (
          <div key={ds.label} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <div style={{ width: 16, height: 2, background: ds.color }} />
            <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text2)' }}>{ds.label}</span>
          </div>
        ))}
      </div>
      {/* ツールチップ */}
      {tooltip && (
        <div style={{
          position: 'absolute', background: 'var(--surface)', border: '1px solid var(--border)',
          borderRadius: 4, padding: '6px 10px', pointerEvents: 'none', fontSize: 11,
          fontFamily: 'var(--mono)', color: 'var(--text)',
        }}>
          <div style={{ color: 'var(--text3)', marginBottom: 4 }}>{tooltip.date}</div>
          {tooltip.vals.map(v => (
            <div key={v.label} style={{ color: v.color }}>{v.label}: {v.v.toFixed(2)}</div>
          ))}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: 型チェック**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
```

- [ ] **Step 3: コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/BenchmarkChart.tsx
git commit -m "feat: BenchmarkChart コンポーネントを追加"
```

---

## Task 7: RollingMetricsChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/RollingMetricsChart.tsx`

- [ ] **Step 1: RollingMetricsChart.tsx を作成**

```tsx
import { useMemo, useState } from 'react'
import { useDashboard, RANGE_N } from '../../contexts/DashboardContext'

interface Props {
  dailyReturns: number[]
  dates: string[]
  compact?: boolean
}

const WINDOWS = [30, 60, 90] as const
type Window = (typeof WINDOWS)[number]

function computeRollingSharpe(returns: number[], window: number): (number | null)[] {
  const result: (number | null)[] = new Array(returns.length).fill(null)
  for (let i = window - 1; i < returns.length; i++) {
    const slice = returns.slice(i - window + 1, i + 1)
    const mean = slice.reduce((a, b) => a + b, 0) / window
    const variance = slice.reduce((a, b) => a + (b - mean) ** 2, 0) / (window - 1)
    const std = Math.sqrt(variance)
    result[i] = std === 0 ? 0 : (mean / std) * Math.sqrt(252)
  }
  return result
}

export function RollingMetricsChart({ dailyReturns, dates, compact = false }: Props) {
  const { selectedRange } = useDashboard()
  const [window, setWindow] = useState<Window>(60)
  const [tooltip, setTooltip] = useState<{ x: number; v: number; date: string } | null>(null)

  const W = 800, H = compact ? 160 : 220
  const P = { l: 58, r: 20, t: 16, b: compact ? 24 : 32 }
  const pW = W - P.l - P.r
  const pH = H - P.t - P.b

  const { slicedSharpe, slicedDates } = useMemo(() => {
    const n = dailyReturns.length
    const bars = Math.min(RANGE_N[selectedRange], n)
    const s = Math.max(0, n - bars)
    const sharpe = computeRollingSharpe(dailyReturns, window)
    return {
      slicedSharpe: sharpe.slice(s),
      slicedDates: dates.slice(s + 1),  // daily_returns は dates より1短い
    }
  }, [dailyReturns, dates, selectedRange, window])

  const valid = slicedSharpe.filter((v): v is number => v !== null)
  const minV = Math.min(...valid, -1)
  const maxV = Math.max(...valid, 1)
  const span = maxV - minV || 1
  const len = slicedSharpe.length

  function toX(i: number) { return P.l + (i / Math.max(len - 1, 1)) * pW }
  function toY(v: number) { return P.t + pH - ((v - minV) / span) * pH }
  function toY0() { return toY(Math.max(minV, Math.min(0, maxV))) }

  const pathD = slicedSharpe.reduce<string>((acc, v, i) => {
    if (v === null) return acc
    return acc + (acc === '' ? 'M' : 'L') + `${toX(i).toFixed(1)},${toY(v).toFixed(1)}`
  }, '')

  return (
    <div>
      <div style={{ display: 'flex', gap: 4, marginBottom: 6 }}>
        {WINDOWS.map(w => (
          <button key={w} onClick={() => setWindow(w)} style={{
            height: 22, padding: '0 8px', borderRadius: 4, cursor: 'pointer',
            fontFamily: 'var(--mono)', fontSize: 11,
            background: window === w ? 'var(--accent-bg)' : 'var(--surface)',
            border: window === w ? '1px solid var(--accent-glow)' : '1px solid var(--border)',
            color: window === w ? 'var(--accent)' : 'var(--text2)',
          }}>{w}d</button>
        ))}
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', display: 'block' }}
        onMouseMove={e => {
          const rect = (e.currentTarget as SVGElement).getBoundingClientRect()
          const mx = (e.clientX - rect.left) * (W / rect.width)
          const i = Math.round(((mx - P.l) / pW) * Math.max(len - 1, 1))
          const ci = Math.max(0, Math.min(len - 1, i))
          const v = slicedSharpe[ci]
          if (v !== null) setTooltip({ x: toX(ci), v, date: slicedDates[ci] ?? '' })
        }}
        onMouseLeave={() => setTooltip(null)}
      >
        {/* グリッドと0ライン */}
        {[-2, -1, 0, 1, 2].filter(v => v >= minV - 0.1 && v <= maxV + 0.1).map(v => (
          <g key={v}>
            <line x1={P.l} x2={P.l + pW} y1={toY(v)} y2={toY(v)}
              stroke={v === 0 ? 'var(--text3)' : 'var(--border)'}
              strokeWidth={v === 0 ? 1 : 0.5}
              strokeDasharray={v === 0 ? undefined : '3,3'} />
            <text x={P.l - 4} y={toY(v) + 4} textAnchor="end" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">{v}</text>
          </g>
        ))}
        {/* 0ライン以上を緑、以下を赤で塗りつぶし */}
        <path d={pathD} fill="none" stroke="#00e49a" strokeWidth={1.5} />
        {tooltip && <line x1={tooltip.x} x2={tooltip.x} y1={P.t} y2={P.t + pH} stroke="var(--text3)" strokeWidth={0.5} />}
        {len > 1 && [0, Math.floor(len / 2), len - 1].map(i => (
          <text key={i} x={toX(i)} y={H - 4} textAnchor="middle" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">
            {(slicedDates[i] ?? '').slice(0, 7)}
          </text>
        ))}
      </svg>
      {tooltip && (
        <div style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text)', marginTop: 4 }}>
          {tooltip.date} — Sharpe({window}d): <span style={{ color: tooltip.v >= 0 ? '#00e49a' : '#ff5c5c' }}>{tooltip.v.toFixed(3)}</span>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/RollingMetricsChart.tsx
git commit -m "feat: RollingMetricsChart（ローリングSharpe）を追加"
```

---

## Task 8: ReturnDistributionChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/ReturnDistributionChart.tsx`

- [ ] **Step 1: ReturnDistributionChart.tsx を作成**

```tsx
import { useMemo, useState } from 'react'
import { useDashboard, RANGE_N } from '../../contexts/DashboardContext'

export interface ReturnDataset {
  label: string
  returns: number[]
  color: string
}

interface Props {
  datasets: ReturnDataset[]
  var95?: number
  skewness?: number
  excessKurtosis?: number
  compact?: boolean
}

function computeHistogram(returns: number[], bins = 40): { x: number; count: number; width: number }[] {
  if (returns.length === 0) return []
  const min = Math.min(...returns)
  const max = Math.max(...returns)
  const width = (max - min) / bins || 0.01
  const counts = new Array(bins).fill(0)
  for (const r of returns) {
    const idx = Math.min(Math.floor((r - min) / width), bins - 1)
    counts[idx]++
  }
  return counts.map((count, i) => ({ x: min + (i + 0.5) * width, count, width }))
}

function normalPdf(x: number, mean: number, std: number): number {
  if (std === 0) return 0
  return Math.exp(-0.5 * ((x - mean) / std) ** 2) / (std * Math.sqrt(2 * Math.PI))
}

export function ReturnDistributionChart({ datasets, var95, skewness, excessKurtosis, compact = false }: Props) {
  const { selectedRange } = useDashboard()

  const W = 800, H = compact ? 200 : 260
  const P = { l: 50, r: 20, t: 24, b: 36 }
  const pW = W - P.l - P.r
  const pH = H - P.t - P.b

  const primary = datasets[0]
  const returns = useMemo(() => {
    if (!primary) return []
    const n = primary.returns.length
    const bars = Math.min(RANGE_N[selectedRange], n)
    return primary.returns.slice(Math.max(0, n - bars))
  }, [primary, selectedRange])

  const hist = useMemo(() => computeHistogram(returns), [returns])

  const allX = hist.map(h => h.x)
  const minX = Math.min(...allX, -3)
  const maxX = Math.max(...allX, 3)
  const maxCount = Math.max(...hist.map(h => h.count), 1)

  function toX(x: number) { return P.l + ((x - minX) / (maxX - minX)) * pW }
  function toY(count: number) { return P.t + pH - (count / maxCount) * pH }

  const mean = returns.length > 0 ? returns.reduce((a, b) => a + b, 0) / returns.length : 0
  const std = returns.length > 1
    ? Math.sqrt(returns.reduce((a, b) => a + (b - mean) ** 2, 0) / (returns.length - 1))
    : 1

  const normalPath = (() => {
    const steps = 100
    const step = (maxX - minX) / steps
    return Array.from({ length: steps + 1 }, (_, i) => {
      const x = minX + i * step
      const density = normalPdf(x, mean, std)
      const scaledCount = density * returns.length * (hist[0]?.width ?? 0.1)
      return `${i === 0 ? 'M' : 'L'}${toX(x).toFixed(1)},${toY(scaledCount).toFixed(1)}`
    }).join(' ')
  })()

  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', display: 'block' }}>
        {/* ヒストグラムバー */}
        {hist.map((h, i) => {
          const x = toX(h.x - h.width / 2)
          const w = Math.max((pW / hist.length) - 1, 1)
          const isLeft = h.x < 0
          return (
            <rect key={i} x={x} y={toY(h.count)} width={w} height={toY(0) - toY(h.count)}
              fill={isLeft ? 'rgba(255,92,92,0.5)' : 'rgba(0,228,154,0.5)'} />
          )
        })}
        {/* 正規分布カーブ */}
        <path d={normalPath} fill="none" stroke="var(--text3)" strokeWidth={1} strokeDasharray="4,3" />
        {/* 0ライン */}
        <line x1={toX(0)} x2={toX(0)} y1={P.t} y2={P.t + pH} stroke="var(--text3)" strokeWidth={0.5} />
        {/* VaR95ライン */}
        {var95 != null && (
          <g>
            <line x1={toX(-var95)} x2={toX(-var95)} y1={P.t} y2={P.t + pH} stroke="#ff5c5c" strokeWidth={1.5} strokeDasharray="4,2" />
            <text x={toX(-var95) - 3} y={P.t + 12} textAnchor="end" fontSize={9} fill="#ff5c5c" fontFamily="var(--mono)">VaR95</text>
          </g>
        )}
        {/* X軸ラベル */}
        {[-2, -1, 0, 1, 2].filter(v => v >= minX && v <= maxX).map(v => (
          <text key={v} x={toX(v)} y={H - 4} textAnchor="middle" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">{v}%</text>
        ))}
        {/* 統計情報 */}
        {skewness != null && (
          <text x={P.l + pW - 4} y={P.t + 14} textAnchor="end" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">
            {`歪度: ${skewness.toFixed(2)}  尖度: ${(excessKurtosis ?? 0).toFixed(2)}`}
          </text>
        )}
      </svg>
    </div>
  )
}
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/ReturnDistributionChart.tsx
git commit -m "feat: ReturnDistributionChart（リターン分布ヒストグラム）を追加"
```

---

## Task 9: WeekdayPerformanceChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/WeekdayPerformanceChart.tsx`

- [ ] **Step 1: WeekdayPerformanceChart.tsx を作成**

```tsx
import { useMemo, useState } from 'react'
import { useDashboard, RANGE_N } from '../../contexts/DashboardContext'
import type { Lang } from '../../i18n/strings'
import { makeL } from '../../i18n/strings'

interface Props {
  dailyReturns: number[]
  dates: string[]
  lang: Lang
  compact?: boolean
}

interface WeekdayStat { day: string; avg: number; count: number; winRate: number }

function computeWeekdayStats(returns: number[], dates: string[]): WeekdayStat[] {
  const dayLabels = ['月', '火', '水', '木', '金']
  const stats = dayLabels.map(() => ({ total: 0, count: 0, wins: 0 }))
  for (let i = 0; i < returns.length; i++) {
    const d = new Date(dates[i + 1] ?? '')
    const idx = d.getDay() - 1
    if (idx >= 0 && idx <= 4) {
      stats[idx].total += returns[i]
      stats[idx].count++
      if (returns[i] > 0) stats[idx].wins++
    }
  }
  return dayLabels.map((day, i) => ({
    day,
    avg: stats[i].count > 0 ? stats[i].total / stats[i].count : 0,
    count: stats[i].count,
    winRate: stats[i].count > 0 ? (stats[i].wins / stats[i].count) * 100 : 0,
  }))
}

export function WeekdayPerformanceChart({ dailyReturns, dates, lang, compact = false }: Props) {
  const { selectedRange } = useDashboard()
  const [hovIdx, setHovIdx] = useState<number | null>(null)
  const L = makeL(lang)

  const slicedReturns = useMemo(() => {
    const n = dailyReturns.length
    const bars = Math.min(RANGE_N[selectedRange], n)
    return dailyReturns.slice(Math.max(0, n - bars))
  }, [dailyReturns, selectedRange])

  const stats = useMemo(() => computeWeekdayStats(slicedReturns, dates), [slicedReturns, dates])

  const W = 400, H = compact ? 160 : 200
  const P = { l: 40, r: 20, t: 20, b: 36 }
  const pW = W - P.l - P.r
  const pH = H - P.t - P.b

  const maxAbs = Math.max(...stats.map(s => Math.abs(s.avg)), 0.01)
  const barW = pW / stats.length - 4
  const midY = P.t + pH / 2

  function barH(avg: number) { return Math.abs(avg) / maxAbs * (pH / 2) }

  return (
    <div style={{ position: 'relative' }}>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', maxWidth: W, display: 'block' }}>
        {/* 0ライン */}
        <line x1={P.l} x2={P.l + pW} y1={midY} y2={midY} stroke="var(--text3)" strokeWidth={0.75} />
        {/* グリッド */}
        {[-maxAbs, -maxAbs / 2, maxAbs / 2, maxAbs].map(v => {
          const y = midY - (v / maxAbs) * (pH / 2)
          return (
            <g key={v}>
              <line x1={P.l} x2={P.l + pW} y1={y} y2={y} stroke="var(--border)" strokeWidth={0.4} />
              <text x={P.l - 4} y={y + 4} textAnchor="end" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">
                {v.toFixed(2)}%
              </text>
            </g>
          )
        })}
        {/* 棒グラフ */}
        {stats.map((s, i) => {
          const x = P.l + i * (pW / stats.length) + 2
          const h = barH(s.avg)
          const y = s.avg >= 0 ? midY - h : midY
          return (
            <g key={i}>
              <rect x={x} y={y} width={barW} height={h}
                fill={s.avg >= 0 ? 'rgba(0,228,154,0.7)' : 'rgba(255,92,92,0.7)'}
                opacity={hovIdx === i ? 1 : 0.8}
                onMouseEnter={() => setHovIdx(i)}
                onMouseLeave={() => setHovIdx(null)}
                style={{ cursor: 'pointer' }}
              />
              <text x={x + barW / 2} y={H - 4} textAnchor="middle" fontSize={10} fill="var(--text2)" fontFamily="var(--sans)">
                {s.day}
              </text>
            </g>
          )
        })}
      </svg>
      {/* ツールチップ */}
      {hovIdx !== null && stats[hovIdx] && (
        <div style={{
          position: 'absolute', top: 8, right: 8, background: 'var(--surface)',
          border: '1px solid var(--border)', borderRadius: 6, padding: '6px 10px',
          fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text)',
        }}>
          <div>{stats[hovIdx].day}曜日</div>
          <div>平均: {stats[hovIdx].avg.toFixed(3)}%</div>
          <div>勝率: {stats[hovIdx].winRate.toFixed(1)}%</div>
          <div>{L('件数', 'Count')}: {stats[hovIdx].count}</div>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/WeekdayPerformanceChart.tsx
git commit -m "feat: WeekdayPerformanceChart（曜日別パフォーマンス）を追加"
```

---

## Task 10: DrawdownDetailChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/DrawdownDetailChart.tsx`

- [ ] **Step 1: DrawdownDetailChart.tsx を作成**

```tsx
import { useMemo } from 'react'
import { useDashboard } from '../../contexts/DashboardContext'
import type { Lang } from '../../i18n/strings'
import { makeL } from '../../i18n/strings'

interface DrawdownPeriod {
  startIdx: number
  peakIdx: number
  endIdx: number
  depth: number
  durationDays: number
  recoveryDays: number | null
  startDate: string
  endDate: string
}

function detectTopDrawdowns(dd: number[], dates: string[], top = 5): DrawdownPeriod[] {
  const periods: DrawdownPeriod[] = []
  let inDD = false
  let start = 0
  let minIdx = 0
  let minVal = 0

  for (let i = 0; i < dd.length; i++) {
    if (!inDD && dd[i] < -0.01) {
      inDD = true
      start = i
      minIdx = i
      minVal = dd[i]
    } else if (inDD) {
      if (dd[i] < minVal) { minIdx = i; minVal = dd[i] }
      if (dd[i] >= -0.01 || i === dd.length - 1) {
        const recovery = dd[i] >= -0.01 ? i - minIdx : null
        periods.push({
          startIdx: start, peakIdx: minIdx, endIdx: i,
          depth: minVal,
          durationDays: i - start,
          recoveryDays: recovery,
          startDate: dates[start] ?? '',
          endDate: dates[i] ?? '',
        })
        inDD = false
      }
    }
  }
  return periods.sort((a, b) => a.depth - b.depth).slice(0, top)
}

interface Props {
  drawdown: number[]
  dates: string[]
  lang: Lang
}

export function DrawdownDetailChart({ drawdown, dates, lang }: Props) {
  const { setHighlightedDateRange } = useDashboard()
  const L = makeL(lang)

  const periods = useMemo(() => detectTopDrawdowns(drawdown, dates), [drawdown, dates])

  const maxDepth = Math.abs(Math.min(...periods.map(p => p.depth), -0.01))

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text3)', marginBottom: 4 }}>
        {L('クリックで Overview に期間ハイライト', 'Click to highlight period in Overview')}
      </div>
      {periods.map((p, i) => {
        const barWidth = (Math.abs(p.depth) / maxDepth) * 100
        return (
          <div key={i}
            onClick={() => setHighlightedDateRange({ start: p.startDate, end: p.endDate })}
            style={{
              display: 'grid', gridTemplateColumns: '80px 1fr 120px',
              alignItems: 'center', gap: 8, cursor: 'pointer',
              padding: '6px 8px', borderRadius: 6,
              background: 'var(--surface)', border: '1px solid var(--border)',
              transition: 'border-color 0.1s',
            }}
            onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--accent-glow)')}
            onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border)')}
          >
            <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#ff5c5c' }}>
              {p.depth.toFixed(2)}%
            </span>
            <div style={{ background: 'var(--border)', borderRadius: 2, height: 8, overflow: 'hidden' }}>
              <div style={{ width: `${barWidth}%`, height: '100%', background: '#ff5c5c', borderRadius: 2 }} />
            </div>
            <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--text3)' }}>
              <div>{p.startDate.slice(0, 10)}</div>
              <div>{p.durationDays}d / {p.recoveryDays != null ? `${p.recoveryDays}d回復` : L('未回復', 'No recovery')}</div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/DrawdownDetailChart.tsx
git commit -m "feat: DrawdownDetailChart（ドローダウンTOP5）を追加"
```

---

## Task 11: VaRChart

**Files:**
- Create: `alpha-forge/visualizer/src/components/charts/VaRChart.tsx`

- [ ] **Step 1: VaRChart.tsx を作成**

```tsx
import { useMemo } from 'react'
import { useDashboard, RANGE_N } from '../../contexts/DashboardContext'
import type { Lang } from '../../i18n/strings'
import { makeL } from '../../i18n/strings'

interface Props {
  dailyReturns: number[]
  var95: number
  cvar95: number
  lang: Lang
}

export function VaRChart({ dailyReturns, var95, cvar95, lang }: Props) {
  const { selectedRange } = useDashboard()
  const L = makeL(lang)

  const returns = useMemo(() => {
    const n = dailyReturns.length
    const bars = Math.min(RANGE_N[selectedRange], n)
    return dailyReturns.slice(Math.max(0, n - bars))
  }, [dailyReturns, selectedRange])

  const W = 800, H = 200
  const P = { l: 50, r: 20, t: 24, b: 36 }
  const pW = W - P.l - P.r
  const pH = H - P.t - P.b

  const sorted = [...returns].sort((a, b) => a - b)
  const BINS = 40
  const minX = sorted[0] ?? -5
  const maxX = Math.min(sorted[sorted.length - 1] ?? 0, 0)
  const binW = (maxX - minX) / BINS || 0.01

  const hist = Array.from({ length: BINS }, (_, i) => {
    const lo = minX + i * binW
    const hi = lo + binW
    return { x: lo + binW / 2, count: sorted.filter(v => v >= lo && v < hi).length }
  })

  const maxCount = Math.max(...hist.map(h => h.count), 1)
  function toX(x: number) { return P.l + ((x - minX) / (maxX - minX)) * pW }
  function toY(count: number) { return P.t + pH - (count / maxCount) * pH }

  const varLine = toX(-var95)
  const cvarLine = toX(-cvar95)

  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} style={{ width: '100%', display: 'block' }}>
        {hist.map((h, i) => {
          const x = toX(h.x - binW / 2)
          const bw = Math.max((pW / BINS) - 1, 1)
          const isTail = h.x < -var95
          return (
            <rect key={i} x={x} y={toY(h.count)} width={bw} height={toY(0) - toY(h.count)}
              fill={isTail ? 'rgba(255,92,92,0.8)' : 'rgba(255,92,92,0.3)'} />
          )
        })}
        {/* VaR ライン */}
        <line x1={varLine} x2={varLine} y1={P.t} y2={P.t + pH} stroke="#ff5c5c" strokeWidth={2} />
        <text x={varLine - 4} y={P.t + 12} textAnchor="end" fontSize={9} fill="#ff5c5c" fontFamily="var(--mono)">
          VaR95 {var95.toFixed(2)}%
        </text>
        {/* CVaR ライン */}
        {cvar95 > var95 && (
          <g>
            <line x1={cvarLine} x2={cvarLine} y1={P.t} y2={P.t + pH} stroke="#ff8c42" strokeWidth={2} strokeDasharray="4,2" />
            <text x={cvarLine - 4} y={P.t + 22} textAnchor="end" fontSize={9} fill="#ff8c42" fontFamily="var(--mono)">
              CVaR95 {cvar95.toFixed(2)}%
            </text>
          </g>
        )}
        {/* X軸 */}
        {[-4, -3, -2, -1, 0].filter(v => v >= minX && v <= maxX).map(v => (
          <text key={v} x={toX(v)} y={H - 4} textAnchor="middle" fontSize={9} fill="var(--text3)" fontFamily="var(--mono)">{v}%</text>
        ))}
      </svg>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--text3)', marginTop: 6 }}>
        {L(
          `5%の確率で1日あたり ${var95.toFixed(2)}% 以上の損失が発生（VaR95）。テール期待損失は ${cvar95.toFixed(2)}%（CVaR95）。`,
          `5% chance of losing more than ${var95.toFixed(2)}% per day (VaR95). Expected tail loss: ${cvar95.toFixed(2)}% (CVaR95).`
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/VaRChart.tsx
git commit -m "feat: VaRChart（VaR/CVaR テール可視化）を追加"
```

---

## Task 12: BacktestScreen タブ再編成 + UX統合

**Files:**
- Modify: `alpha-forge/visualizer/src/screens/BacktestScreen.tsx`
- Modify: `alpha-forge/visualizer/src/components/charts/EquityChart.tsx`

- [ ] **Step 1: EquityChart に highlightedDateRange 受信を追加**

`EquityChart.tsx` のprops インターフェースに追加：

```typescript
interface EquityChartProps {
  // 既存のprops はそのまま
  equity: number[]
  dates: string[]
  isCutoffIdx: number
  benchmark?: number[]
  showBenchmark?: boolean
  compact: boolean
  variation: Variation
  // 追加
  highlightedDateRange?: { start: string; end: string } | null
}
```

`EquityChart` 関数内で、SVGの `<g>` の中にハイライト矩形を追加（既存のISカットラインの描画と同じパターン）：

```tsx
{highlightedDateRange && (() => {
  const startI = dates.findIndex(d => d >= highlightedDateRange.start)
  const endI = dates.findIndex(d => d >= highlightedDateRange.end)
  if (startI < 0) return null
  const x1 = toX(Math.max(0, startI - startIdx), slice.length)
  const x2 = toX(Math.min(slice.length - 1, endI - startIdx), slice.length)
  return <rect x={x1} y={P.t} width={Math.max(x2 - x1, 2)} height={pH} fill="rgba(255,92,92,0.15)" />
})()}
```

- [ ] **Step 2: BacktestScreen.tsx をタブ再編成**

`BacktestScreen.tsx` を以下の構成に書き換える（既存コードを参考に）：

```tsx
import { useState } from 'react'
import type { Lang } from '../i18n/strings'
import { makeL } from '../i18n/strings'
import type { Theme, Variation } from '../hooks/useTheme'
import type { BacktestDetail } from '../api/types'
import { Pill, SecHead, SectionLabel } from '../components/common'
import { DashboardProvider, useDashboard } from '../contexts/DashboardContext'
import { MetricsSummaryBar } from '../components/MetricsSummaryBar'
import { EquityChart } from '../components/charts/EquityChart'
import { DrawdownChart } from '../components/charts/DrawdownChart'
import { BenchmarkChart } from '../components/charts/BenchmarkChart'
import { MonthlyHeatmap } from '../components/charts/MonthlyHeatmap'
import { RollingMetricsChart } from '../components/charts/RollingMetricsChart'
import { ReturnDistributionChart } from '../components/charts/ReturnDistributionChart'
import { WeekdayPerformanceChart } from '../components/charts/WeekdayPerformanceChart'
import { MAEMFEScatter } from '../components/charts/MAEMFEScatter'
import { DrawdownDetailChart } from '../components/charts/DrawdownDetailChart'
import { VaRChart } from '../components/charts/VaRChart'
import { MonteCarloChart } from '../components/charts/MonteCarloChart'
import { MetricsGrid } from '../components/metrics/MetricsGrid'
import { SignalQualityBadge } from '../components/metrics/SignalQualityBadge'
import { TradeTable } from '../components/trades/TradeTable'

interface Props {
  data: BacktestDetail
  compact: boolean
  lang: Lang
  variation: Variation
  theme: Theme
}

type Tab = 'overview' | 'metrics' | 'performance' | 'trades' | 'risk' | 'monte'

function BacktestScreenInner({ data, compact, lang, variation, theme }: Props) {
  const [tab, setTab] = useState<Tab>('overview')
  const { highlightedDateRange } = useDashboard()
  const L = makeL(lang)

  const tabs: ReadonlyArray<readonly [Tab, string]> = [
    ['overview', L('概要', 'Overview')],
    ['metrics', L('メトリクス', 'Metrics')],
    ['performance', L('パフォーマンス', 'Performance')],
    ['trades', L('取引', 'Trades')],
    ['risk', L('リスク', 'Risk')],
    ['monte', L('モンテカルロ', 'Monte Carlo')],
  ]

  const period = `${data.period.start} → ${data.period.end}`
  const subtitle = `${data.symbol} · ${data.strategy_name} · ${data.timeframe} · ${period}`

  const strategyDataset = {
    label: L('戦略', 'Strategy'),
    values: data.equity.values,
    dates: data.equity.dates,
    color: 'var(--accent)',
  }
  const buyHoldDataset = data.buy_hold_equity.length > 0 ? {
    label: 'Buy & Hold',
    values: data.buy_hold_equity,
    dates: data.equity.dates,
    color: 'var(--text3)',
  } : undefined

  const skew = data.metrics.deflated_sharpe?.skewness
  const kurt = data.metrics.deflated_sharpe?.excess_kurtosis

  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      <SecHead title={L('バックテスト結果', 'Backtest Results')} subtitle={subtitle} />
      <MetricsSummaryBar metrics={data.metrics} lang={lang} />
      <div style={{ display: 'flex', gap: 0, borderBottom: '1px solid var(--border)', marginBottom: 20 }}>
        {tabs.map(([id, label]) => (
          <Pill key={id} active={tab === id} onClick={() => setTab(id)}>{label}</Pill>
        ))}
      </div>

      {tab === 'overview' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <div>
            <SectionLabel>{L('エクイティ vs Buy&Hold', 'Equity vs Buy & Hold')}</SectionLabel>
            <BenchmarkChart
              datasets={buyHoldDataset ? [strategyDataset, buyHoldDataset] : [strategyDataset]}
              lang={lang} compact={compact}
            />
          </div>
          <div>
            <SectionLabel>{L('ドローダウン', 'Drawdown')}</SectionLabel>
            <DrawdownChart dd={data.drawdown} dates={data.equity.dates} isCutoffIdx={data.is_cutoff.index} compact={compact} />
          </div>
        </div>
      )}

      {tab === 'metrics' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <MetricsGrid metrics={data.metrics} compact={compact} lang={lang} variation={variation} />
          <SignalQualityBadge metrics={data.metrics} lang={lang} variation={variation} />
        </div>
      )}

      {tab === 'performance' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <div>
            <SectionLabel>{L('月別リターン', 'Monthly Returns')}</SectionLabel>
            <MonthlyHeatmap data={data.monthly_returns} lang={lang} theme={theme} />
          </div>
          <div>
            <SectionLabel>{L('ローリング Sharpe', 'Rolling Sharpe')}</SectionLabel>
            <RollingMetricsChart dailyReturns={data.daily_returns} dates={data.equity.dates} compact={compact} />
          </div>
          <div>
            <SectionLabel>{L('リターン分布', 'Return Distribution')}</SectionLabel>
            <ReturnDistributionChart
              datasets={[{ label: L('日次リターン', 'Daily Returns'), returns: data.daily_returns, color: 'var(--accent)' }]}
              var95={data.metrics.var_95_pct}
              skewness={skew}
              excessKurtosis={kurt}
              compact={compact}
            />
          </div>
          <div>
            <SectionLabel>{L('曜日別パフォーマンス', 'Weekday Performance')}</SectionLabel>
            <WeekdayPerformanceChart dailyReturns={data.daily_returns} dates={data.equity.dates} lang={lang} compact={compact} />
          </div>
        </div>
      )}

      {tab === 'trades' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div>
            <SectionLabel>{L('取引一覧', 'Trade List')}</SectionLabel>
            <TradeTable trades={data.trades} lang={lang} />
          </div>
        </div>
      )}

      {tab === 'risk' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <div>
            <SectionLabel>{L('MAE / MFE 散布図', 'MAE / MFE Scatter')}</SectionLabel>
            <MAEMFEScatter trades={data.trades} lang={lang} compact={compact} />
          </div>
          <div>
            <SectionLabel>{L('ドローダウン TOP5', 'Drawdown TOP5')}</SectionLabel>
            <DrawdownDetailChart drawdown={data.drawdown} dates={data.equity.dates} lang={lang} />
          </div>
          {data.metrics.var_95_pct != null && data.metrics.cvar_95_pct != null && (
            <div>
              <SectionLabel>{L('VaR / CVaR', 'VaR / CVaR')}</SectionLabel>
              <VaRChart
                dailyReturns={data.daily_returns}
                var95={data.metrics.var_95_pct}
                cvar95={data.metrics.cvar_95_pct}
                lang={lang}
              />
            </div>
          )}
        </div>
      )}

      {tab === 'monte' && (
        <div>
          <SectionLabel>{L('モンテカルロ シミュレーション', 'Monte Carlo Simulation')}</SectionLabel>
          <MonteCarloChart trades={data.trades} lang={lang} compact={compact} />
        </div>
      )}
    </div>
  )
}

export function BacktestScreen(props: Props) {
  return (
    <DashboardProvider>
      <BacktestScreenInner {...props} />
    </DashboardProvider>
  )
}
```

- [ ] **Step 3: 型チェック**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
```

エラーがある場合は修正してから次のステップへ。

- [ ] **Step 4: コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/screens/BacktestScreen.tsx visualizer/src/components/charts/EquityChart.tsx
git commit -m "feat: BacktestScreen タブを6グループに再編成し全新チャートを統合"
```

---

## Task 13: CompareScreen 拡張

**Files:**
- Modify: `alpha-forge/visualizer/src/screens/CompareScreen.tsx`
- Modify: `alpha-forge/visualizer/src/api/types.ts`

- [ ] **Step 1: StrategyComparison 型に equity を追加**

`types.ts` の `StrategyComparison` に追加：

```typescript
  equity?: { dates: string[]; values: number[] }
  daily_returns?: number[]
```

- [ ] **Step 2: CompareScreen.tsx にパネルを追加**

`CompareScreen.tsx` の既存 `CompareTable` の下に追記：

```tsx
import { BenchmarkChart } from '../components/charts/BenchmarkChart'
import { ReturnDistributionChart } from '../components/charts/ReturnDistributionChart'
import { DashboardProvider } from '../contexts/DashboardContext'
import { SectionLabel } from '../components/common'
```

`return` ブロックの `<CompareTable ... />` の後に追加：

```tsx
{data.some(s => s.equity) && (
  <DashboardProvider>
    <div style={{ marginTop: 24 }}>
      <SectionLabel>{L('エクイティ比較', 'Equity Comparison')}</SectionLabel>
      <BenchmarkChart
        datasets={data
          .filter(s => s.equity)
          .map((s, i) => ({
            label: s.name,
            values: s.equity!.values,
            dates: s.equity!.dates,
            color: ['var(--accent)', '#63b3ed', '#f6ad55', '#b794f4'][i % 4] as string,
          }))}
        lang={lang}
      />
    </div>
    {data.some(s => s.daily_returns) && (
      <div style={{ marginTop: 24 }}>
        <SectionLabel>{L('リターン分布比較', 'Return Distribution Comparison')}</SectionLabel>
        <ReturnDistributionChart
          datasets={data
            .filter(s => s.daily_returns)
            .map((s, i) => ({
              label: s.name,
              returns: s.daily_returns!,
              color: ['var(--accent)', '#63b3ed', '#f6ad55', '#b794f4'][i % 4] as string,
            }))}
        />
      </div>
    )}
  </DashboardProvider>
)}
```

- [ ] **Step 3: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/screens/CompareScreen.tsx visualizer/src/api/types.ts
git commit -m "feat: CompareScreen にエクイティ比較・リターン分布比較パネルを追加"
```

---

## セルフレビュー

**スペックカバレッジ確認:**
- ✅ 6新チャート: BenchmarkChart / RollingMetricsChart / ReturnDistributionChart / WeekdayPerformanceChart / DrawdownDetailChart / VaRChart
- ✅ グループタブ再編成（Overview/Metrics/Performance/Trades/Risk/Monte Carlo）
- ✅ DashboardContext（期間同期 + クロスハイライト）
- ✅ MetricsSummaryBar（固定ヘッダー）
- ✅ ツールチップ定義（metricDefinitions.ts）
- ✅ CompareScreen 拡張
- ⚠️ MAEMFEScatter のクロスハイライト連動（highlightedTradeId 受信）は Task 12 では省略した → Task 14 として追加が必要

**プレースホルダーなし確認:** 全ステップにコードあり。

**型整合性:** `EquityDataset`・`ReturnDataset` は BenchmarkChart/ReturnDistributionChart 内で定義し、CompareScreen から正しく参照している。

---

## Task 14（補完）: MAEMFEScatter クロスハイライト

**Files:**
- Modify: `alpha-forge/visualizer/src/components/charts/MAEMFEScatter.tsx`

- [ ] **Step 1: useDashboard を組み込む**

`MAEMFEScatter.tsx` の import に追加：

```typescript
import { useDashboard } from '../../contexts/DashboardContext'
```

`MAEMFEScatter` 関数内に追加：

```typescript
const { highlightedTradeId, setHighlightedTradeId } = useDashboard()
```

各 `<circle>` の `onMouseEnter`/`onMouseLeave` を変更：

```tsx
onMouseEnter={() => {
  setTooltip({ t, cx, cy })
  setHighlightedTradeId(String(t.id))
}}
onMouseLeave={() => {
  setTooltip(null)
  setHighlightedTradeId(null)
}}
opacity={highlightedTradeId === null || highlightedTradeId === String(t.id) ? 0.85 : 0.25}
```

ただし `MAEMFEScatter` は `DashboardProvider` の外で使われる場合があるため、`useDashboard()` のエラーハンドリングを追加：

```typescript
// DashboardProvider の外でも動くよう try-catch
let dashboardCtx: { highlightedTradeId: string | null; setHighlightedTradeId: (id: string | null) => void } | null = null
try {
  dashboardCtx = useDashboard()
} catch {
  // Provider外では無効化
}
```

**注意:** React のフック呼び出しは条件分岐できない。代わりに `DashboardContext` の `useContext` を直接使う：

```typescript
import { useContext } from 'react'
import { DashboardContext } from '../../contexts/DashboardContext'
// ...
const ctx = useContext(DashboardContext)
const highlightedTradeId = ctx?.highlightedTradeId ?? null
const setHighlightedTradeId = ctx?.setHighlightedTradeId ?? (() => {})
```

`DashboardContext.tsx` で `DashboardContext` を `export` に変更：

```typescript
export const DashboardContext = createContext<DashboardContextValue | null>(null)
```

- [ ] **Step 2: 型チェック＆コミット**

```bash
cd /Users/sakae/dev/alpha-trade/alpha-forge/visualizer && npx tsc --noEmit
cd /Users/sakae/dev/alpha-trade/alpha-forge
git add visualizer/src/components/charts/MAEMFEScatter.tsx visualizer/src/contexts/DashboardContext.tsx
git commit -m "feat: MAEMFEScatter にクロスハイライト連動を追加"
```
