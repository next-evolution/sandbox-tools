#!/usr/bin/env bash
# ログインシナリオを順番に実行する。
# vars:secret の email / password は Bruno CLI が env ファイルから展開しないため
# local.bru から読み取って --env-var で渡す。
#
# 実行:
#   ./scenarios/login/login.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

get_bru_env_var() {
  grep -E "^\s*${1}:" "$TOOL_DIR/environments/local.bru" | sed -E "s/^[[:space:]]*${1}:[[:space:]]*//"
}

cd "$TOOL_DIR"

EMAIL=$(get_bru_env_var "email")
PASSWORD=$(get_bru_env_var "password")

echo "=== ログイン ==="
# 同一プロセスで実行することで step01 の bru.setEnvVar("idToken") を後続ステップに引き継ぐ
bru run "scenarios/login/" \
  --env local \
  --env-var "email=$EMAIL" \
  --env-var "password=$PASSWORD"

echo "=== 完了 ==="
