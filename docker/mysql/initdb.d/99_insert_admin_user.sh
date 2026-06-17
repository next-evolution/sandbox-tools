#!/bin/bash
set -e

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" <<-EOSQL
    INSERT INTO \`sandbox_user\` VALUES
    (
      1
      ,'${ADMIN_UUID}'
      ,'${ADMIN_EMAIL}'
      ,'system-admin'
      ,1
      ,'2026-06-01 00:00:00'
      ,1
      ,0
      ,0
      ,'2026-06-01 00:00:00'
      ,'initialize'
      ,'2026-06-01 00:00:00'
      ,'initialize'
    );
EOSQL
