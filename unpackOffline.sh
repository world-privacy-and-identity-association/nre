#!/bin/bash

mkdir -p generated
cd generated

openssl enc -d -kfile <(echo 1234) -md sha256 -aes-256-cbc | tar xz
