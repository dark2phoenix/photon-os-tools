#!/bin/bash
set -eo xtrace
#
# Get and install packages (some may be there)
#
tdnf makecache
tdnf distro-sync -y
tdnf update -y
tdnf install bindutils -y
tdnf install sudo -y
tdnf install openssl-c_rehash -y
tdnf install vim -y
tdnf install nfs-utils -y
#
# Configure static networking - not requried if you are using DHCP
# Comment from here to the beginning of the certs section if DHCP
#

cat > /etc/systemd/network/10-eth0.network << "EOF"
[Match]
Name=eth0

[Network]
Address=172.28.1.51/22
Gateway=172.28.1.1
DNS=172.28.5.254
DNS=172.28.1.220
Domains=ourhome.local lab.local
EOF

chmod 644 /etc/systemd/network/10-eth0.network
if [ -e /etc/systemd/network/99-dhcp-en.network ]
  sed -i '/DHCP=yes/c\DHCP=no' /etc/systemd/network/99-dhcp-en.network
fi

#
# Add your CA Root Certifcate to the host
#
cat > /etc/ssl/certs/OurhomeRoot.pem << "EOF"
EOF

c_rehash

#
# Add the cert you're using on hour rancher primary host so this
# host can connect to it
#
mkdir -p /var/lib/rancher/etc/ssl

cat > /var/lib/rancher/etc/ssl/ca.crt << "EOF"
EOF
chmod 644 /var/lib/rancher -R

#
# set hostname
#
hostnamectl set-hostname htpc-server2.ourhome.local
systemctl restart systemd-hostnamed
sed -i "s/photon-machine/`hostname` `hostname -s`/" /etc/hosts
echo -e "`/sbin/ip -o -4 addr list eth0  | awk '{print $4}' | cut -d/ -f1`\t`hostname` `hostname -s`" >> /etc/hosts

#
# Configure NTP
#

sed -i '/#NTP=/c\NTP=172.28.5.254 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org' /etc/systemd/timesyncd.conf
sed -i '/#FallbackNTP/c\FallbackNTP' /etc/systemd/timesyncd.conf

timedatectl set-timezone America/New_York

#
#  Set Docker to autostart
#
systemctl enable docker

#
# Configure firewall to allow ICMP and Rancher specific traffic
#
IPTABLE_CONFIG_EXIST=$(cat /etc/systemd/scripts/iptables/ip4save | grep -c "# Configure rancher related settings")
if [ $IPTABLE_CONFIG_EXIST -eq 0 ]; then
  cat >> /etc/systemd/scripts/iptables/ip4save << EOF

# Configure rancher related settings
 -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
 -A INPUT -p udp --dport 500 -j ACCEPT
 -A INPUT -p udp --dport 4500 -j ACCEPT
 -A INPUT -p udp --dport 4789 -j ACCEPT  
 -A OUTPUT -p udp --dport 500 -j ACCEPT
 -A OUTPUT -p udp --dport 4500 -j ACCEPT
 -A OUTPUT -p udp --dport 4789 -j ACCEPT  
# Allow ping
 -A OUTPUT -p icmp -j ACCEPT
 -A INPUT  -p icmp  -j ACCEPT

#Allow http and https for rancher server
 -A INPUT -p tcp --dport 80 -j ACCEPT
 -A INPUT -p tcp --dport 443 -j ACCEPT
 -A INPUT -p tcp --dport 8080 -j ACCEPT

# Plex has shared networking with host, so need to allow it's rules directly
 -A INPUT -p tcp --dport 32400 -j ACCEPT
 -A INPUT -p udp --dport 32400 -j ACCEPT
 -A INPUT -p tcp --dport 32469 -j ACCEPT
 -A INPUT -p udp --dport 32469 -j ACCEPT
 -A INPUT -p udp --dport 5353 -j ACCEPT
 -A INPUT -p udp --dport 1900 -j ACCEPT

COMMIT
EOF
else
    echo "Rancher config already present in /etc/systemd/scripts/iptables"
fi



#
# Tell the user we are done
#
echo Configuration is complete, suggest you reboot to fully activate everything
