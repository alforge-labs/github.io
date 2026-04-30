# はじめに

AlphaForge CLI をインストールしてライセンス認証し、最初のバックテストを実行するまでの手順です。所要時間は約 5 分です。

## 前提条件

- macOS 12 (Monterey) 以降 / Ubuntu 22.04 以降 / Windows 11
- インターネット接続（ライセンス認証時）
- 有効な AlphaForge ライセンスキー（[購入ページ](https://alforgelabs.com/ja/index.html#pricing)から入手）

## インストール

=== "macOS / Linux"

    ターミナルで以下のコマンドを実行してください。インストーラーが最新バイナリをダウンロードし、`/usr/local/bin` に配置します。

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    !!! tip "インストール先のカスタマイズ"
        インストール先を変更したい場合は `INSTALL_DIR` 環境変数で指定できます。

        ```bash
        INSTALL_DIR=~/.local/bin curl -sSL https://alforge-labs.github.io/install.sh | bash
        ```

=== "Windows"

    PowerShell（管理者権限不要）で以下を実行してください。バイナリを `%USERPROFILE%\.forge\bin` にインストールし、PATH を自動設定します。

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    !!! tip "新しいターミナル"
        インストール後、新しいターミナルウィンドウを開いてから次の手順に進んでください。

=== "手動インストール"

    1. [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest) から使用するプラットフォームのバイナリをダウンロードします。

    2. **macOS / Linux**: 実行権限を付与して PATH の通ったディレクトリに配置します。

        ```bash
        chmod +x forge-macos-arm64
        sudo mv forge-macos-arm64 /usr/local/bin/forge
        ```

    3. **Windows**: バイナリを任意のフォルダに配置し、そのフォルダを PATH に追加します。

## ライセンス認証

### 1. インストール確認

インストールが成功したことを確認します。

```bash
forge --version
```

### 2. ライセンスキーの認証

購入完了メールに記載されているライセンスキーで認証します。

```bash
forge license activate <YOUR_LICENSE_KEY>
```

認証情報は `~/.forge/license.json` に保存されます。オンライン接続が必要です。

### 3. コマンド利用可能性の確認

バックテストコマンドが利用可能なことを確認します。

```bash
forge backtest --help
```

## 最初のバックテスト

ここでは **SMA(10) と SMA(50) のゴールデンクロス／デッドクロス** を使った、もっともシンプルな戦略を例にバックテストを実行します。

### ステップ 1: 戦略 JSON を作成

任意のディレクトリ（例: `strategies/`）に `my_first_strategy.json` を作成します。

```json
{
  "strategy_id": "my_first_strategy",
  "name": "SMA Crossover Example",
  "version": "1.0.0",
  "description": "SMA(10) > SMA(50) でロング（ゴールデンクロス／デッドクロス）",
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

### ステップ 2: バックテスト実行

```bash
forge backtest run SPY --strategy my_first_strategy --json
```

### ステップ 3: 出力例

!!! warning "サンプル出力です"
    以下は典型的な出力イメージで、実際の数値は実行時のデータと環境により異なります。

```text
==> SPY 2018-01-01 → 2025-12-31 (1d)
   trades: 14   win_rate: 50.0%   profit_factor: 1.74
   total_return: +52.3%   cagr: +5.4%   sharpe: 0.92
   max_drawdown: -16.8%   exposure: 38.2%
   final_equity: $15,230  (initial: $10,000)
```

## 結果の見方

主要 6 指標の意味と目安です。詳細な指標一覧は [CLI リファレンス](cli-reference.md) と [戦略テンプレート](templates.md) を参照してください。

| 指標 | 意味 | 目安 |
|------|------|------|
| **CAGR** | 年率リターン（複利ベース） | 市場ベンチマーク（S&P 500: 約 10%）と比較。プラスでも市場以下なら戦略の付加価値は限定的。 |
| **Sharpe Ratio** | リスク調整後リターン | 1.0 以上で「使える」、1.5 以上は優秀、2.0 超は上位戦略。負ならアウト。 |
| **Max Drawdown** | 過去最大の資産の落ち込み（ピークから） | 浅いほど良い。−20% を超えると心理的に運用継続が難しくなる目安。 |
| **Win Rate** | 勝ちトレードの割合 | 50% 前後が標準。トレンドフォローは 30–40%、平均回帰は 60–70% が典型。 |
| **Profit Factor** | 総利益 ÷ 総損失 | 1.5 以上で良好、2.0 超は優秀。1.0 未満は損失過剰。 |
| **Total Trades** | 期間中の総トレード数 | 統計的有意性のため最低 30 件以上は欲しい。少なすぎると過学習リスク。 |

!!! info "次に試すべきこと"
    - パラメータ最適化: [`forge optimize bayes`](cli-reference.md) でベイズ最適化
    - ウォークフォワード検証: [`forge wft`](cli-reference.md) で過学習を検証
    - 戦略テンプレート: [HMM × BB × RSI など](templates.md)を試す

## アンインストール

=== "macOS / Linux"

    ```bash
    sudo rm /usr/local/bin/forge
    rm -rf ~/.forge
    ```

=== "Windows"

    ```powershell
    Remove-Item -Recurse $env:USERPROFILE\.forge
    # PATH から %USERPROFILE%\.forge\bin を手動で除去
    ```

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `command not found: forge` | 新しいターミナルを開くか、`source ~/.bashrc` を実行してください。 |
| ライセンス認証エラー | ネットワーク接続を確認し、キーに余分なスペースがないか確認してください。 |
| macOS セキュリティ警告 | システム設定 → プライバシーとセキュリティ → 「forge を開く」を許可してください。 |

その他のトラブルや詳細な FAQ は [`/ja/install.html`](https://alforgelabs.com/ja/install.html) も参照してください。問題が解決しない場合は [support@alforgelabs.com](mailto:support@alforgelabs.com) までお問い合わせください。

## 次のステップ

- [CLI リファレンス](cli-reference.md) — `forge` コマンドの全パラメータと出力形式
- [戦略テンプレート](templates.md) — HMM × BB × RSI などの複合戦略例
- [AI エージェント連携](ai-driven-forges.md) — Claude Code / Codex × AlphaForge による自律探索

---

*同期元: `ja/install.html`（インストール・ライセンス認証・トラブルシューティング部分）。バックテスト実行例は alpha-forge の戦略 JSON スキーマ（`spy_sma_crossover_v1.json` を参考）に基づく。*
