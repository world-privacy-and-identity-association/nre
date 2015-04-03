#!/bin/sh

set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure

mkdir -p signer-client
for ca in $STRUCT_CAS; do
    [ "$ca" == "env" ] && continue
    mkdir -p signer-client/ca/${ca}_${year}_1
    cp ${year}/ca/${ca}_${year}_1.crt  signer-client/ca/${ca}_${year}_1/ca.crt
done
mkdir -p signer-client/keys
for file in signer_client.{crt,key}; do
    cp ${year}/keys/$file signer-client/keys/$file
done

tar czf signer-client-$year.tar.gz profiles -C signer-client keys ca
rm -R signer-client
