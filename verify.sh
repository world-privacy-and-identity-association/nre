#!/bin/bash
set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure

verify(){ # crt, [untrusted], additional
    untrusted="$2"
    [[ "$untrusted" != "" ]] && untrusted="-untrusted $untrusted"
    openssl verify $3 -CAfile root.ca/key.crt $untrusted "$1" || error "$1 did not verify"
}

error() { # message
    echo $1
    exit -1
}

# Verify root
verify root.ca/key.crt

# Verify level-1 structure
for ca in $STRUCT_CAS; do
    verify $ca.ca/key.crt
done

# Verify level-2 (time) structure
for ca in ${STRUCT_CAS}; do
    for i in $TIME_IDX; do
	. CAs/$ca
	if [ "$ca" == "env" ]; then
	    CA_FILE=$year/ca/${ca}_${year}_${i}.ca/key.crt
	else
	    CA_FILE=$year/ca/${ca}_${year}_${i}.crt
	fi
	time=${points[${i}]}
	timestamp=$(date --date="${time:0:2}/${time:2:2}/${year} 03:00:00 UTC" +"%s")
	verify "$CA_FILE" "$ca.ca/key.crt" "-attime ${timestamp}"
	openssl x509 -in "$CA_FILE" -noout -text | grep "CA Issuers" | grep "/$ca.crt" > /dev/null || error "CA Issuers field is wrong for $ca"
	openssl x509 -in "$CA_FILE" -noout -text | grep "Subject: " | grep "CN=$name" > /dev/null || error "Subject field did not verify"
    done
done

# Verify infra keys
cat env.ca/key.crt $year/ca/env_${year}_1.ca/key.crt > envChain.crt

for key in $SERVER_KEYS; do
    verify ${year}/keys/$key.crt envChain.crt
done

rm envChain.crt

