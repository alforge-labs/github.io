# 10分クイックスタート

AlphaForge CLI をインストールして最初のバックテスト結果を確認するまでを一本道で案内します。**Free プランのみで完結**します。ライセンス購入は不要です。

---

!!! info "Free プランで試せる範囲"
    - バックテスト・最適化 ✅（データ上限: **2023-12-31** まで）
    - 最適化トライアル: **50 回**まで
    - Pine Script エクスポート ❌（有料プランが必要）

    上限の詳細は [フリーミアム制限](guides/freemium-limits.md) を参照してください。

---

## ステップ 1 — インストール（約 2 分）

=== "macOS / Linux"

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    インストール後、**新しいターミナルを開いてから**次に進んでください。

=== "Windows"

    PowerShell で実行します（管理者権限不要）。

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    インストール後、**新しいターミナルを開いてから**次に進んでください。

インストールを確認します。

```bash
forge --version
```

```
AlphaForge CLI v1.x.x
```

バージョンが表示されれば完了です。

---

## ステップ 2 — ライセンスを確認する（約 1 分）

Free プランは**ライセンスキーなしで動作します**。現在のプランを確認します。

```bash
forge license status
```

```
Plan  : free
Expiry: n/a
```

!!! tip "有料プランをお持ちの場合"
    購入完了メールに記載されているキーで認証してください。

    ```bash
    forge license activate <YOUR_LICENSE_KEY>
    ```

---

## ステップ 3 — 戦略ファイルを用意する（約 2 分）

`quickstart/` ディレクトリを作成し、サンプル戦略 JSON を保存します。

```bash
mkdir quickstart && cd quickstart
```

`sma_cross.json` という名前で以下を保存します。

```json
{
  "strategy_id": "sma_cross_qs",
  "name": "SMA Crossover Quickstart",
  "version": "1.0.0",
  "description": "SMA(10)/SMA(50) ゴールデンクロス戦略（クイックスタート用）",
  "target_symbols": ["SPY"],
  "asset_type": "stock",
  "timeframe": "1d",
  "indicators": [
    { "id": "sma_fast", "type": "SMA", "params": { "length": 10 }, "source": "close" },
    { "id": "sma_slow", "type": "SMA", "params": { "length": 50 }, "source": "close" }
  ],
  "entry_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": ">", "right": "sma_slow" }]
    }
  },
  "exit_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": "<", "right": "sma_slow" }]
    }
  },
  "risk_management": {
    "position_size_pct": 10.0,
    "position_sizing_method": "fixed",
    "max_positions": 1,
    "leverage": 1.0
  }
}
```

---

## ステップ 4 — バックテストを実行する（約 2 分）

Free プランの範囲（〜2023-12-31）でバックテストを実行します。

```bash
forge backtest run SPY \
  --strategy sma_cross_qs \
  --start 2019-01-01 \
  --end 2023-12-31
```

!!! note "データを自動取得"
    初回実行時は `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` が自動的に走ります。数秒かかる場合があります。

---

## ステップ 5 — 結果を読む（約 3 分）

実行が完了すると以下のような出力が表示されます。

!!! warning "サンプル出力です"
    実際の数値はデータ取得タイミングにより異なります。

```
==> SPY 2019-01-01 → 2023-12-31 (1d)
   trades: 9   win_rate: 55.6%   profit_factor: 1.82
   total_return: +38.4%   cagr: +6.7%   sharpe: 0.88
   max_drawdown: -14.2%   exposure: 41.5%
   final_equity: $13,840  (initial: $10,000)
```

### 主要指標の見方

| 指標 | 今回の値 | 読み方 |
|------|----------|--------|
| **CAGR** | +6.7% | 年率リターン。S&P 500 の年平均（約 10%）と比較しましょう。 |
| **Sharpe** | 0.88 | リスク調整後リターン。**1.0 以上**が目安。もう一息です。 |
| **Max Drawdown** | -14.2% | 過去最大の資産の落ち込み。20% 以内なら運用継続しやすい水準。 |
| **Win Rate** | 55.6% | 勝ちトレードの割合。トレンドフォローでは 40〜60% が標準。 |
| **Profit Factor** | 1.82 | 総利益 ÷ 総損失。**1.5 以上**で良好。 |
| **Trades** | 9 | 期間中のトレード数。信頼性のために **30 件以上**が望ましい。 |

---

## ここまでできたら次のステップへ

| やりたいこと | 参照先 |
|-------------|--------|
| パラメータを最適化したい | [optimize コマンド](cli-reference/optimize.md) |
| ウォークフォワードで過学習を検証したい | [エンドツーエンドワークフロー](guides/end-to-end-workflow.md) |
| 複合指標の戦略テンプレートを使いたい | [戦略テンプレート](templates.md) |
| TradingView と連携したい | [Pine Script 反映ガイド](guides/tradingview-pine-integration.md) |
| Free プランの制限を確認したい | [フリーミアム制限](guides/freemium-limits.md) |

---

## よくある初回エラー

| エラーメッセージ / 症状 | 原因と対処 |
|------------------------|-----------|
| `command not found: forge` | ターミナルを再起動してください。それでも出る場合は PATH を確認（[はじめに](getting-started.md)）。 |
| `No data found for SPY` | `forge data fetch SPY --start 2019-01-01 --end 2023-12-31` を先に実行してください。 |
| `Free plan: date clipped to 2023-12-31` | 仕様どおりの動作です。Free プランの上限日以降のデータは自動的に除外されます。 |
| `Strategy not found: sma_cross_qs` | JSON の `strategy_id` が `sma_cross_qs` になっているか確認してください。 |
| ライセンス認証エラー | ネットワーク接続を確認し、キーに余分なスペースがないか確認してください。 |
| macOS セキュリティ警告 | システム設定 → プライバシーとセキュリティ → 「forge を開く」を許可してください。 |

詳細なトラブルシューティングは [はじめに](getting-started.md) も参照してください。
