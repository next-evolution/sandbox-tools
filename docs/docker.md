# Docker 環境

`docker/` ディレクトリで管理する MySQL / Redis のローカル開発環境。

---

## 起動・停止

```bash
cd docker
cp .env.compose.example .env.compose  # 初回のみ
docker compose --env-file .env.compose up -d
docker compose --env-file .env.compose down
```

---

## 環境変数（`.env.compose`）

| 変数 | 説明 |
|---|---|
| `COMPOSE_PROJECT_NAME` | Docker Compose プロジェクト名（`sandbox`） |
| `MYSQL_ROOT_PASSWORD` | MySQL root パスワード |
| `DB_SCHEMA` | 使用するスキーマ名 |
| `DB_USER` | アプリ用 DB ユーザー名 |
| `DB_PASSWORD` | アプリ用 DB パスワード |
| `DB_PORT` | ホスト側公開ポート（デフォルト: `23306`） |
| `REDIS_PORT` | ホスト側公開ポート（デフォルト: `26379`） |
| `ADMIN_UUID` | 初期管理者の Cognito Sub（`sandbox_user` に INSERT） |
| `ADMIN_EMAIL` | 初期管理者のメールアドレス |

---

## サービス構成

| サービス | イメージ | コンテナ名 | 内部ポート | ホストポート |
|---|---|---|---|---|
| db | mysql:8.4.7 | sandbox-db | 3306 | `DB_PORT` |
| redis | redis:8.0.0-alpine | sandbox-redis | 6379 | `REDIS_PORT` |

共有ボリューム `../local/work` が `/work`（コンテナ内作業ディレクトリ）としてマウントされる。

---

## MySQL 初期化スクリプト（`docker/mysql/initdb.d/`）

コンテナ初回起動時にファイル名順に自動実行される。

### 実行順と役割

| ファイル | 内容 |
|---|---|
| `00_create_database-local.sh` | スキーマを DROP & CREATE |
| `10_sandbox_users.sql` | `sandbox_user` テーブル作成 |
| `20_fx_symbol.sql` | `fx_symbol` テーブル作成 |
| `20_fx_country.sql` | `fx_country` テーブル作成 |
| `20_fx_summer_time.sql` | `fx_summer_time` テーブル作成 |
| `20_fx_economic_indicator.sql` | `fx_economic_indicator` テーブル作成 |
| `20_fx_economic_indicator_data.sql` | `fx_economic_indicator_data` テーブル作成 |
| `20_fx_economic_indicator_data_load.sql` | `fx_economic_indicator_data_load` テーブル作成 |
| `20_fx_bar_15m.sql` | `fx_bar_15m` テーブル作成（15分足） |
| `20_fx_bar_1h.sql` | `fx_bar_1h` テーブル作成（1時間足） |
| `20_fx_bar_4h.sql` | `fx_bar_4h` テーブル作成（4時間足） |
| `20_fx_bar_1d.sql` | `fx_bar_1d` テーブル作成（日足） |
| `20_fx_bar_load.sql` | `fx_bar_load` テーブル作成（足データ Load 用） |
| `20_fx_bar_15m_sma.sql` | `fx_bar_15m_sma` テーブル作成 |
| `20_fx_bar_1h_sma.sql` | `fx_bar_1h_sma` テーブル作成 |
| `20_fx_bar_4h_sma.sql` | `fx_bar_4h_sma` テーブル作成 |
| `20_fx_bar_1d_sma.sql` | `fx_bar_1d_sma` テーブル作成 |
| `20_fx_bar_load_sma.sql` | `fx_bar_load_sma` テーブル作成 |
| `20_fx_bar_15m_rsi.sql` | `fx_bar_15m_rsi` テーブル作成 |
| `20_fx_bar_1h_rsi.sql` | `fx_bar_1h_rsi` テーブル作成 |
| `20_fx_bar_4h_rsi.sql` | `fx_bar_4h_rsi` テーブル作成 |
| `20_fx_bar_1d_rsi.sql` | `fx_bar_1d_rsi` テーブル作成 |
| `20_fx_bar_load_rsi.sql` | `fx_bar_load_rsi` テーブル作成 |
| `20_fx_zigzag_15m.sql` | `fx_zigzag_15m` テーブル作成 |
| `20_fx_zigzag_1h.sql` | `fx_zigzag_1h` テーブル作成 |
| `20_fx_zigzag_4h.sql` | `fx_zigzag_4h` テーブル作成 |
| `20_fx_zigzag_1d.sql` | `fx_zigzag_1d` テーブル作成 |
| `20_fx_zigzag_wave_15m.sql` | `fx_zigzag_wave_15m` テーブル作成 |
| `20_fx_zigzag_wave_1h.sql` | `fx_zigzag_wave_1h` テーブル作成 |
| `20_fx_zigzag_wave_4h.sql` | `fx_zigzag_wave_4h` テーブル作成 |
| `20_fx_zigzag_wave_1d.sql` | `fx_zigzag_wave_1d` テーブル作成 |
| `99_create_app_user.sh` | DB ユーザー作成・権限付与 |
| `99_insert_admin_user.sh` | 初期管理者を `sandbox_user` に INSERT |

---

## テーブル一覧

### アプリ系

| テーブル | 説明 |
|---|---|
| `sandbox_user` | アカウント情報（Cognito Sub・承認フラグ・管理者フラグ） |

### FX マスター系

| テーブル | 説明 |
|---|---|
| `fx_symbol` | 銘柄コード情報（FX/INDEX/CRYPTO/STOCK） |
| `fx_country` | 国情報（国コード・通貨コード） |
| `fx_summer_time` | サマータイム情報（年単位） |
| `fx_economic_indicator` | 経済指標マスター |
| `fx_economic_indicator_data` | 経済指標データ（公表日時・実績・予想） |
| `fx_economic_indicator_data_load` | 経済指標データ Load 用 |

### FX 足データ系

| テーブル | 説明 |
|---|---|
| `fx_bar_15m` | 15分足（OHLCV + 差分カラム） |
| `fx_bar_1h` | 1時間足 |
| `fx_bar_4h` | 4時間足 |
| `fx_bar_1d` | 日足 |
| `fx_bar_load` | 足データ Load 用（OHLCV のみ） |

### FX テクニカル系（SMA）

| テーブル | 説明 |
|---|---|
| `fx_bar_15m_sma` | 15分足 SMA |
| `fx_bar_1h_sma` | 1時間足 SMA |
| `fx_bar_4h_sma` | 4時間足 SMA |
| `fx_bar_1d_sma` | 日足 SMA |
| `fx_bar_load_sma` | Load 用 SMA |

### FX テクニカル系（RSI）

| テーブル | 説明 |
|---|---|
| `fx_bar_15m_rsi` | 15分足 RSI |
| `fx_bar_1h_rsi` | 1時間足 RSI |
| `fx_bar_4h_rsi` | 4時間足 RSI |
| `fx_bar_1d_rsi` | 日足 RSI |
| `fx_bar_load_rsi` | Load 用 RSI |

### FX ZigZag 系

| テーブル | 説明 |
|---|---|
| `fx_zigzag_15m` | 15分足 ZigZag（支持・抵抗・トレンド） |
| `fx_zigzag_1h` | 1時間足 ZigZag |
| `fx_zigzag_4h` | 4時間足 ZigZag |
| `fx_zigzag_1d` | 日足 ZigZag |
| `fx_zigzag_wave_15m` | 15分足 ZigZag Wave（波動） |
| `fx_zigzag_wave_1h` | 1時間足 ZigZag Wave |
| `fx_zigzag_wave_4h` | 4時間足 ZigZag Wave |
| `fx_zigzag_wave_1d` | 日足 ZigZag Wave |

---

## データファイル（`data/`）

Bruno テストと init スクリプトで共用するデータファイル。

| ファイル / ディレクトリ | 用途 |
|---|---|
| `data/symbol.csv` | 銘柄マスター（Bruno setup で登録） |
| `data/country.csv` | 国マスター（Bruno setup で登録） |
| `data/summer_time.csv` | サマータイムマスター（Bruno setup で登録） |
| `data/economic_indicator.csv` | 経済指標マスター（Bruno setup で登録） |
| `data/economic_indicator_data.csv` | 経済指標データ（Bruno setup で登録） |
| `data/economic_indicator-all.csv` | 全経済指標データ（参照用） |
| `data/user.csv` | 一般ユーザー一覧（Bruno 初期化でループ） |
| `data/user.csv.example` | ユーザー CSV テンプレート（git 管理対象） |
| `data/admin_user.csv` | 管理者ユーザー情報 |
| `data/admin_user.csv.example` | 管理者 CSV テンプレート（git 管理対象） |
| `data/2026_03_H.txt` | 経済指標データ テキスト（高値系） |
| `data/2026_03_M.txt` | 経済指標データ テキスト（中値系） |
| `data/bar_15m/` | 15分足 CSV（FX_SYMBOL_15_*.csv） |
| `data/bar_1h/` | 1時間足 CSV |
| `data/bar_4h/` | 4時間足 CSV |
| `data/bar_1d/` | 日足 CSV（DXY を含む） |
| `data/zigzag/` | ZigZag 初期データ CSV（setup で INSERT） |
