#!/bin/sh

NTPDATE=/usr/bin/ntpdate
HWCLOCK=/sbin/hwclock

# synchronize systime from NTP-Server
test -f $NTPDATE || exit 0
test -f /etc/default/ntpdate || exit 0

. /etc/default/ntpdate

test -n "$NTPSERVERS" || exit 0

logger "$0 Running ntpdate to synchronize clock"
$NTPDATE $NTPOPTIONS $NTPSERVERS && $HWCLOCK -w
logger "$0 ntpdate finished with: `date`"
