#!/bin/sh
set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure

verify(){ # CAfile, crt
    openssl verify -CAfile "$1" "$2" || error "$2 did not verify"
}

error() { # message
    echo $1
    exit -1
}

# Verify root
verify root.ca/key.crt root.ca/key.crt

# Verify level-1 structure
for i in $STRUCT_CAS; do
    verify root.ca/key.crt $i.ca/key.crt
done

# Verify level-2 (time) structure
for i in $STRUCT_CAS; do
    . CAs/$i
    if [ "$i" == "env" ]; then
	CA_FILE=$year/ca/${i}_${year}_1.ca/key.crt
    else
	CA_FILE=$year/ca/${i}_${year}_1.crt
    fi
    verify <(cat root.ca/key.crt $i.ca/key.crt) "$CA_FILE"
    openssl x509 -in "$CA_FILE" -noout -text | grep "CA Issuers" | grep "/$i.crt" > /dev/null || error "CA Issuers field is wrong for $i"
    openssl x509 -in "$CA_FILE" -noout -text | grep "Subject: " | grep "CN=$name" > /dev/null || error "Subject field did not verify"
done

# Verify infra keys
cat root.ca/key.crt env.ca/key.crt $year/ca/env_${year}_1.ca/key.crt > envChain.crt

for i in $SERVER_KEYS; do
    verify envChain.crt ${year}/keys/$i.crt
done

rm envChain.crt

