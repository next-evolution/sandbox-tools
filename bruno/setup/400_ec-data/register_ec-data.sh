#!/usr/bin/env bash
# ログイン後、経済指標データ（実績値）を一括登録する。
#
# 実行順序:
#   [Step01] 経済指標データ登録              POST:/api/v1/fx/economic-indicator-data
#   [Step02] 経済指標データ テキストインポート POST:/api/v1/fx/economic-indicator-data/import-text
#
# 前提:
#   - bru (Bruno CLI) がインストール済み: npm install -g @usebruno/cli
#   - environments/local.bru が作成済み（email, password, cognitoClientId 等を設定）
#   - tools/data/ 配下の CSV / テキストファイルが存在する
#   - setup/200_master_data/register.sh 実行済み（Step07 経済指標登録が完了していること）
#
# 実行:
#   ./setup/400_ec-data/register_ec-data.sh [--from-step N]
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

# ===== [Step01] 経済指標データ登録 =====

# ※ economic_indicator.csv 登録後の実際の id（自動採番）を反映済みであること
if run_from 1; then
  echo "=== [Step01] 経済指標データ登録 ==="
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
    bru run "setup/400_ec-data/step01_economic_indicator_data_register.bru" \
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
if run_from 2; then
  echo "=== [Step02] 経済指標データ テキストインポート ==="
  curl -sf -X POST \
    -H "Authorization: Bearer $ID_TOKEN" \
    -F "uploadFileList=@$DATA_DIR/2026_03_H.txt" \
    -F "uploadFileList=@$DATA_DIR/2026_03_M.txt" \
    "${API_BASE}/fx/economic-indicator-data/import-text"
  echo ""
  echo ""
fi

echo "=== 登録完了 ==="
