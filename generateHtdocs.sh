#!/bin/bash

. structure
[[ "$1" == "" ]] && echo "Usage: $0 <year>" && exit 1
year=$1

cd generated

mkdir -p htdocs/crt/g2/$year

for ca in root $STRUCT_CAS; do
    cp $ca.ca/key.crt htdocs/crt/g2/$ca.crt
done

for i in $TIME_IDX; do
    cp $year/ca/env_${year}_${i}.ca/key.crt htdocs/crt/g2/$year/env-${year}-${i}.crt
done
for ca in $STRUCT_CAS; do
    [[ "$ca" == "env" ]] && continue
    for i in $TIME_IDX; do
	cp $year/ca/${ca}_${year}_${i}.crt htdocs/crt/g2/$year/${ca}-${year}-${i}.crt
    done
done

tar czf htdocs.tgz htdocs
rm -R htdocs
