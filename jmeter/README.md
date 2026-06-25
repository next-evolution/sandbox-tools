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

### 2. ユーザーデータファイルの作成

```bash
cp jmeter/data/login-user.csv.example jmeter/data/login-user.csv
```

`jmeter/data/login-user.csv` を実際のユーザー情報に合わせて編集する。

```csv
"email","password","nickName"
"user01@example.com","password","User01"
```

- データ行数がそのままスレッド数（同時実行ユーザー数）になる

---

## 実行方法

```bash
./jmeter/jmeter-exec.sh <jmxPrefix> <resultSuffix> [threads] [loops] [rampUp]
```

| 引数 | 説明 | デフォルト |
|---|---|---|
| `jmxPrefix` | JMX ファイルのパス（拡張子なし） | 必須 |
| `resultSuffix` | 結果フォルダの suffix | 必須 |
| `threads` | スレッド数（同時実行ユーザー数） | `login-user.csv` のデータ行数 |
| `loops` | ループ数 | `1` |
| `rampUp` | Ramp-up 秒数 | `1` |

### 実行例

```bash
# login-user.csv のユーザー数分のスレッドで 1 回実行
./jmeter/jmeter-exec.sh scenarios/sandbox 20260626_001

# 3 スレッド・5 ループで実行
./jmeter/jmeter-exec.sh scenarios/sandbox 20260626_002 3 5
```

### 結果の確認

```
jmeter/result/<resultSuffix>/result.csv          # サンプル結果（レイテンシ・成否など）
jmeter/result/<resultSuffix>/jmeter.log          # JMeter 内部ログ
jmeter/result/<resultSuffix>/jmeter-console.log  # コンソール出力ログ
```

---

## シナリオ

### `scenarios/sandbox.jmx`

ログインして IdToken・userId を取得し、プロフィール API で値を検証するシナリオ。

| ステップ | エンドポイント | 内容 |
|---|---|---|
| Step1 | `POST` Cognito InitiateAuth | ユーザー認証。レスポンスから `idToken` を抽出 |
| Step2 | `POST /v1/auth/login` | Sandbox API ログイン。レスポンスから `userId` を抽出 |
| Step3 | `GET /v1/user` | プロフィール取得。`returnCode:0` かつ `userId` が Step2 の値と一致することを検証 |

---

## 後続 API を追加する場合

`scenarios/sandbox.jmx` の Step3 の `</hashTree>` 直後に `HTTPSamplerProxy` を追記する。
`Authorization: Bearer ${idToken}` ヘッダーと `ResponseAssertion` を合わせて追加すること。

---

## API エンドポイント一覧（参考）

### user
- `GET /api/v1/user`

### master cache
- `GET /api/v1/fx/master-list/country`
- `GET /api/v1/fx/master-list/currency-pair`
- `GET /api/v1/fx/master-list/currency-index`
- `GET /api/v1/fx/master-list/symbol/{symbolType}`
- `GET /api/v1/fx/master-list/economic-indicator/{countryCode}`

### master data
- `GET /api/v1/fx/symbol/{symbol}`
- `POST /api/v1/fx/symbol/search`
- `GET /api/v1/fx/symbol/currency-pair-list`
- `GET /api/v1/fx/symbol/currency-index-list`
- `GET /api/v1/fx/country/{code}`
- `POST /api/v1/fx/country/search`
- `GET /api/v1/fx/summer-time/{targetYear}`
- `POST /api/v1/fx/summer-time/search`
- `GET /api/v1/fx/economic-indicator/{countryCode}/{id}`
- `POST /api/v1/fx/economic-indicator/search`

### data search
- `GET /api/v1/fx/economic-indicator-data/{economicIndicatorId}/{publication}`
- `POST /api/v1/fx/economic-indicator-data/search`
- `POST /api/v1/fx/bar-data`
- `GET /api/v1/fx/bar-data/{symbolType}/{barType}`
- `POST /api/v1/fx/zigzag`
- `POST /api/v1/fx/zigzag/status`
- `POST /api/v1/fx/zigzag/bar-data`
- `POST /api/v1/fx/trade/simulation`
