# フリーミアム制限

AlphaForge には **Free / Monthly / Annual / Lifetime** の 4 プランがあります。Free 以外（Lifetime / Annual / Monthly）はまとめて**有料プラン**と呼びます。Free プランでは、評価エンジン（バックテスト・最適化）に渡せるデータ日付の上限が **2023-12-31** に制限されています。本ページでは、その挙動と確認方法を整理します。

!!! note "対象コマンド"
    制限は以下の経路で適用されます。
    - **データ取得**: `forge data fetch` / `forge data update` / `forge pine generate --with-training-data` / 戦略の外部シンボル自動取得（`merge_external_symbols`）
    - **評価エンジン入口**: `forge backtest run` / `forge optimize`（`run` / `grid` / `walk-forward` / `cross-symbol`）

    取得時にも評価時にも **2023-12-31** をキャップとして共有しています。

## プラン構成

| プラン | データ取得・評価の日付制限 | 補足 |
|---|---|---|
| Free | 2023-12-31 まで | 取得時に end が 2023-12-31 にキャップされ、評価エンジン入口でも同日でクリップされます |
| Monthly | 制限なし | 月額サブスクリプション。最新データを含めて取得・評価可能 |
| Annual | 制限なし | 年額サブスクリプション。最新データを含めて取得・評価可能 |
| Lifetime | 制限なし | 買い切り。最新データを含めて取得・評価可能 |

内部的には Lifetime / Annual / Monthly はいずれも「制限なし」挙動が同一のため、`lifetime` プランとして一括して扱われます。プラン構成や価格はランディングページの最新情報を参照してください。

## 挙動

### Free プラン

#### データ取得時（`forge data fetch` / `forge data update` / `forge pine generate --with-training-data` / 外部シンボル自動取得）
- `end` 引数（明示指定または `today` のフォールバック）が 2023-12-31 を超える場合、強制的に 2023-12-31 にキャップして取得します。
- `forge data update` で保有最終日が 2023-12-31 以降のアイテムは「Free プラン制限により」スキップされます。
- CLI 通常出力には黄色の Panel で警告が表示され、有料プランでの解除誘導が表示されます。
- `--json` 出力には `freemium_limit_notices` 構造化フィールドが含まれます（`code = "free_tier_data_fetch_clipped"`）。

#### 評価エンジン入口（`forge backtest run` / `forge optimize`）
- 入力データに 2023-12-31 より新しい行が含まれる場合、評価直前に自動で切り捨てられます。これは外部 CSV を直接持ち込んだ場合の保険として機能します（取得経路で既にカットされているはずのため通常は発動しません）。
- CLI 通常出力には黄色の Panel で警告が表示されます。
- `--json` 出力の `freemium_limit_notices` の `code` は `free_tier_evaluation_date_clipped`。

取得時の `freemium_limit_notices` 例:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_data_fetch_clipped",
      "message": "Freeプランでは2023-12-31までのデータのみ取得できます。最新データを取得するには有料プラン（Lifetime / Annual / Monthly）が必要です。",
      "original_value": "2025-06-30",
      "applied_value": "2023-12-31"
    }
  ]
}
```

評価時の `freemium_limit_notices` 例:
```json
{
  "freemium_limit_notices": [
    {
      "code": "free_tier_evaluation_date_clipped",
      "message": "Freeプランでは2023-12-31までのデータのみ評価できます。最新データで評価するには有料プラン（Lifetime / Annual / Monthly）が必要です。",
      "original_value": "2025-01-15",
      "applied_value": "2023-12-31"
    }
  ]
}
```

### 有料プラン（Lifetime / Annual / Monthly）

制限は一切発動せず、最新データを含めて取得・評価できます。出力にも `freemium_limit_notices` の警告は載りません。

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
| `lifetime` | 有料プラン（Lifetime / Annual / Monthly）相当の制限なし挙動 |
| `dev` | EULA 同意スキップを伴う開発時プラン。配布ビルドでは利用不可 |

`ALPHA_FORGE_PLAN` が未設定の場合は、認証キャッシュ（Whop メンバーシップ情報）から取得したプランが適用されます。`ALPHA_FORGE_DEV_SKIP_LICENSE=1` を設定するとライセンス確認をスキップする `dev` プランで動作しますが、これは有料プランとは別扱いです。

## 制限を回避する方法

正規の解除手段は **有料プランの購入**（Lifetime / Annual / Monthly のいずれか）です。CSV を手動で 2023-12-31 までに切り詰めて再実行しても結果は変わりません（評価エンジン側で必ず切り捨てが適用されるため）。

- 有料プランの購入: AlphaForge の販売ページから Monthly / Annual / Lifetime を選択して購入してください。
- Whop メンバーシップが認証キャッシュに反映されないときは、`forge auth login` を再実行してください。
