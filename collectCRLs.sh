#!/bin/bash

set -e

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
. commonFunctions

fetchCRLS(){ #year, cyear month timeIdx
    year=$1
    cyear=$2
    month=$3
    timeIdx=$4
    cp $year/ca/env_${year}_${timeIdx}.ca/${cyear}_${month}.crl crls-${year}/$year-$month/${year}/env_${year}_${timeIdx}.crl	
    # no "for ca in $STRUCT_CAs" because that's cassiopeias work.
}

mkdir -p crls-${year}
for month in {01..12}; do
    BASE=crls-${year}/$year-$month
    mkdir -p $BASE
    cp root.ca/${year}_${month}.crl $BASE/root.crl
    for ca in $STRUCT_CAS; do
	cp $ca.ca/${year}_${month}.crl $BASE/$ca.crl
    done
done

cyear=$year
for month in {01..12}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 1
    [ "$month" -gt "6" ] && fetchCRLS $year $cyear $month 2
done

cyear=$((year+1))
for month in {01..12}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 1
    fetchCRLS $year $cyear $month 2
done

cyear=$((year+2))
for month in {01..06}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 2
done

pushd crls-${year}
for i in *; do
    tar czf $i.tgz -C $i .
done
popd
