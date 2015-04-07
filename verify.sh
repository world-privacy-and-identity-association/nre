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

verifyExtlist() { # ext
	EXTLIST=`echo "$1" | grep "X509v3\|Authority Information" | sed "s/^[ \t]*//"`
	VAR="X509v3 extensions:
X509v3 Basic Constraints: $2
X509v3 Key Usage: 
${3}X509v3 Subject Key Identifier: 
X509v3 Authority Key Identifier: 
X509v3 CRL Distribution Points: 
Authority Information Access: "

	diff <(echo "$EXTLIST" | dos2unix) <(echo "$VAR" | dos2unix) || error "Extensions order is wrong for $ca"

}

# Verify root
verify root.ca/key.crt
verifyExtlist "$(openssl x509 -in "root.ca/key.crt" -noout -text)"

# Verify level-1 structure
for ca in $STRUCT_CAS; do
    verify $ca.ca/key.crt
    verifyExtlist "$(openssl x509 -in "$ca.ca/key.crt" -noout -text)"
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
	EXT=`openssl x509 -in "$CA_FILE" -noout -text`

	verifyExtlist "$EXT"

	echo "$EXT" | grep "Subject: " | grep "CN=$name" > /dev/null || error "Subject field did not verify"

	echo "$EXT" | grep -A 2 "Basic Constraints" | grep "CA:TRUE" > /dev/null || error "Basic Constraints field is wrong for $ca"
	echo "$EXT" | grep -A 2 "Key Usage" | grep "^ *Certificate Sign, CRL Sign$" > /dev/null || error "KeyUsage field is wrong for $ca"

	echo "$EXT" | grep -A 4 "CRL Distribution" | grep "g2.crl.cacert.org/g2/$ca.crl" > /dev/null || error "CRL field is wrong for $ca"
	echo "$EXT" | grep "CA Issuers" | grep "/$ca.crt" | grep "g2.crt.cacert.org/g2/" > /dev/null || error "CA Issuers field is wrong for $ca"
	echo "$EXT" | grep "OCSP" | grep "http://g2.ocsp.cacert.org" > /dev/null || error "OCSP field is wrong for $ca"
    done
done

# Verify infra keys
cat env.ca/key.crt $year/ca/env_${year}_1.ca/key.crt > envChain.crt

for key in $SERVER_KEYS; do
    verify ${year}/keys/$key.crt envChain.crt
    verifyExtlist "$(openssl x509 -in "${year}/keys/$key.crt" -noout -text)" critical "X509v3 Extended Key Usage: 
"
done

rm envChain.crt

