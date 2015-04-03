#!/bin/sh

. ./clear.sh

echo "========== Generating Root ======="
. ./generateKeys.sh
echo "========== Generating Year 2015 ======="
. ./generateTime.sh 2015
echo "========== Generating Infra for Year 2015 ======="
. ./generateInfra.sh 2015
echo "========== Verifying Year 2015 ======="
. ./verify.sh 2015
