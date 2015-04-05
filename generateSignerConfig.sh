#!/bin/bash

set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure

installCommKeys() { # peer (server,client)
    peer="$1"
    mkdir -p signer-config/keys
    cp ${year}/ca/env_${year}_1.ca/key.crt signer-config/keys/ca.crt
    for file in signer_${peer}.{crt,key}; do
	cp ${year}/keys/$file signer-config/keys/$file
    done

}

mkdir -p signer-config
for ca in $STRUCT_CAS; do
    [ "$ca" == "env" ] && continue
    for i in $TIME_IDX; do
	mkdir -p signer-config/ca/${ca}_${year}_${i}
	cp ${year}/ca/${ca}_${year}_${i}.crt  signer-config/ca/${ca}_${year}_${i}/ca.crt
    done
done

installCommKeys client

tar czf signer-client-$year.tar.gz profiles -C signer-config keys ca

# Updating for server
rm signer-config/keys/signer_*

for ca in $STRUCT_CAS; do
    [ "$ca" == "env" ] && continue
    for i in $TIME_IDX; do
	cp ${year}/ca/${ca}_${year}_${i}.key  signer-config/ca/${ca}_${year}_${i}/ca.key
    done
done

installCommKeys server

tar czf signer-server-$year.tar.gz profiles -C signer-config keys ca

rm -R signer-config
