#!/bin/bash

. structure
. commonFunctions

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

cd generated

genTimeCA(){ #csr,ca to sign with,start,end
    cat <<TESTCA > timesubca.cnf
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always

crlDistributionPoints=URI:http://g2.crl.${DOMAIN}/g2/$2.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.${DOMAIN},caIssuers;URI:http://g2.crt.${DOMAIN}/g2/$2.crt
TESTCA
    caSign $1 $2 timesubca.cnf "$3" "$4"
    rm timesubca.cnf
}

mkdir -p $year/ca


for i in $TIME_IDX; do
    point=${year}${points[${i}]}
    nextp=${points[$((${i} + 1))]}
    if [[ "$nextp" == "" ]]; then
	epoint=$((${year} + 3 ))${epoints[${i}]}
    else
	epoint=$((${year} + 2 ))${epoints[${i}]}
    fi

    . ../CAs/env
    genca "/CN=$name ${year}-${i}" $year/ca/env_${year}_${i}
    genTimeCA $year/ca/env_${year}_${i}.ca/key env "$point" "$epoint"
    
    for ca in $STRUCT_CAS; do
	[ "$ca" == "env" ] && continue
	. ../CAs/$ca
	genKey "/CN=$name ${year}-${i}" $year/ca/${ca}_${year}_${i}
	genTimeCA $year/ca/${ca}_${year}_${i} $ca "$point" "$epoint"
    done
done
