# MEMO（未実施・検討中の事項）

実装・動作確認が完了した内容は `README.md` へ移動済み。
本ファイルには未実施または継続検討中の事項のみ記録する。

---

## economic_indicator.code 命名規則（未実施）

`economic_indicator` テーブルに `code` カラムを追加し、`country_code + code` を複合ユニークキーとする設計の検討メモ。
DB 再構築時に `economic_indicator_data` の参照 ID がズレる問題を根本解決するため。

### 背景

- `economic_indicator.id` が AUTO_INCREMENT のため、DB 再構築のたびに `economic_indicator_data.csv` の `id` カラムと乖離する
- `code`（短い識別子）を追加し `country_code + code` でユニークにすることで、ID に依存しない参照が可能になる

### 命名規則

```
{INDICATOR}[_{SUBTYPE}][_{REVISION}][_{BASIS}]
```

| 要素 | 略語 |
|---|---|
| 速報値 / 改定値 / 確定値 | `F` / `R` / `FF` |
| 前月比 / 前期比 | `MOM` / `QOQ` |
| 前年同月比 / 前年同期比 | `YOY` |
| 年率換算 | `ANN` |
| コア指数（生鮮除く） | `CORE` |
| コア指数（生鮮・エネルギー除く） | `CORE2` |
| 製造業 / サービス業 / 総合 | `MFG` / `SVC` / `COMP` |
| 自動車除く | `EX_AUTO` |

### 主要 INDICATOR 略語

| 日本語 | code |
|---|---|
| 国内総生産 | `GDP` |
| 消費者物価指数 | `CPI` |
| 卸売・生産者物価指数 | `PPI` |
| 購買担当者景気指数 | `PMI` |
| 政策金利 | `RATE` |
| 失業率 | `UNEMP` |
| 小売売上高 | `RETAIL` |
| 貿易収支 | `TRADE` |
| 鉱工業生産 | `IPI` |
| 個人消費支出 | `PCE` |
| 非農業部門雇用者数 | `NFP` |
| 平均時給 | `AWE` |
| 新規雇用者数 | `NEW_EMP` |
| 失業保険申請件数 | `UI_CLAIMS` |
| 住宅着工件数 | `HOUSING_START` |
| 住宅建設許可件数 | `HOUSING_PERMIT` |
| 機械受注 | `MACH_ORDER` |
| 日銀短観 | `TANKAN` |

### 中央銀行関連の規則

人名（黒田/植田など）は code に含めない。役職ベースで統一する。

| 内容 | code パターン |
|---|---|
| 政策金利発表 | `{BANK}_RATE` |
| 会合議事要旨 | `{BANK}_MIN` |
| 総裁定例記者会見 | `{BANK}_PC` |
| 総裁発言 | `{BANK}_SPEECH` |
| 展望・報告 | `{BANK}_REPORT` |

例: `BOJ_RATE`, `ECB_PC`, `FED_MIN`（FOMC は `FED` で統一）

### 実装方針（未実施）

- `economic_indicator` テーブルに `code VARCHAR(40) NOT NULL` を追加
- `UNIQUE KEY uq_economic_indicator_code (country_code, code)`
- `economic_indicator_data.csv` の `id` カラムを `country_code + code` に変更
- API 側は `country_code + code` で `economic_indicator` を検索して `id` を解決する

---

## ZigZag 生成パラメータ（要確認）

`register.sh` の Step13 で使用するパラメータ。

| パラメータ | 現在値 | 備考 |
|---|---|---|
| `ZIGZAG_DEPTH` | `3` | 一般的なデフォルト値として仮置き。**要承認・要調整** |
| `ZIGZAG_BAR_DATE_TIME` | `2026-03-01T00:00:00+09:00` | 固定値（指示の `+0900` を RFC3339 形式に補正） |
| `ZIGZAG_LOAD_SIZE` | `1000` | 指示どおり |
