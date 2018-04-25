#!/bin/bash

cat /var/log/syslog |grep Found|grep -v "null"|awk -F ":" '{print $5}'|sort -n | uniq -c|awk -v x="\"" -F " " '{print "node_lrn_vendor_total{vendor="x$2x"}",$1}' > /root/scripts/calls/lrn_vendor_calls.prom

