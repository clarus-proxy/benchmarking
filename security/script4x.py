#! /usr/bin/env python
# -*- coding: latin-1 -*-
import sys
from scapy.all import *

#C4_Analyse_3b
#alert tcp $EXTERNAL_NET any -> $HOME_NET any (msg:”Donnees dans paquet SYN”; flags:S; dsize:>0; sid:42420050;)
print "***  ***"
n = 0
ip_victime = "172.17.117.29"
ip_attaquant = "4.4.4.4"
p = IP(dst=ip_victime, src=ip_attaquant)/TCP(sport=6666, dport=6363, flags="S")/("A"*20)
#no attack if changed to:
#p = IP(dst=ip_victime, src=ip_attaquant)/TCP(sport=6666, dport=6363, flags="S")
send(p)
print n
