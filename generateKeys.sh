#!/bin/sh
# this script generates a set of sample keys
set -e

. structure
. commonFunctions


####### create various extensions files for the various certificate types ######
cat <<TESTCA > ca.cnf
basicConstraints = CA:true
subjectKeyIdentifier = hash
keyUsage = keyCertSign, cRLSign
crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/root.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/root.crt
TESTCA

cat <<TESTCA > subca.cnf
basicConstraints = CA:true
subjectKeyIdentifier = hash
keyUsage = keyCertSign, cRLSign
crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/root.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/root.crt
TESTCA


rootSign(){ # csr
    caSign "$1.ca/key" root subca.cnf
}


# Generate the super Root CA
genca "/CN=Cacert-gigi testCA" root
openssl x509 -req -days 365 -in root.ca/key.csr -signkey root.ca/key.key -out root.ca/key.crt -extfile ca.cnf

# generate the various sub-CAs
for ca in $STRUCT_CAS; do
    . CAs/$ca
    genca "/CN=$name" $ca
    rootSign $ca
done

rm ca.cnf subca.cnf


