#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if [ ! -f "jmeter.env" ]; then
  echo "ERROR: jmeter.env が見つかりません。jmeter.env.example をコピーして作成してください。"
  echo "  cp jmeter/jmeter.env.example jmeter/jmeter.env"
  exit 1
fi
source jmeter.env

execDateTime=`date +'%Y%m%d_%H%M%S'`
jmxPrefix=$1
resultSuffix=$2
loops=${4:-1}
rampUp=${5:-1}
jmxFile=${jmxPrefix}.jmx
outputDir=result/${resultSuffix}

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <jmxPrefix> <resultSuffix> [threads] [loops] [rampUp]"
  echo "  jmxPrefix    : JMX ファイル名のプレフィックス (例: scenarios/sandbox)"
  echo "  resultSuffix : 結果フォルダの suffix (例: 20240614_001)"
  echo "  threads      : スレッド数 (デフォルト: login-user.csv のデータ行数)"
  echo "  loops        : ループ数 (デフォルト: 1)"
  echo "  rampUp       : Ramp-up 秒数 (デフォルト: 1)"
  exit 1
fi

USER_COUNT=0
if [ -f "data/login-user.csv" ]; then
  USER_COUNT=$(( $(wc -l < "data/login-user.csv") - 1 ))
fi

threads=${3:-${USER_COUNT}}

mkdir -pv ${outputDir}

echo "execDateTime=${execDateTime}"
echo "jmxPrefix=${jmxPrefix}"
echo "resultSuffix=${resultSuffix}"
echo "threads=${threads}"
echo "loops=${loops}"
echo "rampUp=${rampUp}"
echo "USER_COUNT=${USER_COUNT}"
echo "jmxFile=${jmxFile}"
echo "outputDir=${outputDir}"
echo "API_SCHEME=${API_SCHEME}"
echo "API_HOST=${API_HOST}"
echo "API_PORT=${API_PORT}"
echo "API_ROOT=${API_ROOT}"
echo "COGNITO_REGION=${COGNITO_REGION}"

jmeter -n \
  -t ${jmxFile} \
  -j ${outputDir}/jmeter.log \
  -JresultSuffix=${resultSuffix} \
  -Jthreads=${threads} \
  -Jloops=${loops} \
  -JrampUp=${rampUp} \
  -JUSER_COUNT=${USER_COUNT} \
  -JAPI_SCHEME=${API_SCHEME} \
  -JAPI_HOST=${API_HOST} \
  -JAPI_PORT=${API_PORT} \
  -JAPI_ROOT=${API_ROOT} \
  -JAPI_CHARSET=${API_CHARSET} \
  -JCOGNITO_REGION=${COGNITO_REGION} \
  -JCOGNITO_CLIENT_ID=${COGNITO_CLIENT_ID} \
  -JDEBUG_MODE=${DEBUG_MODE} \
  |tee -a ${outputDir}/jmeter-console.log
