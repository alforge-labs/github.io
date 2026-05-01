# フリーミアム制限

AlphaForge には Free / Lifetime の 2 プランがあります。Free プランでは、評価エンジン（バックテスト・最適化）に渡せるデータ日付の上限が **2023-12-31** に制限されています。本ページでは、その挙動と確認方法を整理します。

!!! note "対象コマンド"
    制限は `forge backtest run` と `forge optimize`（`run` / `grid` / `walk-forward` / `cross-symbol`）の入口で適用されます。`forge data fetch` などのデータ取得経路の制限は別途設けられています。

## 挙動

### Free プラン

- 入力データに 2023-12-31 より新しい行が含まれる場合、評価直前に自動で切り捨てられます。
- CLI 通常出力には黄色の Panel で警告が表示され、Lifetime ライセンスでの解除誘導が表示されます。
- `--json` 出力には `freemium_limit_notices` 構造化フィールドが含まれます。

```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_evaluation_date_clipped",
      "message": "Freeプランでは2023-12-31までのデータのみ評価できます。最新データで評価するにはLifetimeライセンスが必要です。",
      "original_value": "2025-01-15",
      "applied_value": "2023-12-31"
    }
  ]
}
```

### Lifetime プラン

制限は一切発動せず、最新データを含めて評価できます。出力にも `freemium_limit_notices` の警告は載りません。

## 開発・検証時のオーバーライド

ローカルでプラン挙動を切り替えて確認したい場合は、環境変数 `ALPHA_FORGE_PLAN` を使います。

```bash
ALPHA_FORGE_PLAN=free uv run forge backtest run AAPL --strategy sma_crossover_v1
ALPHA_FORGE_PLAN=lifetime uv run forge backtest run AAPL --strategy sma_crossover_v1
ALPHA_FORGE_PLAN=dev uv run forge backtest run AAPL --strategy sma_crossover_v1
```

| 値 | 用途 |
|---|---|
| `free` | Free プランの制限を強制適用 |
| `lifetime` | Lifetime プラン相当（制限なし） |
| `dev` | EULA 同意スキップを伴う開発時プラン。配布ビルドでは利用不可 |

`ALPHA_FORGE_PLAN` が未設定の場合は、認証キャッシュ（Whop メンバーシップ情報）から取得したプランが適用されます。`ALPHA_FORGE_DEV_SKIP_LICENSE=1` を設定するとライセンス確認をスキップする `dev` プランで動作しますが、これは Lifetime とは別扱いです。

## 制限を回避する方法

正規の解除手段は **Lifetime ライセンスの取得**のみです。CSV を手動で 2023-12-31 までに切り詰めて再実行しても結果は変わりません（評価エンジン側で必ず切り捨てが適用されるため）。

- Lifetime ライセンスの購入: AlphaForge の販売ページを参照してください。
- Whop メンバーシップが認証キャッシュに反映されないときは、`forge auth login` を再実行してください。
