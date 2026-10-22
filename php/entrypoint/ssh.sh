#!/bin/bash
# start dropbear sshd; keys are generated on first connection (-R)
mkdir -p /etc/dropbear /root/.ssh
[ -f /root/.ssh/authorized_keys ] || touch /root/.ssh/authorized_keys

/usr/bin/dropbear -REFms -p 22 2>&1 &
echo -n "$! " >> /var/run/services
