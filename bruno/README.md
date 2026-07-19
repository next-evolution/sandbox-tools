# Bruno テスト方針

[Bruno](https://www.usebruno.com/) を使った API テストコレクション。
JMeter と同等のシナリオを、GUI 操作・CLI の両方で実行できる。

## ファイル構成

```
./
  README.md                    ← 本ファイル
  bruno.json                   ← コレクション設定
  .gitignore                   ← environments/local.bru を除外
  environments/
    local.bru.example          ← 環境変数テンプレート（git 管理対象）
    local.bru                  ← 実際の値（git 除外・要作成）
  setup/                       ← DB 再構築後に 1 回だけ実行するもの
    100_initialize/
      step01〜10.bru           ← 初期化フロー（ユーザー登録・管理者承認）
      setup.sh                 ← user.csv をループして全ユーザーを初期化
    200_master_data/
      step01_cognito_login.bru ← Cognito ログイン（GUI 実行用。register.sh は curl で直接実行するため未使用）
      step02〜10.bru           ← マスターデータ登録（シンボル・国・サマータイム・経済指標）
      register.sh              ← CSV データを読んで一括登録（CLI 用）
    300_bar_data/
      step02〜03.bru           ← バーデータ・ZigZag 登録
      register_bar-data.sh     ← バーデータ・ZigZag の一括登録（CLI 用）
    400_ec-data/
      step01〜02.bru           ← 経済指標データ（実績値）登録
      register_ec-data.sh      ← 経済指標データの一括登録（CLI 用）
  scenarios/                   ← 機能確認時に繰り返し実行するもの
    login/
      step01〜03.bru           ← ログイン単体確認
      login.sh                 ← ログイン確認用ラッパー
```

データ CSV は `../data/`（`tools/data/`）を共用する（コピー不要）。

---

## セットアップ

### 1. Bruno CLI のインストール

```bash
npm install -g @usebruno/cli
```

### 2. 環境変数ファイルの作成

```bash
cp environments/local.bru.example environments/local.bru
# 各値を実際の環境に合わせて編集する
```

| 変数                           | 説明                            |
| ------------------------------ | ------------------------------- |
| `apiScheme`                    | `http` or `https`               |
| `apiHost`                      | API サーバーホスト              |
| `apiPort`                      | API サーバーポート              |
| `apiRoot`                      | API ルートパス（例: `/api/v1`） |
| `cognitoRegion`                | Cognito リージョン              |
| `cognitoClientId`              | Cognito クライアント ID         |
| `email` / `password`           | 一般ユーザーの認証情報          |
| `adminEmail` / `adminPassword` | 管理者の認証情報                |

`idToken`、`adminIdToken`、`userId` 等は各ステップのスクリプトが自動で書き込む。

---

## シナリオ概要

### setup/（DB 再構築後に 1 回だけ実行）

| ファイル                                | 用途                                  | 状態 |
| --------------------------------------- | ------------------------------------- | ---- |
| `setup/100_initialize/setup.sh`         | user.csv の全件を直列処理するラッパー | ✅   |
| `setup/100_initialize/step01〜10.bru`   | ユーザー登録・管理者承認フロー        | ✅   |
| `setup/200_master_data/step01_cognito_login.bru` | Cognito ログイン（GUI 実行用、register.sh は未使用） | ✅   |
| `setup/200_master_data/register.sh`     | マスターデータ（シンボル・国・サマータイム・経済指標）の一括登録 | ✅   |
| `setup/200_master_data/step02〜10.bru`  | 各登録ステップ（CLI から呼び出し）    | ✅   |
| `setup/300_bar_data/register_bar-data.sh` | バーデータ・ZigZag の一括登録       | ✅   |
| `setup/300_bar_data/step02〜03.bru`     | 各登録ステップ（CLI から呼び出し）    | ✅   |
| `setup/400_ec-data/register_ec-data.sh` | 経済指標データ（実績値）の一括登録    | ✅   |
| `setup/400_ec-data/step01〜02.bru`      | 各登録ステップ（CLI から呼び出し）    | ✅   |

### scenarios/（機能確認時に繰り返し実行）

| ファイル                  | 用途             | 状態 |
| ------------------------- | ---------------- | ---- |
| `scenarios/login/`        | ログイン単体確認 | ✅   |

---

## 実行方法

### CLI

コレクションルート（`tools/bruno/`）から実行する。

```bash
cd tools/bruno

# [1] ユーザー初期化（DB 再構築後に 1 回・user.csv 全件をループ）
./setup/100_initialize/setup.sh

# [2] マスターデータ登録（シンボル・国・サマータイム・経済指標、Step02 から全実行）
./setup/200_master_data/register.sh

# [2'] 任意ステップから再開
./setup/200_master_data/register.sh --from-step 10

# [3] バーデータ・ZigZag 登録（Step01 から全実行、Step02 完了後に実行すること）
./setup/300_bar_data/register_bar-data.sh

# [3'] 任意ステップから再開
./setup/300_bar_data/register_bar-data.sh --from-step 3

# [4] 経済指標データ（実績値）登録（Step01 から全実行、Step02 完了後に実行すること）
./setup/400_ec-data/register_ec-data.sh

# [4'] 任意ステップから再開
./setup/400_ec-data/register_ec-data.sh --from-step 2

# [5] ログイン単体確認
./scenarios/login/login.sh
```

### GUI（Bruno デスクトップアプリ）

1. Bruno を開いて `tools/bruno/` フォルダをコレクションとして開く
2. 左サイドバーで `local` 環境を選択
3. 実行したいリクエストを選んで「Send」または「Run」

---

## setup/100_initialize フロー

`setup.sh` が `user.csv` をループし、1ユーザーごとに以下を実行する。

```
[Step01] Cognito ログイン（一般ユーザー）← curl で idToken を取得
[Step02] Sandbox API 初回ログイン         ← returnCode:1 (Warn) を期待
[Step03] ユーザー登録 POST /api/v1/user

[Step04] Cognito ログイン（管理者）       ← curl で adminIdToken を取得
[Step05] Sandbox API ログイン（管理者）   ← returnCode:0 を期待
[Step06] ユーザー検索 POST /api/v1/admin/users  ← curl で userId を取得
[Step07] ユーザー承認 PUT /api/v1/admin/users/approved/{userId}
[Step08] 管理者権限付与 PUT /api/v1/admin/users/admin/{userId}  ← 最初のユーザーのみ

[Step09] Cognito 再ログイン（一般ユーザー）← curl で idToken を再取得
[Step10] Sandbox API 再ログイン            ← returnCode:0 (Ok) を期待
```

- Step01・Step04・Step09 は Cognito への curl 直呼び（bru 非経由）
- Step06 も curl 直呼びで userId をシェル変数に保持し後続ステップに渡す
- Step08 は `USER_INDEX==0`（1件目）の場合のみ実行

---

## setup/200_master_data フロー

`register.sh` が以下の順で実行する。マスターデータ（シンボル・国・サマータイム・経済指標の定義）のみを扱い、
バーデータ・ZigZag は `300_bar_data`、経済指標データ（実績値）は `400_ec-data` に分離済み。

```
[Cognito]  Cognito ログイン（curl）← --from-step に関わらず常に実行

[Step02]   Sandbox API ログイン                POST:/api/v1/auth/login
[Step04]   シンボル登録                        POST:/api/v1/fx/symbol             ← symbol.csv をループ
[Step05]   国登録                              POST:/api/v1/fx/country            ← country.csv をループ
[Step06]   サマータイム登録                    POST:/api/v1/fx/summer-time        ← summer_time.csv をループ
[Step07]   経済指標マスター投入                直接 DB INSERT                     ← economic_indicator-all.csv
[Step10]   経済指標登録                        POST:/api/v1/fx/economic-indicator  ← economic_indicator.csv をループ
```

- Step07 は API を経由せず `mysql` コマンドで直接 INSERT する

### --from-step N

特定ステップから再開できる（Cognito ログインは常に実行）。

```bash
# 経済指標マスター投入から再開
./setup/200_master_data/register.sh --from-step 7

# 経済指標登録のみ実行
./setup/200_master_data/register.sh --from-step 10
```

---

## setup/300_bar_data フロー

`register_bar-data.sh` が以下の順で実行する。**`200_master_data` の Step04（シンボル登録）完了が前提。**

```
[Cognito]  Cognito ログイン（curl）← --from-step に関わらず常に実行
[Sandbox]  Sandbox API ログイン（curl）← --from-step に関わらず常に実行

[Step01]   ZigZag 初期データ投入               直接 DB INSERT                     ← data/zigzag/*.csv
[Step02]   バーデータ CSV インポート           POST:/api/v1/fx/bar-data/import-csv ← curl（bar_15m/1h/4h/1d）
[Step03]   ZigZag 生成                         POST:/api/v1/fx/zigzag/generate    ← 全シンボル × 4 barType（15M/1H/4H/1D）
```

- Step01 は API を経由せず `mysql` コマンドで直接 INSERT する
- Step02 はファイルアップロードのため `bru run` を使わず curl で直接実行する
  - bru run では `@file({{変数}})` の変数展開が機能せず 500 エラーになるため
- Step03 の ZigZag 生成パラメータ: `depth=3`・`barDateTime=2026-03-01T00:00:00+09:00`・`loadSize=1000`
  - バーデータが存在しないシンボル/barType の組み合わせはエラーをログして継続（スクリプトは止まらない）

### --from-step N

```bash
# バーデータ投入から再開
./setup/300_bar_data/register_bar-data.sh --from-step 2

# ZigZag 生成のみ実行
./setup/300_bar_data/register_bar-data.sh --from-step 3
```

---

## setup/400_ec-data フロー

`register_ec-data.sh` が以下の順で実行する。**`200_master_data` の Step10（経済指標登録）完了が前提。**

```
[Cognito]  Cognito ログイン（curl）← --from-step に関わらず常に実行
[Sandbox]  Sandbox API ログイン（curl）← --from-step に関わらず常に実行

[Step01]   経済指標データ登録                  POST:/api/v1/fx/economic-indicator-data ← economic_indicator_data.csv をループ
[Step02]   経済指標データ テキストインポート   POST:/api/v1/fx/economic-indicator-data/import-text ← curl（2026_03_H.txt + 2026_03_M.txt）
```

- Step02 はファイルアップロードのため `bru run` を使わず curl で直接実行する
  - bru run では `@file({{変数}})` の変数展開が機能せず 500 エラーになるため

### --from-step N

```bash
# テキストインポートのみ実行
./setup/400_ec-data/register_ec-data.sh --from-step 2
```

---

## トークンの引き継ぎ方式

`bru run` は毎回独立した Node.js プロセスとして起動するため、
`bru.setEnvVar()` の値は別プロセスに引き継がれない。

| 役割 | 方法 |
|---|---|
| idToken / adminIdToken の取得 | curl で Cognito に直接リクエスト |
| userId の取得 | curl で管理者 API に直接リクエスト |
| 後続ステップへの注入 | `--env-var "key=$SHELL_VAR"` |

唯一の例外として `scenarios/login/login.sh` は `bru run scenarios/login/`（フォルダ指定）で
全ステップを1プロセス内に収め、`bru.setEnvVar()` の in-memory 共有を活用している。

---

## JMeter との違い

| 機能             | JMeter                   | Bruno                            |
| ---------------- | ------------------------ | -------------------------------- |
| GUI での実行     | JMeter GUI（.jmx）       | Bruno デスクトップアプリ（.bru） |
| CLI での実行     | `jmeter-exec.sh`         | `bru run` + 各 .sh               |
| CSV ループ       | ThreadGroup で自動ループ | シェルスクリプトでループ         |
| スレッド並列実行 | ✅（負荷テスト対応）     | ❌（逐次実行のみ）               |
| アサーション     | ResponseAssertion        | `assert {}` ブロック             |
| トークン引き継ぎ | BeanShell `props.put()`  | curl → シェル変数 → `--env-var`  |
| データファイル   | `tools/data/`            | 同上（共用）                     |

Bruno は負荷テストには対応しない。参照系の負荷テストは JMeter を継続使用する。

---

## API 動作確認カテゴリ

### 1. ログイン

`POST:/api/v1/auth/login`

### 2. 登録系

```
POST:/api/v1/user
POST:/api/v1/fx/symbol
POST:/api/v1/fx/country
POST:/api/v1/fx/summer-time
POST:/api/v1/fx/economic-indicator
POST:/api/v1/fx/economic-indicator-data
POST:/api/v1/fx/economic-indicator-data/import-text
POST:/api/v1/fx/bar-data/import-csv/{symbol}/{barType}/{skipLatest}
POST:/api/v1/fx/zigzag/generate
```

### 3. 更新系

```
PUT:/api/v1/user/{userId}
PUT:/api/v1/fx/symbol/{symbol}
PUT:/api/v1/fx/country/{code}
PUT:/api/v1/fx/summer-time/{targetYear}
PUT:/api/v1/fx/economic-indicator/{countryCode}/{id}
PUT:/api/v1/fx/economic-indicator-data/{economicIndicatorId}/{publication}
```

### admin

```
POST:/api/v1/admin/users
GET:/api/v1/admin/master-refresh
PUT:/api/v1/admin/master-refresh
PUT:/api/v1/admin/users/approved/{userId}
PUT:/api/v1/admin/users/block/{userId}
PUT:/api/v1/admin/users/admin/{userId}
```

### 4. 参照系

```
GET:/api/v1/user
GET:/api/v1/fx/symbol/{symbol}
POST:/api/v1/fx/symbol/search
GET:/api/v1/fx/symbol/currency-pair-list
GET:/api/v1/fx/symbol/currency-index-list
GET:/api/v1/fx/country/{code}
POST:/api/v1/fx/country/search
GET:/api/v1/fx/summer-time/{targetYear}
POST:/api/v1/fx/summer-time/search
GET:/api/v1/fx/economic-indicator/{countryCode}/{id}
POST:/api/v1/fx/economic-indicator/search
GET:/api/v1/fx/economic-indicator-data/{economicIndicatorId}/{publication}
GET:/api/v1/fx/master-list/country
GET:/api/v1/fx/master-list/currency-pair
GET:/api/v1/fx/master-list/currency-index
GET:/api/v1/fx/master-list/symbol/{symbolType}
GET:/api/v1/fx/master-list/economic-indicator/{countryCode}
POST:/api/v1/fx/bar-data
POST:/api/v1/fx/zigzag
POST:/api/v1/fx/zigzag/status
POST:/api/v1/fx/zigzag/bar-data
POST:/api/v1/fx/trade/simulation
POST:/api/v1/fx/economic-indicator-data/search
GET:/api/v1/fx/bar-data/{symbolType}/{barType}
```

### 5. ログアウト

`POST:/api/v1/auth/logout-api`
