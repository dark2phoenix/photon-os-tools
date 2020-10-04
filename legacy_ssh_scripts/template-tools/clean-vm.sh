#!/bin/bash

# clean tdnf
tdnf clean all

# Shrink the log space, remove old logs and truncate logs
logrotate -f /etc/logrotate.conf
rm -f /var/log/*-???????? /var/log/*.gz

cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog

# Remove SSH host keys so that each new VM gets unique ones
rm -f /etc/ssh/*key*

# Remove the root users shell history
rm -f ~root/.bash_history
unset HISTFILE

# Remove root users SSH history and then shutdown for template creation

rm -rf ~root/.ssh/
history –c

# Clear machine id
echo -n > /etc/machine-id