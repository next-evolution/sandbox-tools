#!/bin/bash

#--------------------------------------------------
# manual install
#
# yum -y install mariadb1011 zip
#--------------------------------------------------

EXEC_DATE_TIME=`date +'%Y%m%d_%H%M%S'`
BACKUP_DIR=`pwd`
BACKUP_SCHEMA=sandbox1

export TABLE_LIST=`cat <<EOF
fx_bar_15m
fx_bar_15m_rsi
fx_bar_15m_sma
fx_bar_1d
fx_bar_1d_rsi
fx_bar_1d_sma
fx_bar_1h
fx_bar_1h_rsi
fx_bar_1h_sma
fx_bar_4h
fx_bar_4h_rsi
fx_bar_4h_sma
fx_country
fx_economic_indicator
fx_economic_indicator_data
fx_summer_time
fx_symbol
fx_zigzag_15m
fx_zigzag_1d
fx_zigzag_1h
fx_zigzag_4h
fx_zigzag_wave_15m
fx_zigzag_wave_1d
fx_zigzag_wave_1h
fx_zigzag_wave_4h
sandbox_user
EOF`

mkdir -p ${BACKUP_DIR}/${BACKUP_SCHEMA}-${EXEC_DATE_TIME}

for table in $TABLE_LIST
do
  echo "----- ${table} -----"
  mysqldump -uroot -ppassword --no-create-info ${BACKUP_SCHEMA} ${table} > ${BACKUP_DIR}/${BACKUP_SCHEMA}-${EXEC_DATE_TIME}/${table}.dmp
done

echo "backup to ${BACKUP_DIR}/${BACKUP_SCHEMA}-${EXEC_DATE_TIME}"
