#! /usr/bin/env python
# -*- coding: latin-1 -*-
import sys
from scapy.all import *

#option field can exist in IP fragments if it is homogeneous
ipDest = "172.17.117.29"
ipSrc  = "1.1.1.1"
p = IP(dst=ipDest, src=ipSrc) / TCP(sport=6667, dport=6364, flags="P") / ("A"*100)
f = fragment(p,fragsize=1)
n = 0
i = 0
print range(len(f))
for i in range(len(f)):
    n += 1
    f[i].options = IPOption('\x07')
#not detected if next two lines are commented out, note that the probe needs to run long enough because de packets are not always sent immediately
    if i == 1:
        f[i].options = IPOption('\x19')
    send(f[i])
print n
