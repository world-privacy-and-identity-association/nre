#!/bin/sh
#
set -e

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
. commonFunctions

CRL="
crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/$year/env.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/$year/env.crt"

cat <<TESTCA > req.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
$CRL
TESTCA

cat <<TESTCA > reqClient.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
$CRL
TESTCA

cat <<TESTCA > reqMail.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=emailProtection
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
$CRL
TESTCA

genserver(){ #key, subject, config
    openssl genrsa -out $1.key ${KEYSIZE}
    openssl req -new -key $1.key -out $1.csr -subj "$2"
    caSign $1 $year/ca/env_${year}_1 "$3"
    
    openssl pkcs12 -inkey $1.key -in $1.crt -CAfile env.chain.crt -chain -name $1 -export -passout pass:changeit -out $1.pkcs12
    
}

mkdir -p $year/keys

cat $year/ca/env_${year}_1.ca/key.crt env.ca/key.crt root.ca/key.crt > env.chain.crt

# generate environment-keys specific to gigi.
# first the server keys
genserver $year/keys/www "/CN=www.${DOMAIN}" req.cnf
genserver $year/keys/secure "/CN=secure.${DOMAIN}" req.cnf
genserver $year/keys/static "/CN=static.${DOMAIN}" req.cnf
genserver $year/keys/api "/CN=api.${DOMAIN}" req.cnf

# then the email signing key
genserver $year/keys/mail "/emailAddress=support@${DOMAIN}" reqMail.cnf

# then environment-keys for cassiopeia
genserver $year/keys/signer_client "/CN=CAcert signer handler 1" reqClient.cnf
genserver $year/keys/signer_server "/CN=CAcert signer 1" req.cnf

rm req.cnf reqMail.cnf reqClient.cnf

rm env.chain.crt
