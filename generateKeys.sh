#!/bin/sh
# this script generates a set of sample keys
DOMAIN="cacert.local"
KEYSIZE=4096
PRIVATEPW="changeit"

[ -f config ] && . ./config


rm -Rf *.csr *.crt *.key *.pkcs12 *.ca *.crl


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

cat <<TESTCA > req.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
#crlDistributionPoints=URI:http://www.my.host/ca.crl
#authorityInfoAccess = OCSP;URI:http://ocsp.my.host/
TESTCA

cat <<TESTCA > reqClient.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
#crlDistributionPoints=URI:http://www.my.host/ca.crl
#authorityInfoAccess = OCSP;URI:http://ocsp.my.host/
TESTCA

cat <<TESTCA > reqMail.cnf
basicConstraints = critical,CA:false
keyUsage = keyEncipherment, digitalSignature
extendedKeyUsage=emailProtection
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
#crlDistributionPoints=URI:http://www.my.host/ca.crl
#authorityInfoAccess = OCSP;URI:http://ocsp.my.host/
TESTCA

genKey(){ #subj, internalName
    openssl genrsa -out $2.key ${KEYSIZE}
    openssl req -new -key $2.key -out $2.csr -subj "$1/O=Test Environment CA Ltd./OU=Test Environment CAs"

}

genca(){ #subj, internalName
    mkdir $2.ca

    genKey "$1" "$2.ca/key"
    
    mkdir $2.ca/newcerts
    echo 01 > $2.ca/serial
    touch $2.ca/db
    echo unique_subject = no >$2.ca/db.attr

}

caSign(){ # csr,ca,config
    cd $2.ca
    openssl ca -cert key.crt -keyfile key.key -in ../$1.csr -out ../$1.crt -days 365 -batch -config ../selfsign.config -extfile ../$3
    cd ..
}

rootSign(){ # csr
    caSign "$1.ca/key" root subca.cnf
}

genTimeCA(){ #csr,ca,
    cat <<TESTCA > timesubca.cnf
basicConstraints = CA:true
subjectKeyIdentifier = hash
keyUsage = keyCertSign, cRLSign
crlDistributionPoints=URI:http://g2.crl.cacert.org/g2/$2.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.cacert.org,caIssuers;URI:http://g2.crt.cacert.org/$2.crt
TESTCA
    caSign $1 $2 timesubca.cnf
    rm timesubca.cnf
}

genserver(){ #key, subject, config
    openssl genrsa -out $1.key ${KEYSIZE}
    openssl req -new -key $1.key -out $1.csr -subj "$2"
    caSign $1 env15_1 "$3"
    
    openssl pkcs12 -inkey $1.key -in $1.crt -CAfile env.chain.crt -chain -name $1 -export -passout pass:changeit -out $1.pkcs12
    
}


# Generate the super Root CA
genca "/CN=Cacert-gigi testCA" root
openssl x509 -req -days 365 -in root.ca/key.csr -signkey root.ca/key.key -out root.ca/key.crt -extfile ca.cnf

# generate the various sub-CAs
genca "/CN=Environment" env
rootSign env
genca "/CN=Unassured" unassured
rootSign unassured
genca "/CN=Assured" assured
rootSign assured
genca "/CN=Codesigning" codesign
rootSign codesign
genca "/CN=Orga" orga
rootSign orga
genca "/CN=Orga sign" orgaSign
rootSign orgaSign

genca "/CN=Environment 2015-1" env15_1
genTimeCA env15_1.ca/key env
genKey "/CN=Unassured 2015-1" unassured15_1
genTimeCA unassured15_1 unassured

cat env15_1.ca/key.crt env.ca/key.crt root.ca/key.crt > env.chain.crt

# generate environment-keys specific to gigi.
# first the server keys
genserver www "/CN=www.${DOMAIN}" req.cnf
genserver secure "/CN=secure.${DOMAIN}" req.cnf
genserver static "/CN=static.${DOMAIN}" req.cnf
genserver api "/CN=api.${DOMAIN}" req.cnf

# then the email signing key
genserver mail "/emailAddress=support@${DOMAIN}" reqMail.cnf

# then environment-keys for cassiopeia
genserver signer_client "/CN=CAcert signer handler 1" reqClient.cnf
genserver signer_server "/CN=CAcert signer 1" req.cnf

rm ca.cnf subca.cnf req.cnf reqMail.cnf reqClient.cnf

for local in www secure static api signer_client signer_server mail; do
  openssl verify -CAfile root.ca/key.crt -untrusted env.chain.crt $local.crt
done
rm env.chain.crt
