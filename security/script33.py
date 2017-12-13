import sys
from scapy.all import *

n = "33"
ipDest = "172.17.117.29"
#macDest = "08:00:27:84:90:86"
macDest = "ff:ff:ff:ff:ff:ff"
ipSrc  = "10.0.0.1"
gateway = "172.17.117.29"
#Classical attacks from http://www.secdev.org/projects/scapy/doc/usage.html#simple-one-liners

#TCP Port Scanning
#Send a TCP SYN on each port. Wait for a SYN-ACK or a RST or an ICMP error:
ipSrc  = "10.0.0.5"
res,unans = sr( IP(dst=ipDest)/TCP(flags="S", dport=(1,1024)) )
print "**************************:" + n
