#!/bin/bash

. structure
. commonFunctions

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

genTimeCA(){ #csr,ca to sign with,start,end
    cat <<TESTCA > timesubca.cnf
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always

crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/$2.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/$2.crt
TESTCA
    caSign $1 $2 timesubca.cnf "$3" "$4"
    rm timesubca.cnf
}

mkdir -p $year/ca


STARTDATE="${year}"
ENDDATE="$((${year} + 3))"

for i in $TIME_IDX; do
    point=${points[${i}]}
    . CAs/env
    genca "/CN=$name ${year}-${i}" $year/ca/env_${year}_${i}
    genTimeCA $year/ca/env_${year}_${i}.ca/key env "$STARTDATE$point" "$ENDDATE$point"
    
    for ca in $STRUCT_CAS; do
	[ "$ca" == "env" ] && continue
	. CAs/$ca
	genKey "/CN=$name ${year}-${i}" $year/ca/${ca}_${year}_${i}
	genTimeCA $year/ca/${ca}_${year}_${i} $ca "$STARTDATE$point" "$ENDDATE$point"
    done
done
