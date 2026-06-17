#!/usr/bin/env bash
# user.csv の各ユーザーに対して初期化フロー（Step01〜10）を実行する。
# Step08（管理者権限付与）は最初の1件のみ実行する。
#
# 前提:
#   - bru (Bruno CLI) がインストール済み: npm install -g @usebruno/cli
#   - environments/local.bru が作成済み（local.bru.example をコピーして編集）
#   - tools/data/user.csv と admin_user.csv が存在する
#
# 実行:
#   ./setup/100_initialize/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="$(cd "$TOOL_DIR/../data" && pwd)"

echo "Bruno コレクションルート: $TOOL_DIR"
echo "データディレクトリ: $DATA_DIR"
echo ""

# 必要なファイルの存在確認
for f in user.csv admin_user.csv; do
  if [[ ! -f "$DATA_DIR/$f" ]]; then
    echo "ERROR: $DATA_DIR/$f が見つかりません"
    echo "  cp $DATA_DIR/$f.example $DATA_DIR/$f"
    echo "  を実行して内容を設定してください"
    exit 1
  fi
done

if [[ ! -f "$TOOL_DIR/environments/local.bru" ]]; then
  echo "ERROR: $TOOL_DIR/environments/local.bru が見つかりません"
  echo "  cp $TOOL_DIR/environments/local.bru.example $TOOL_DIR/environments/local.bru"
  echo "  を実行して内容を設定してください"
  exit 1
fi

# local.bru から環境変数を取得する
# ※ \s は macOS BSD sed 非対応のため [[:space:]] を使用
get_bru_env_var() {
  grep -E "^\s*${1}:" "$TOOL_DIR/environments/local.bru" | sed -E "s/^[[:space:]]*${1}:[[:space:]]*//"
}

COGNITO_REGION=$(get_bru_env_var "cognitoRegion")
COGNITO_CLIENT_ID=$(get_bru_env_var "cognitoClientId")
API_SCHEME=$(get_bru_env_var "apiScheme")
API_HOST=$(get_bru_env_var "apiHost")
API_PORT=$(get_bru_env_var "apiPort")
API_ROOT=$(get_bru_env_var "apiRoot")
API_BASE="${API_SCHEME}://${API_HOST}:${API_PORT}${API_ROOT}"

# admin_user.csv から管理者情報を取得（1行目のデータ行）
ADMIN_ROW=$(tail -n +2 "$DATA_DIR/admin_user.csv" | head -1)
ADMIN_EMAIL=$(echo "$ADMIN_ROW" | cut -d',' -f1 | tr -d '"')
ADMIN_PASSWORD=$(echo "$ADMIN_ROW" | cut -d',' -f2 | tr -d '"')

# bru run はコレクションルートから実行する必要がある
cd "$TOOL_DIR"

# Cognito からトークンを取得するヘルパー
# bru.setEnvVar() は別プロセス間で共有されないため curl を使用し shell 変数として保持する
cognito_login() {
  local login_email="$1"
  local login_password="$2"
  curl -sf -X POST \
    -H "Content-Type: application/x-amz-json-1.1" \
    -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
    "https://cognito-idp.${COGNITO_REGION}.amazonaws.com/" \
    -d "{\"AuthFlow\":\"USER_PASSWORD_AUTH\",\"ClientId\":\"${COGNITO_CLIENT_ID}\",\"AuthParameters\":{\"USERNAME\":\"${login_email}\",\"PASSWORD\":\"${login_password}\"}}" \
    | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['AuthenticationResult']['IdToken'])"
}

USER_INDEX=0

# user.csv をヘッダー行スキップしてループ
while IFS=',' read -r email password nickName; do
  email=$(echo "$email" | tr -d '"')
  password=$(echo "$password" | tr -d '"')
  nickName=$(echo "$nickName" | tr -d '"')

  echo "======================================"
  echo "ユーザー処理[$((USER_INDEX + 1))]: $email"
  echo "======================================"

  # --- [Step01] 一般ユーザー Cognito ログイン ---
  echo "[Step01] Cognito ログイン（一般ユーザー）..."
  ID_TOKEN=$(cognito_login "$email" "$password")
  EMAIL_ENCODED=$(printf '%s' "$email" | base64)
  echo "  idToken 取得済み"

  # --- [Step02] Sandbox API 初回ログイン（returnCode:1 Warn 期待） ---
  echo "[Step02] Sandbox API 初回ログイン（Warn 期待）..."
  bru run "setup/100_initialize/step02_sandbox_login_warn.bru" \
    --env local \
    --env-var "idToken=$ID_TOKEN" \
    --env-var "emailEncoded=$EMAIL_ENCODED"

  # --- [Step03] ユーザー登録 ---
  echo "[Step03] ユーザー登録 (POST /api/v1/user)..."
  bru run "setup/100_initialize/step03_user_register.bru" \
    --env local \
    --env-var "idToken=$ID_TOKEN" \
    --env-var "nickName=$nickName"

  # --- [Step04] 管理者 Cognito ログイン ---
  echo "[Step04] Cognito ログイン（管理者）..."
  ADMIN_ID_TOKEN=$(cognito_login "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  ADMIN_EMAIL_ENCODED=$(printf '%s' "$ADMIN_EMAIL" | base64)
  echo "  adminIdToken 取得済み"

  # --- [Step05] Sandbox API ログイン（管理者） ---
  echo "[Step05] Sandbox API ログイン（管理者）..."
  bru run "setup/100_initialize/step05_admin_sandbox_login.bru" \
    --env local \
    --env-var "adminIdToken=$ADMIN_ID_TOKEN" \
    --env-var "adminEmailEncoded=$ADMIN_EMAIL_ENCODED"

  # --- [Step06] ユーザー検索（curl で userId を取得） ---
  # bru.setEnvVar() は別プロセスに引き継げないため curl で直接レスポンスを解析する
  echo "[Step06] ユーザー検索 (POST /api/v1/admin/users)..."
  USER_SEARCH_RESPONSE=$(curl -sf -X POST \
    -H "Authorization: Bearer $ADMIN_ID_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"emailAddress\":\"${email}\",\"approved\":false,\"page\":1,\"size\":10}" \
    "${API_BASE}/admin/users")
  USER_ID=$(echo "$USER_SEARCH_RESPONSE" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d['list'][0]['userId'])")
  USER_ID_ENCODED=$(printf '%s' "$USER_ID" | base64)
  echo "  userId 取得済み: $USER_ID"

  # --- [Step07] ユーザー承認 ---
  echo "[Step07] ユーザー承認 (PUT /api/v1/admin/users/approved/{userId})..."
  bru run "setup/100_initialize/step07_user_approved.bru" \
    --env local \
    --env-var "adminIdToken=$ADMIN_ID_TOKEN" \
    --env-var "userIdEncoded=$USER_ID_ENCODED"

  # Step08 は最初のユーザーのみ実行
  if [[ $USER_INDEX -eq 0 ]]; then
    echo "[Step08] 管理者権限付与（初回ユーザーのみ）..."
    bru run "setup/100_initialize/step08_admin_grant.bru" \
      --env local \
      --env-var "adminIdToken=$ADMIN_ID_TOKEN" \
      --env-var "userIdEncoded=$USER_ID_ENCODED"
  else
    echo "[Step08] スキップ（管理者権限付与は初回ユーザーのみ）"
  fi

  # --- [Step09] Cognito 再ログイン（承認後の新しい idToken を取得） ---
  echo "[Step09] Cognito 再ログイン（一般ユーザー）..."
  ID_TOKEN=$(cognito_login "$email" "$password")
  echo "  idToken（再取得）済み"

  # --- [Step10] Sandbox API 再ログイン（returnCode:0 Ok 期待） ---
  echo "[Step10] Sandbox API 再ログイン（Ok 期待）..."
  bru run "setup/100_initialize/step10_sandbox_relogin.bru" \
    --env local \
    --env-var "idToken=$ID_TOKEN" \
    --env-var "emailEncoded=$EMAIL_ENCODED"

  echo "完了: $email"
  echo ""
  USER_INDEX=$((USER_INDEX + 1))
done < <(tail -n +2 "$DATA_DIR/user.csv")

echo "======================================"
echo "初期化完了: ${USER_INDEX}ユーザー処理済み"
echo "======================================"
