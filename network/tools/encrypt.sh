#!/bin/bash
# RSA encryption
#echo $1 | openssl rsautl -inkey ./network/tools/RSA_2048.key -encrypt | openssl enc -base64

#AES encryption
key256="CLARUSISTHEBESTANONYMIZATIONTOOLBOX"
echo $1 | openssl enc -a -A -aes-256-cbc -k $key256
