#!/bin/bash
. structure.bash

genKey(){ #subj, internalName
    openssl genrsa -out $2.key ${KEYSIZE}
    openssl req -new -key $2.key -out $2.csr -subj "$1/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/C=$COUNTRY"

}

genca(){ #subj, internalName
    mkdir $2.ca

    genKey "$1" "$2.ca/key"
    
    mkdir $2.ca/newcerts
    echo 01 > $2.ca/serial
    touch $2.ca/db
    echo unique_subject = no >$2.ca/db.attr

}

caSign(){ # csr,ca,config,start,end
    start="$4"
    end="$5"
    [[ "$start" != "" ]] && start="-startdate $start"
    [[ "$end" != "" ]] && end="-enddate $end"
    [[ "$start" == "" && "$end" == "" ]] && start="$ROOT_VALIDITY"
    BASE="$PWD"
    echo "Signing: $BASE/$1 with $2"
    echo "$start $end"
    pushd $2.ca > /dev/null
    if [[ "$2" == "root" && "$1" == root.* ]]; then
        signkey="-selfsign"
    else
        signkey="-cert key.crt"
    fi
    openssl ca $signkey -keyfile key.key -in "$BASE/$1.csr" -out "$BASE/$1.crt" -batch -config "$BASE/../selfsign.config" -extfile "$BASE/$3" $start $end
    popd > /dev/null
    echo "Signed"
}

findLibfaketime() {
    for candidate in /usr/lib/faketime/libfaketime.so.1 /usr/lib/*/faketime/libfaketime.so.1; do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    printf >&2 'error: no libfaketime found\n'
    exit 1 # unfortunately, this will only exit the $() subshell
}
