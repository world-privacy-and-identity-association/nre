# NRE

This project is a collection of shell scripts to generate X.509 certificates suitable for operating a Certificate Authority.
It is usually used in conjunction with *Cassiopeia* and *Gigi*.

To generate a root certificate and all intermediate certificates for the years 2017 and 2018, run `./all root 2017 2018`.
To adjust the settings of the certificates (organization name, domain name, …),
create a `config` file and set the appropriate variables;
the `config.example` file documents the available variables.

## Overview of Generating Shell Scripts

The shell scripts that can be invoked (in order of `all`) are:

* `clear`: remove all previously generated keys
* `generateKeys`: generate the root certificate and structure certificates (levels 0 and 1)
* `generateTime 2017`: generate the sub-cas for one year
* `generateInfra 2017`: generate the CA Infrastructure keys (Gigi TLS, Gigi S/MIME, communication with the signer, …) for one year
* `verify 2017`: verify all keys for one year
* (optional) `generateSignerConfig 2017`: generate config to be deployed on cassiopeia

All of these scripts depend on 2 “library scripts”:

* `commonFunctions.bash`: functions used all over those scripts
* `structure.bash`: definitions of which CAs and keys exist

## Other Files and Folders

* `CAs`: configuration per structure sub-ca
* `profiles`: configuration per certificate profile
* `selfsign.config`: config for the CAs maintained by this script-collection internally

## Generated Files and Folders

The following files and directories are generated in the `generated/` directory.

* `2017/ca`: generated time-based sub-certificates for one year
* `2017/keys`: generated infrastructure keys for one year
* `{root,assured,unassured,...}.ca/`: subdirectories for the individual certificates
* `*.ca/key.key`: the certificate’s private key
* `*.ca/key.crt`: the certificate’s certificate

They are also bundled into several `*.tar.gz` files in the `generated/` directory,
which are used by the `manager/` scripts in the *infra* project.
