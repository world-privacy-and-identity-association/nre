# cacert-nre

This is the a project that contains scripts to generate CAcerts new ( after 2015 ) root structure.

You can run the whole generation process for 2015 by invoking `./all root 2015`.

## Overview of Generating Shell Scripts

The shellscripts that can be invoked (in order of `all`) are:

* `clear` remove all previously generated keys
* `generateKeys` generate the root certificate and structure certificates (levels 0 and 1)
* `generateTime 2015` generate the sub-cas for the year 2015
* `generateInfra 2015` generate the CAcert Infrastructure keys (gigi ssl, gigi smime, signer communication, ...)
* `verify 2015` verify all keys for the year 2015
* (optional) `generateSignerConfig 2015` generate config to be deployed on cassiopeia

all these scripts depend on 2 'library-scripts':

* `commonFunctions.bash` functions used all over those scripts
* `structure.bash` definitions of what cas and keys exist

## Other Files and Folders

* `CAs` configuration per structure sub-ca
* `profiles` configuration per certificate profile
* `selfsign.config` config for the CAs maintained by this script-collection internally

## Generated Files and Folders
* `2015/ca` generated time-based subcas for 2015
* `2015/keys` generated infrastructure keys for 2015
* `{root,assured,unassured,...}.ca` root CAs
* `*.ca/key.key` the CAs private key
* `*.ca/key.crt` the CAs certificate

