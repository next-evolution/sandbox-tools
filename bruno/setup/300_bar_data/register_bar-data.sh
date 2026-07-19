#!/usr/bin/env bash
# ログイン後、バーデータ・ZigZag 関連データを一括登録する。
#
# 実行順序:
#   [Step01] ZigZag データ投入        直接 DB INSERT
#   [Step02] バーデータ CSV インポート POST:/api/v1/fx/bar-data/import-csv/{symbol}/{barType}/{skipLatest}
#   [Step03] ZigZag 生成              POST:/api/v1/fx/zigzag/generate
#
# 前提:
#   - bru (Bruno CLI) がインストール済み: npm install -g @usebruno/cli
#   - environments/local.bru が作成済み（email, password, cognitoClientId 等を設定）
#   - tools/data/ 配下の CSV / バーデータファイルが存在する
#   - setup/200_master_data/register.sh 実行済み（Step04 シンボル登録が完了していること）
#
# 実行:
#   ./setup/300_bar_data/register_bar-data.sh [--from-step N]
#
# --from-step N: ステップ N から再開する（省略時は 1 から全て実行）
#
# ※ Cognito ログイン・Sandbox API ログインは --from-step に関わらず常に実行する
#   （bru run は毎回別プロセスのため、idToken を毎回シェル変数として取得する）

set -euo pipefail

FROM_STEP=1
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

# DB接続情報（Step01 で使用）
if [[ $FROM_STEP -le 1 ]]; then
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
# Cognito ログイン・Sandbox API ログインを curl で行い idToken をシェル変数として保持する
echo "=== ログイン（Cognito） ==="
COGNITO_RESPONSE=$(curl -sf -X POST \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  "https://cognito-idp.${COGNITO_REGION}.amazonaws.com/" \
  -d "{\"AuthFlow\":\"USER_PASSWORD_AUTH\",\"ClientId\":\"${COGNITO_CLIENT_ID}\",\"AuthParameters\":{\"USERNAME\":\"${EMAIL}\",\"PASSWORD\":\"${PASSWORD}\"}}")
ID_TOKEN=$(echo "$COGNITO_RESPONSE" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['AuthenticationResult']['IdToken'])")
EMAIL_ENCODED=$(printf '%s' "$EMAIL" | base64)
echo "  idToken 取得済み"

echo "=== ログイン（Sandbox API） ==="
curl -sf -X POST \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  "${API_BASE}/auth/login" \
  -d "{\"email\":\"$EMAIL_ENCODED\"}" > /dev/null
echo "  ログイン済み"
echo ""

# ===== [Step01] ZigZag データ投入（直接 DB INSERT） =====

if run_from 1; then
  echo "=== [Step01] ZigZag データ投入 ==="
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

# ===== [Step02] バーデータ CSV インポート =====

if run_from 2; then
  echo "=== [Step02] バーデータ CSV インポート ==="
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

# ===== [Step03] ZigZag 生成 =====

if run_from 3; then
  echo "=== [Step03] ZigZag 生成 ==="
  ZIGZAG_BAR_TYPES=("15M" "1H" "4H" "1D")
  ZIGZAG_DEPTH=3
  ZIGZAG_BAR_DATE_TIME="2026-03-01T00:00:00+09:00"
  ZIGZAG_LOAD_SIZE=1000

  while IFS=',' read -r symbol symbol_type name valid_scale target_volatility sort_order; do
    symbol=$(echo "$symbol" | tr -d '"')

    for bar_type in "${ZIGZAG_BAR_TYPES[@]}"; do
      echo "  生成: $symbol / $bar_type"
      bru run "setup/300_bar_data/step03_zigzag_generate.bru" \
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
