#!/usr/bin/env bash
# ログイン後、CSV データを読み込んでマスターデータを一括登録する。
#
# 実行順序:
#   [Step02-06] API でマスターデータ登録
#     symbol.csv → country.csv → summer_time.csv
#   [Step07-08] CSV から直接 DB INSERT / [Step09] API
#     fx_economic_indicator → バーデータ → ZigZag
#   [Step10-13] API でマスターデータ登録
#     economic_indicator → economic_indicator_data → テキストインポート → ZigZag 生成
#
# 前提:
#   - bru (Bruno CLI) がインストール済み: npm install -g @usebruno/cli
#   - environments/local.bru が作成済み（email, password, cognitoClientId 等を設定）
#   - tools/data/ 配下の CSV / バーデータ / テキストファイルが存在する
#
# 実行:
#   ./setup/200_master_data/register.sh [--from-step N]
#
# --from-step N: ステップ N から再開する（省略時は 2 から全て実行）
#   Step02: Sandbox API ログイン                           POST:/api/v1/auth/login
#   Step04: シンボル登録                                   POST:/api/v1/fx/symbol
#   Step05: 国登録                                         POST:/api/v1/fx/country
#   Step06: サマータイム登録                               POST:/api/v1/fx/summer-time
#   Step07: fx_economic_indicator データ投入               直接 DB INSERT
#   Step08: ZigZag データ投入                              直接 DB INSERT
#   Step09: バーデータ CSV インポート                      POST:/api/v1/fx/bar-data/import-csv/{symbol}/{barType}/{skipLatest}
#   Step10: 経済指標登録                                   POST:/api/v1/fx/economic-indicator
#   Step11: 経済指標データ登録                             POST:/api/v1/fx/economic-indicator-data
#   Step12: 経済指標データ テキストインポート              POST:/api/v1/fx/economic-indicator-data/import-text
#   Step13: ZigZag 生成                                    POST:/api/v1/fx/zigzag/generate
#
# ※ Cognito ログインはトークン取得のため --from-step に関わらず常に実行する

set -euo pipefail

FROM_STEP=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-step) FROM_STEP="$2"; shift 2 ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="$(cd "$TOOL_DIR/../data" && pwd)"

echo "Bruno コレクションルート: $TOOL_DIR"
echo "データディレクトリ: $DATA_DIR"
echo "開始ステップ: Step${FROM_STEP}"
echo ""

# local.bru から環境変数を取得する
# ※ \s は macOS BSD sed 非対応のため [[:space:]] を使用
get_bru_env_var() {
  grep -E "^\s*${1}:" "$TOOL_DIR/environments/local.bru" | sed -E "s/^[[:space:]]*${1}:[[:space:]]*//"
}

# bru run はコレクションルートから実行する
cd "$TOOL_DIR"

# local.bru から認証情報を取得
EMAIL=$(get_bru_env_var "email")
PASSWORD=$(get_bru_env_var "password")
COGNITO_REGION=$(get_bru_env_var "cognitoRegion")
COGNITO_CLIENT_ID=$(get_bru_env_var "cognitoClientId")
API_SCHEME=$(get_bru_env_var "apiScheme")
API_HOST=$(get_bru_env_var "apiHost")
API_PORT=$(get_bru_env_var "apiPort")
API_ROOT=$(get_bru_env_var "apiRoot")
API_BASE="${API_SCHEME}://${API_HOST}:${API_PORT}${API_ROOT}"

# N 以上のステップを実行する
run_from() { [[ $1 -ge $FROM_STEP ]]; }

# DB接続情報（Step07・Step08 で使用）
if [[ $FROM_STEP -le 8 ]]; then
  ENV_COMPOSE="$(cd "$TOOL_DIR/../docker" && pwd)/.env.compose"
  if [[ ! -f "$ENV_COMPOSE" ]]; then
    echo "ERROR: .env.compose が見つかりません"
    exit 1
  fi

  get_compose_var() {
    grep -E "^\s*${1}=" "$ENV_COMPOSE" \
      | sed -E "s/^[[:space:]]*${1}=//" \
      | sed 's/[[:space:]]*#.*//' \
      | tr -d '"'
  }

  DB_HOST="127.0.0.1"
  DB_PORT=$(get_compose_var "DB_PORT")
  DB_SCHEMA=$(get_compose_var "DB_SCHEMA")
  DB_USER=$(get_compose_var "DB_USER")
  DB_PASSWORD=$(get_compose_var "DB_PASSWORD")
fi

# ========== ログイン（--from-step に関わらず常に実行） ==========
# bru.setEnvVar() は CLI では別プロセス間で共有されないため
# Cognito ログインを curl で行い idToken を shell 変数として保持する
echo "=== ログイン（Cognito） ==="
COGNITO_RESPONSE=$(curl -sf -X POST \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  "https://cognito-idp.${COGNITO_REGION}.amazonaws.com/" \
  -d "{\"AuthFlow\":\"USER_PASSWORD_AUTH\",\"ClientId\":\"${COGNITO_CLIENT_ID}\",\"AuthParameters\":{\"USERNAME\":\"${EMAIL}\",\"PASSWORD\":\"${PASSWORD}\"}}")
ID_TOKEN=$(echo "$COGNITO_RESPONSE" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['AuthenticationResult']['IdToken'])")
EMAIL_ENCODED=$(printf '%s' "$EMAIL" | base64)
echo "  idToken 取得済み"

# ===== [Step02-06] API でマスターデータ登録 =====

if run_from 2; then
  echo "=== [Step02] ログイン（Sandbox API） ==="
  bru run "setup/200_master_data/step02_sandbox_login.bru" \
    --env local \
    --env-var "idToken=$ID_TOKEN" \
    --env-var "emailEncoded=$EMAIL_ENCODED"
  echo ""
fi

if run_from 4; then
  echo "=== [Step04] シンボル登録 ==="
  while IFS=',' read -r symbol symbol_type name valid_scale target_volatility sort_order; do
    symbol=$(echo "$symbol" | tr -d '"')
    symbol_type=$(echo "$symbol_type" | tr -d '"')
    name=$(echo "$name" | tr -d '"')
    valid_scale=$(echo "$valid_scale" | tr -d '"')
    target_volatility=$(echo "$target_volatility" | tr -d '"')
    sort_order=$(echo "$sort_order" | tr -d '"')

    echo "  登録: $symbol ($name)"
    bru run "setup/200_master_data/step04_symbol_register.bru" \
      --env local \
      --env-var "idToken=$ID_TOKEN" \
      --env-var "symbol=$symbol" \
      --env-var "symbolType=$symbol_type" \
      --env-var "name=$name" \
      --env-var "validScale=$valid_scale" \
      --env-var "targetVolatility=$target_volatility" \
      --env-var "sortOrder=$sort_order"
  done < <(tail -n +2 "$DATA_DIR/symbol.csv")
  echo ""
fi

if run_from 5; then
  echo "=== [Step05] 国登録 ==="
  while IFS=',' read -r code name currency_code name_en name_short sort_order; do
    code=$(echo "$code" | tr -d '"')
    name=$(echo "$name" | tr -d '"')
    currency_code=$(echo "$currency_code" | tr -d '"')
    name_en=$(echo "$name_en" | tr -d '"')
    name_short=$(echo "$name_short" | tr -d '"')
    sort_order=$(echo "$sort_order" | tr -d '"')

    echo "  登録: $code ($name)"
    bru run "setup/200_master_data/step05_country_register.bru" \
      --env local \
      --env-var "idToken=$ID_TOKEN" \
      --env-var "code=$code" \
      --env-var "name=$name" \
      --env-var "currencyCode=$currency_code" \
      --env-var "nameEn=$name_en" \
      --env-var "nameShort=$name_short" \
      --env-var "sortOrder=$sort_order"
  done < <(tail -n +2 "$DATA_DIR/country.csv")
  echo ""
fi

if run_from 6; then
  echo "=== [Step06] サマータイム登録 ==="
  while IFS=',' read -r target_year apply_start apply_end; do
    target_year=$(echo "$target_year" | tr -d '"')
    apply_start=$(echo "$apply_start" | tr -d '"')
    apply_end=$(echo "$apply_end" | tr -d '"')

    echo "  登録: $target_year ($apply_start 〜 $apply_end)"
    bru run "setup/200_master_data/step06_summer_time_register.bru" \
      --env local \
      --env-var "idToken=$ID_TOKEN" \
      --env-var "targetYear=$target_year" \
      --env-var "applyStart=$apply_start" \
      --env-var "applyEnd=$apply_end"
  done < <(tail -n +2 "$DATA_DIR/summer_time.csv")
  echo ""
fi

# ===== [Step07-08] CSV から直接 DB INSERT / [Step09] API =====

if run_from 7; then
  echo "=== [Step07] fx_economic_indicator データ投入 ==="
  EI_CSV="$DATA_DIR/economic_indicator-all.csv"
  if [[ ! -f "$EI_CSV" ]]; then
    echo "ERROR: $EI_CSV が見つかりません"
    exit 1
  fi

  python3 - "$EI_CSV" <<'PYEOF' | mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_SCHEMA"
import csv, sys

def esc(s):
    return s.replace("'", "''")

with open(sys.argv[1], newline='', encoding='utf-8') as f:
    for row in csv.DictReader(f):
        desc = f"'{esc(row['description'])}'" if row['description'] else 'NULL'
        uov  = f"'{esc(row['unit_of_value'])}'" if row['unit_of_value'] else 'NULL'
        print(
            "INSERT IGNORE INTO fx_economic_indicator"
            " (code, country_code, name, importance, description, unit_of_value,"
            "  deleted, created_at, created_by, updated_at, updated_by) VALUES"
            f" ('{esc(row['code'])}', '{esc(row['country_code'])}', '{esc(row['name'])}',"
            f"  '{esc(row['importance'])}', {desc}, {uov},"
            "  0, NOW(), 'setup', NOW(), 'setup');"
        )
PYEOF

  RECORD_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_SCHEMA" -sN \
    -e "SELECT COUNT(*) FROM fx_economic_indicator;")
  echo "  完了: fx_economic_indicator ${RECORD_COUNT}件"
  echo ""
fi

if run_from 8; then
  echo "=== [Step08] ZigZag データ投入 ==="
  ZIGZAG_DIR="$DATA_DIR/zigzag"
  if [[ ! -d "$ZIGZAG_DIR" ]]; then
    echo "ERROR: $ZIGZAG_DIR が見つかりません"
    exit 1
  fi

  for csv_file in "$ZIGZAG_DIR"/*.csv; do
    [[ -f "$csv_file" ]] || continue
    table_name=$(basename "$csv_file" .csv)
    echo "  投入: $table_name"

    python3 - "$table_name" "$csv_file" <<'PYEOF' | mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_SCHEMA"
import csv, sys

BIT_COLS = {'up_trend', 'break_resistance', 'break_support'}
DATETIME_COLS = {
    'bar_date_time',
    'resistance_bar_date_time', 'resistance_fractal_bar_date_time',
    'support_bar_date_time', 'support_fractal_bar_date_time',
    'high_bar_date_time', 'low_bar_date_time',
    'backstep_high_bar_date_time', 'backstep_low_bar_date_time',
    'wave_start', 'wave_end', 'previous_wave_start',
}

def to_val(col, raw):
    if col in BIT_COLS:
        return '1' if raw and raw not in ('\x00', '\\0') else '0'
    if raw == '':
        return 'NULL'
    if col in DATETIME_COLS:
        return f"'{raw}'"
    return f"'{raw.replace(chr(39), chr(39)*2)}'"

table, csv_path = sys.argv[1], sys.argv[2]
with open(csv_path, newline='', encoding='utf-8') as f:
    for row in csv.DictReader(f):
        cols = list(row.keys())
        vals = [to_val(col, row[col]) for col in cols]
        print(f"INSERT IGNORE INTO {table} ({','.join(cols)}) VALUES ({','.join(vals)});")
PYEOF

    count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_SCHEMA" -sN \
      -e "SELECT COUNT(*) FROM $table_name;")
    echo "    完了: ${count} 件"
  done
  echo ""
fi

if run_from 9; then
  echo "=== [Step09] バーデータ CSV インポート ==="
  for dir_name in bar_15m bar_1h bar_4h bar_1d; do
    bar_dir="$DATA_DIR/$dir_name"
    case "$dir_name" in
      bar_15m) bar_type="15M" ;;
      bar_1h)  bar_type="1H"  ;;
      bar_4h)  bar_type="4H"  ;;
      bar_1d)  bar_type="1D"  ;;
    esac

    if [[ ! -d "$bar_dir" ]]; then
      echo "  スキップ（ディレクトリなし）: $dir_name"
      continue
    fi

    echo "--- $dir_name ($bar_type) ---"
    for csv_file in "$bar_dir"/*.csv; do
      [[ -f "$csv_file" ]] || continue
      symbol=$(basename "$csv_file" | cut -d'_' -f2)
      echo "  インポート: $symbol / $bar_type"
      curl -sf -X POST \
        -H "Authorization: Bearer $ID_TOKEN" \
        -F "uploadFile=@$csv_file" \
        "${API_BASE}/fx/bar-data/import-csv/${symbol}/${bar_type}/false" > /dev/null
    done
  done
  echo ""
fi

# ===== [Step10-13] API でマスターデータ登録 =====

# ※ country が先に登録されている必要がある
if run_from 10; then
  echo "=== [Step10] 経済指標登録 ==="
  while IFS=',' read -r code country_code importance name description unit_of_value; do
    code=$(echo "$code" | tr -d '"')
    country_code=$(echo "$country_code" | tr -d '"')
    importance=$(echo "$importance" | tr -d '"')
    name=$(echo "$name" | tr -d '"')
    description=$(echo "$description" | tr -d '"')
    unit_of_value=$(echo "$unit_of_value" | tr -d '"')

    echo "  登録: $code / $country_code / $name"
    bru run "setup/200_master_data/step10_economic_indicator_register.bru" \
      --env local \
      --env-var "idToken=$ID_TOKEN" \
      --env-var "code=$code" \
      --env-var "countryCode=$country_code" \
      --env-var "importance=$importance" \
      --env-var "name=$name" \
      --env-var "description=$description" \
      --env-var "unitOfValue=$unit_of_value"
  done < <(tail -n +2 "$DATA_DIR/economic_indicator.csv")
  echo ""
fi

# ※ economic_indicator.csv 登録後の実際の id（自動採番）を反映済みであること
if run_from 11; then
  echo "=== [Step11] 経済指標データ登録 ==="
  while IFS=',' read -r code country_code publication sub_title result_value forecast_value previous_value memo; do
    code=$(echo "$code" | tr -d '"')
    country_code=$(echo "$country_code" | tr -d '"')
    publication=$(echo "$publication" | tr -d '"')
    sub_title=$(echo "$sub_title" | tr -d '"')
    result_value=$(echo "$result_value" | tr -d '"')
    forecast_value=$(echo "$forecast_value" | tr -d '"')
    previous_value=$(echo "$previous_value" | tr -d '"')
    memo=$(echo "$memo" | tr -d '"')

    echo "  登録: $code / $country_code ($publication)"
    bru run "setup/200_master_data/step11_economic_indicator_data_register.bru" \
      --env local \
      --env-var "idToken=$ID_TOKEN" \
      --env-var "code=$code" \
      --env-var "countryCode=$country_code" \
      --env-var "publication=$publication" \
      --env-var "subTitle=$sub_title" \
      --env-var "resultValue=$result_value" \
      --env-var "forecastValue=$forecast_value" \
      --env-var "previousValue=$previous_value" \
      --env-var "memo=$memo"
  done < <(tail -n +2 "$DATA_DIR/economic_indicator_data.csv")
  echo ""
fi

# uploadFileList は同一フィールド名で複数ファイルを送る必要があるため curl で直接実行
if run_from 12; then
  echo "=== [Step12] 経済指標データ テキストインポート ==="
  curl -sf -X POST \
    -H "Authorization: Bearer $ID_TOKEN" \
    -F "uploadFileList=@$DATA_DIR/2026_03_H.txt" \
    -F "uploadFileList=@$DATA_DIR/2026_03_M.txt" \
    "${API_BASE}/fx/economic-indicator-data/import-text"
  echo ""
  echo ""
fi

if run_from 13; then
  echo "=== [Step13] ZigZag 生成 ==="
  ZIGZAG_BAR_TYPES=("15M" "1H" "4H" "1D")
  ZIGZAG_DEPTH=3
  ZIGZAG_BAR_DATE_TIME="2026-03-01T00:00:00+09:00"
  ZIGZAG_LOAD_SIZE=1000

  while IFS=',' read -r symbol symbol_type name valid_scale target_volatility sort_order; do
    symbol=$(echo "$symbol" | tr -d '"')

    for bar_type in "${ZIGZAG_BAR_TYPES[@]}"; do
      echo "  生成: $symbol / $bar_type"
      bru run "setup/200_master_data/step13_zigzag_generate.bru" \
        --env local \
        --env-var "idToken=$ID_TOKEN" \
        --env-var "symbol=$symbol" \
        --env-var "barType=$bar_type" \
        --env-var "depth=$ZIGZAG_DEPTH" \
        --env-var "barDateTime=$ZIGZAG_BAR_DATE_TIME" \
        --env-var "loadSize=$ZIGZAG_LOAD_SIZE" \
        || echo "    スキップ（バーデータ未登録の可能性）: $symbol / $bar_type"
    done
  done < <(tail -n +2 "$DATA_DIR/symbol.csv")
  echo ""
fi

echo "=== 登録完了 ==="
