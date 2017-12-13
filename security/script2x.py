#! /usr/bin/env python
# -*- coding: latin-1 -*-
import sys
from scapy.all import *

#options field in IP fragments not homogeneous
#C4_Analyse_3g
#alert tcp $EXTERNAL_NET any -> $HOME_NET any (msg:”Options dans paquet fragmente”; fragbits:M; ipopts:rr; sid:42420051;)
IP_CLIENT = "172.17.117.29" 
p = IP(dst=IP_CLIENT, src = "2.2.2.2")/TCP(flags="P")/("A"*10)
frags = fragment(p, fragsize=1)
n = 0
i = 0
print range(len(frags))
for i in range(len(frags)):
    n += 1
    frags[i].options = IPOption('\x07')
    if i == 1:
        frags[i].options = IPOption('\x06')
    send(frags[i])
print n
