#!/bin/sh

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
    mkdir -p signer-config/ca/${ca}_${year}_1
    cp ${year}/ca/${ca}_${year}_1.crt  signer-config/ca/${ca}_${year}_1/ca.crt
done

installCommKeys client

tar czf signer-client-$year.tar.gz profiles -C signer-config keys ca

# Updating for server
rm signer-config/keys/signer_*

for ca in $STRUCT_CAS; do
    [ "$ca" == "env" ] && continue
    cp ${year}/ca/${ca}_${year}_1.key  signer-config/ca/${ca}_${year}_1/ca.key
done

installCommKeys server

tar czf signer-server-$year.tar.gz profiles -C signer-config keys ca

rm -R signer-config
