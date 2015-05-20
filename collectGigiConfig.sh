#!/bin/bash

set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
cd generated

mkdir -p gigi-config/ca
cp root.ca/key.crt gigi-config/ca/root.crt
for ca in $STRUCT_CAS; do
    cp ${ca}.ca/key.crt gigi-config/ca/${ca}.crt
    [ "$ca" == "env" ] && continue
    for i in $TIME_IDX; do
	cp ${year}/ca/${ca}_${year}_${i}.crt gigi-config/ca/${ca}_${year}_${i}.crt
    done
done

tar czf gigi-$year.tar.gz -C .. profiles -C generated/gigi-config ca

rm -Rf gigi-config
