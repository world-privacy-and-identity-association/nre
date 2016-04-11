#!/bin/bash

cd generated

PASSW=`head -c15 /dev/random | base64`
echo $PASSW > offlinePassword.txt
tar c *.ca | openssl enc -e -kfile <(echo -n "$PASSW") -md sha256 -aes-256-cbc > offline.tar.aes-256-cbc
PASSW=
