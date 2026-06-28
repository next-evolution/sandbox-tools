# JMeter テストツール

Sandbox API の負荷テスト・シナリオテストを JMeter で実行するツール。

---

## 前提

- [Apache JMeter](https://jmeter.apache.org/) がインストールされ、`jmeter` コマンドが PATH に通っていること

---

## セットアップ

### 1. 環境変数ファイルの作成

```bash
cp jmeter/jmeter.env.example jmeter/jmeter.env
```

`jmeter/jmeter.env` を実際の環境に合わせて編集する。

| 変数 | 説明 | デフォルト |
|---|---|---|
| `API_SCHEME` | API のプロトコル | `http` |
| `API_HOST` | API のホスト名 | `localhost` |
| `API_PORT` | API のポート番号 | `8080` |
| `API_ROOT` | API のルートパス | `/api/v1` |
| `API_CHARSET` | 文字コード | `UTF-8` |
| `COGNITO_REGION` | Cognito リージョン | `ap-northeast-1` |
| `COGNITO_CLIENT_ID` | Cognito クライアント ID | ー |
| `DEBUG_MODE` | デバッグログ出力フラグ | `false` |

### 2. ユーザーデータファイルの作成

```bash
cp jmeter/data/login-user.csv.example jmeter/data/login-user.csv
```

`jmeter/data/login-user.csv` を実際のユーザー情報に合わせて編集する。

```csv
"email","password","nickName"
"user01@example.com","password","User01"
"user02@example.com","password","User02"
```

- **データ行数 = スレッド数（同時実行ユーザー数）** となる（`threads` 省略時）
- 全シナリオで共通使用

### 3. シナリオ別 CSV ファイルの作成

データ検索系シナリオには検索パラメーター CSV が必要。

```bash
cp jmeter/data/ec-data-search.csv.example    jmeter/data/ec-data-search.csv
cp jmeter/data/bar-data-search.csv.example   jmeter/data/bar-data-search.csv
cp jmeter/data/zigzag-search.csv.example     jmeter/data/zigzag-search.csv
cp jmeter/data/zigzag-status.csv.example     jmeter/data/zigzag-status.csv
cp jmeter/data/zigzag-bar-data.csv.example   jmeter/data/zigzag-bar-data.csv
cp jmeter/data/trade-simulation.csv.example  jmeter/data/trade-simulation.csv
```

各 CSV を実際のテストパラメーターに合わせて編集する（カラム仕様は各シナリオ節を参照）。

---

## 実行方法

```bash
./jmeter/jmeter-exec.sh <jmxPrefix> <resultSuffix> [threads] [loops] [rampUp]
```

| 引数 | 説明 | デフォルト |
|---|---|---|
| `jmxPrefix` | JMX ファイルのパス（拡張子なし・`jmeter/` からの相対パス） | 必須 |
| `resultSuffix` | 結果フォルダの suffix | 必須 |
| `threads` | スレッド数（同時実行ユーザー数） | `login-user.csv` のデータ行数 |
| `loops` | ループ数 | `1` |
| `rampUp` | Ramp-up 秒数（全スレッド起動に要する秒数） | `1` |

### 実行例

```bash
# login-user.csv のユーザー数分のスレッドで 1 回実行
./jmeter/jmeter-exec.sh scenarios/ec-data 20260628_001

# 10 スレッド・3 ループで実行
./jmeter/jmeter-exec.sh scenarios/bar-data 20260628_002 10 3

# 4 スレッド・rampUp 5 秒で実行
./jmeter/jmeter-exec.sh scenarios/zigzag-search 20260628_003 4 1 5
```

### 結果の確認

```
jmeter/result/<resultSuffix>/result.csv          # サンプル結果（レイテンシ・成否・nickName など）
jmeter/result/<resultSuffix>/jmeter.log          # JMeter 内部ログ
jmeter/result/<resultSuffix>/jmeter-console.log  # コンソール出力ログ
```

---

## 共通仕様

### 認証フロー（全シナリオ共通）

全 JMX ファイルは以下の 2 ステップでログインしてから API 呼び出しを行う。

| ステップ | エンドポイント | 内容 |
|---|---|---|
| Step1 | `POST` Cognito `InitiateAuth` | `login-user.csv` の `email`/`password` で認証。`idToken` を抽出 |
| Step2 | `POST /v1/auth/login` | `idToken` を Bearer トークンとして送信。`userId` を抽出 |

### CSV の共有モード

| CSV | shareMode | 用途 |
|---|---|---|
| `login-user.csv` | `all`（全スレッド共有） | スレッドごとに異なるユーザーを割り当て |
| 検索パラメーター CSV | `thread`（スレッド独立） | 各スレッドが全行を独立して実行 |

### result.csv に出力されるカラム

JMeter 標準項目（`timeStamp`, `elapsed`, `label`, `responseCode`, `success` など）に加え、`nickName` がカスタム列として末尾に追加される。

---

## シナリオ一覧

| ファイル | 対象 API | 特徴 |
|---|---|---|
| `scenarios/master.jmx` | マスターデータ・ユーザー情報 | Step 固定・CSV ループなし |
| `scenarios/ec-data.jmx` | 経済指標データ検索 | `ec-data-search.csv` をループ |
| `scenarios/bar-data.jmx` | バーデータ検索 | `bar-data-search.csv` をループ |
| `scenarios/zigzag-search.jmx` | ZigZag 検索 | `zigzag-search.csv` をループ |
| `scenarios/zigzag-status.jmx` | ZigZag ステータス | `zigzag-status.csv` をループ |
| `scenarios/zigzag-bar-data.jmx` | ZigZag バーデータ | `zigzag-bar-data.csv` をループ |
| `scenarios/trade-simulation.jmx` | トレードシミュレーション | `trade-simulation.csv` をループ |

---

## シナリオ詳細

### `scenarios/master.jmx`

マスターデータ・ユーザー情報の疎通確認シナリオ。CSV ループなし・Step 固定。

| ステップ | メソッド | エンドポイント | 内容 |
|---|---|---|---|
| Step1 | POST | Cognito InitiateAuth | 認証 |
| Step2 | POST | `/v1/auth/login` | Sandbox API ログイン |
| Step3 | GET | `/v1/user` | プロフィール取得。`userId` 一致を検証 |
| Step4-1〜4-7 | GET | `/v1/fx/master-list/*` | マスターリスト取得（country/currency-pair/currency-index/symbol/economic-indicator） |
| Step5-1〜5-4 | POST/GET | `/v1/fx/symbol/*` | シンボル検索・取得 |
| Step6-1〜6-2 | POST/GET | `/v1/fx/country/*` | 国情報検索・取得 |
| Step7-1〜7-2 | POST/GET | `/v1/fx/summer-time/*` | サマータイム検索・取得 |
| Step8-1〜8-2 | POST/GET | `/v1/fx/economic-indicator/*` | 経済指標検索・取得 |

---

### `scenarios/ec-data.jmx`

経済指標データ検索の負荷テストシナリオ。`ec-data-search.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/economic-indicator/search` |

**`data/ec-data-search.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `page` | int | ○ | ページ番号（1〜） |
| `size` | int | ○ | 取得件数 |
| `sortAsc` | boolean | - | 昇順ソート |
| `importance` | string | - | 重要度（`H`/`M`/`X`/`Z`） |
| `countryCode` | string | - | 国コード |
| `publicationBaseDate` | string | - | 発表基準日（`yyyy-MM-dd`） |

---

### `scenarios/bar-data.jmx`

バーデータ検索の負荷テストシナリオ。`bar-data-search.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/bar-data` |

**`data/bar-data-search.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `page` | int | ○ | ページ番号（1〜） |
| `size` | int | ○ | 取得件数 |
| `barType` | string | ○ | 時間足（`M15`/`H1`/`H4`/`D1`） |
| `symbol` | string | ○ | 通貨ペアシンボル（例: `USDJPY`） |
| `barDateFrom` | string | - | 開始日（`yyyyMMdd`） |
| `barDateTo` | string | - | 終了日（`yyyyMMdd`） |
| `sortAsc` | boolean | - | 昇順ソート |

---

### `scenarios/zigzag-search.jmx`

ZigZag 検索の負荷テストシナリオ。`zigzag-search.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/zigzag` |

**`data/zigzag-search.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `page` | int | ○ | ページ番号（1〜） |
| `size` | int | ○ | 取得件数 |
| `barType` | string | ○ | 時間足（`M15`/`H1`/`H4`/`D1`） |
| `symbol` | string | ○ | 通貨ペアシンボル |
| `depth` | int | ○ | ZigZag 深度 |
| `barDateTimeMin` | string | ○ | 開始日時（ISO 8601） |
| `barDateTimeMax` | string | ○ | 終了日時（ISO 8601） |
| `wave`〜`directionTarget4h200` | int | - | フィルター条件各種（空欄で条件なし） |

---

### `scenarios/zigzag-status.jmx`

ZigZag ステータス確認の負荷テストシナリオ。`zigzag-status.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/zigzag/status` |

**`data/zigzag-status.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `symbolType` | string | ○ | シンボル種別（`Trade`/`Analyze`） |
| `barType` | string | ○ | 時間足（`M15`/`H1`/`H4`/`D1`） |
| `depth` | int | ○ | ZigZag 深度 |

---

### `scenarios/zigzag-bar-data.jmx`

ZigZag バーデータ取得の負荷テストシナリオ。`zigzag-bar-data.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/zigzag/bar-data` |

**`data/zigzag-bar-data.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `barType` | string | ○ | 時間足（`M15`/`H1`/`H4`/`D1`） |
| `symbol` | string | ○ | 通貨ペアシンボル |
| `depth` | int | ○ | ZigZag 深度 |
| `waveStart` | string | ○ | ウェーブ開始日時（ISO 8601） |
| `wave` | int | ○ | ウェーブ番号 |

---

### `scenarios/trade-simulation.jmx`

トレードシミュレーションの負荷テストシナリオ。`trade-simulation.csv` の全行をループ実行。

| ステップ | メソッド | エンドポイント |
|---|---|---|
| Step1 | POST | Cognito InitiateAuth |
| Step2 | POST | `/v1/auth/login` |
| Step3（ループ） | POST | `/v1/fx/trade/simulation` |

**`data/trade-simulation.csv` カラム**

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| `riskAmount` | number | ○ | リスク金額 |
| `firstLotRatio` | number | ○ | 初回ロット比率 |
| `tradeVersion` | string | ○ | トレードバージョン |
| `entryType` | string | ○ | エントリー種別（`F3`/`FR`/`F7`/`UP`/`DW`） |
| `symbol` | string | ○ | 通貨ペアシンボル |
| `tradeType` | string | ○ | 売買種別（`L`/`S`） |
| `contractAt` | string | ○ | 約定日時（ISO 8601） |
| `fibonacciType` | string | ○ | フィボナッチ種別 |
| `fibonacciBar` | string | ○ | フィボナッチバー種別 |
| `contractPrice` | number | ○ | 約定価格 |
| `lossPrice` | number | ○ | ロス価格 |
| `priceJpy` | number | ○ | JPY 換算レート |
| `positionNumber` | int | ○ | ポジション番号（1行 = 1ポジション） |
| `settlementPrice` | number | ○ | 決済価格 |

> positionList は 1 件固定。複数ポジションのテストが必要な場合は CSV を複数行に分けて対応する。
