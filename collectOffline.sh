#!/bin/bash

tar cz *.ca | openssl enc -e -kfile <(echo 1234) -md sha256 -aes-256-cbc > offline.tar.gz.aes-256-cbc
