# ダッシュボード可視化強化 設計仕様

**日付:** 2026-05-04  
**対象リポジトリ:** `alforge-labs` / `alpha-forge`  
**対象ディレクトリ:** `alpha-forge/src/alpha_forge/dashboard/` および `alpha-forge/visualizer/`

---

## 概要

alpha-forge バックテストダッシュボードに6つの新チャートを追加し、タブ構成をグループ化して再編成する。あわせて期間同期・クロスハイライト・固定ヘッダー・ツールチップ・比較モード強化の4つのUX改善を実施する。

---

## アーキテクチャ方針（アプローチC: ハイブリッド型）

- **バックエンド変更は最小限**: `/api/results/{run_id}` レスポンスに `daily_returns` と `buy_hold_equity` の2フィールドのみ追加
- **計算の責務分担**: ベンチマークデータはバックエンド（Python）で算出、ローリング計算・統計集計はフロントエンド（TypeScript）で算出
- **既存スタイル踏襲**: チャートはカスタムSVG実装を継続、外部チャートライブラリは導入しない
- **状態管理**: React Context API を使用、外部ライブラリは導入しない

---

## Section 1: バックエンド変更

### 対象ファイル
`alpha-forge/src/alpha_forge/dashboard/routers/results.py`

### 追加フィールド

| フィールド | 型 | 内容 |
|---|---|---|
| `daily_returns` | `list[float]` | エクイティ値の前日比リターン率（%）。`equity.values` から計算。長さは `equity.values` - 1。 |
| `buy_hold_equity` | `list[float]` | バックテスト期間の Buy&Hold エクイティ曲線。開始値を100に正規化。`equity.dates` と同じ長さ。原資産の Close 価格から算出。 |

### 実装方針

- `_compute_daily_returns(values: list[float]) -> list[float]` ヘルパー関数を追加
- `_compute_buy_hold_equity(record: dict) -> list[float]` ヘルパー関数を追加（OHLCV の Close 価格を使用）
- `_shape_detail()` の返却値に両フィールドを追加
- 既存フィールドへの変更なし（後方互換性を維持）

---

## Section 2: フロントエンド状態管理

### 新規ファイル
`alpha-forge/visualizer/src/contexts/DashboardContext.tsx`

### 管理する状態

```typescript
type DashboardContextValue = {
  selectedRange: "1M" | "3M" | "6M" | "1Y" | "2Y" | "ALL";
  setSelectedRange: (range: SelectedRange) => void;
  highlightedTradeId: string | null;
  setHighlightedTradeId: (id: string | null) => void;
  highlightedDateRange: { start: string; end: string } | null;
  setHighlightedDateRange: (range: { start: string; end: string } | null) => void;
};
```

### 連動ルール

| トリガー | 連動先 |
|---|---|
| Overview の期間ボタン操作 | 全時系列チャート（ローリングSharpe・リターン分布・曜日別・ベンチマーク） |
| DrawdownDetailChart のドローダウン期間クリック | EquityChart の該当期間を強調表示 |
| EquityChart のトレードマーカーホバー | TradeTable の該当行をハイライト・スクロール |
| MAEMFEScatter の点ホバー | TradeTable の該当行をハイライト（逆方向も同様） |

### 適用範囲
`BacktestScreen.tsx` の最上位で `DashboardProvider` をラップ。既存コンポーネントへの変更は期間フィルタ props の追加のみ。

---

## Section 3: 新チャートコンポーネント

### ① `BenchmarkChart.tsx`
- **配置**: Overview タブ
- **内容**: 戦略エクイティと Buy&Hold を重ね合わせた折れ線グラフ。y軸は正規化（開始=100）
- **入力**: `equity`、`buy_hold_equity`
- **UX**: 期間選択連動あり

### ② `RollingMetricsChart.tsx`
- **配置**: Performance タブ
- **内容**: ローリングSharpe（30/60/90日）の時系列折れ線。ウィンドウはトグルで切り替え。0ラインを基準線として表示
- **入力**: `daily_returns`
- **フロント計算**: ウィンドウ内の日次リターンから Sharpe を算出（年率換算: × √252）
- **UX**: ウィンドウ切替ボタン（30d/60d/90d）、期間選択連動あり

### ③ `ReturnDistributionChart.tsx`
- **配置**: Performance タブ
- **内容**: 日次リターンのヒストグラム。正規分布カーブを重ね合わせ、VaR95ラインを垂直線でマーク。歪度・尖度を右上に表示
- **入力**: `daily_returns`、`metrics.var_95_pct`、`metrics.skewness`、`metrics.excess_kurtosis`
- **UX**: 期間選択連動あり
- **比較モード対応**: 複数データセットを半透明で重ね合わせ可能

### ④ `WeekdayPerformanceChart.tsx`
- **配置**: Performance タブ
- **内容**: 月〜金の曜日別平均リターン棒グラフ。正値を緑・負値を赤で色分け
- **入力**: `daily_returns`、`equity.dates`
- **フロント計算**: 日付文字列から曜日を算出し集計
- **UX**: ホバーで取引数・勝率ツールチップ、期間選択連動あり

### ⑤ `VaRChart.tsx`
- **配置**: Risk タブ
- **内容**: リターン分布の左テール拡大ビュー。VaR95・CVaR95のラインを色付きで強調。解説テキストを添付
- **入力**: `daily_returns`、`metrics.var_95_pct`、`metrics.cvar_95_pct`
- **UX**: VaR/CVaR の値と「5%の確率でこの損失が発生する」という説明テキストを表示

### ⑥ `DrawdownDetailChart.tsx`
- **配置**: Risk タブ
- **内容**: drawdown配列からTOP5の谷を自動検出し、横棒グラフで表示（深さ・期間・回復日数）
- **入力**: `drawdown`、`equity.dates`
- **フロント計算**: 連続マイナス区間を走査してピーク→谷→回復を検出
- **UX**: クリックでEquityチャートの該当期間をハイライト（クロスハイライト連動）

---

## Section 4: タブ再編成

### `BacktestScreen.tsx` タブ構成変更

| タブ名 | 含まれるコンポーネント | 変更 |
|---|---|---|
| **Overview** | EquityChart + DrawdownChart + BenchmarkChart | 旧 Equity タブを拡張 |
| **Metrics** | MetricsGrid（既存） | 変更なし |
| **Performance** | MonthlyHeatmap + RollingMetricsChart + ReturnDistributionChart + WeekdayPerformanceChart | 旧 Monthly タブを拡張 |
| **Trades** | TradeTable（クロスハイライト連動追加） | ほぼ変更なし |
| **Risk** | MAEMFEScatter + DrawdownDetailChart + VaRChart | 新設 |
| **Monte Carlo** | MonteCarloChart | 旧 Monte Carlo から分離・独立 |

### `CompareScreen.tsx` 追加

- エクイティ重ね合わせパネル（`BenchmarkChart` を `datasets: { label: string; values: number[]; dates: string[] }[]` props を受け取る形に拡張）
- リターン分布比較パネル（`ReturnDistributionChart` を `datasets: { label: string; returns: number[] }[]` props を受け取る形に拡張し、複数系列を半透明で重ね合わせ）

---

## Section 5: UX機能

### D — メトリクス固定ヘッダー

**新規ファイル**: `MetricsSummaryBar.tsx`

`BacktestScreen.tsx` の上部に常時表示。タブ切り替えに関わらず以下の6指標を横並びで表示：
Sharpe・CAGR・MDD・Win%・PF・Trades

### E — メトリクスツールチップ

**新規ファイル**: `metricDefinitions.ts`

```typescript
export const METRIC_DEFINITIONS: Record<string, { label: string; description: string; formula?: string }> = {
  sharpe: { label: "Sharpe Ratio", description: "超過リターンをリターンの標準偏差で割った値。リスク調整後リターンの指標。", formula: "(Rp - Rf) / σp × √252" },
  // ... 他の指標
};
```

`MetricsSummaryBar` と既存 `MetricsGrid` の両方で共有。指標名の右に `ⓘ` アイコンを追加し、ホバーでポップアップ表示。

### A — 期間選択の全チャート同期

`DashboardContext.selectedRange` 経由で管理（Section 2参照）。Overview タブの既存タイムレンジボタンが `setSelectedRange` を呼び出し、各時系列チャートが `selectedRange` に基づいてデータをスライス。

### B — クロスハイライト

`DashboardContext.highlightedTradeId` 経由で管理（Section 2参照）。3つの連動ポイント：
1. `DrawdownDetailChart` クリック → `highlightedDateRange` を更新 → `EquityChart` が該当期間を強調表示
2. `EquityChart` トレードマーカーホバー → `TradeTable` 行ハイライト・スクロール
3. `MAEMFEScatter` 点ホバー → `TradeTable` 行ハイライト（双方向）

### F — 比較モード強化

`CompareScreen.tsx` に2パネル追加（Section 4参照）。`BenchmarkChart` と `ReturnDistributionChart` を複数データセット対応に拡張して流用。

---

## 実装ファイル一覧

### 新規作成
| ファイル | 役割 |
|---|---|
| `visualizer/src/contexts/DashboardContext.tsx` | グローバル状態管理 |
| `visualizer/src/components/charts/BenchmarkChart.tsx` | ベンチマーク比較 |
| `visualizer/src/components/charts/RollingMetricsChart.tsx` | ローリングSharpe |
| `visualizer/src/components/charts/ReturnDistributionChart.tsx` | リターン分布 |
| `visualizer/src/components/charts/WeekdayPerformanceChart.tsx` | 曜日別パフォーマンス |
| `visualizer/src/components/charts/VaRChart.tsx` | VaR/CVaR リスク |
| `visualizer/src/components/charts/DrawdownDetailChart.tsx` | ドローダウン詳細TOP5 |
| `visualizer/src/components/MetricsSummaryBar.tsx` | 固定ヘッダー |
| `visualizer/src/constants/metricDefinitions.ts` | ツールチップ定義 |

### 変更
| ファイル | 変更内容 |
|---|---|
| `alpha-forge/src/alpha_forge/dashboard/routers/results.py` | `daily_returns`・`buy_hold_equity` フィールド追加 |
| `visualizer/src/screens/BacktestScreen.tsx` | タブ再編成、DashboardProvider ラップ、MetricsSummaryBar 追加 |
| `visualizer/src/screens/CompareScreen.tsx` | エクイティ重ね合わせ・分布比較パネル追加 |
| `visualizer/src/components/charts/MAEMFEScatter.tsx` | クロスハイライト連動追加 |
| `visualizer/src/components/charts/EquityChart.tsx` | クロスハイライト受信・期間フィルタ props 追加 |
| `visualizer/src/components/MetricsGrid.tsx` | metricDefinitions からツールチップ追加 |

---

## 対象外（スコープ外）

- エクスポート機能（PNG・CSV）
- PDFレポート生成
- ダークモード切り替え
- モバイル対応
- WFOScreen・ISOOSScreen への新チャート適用
