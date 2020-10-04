#!/bin/bash

mkdir -p /var/spool/cron
chmod 755 /var/spool/cron
touch /var/spool/cron/root

if grep -q re_init.sh "/var/spool/cron/root"; then
  `echo '@reboot ( sleep 30 ; sh /etc/cloud/re_init.sh )' >> /var/spool/cron/root`
fi

cat > /etc/cloud/re_init.sh <<EOF
sudo rm -rf /etc/cloud/cloud-init.disabled
sudo cloud-init init
sleep 5
sudo cloud-init modules --mode config
sleep 5
sudo cloud-init modules --mode final
EOF