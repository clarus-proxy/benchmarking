#!/bin/bash
# RSA Decryption
#openssl enc -base64 -d | openssl rsautl -inkey ./network/tools/RSA_2048.key -decrypt

#AES decryption
key256="CLARUSISTHEBESTANONYMIZATIONTOOLBOX"
echo $1 | openssl aes-256-cbc -a -d -k $key256
