#!/usr/bin/python3
import re, subprocess
from sys import stdin

def encrypt(text):
    return "'{}'".format(subprocess.getoutput("echo \"{}\" | openssl enc -a -A -aes-256-cbc -k CLARUSISTHEBESTANONYMIZATIONTOOLBOX".format(text.group(1))))

for text in stdin:
    print("{}".format(re.sub(r"'(.+?)'", encrypt, text.rstrip())))
