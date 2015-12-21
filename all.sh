#!/bin/bash

date


for arg in "$@"; do
    if [[ "$arg" == "root" ]]; then
	echo "========== Generating Root ======="
	./clear.sh
	./generateKeys.sh
    else
	echo "========== Generating Year $arg ======="
	./generateTime.sh "$arg"
	echo "========== Generating Infra for Year $arg ======="
	./generateInfra.sh "$arg"
	echo "========== Generating CRLs for Year $arg ======="
	./generateCRLs.sh "$arg"
	
	
	echo "========== Verifying Year $arg ======="
	./verify.sh "$arg"
	
	
	echo "========== Collection things ======="
	./collectCRLs.sh "$arg"
	./collectGigiConfig.sh "$arg"
	./collectOffline.sh "$arg"
	./collectSignerConfig.sh "$arg"
	
	./summary.sh "$arg"
    fi
done


