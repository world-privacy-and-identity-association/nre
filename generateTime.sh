#!/bin/sh

. structure
. commonFunctions

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

genTimeCA(){ #csr,ca to sign with,start,end
    cat <<TESTCA > timesubca.cnf
basicConstraints = CA:true
subjectKeyIdentifier = hash
keyUsage = keyCertSign, cRLSign
crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/$2.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/$2.crt
TESTCA
    caSign $1 $2 timesubca.cnf "$3" "$4"
    rm timesubca.cnf
}

mkdir -p $year/ca

STARTDATE="${year:2}0101000000Z"
ENDDATE="$((${year:2} + 2))0101000000Z"

. CAs/env
genca "/CN=$name ${year}-1" $year/ca/env_${year}_1
genTimeCA $year/ca/env_${year}_1.ca/key env "$STARTDATE" "$ENDDATE"

for ca in $STRUCT_CAS; do
    [ "$ca" == "env" ] && continue
    . CAs/$ca
    genKey "/CN=$name ${year}-1" $year/ca/${ca}_${year}_1
    genTimeCA $year/ca/${ca}_${year}_1 $ca "$STARTDATE" "$ENDDATE"
done
