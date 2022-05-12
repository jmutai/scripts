#!/bin/bash - 
#===============================================================================
#
#          FILE: zimbra_bind_setup_ubuntu.sh
# 
#         USAGE: ./zimbra_bind_setup_ubuntu.sh 
# 
#   DESCRIPTION: Install and Configure Bind DNS server for Zimbra Mail 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Josphat Mutai, josphatkmutai@gmail.com 
#  ORGANIZATION: 
#       CREATED: 05/11/2022 13:39
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#!/bin/bash
echo ""
echo -e "Internet connectivity is required for packages installation..."
echo ""
echo -e "Press key enter to continue"
read presskey

echo -e "[INFO] : Installing required dependencies"
sleep 3
#Install required packages
sudo apt update
sudo apt install bind9 bind9utils net-tools resolvconf sudo -y

# Configure Bind DNS Server
## Input required variables
echo ""
read -p "Input Zimbra Base Domain. E.g example.com : " ZIMBRA_DOMAIN
read -p "Input Zimbra Mail Server hostname (first part of FQDN). E.g mail : " ZIMBRA_HOSTNAME
read -p "Please insert your IP Address : " ZIMBRA_SERVERIP
echo ""

# Disable systemd-resolved and reset DNS settings
sudo cp /etc/resolvconf/resolv.conf.d/head /etc/resolvconf/resolv.conf.d/head.backup
sudo tee /etc/resolvconf/resolv.conf.d/head<<EOF
search $ZIMBRA_DOMAIN
nameserver 127.0.0.1
nameserver $ZIMBRA_SERVERIP
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

## Disable systemd-resolved and enable resolvconf
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl enable resolvconf
sudo systemctl restart resolvconf

# Update /etc/resolv.conf file
sudo tee /etc/resolv.conf<<EOF
search $ZIMBRA_DOMAIN
nameserver $ZIMBRA_SERVERIP
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

## Configure Bind DNS Server
echo ""
echo -e "[INFO] : Configuring DNS Server"
sleep 3
### Backup configs
BIND_CONFIG=$(ls /etc/bind/ | grep named.conf.local.back)
if [ "$BIND_CONFIG" == "named.conf.local.back" ]; then
    sudo cp /etc/bind/named.conf.local.back /etc/bind/named.conf.local
else
    sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.back
fi

### Configure DNS Zone

sudo tee -a /etc/bind/named.conf.local<<EOF
zone "$ZIMBRA_DOMAIN" IN {
type master;
file "/etc/bind/db.$ZIMBRA_DOMAIN";
};
EOF

# Create Zone database file
sudo touch /etc/bind/db.$ZIMBRA_DOMAIN
sudo chgrp bind /etc/bind/db.$ZIMBRA_DOMAIN


sudo tee /etc/bind/db.$ZIMBRA_DOMAIN<<EOF
\$TTL 1D
@       IN SOA  ns1.$ZIMBRA_DOMAIN. root.$ZIMBRA_DOMAIN. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@		IN	NS	ns1.$ZIMBRA_DOMAIN.
@		IN	MX	0 $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN.
ns1	IN	A	$ZIMBRA_SERVERIP
mail	IN	A	$ZIMBRA_SERVERIP
EOF

sudo sed -i 's/dnssec-validation yes/dnssec-validation no/g' /etc/bind/named.conf.options

# Configure DNS Options
sudo tee /etc/bind/named.conf.options<<EOF
options {
	directory "/var/cache/bind";

	forwarders {
		8.8.8.8;
		1.1.1.1;
	};

	dnssec-validation auto;

	listen-on-v6 { any; };
};
EOF

# Restart Service & Check results configuring DNS Server

sudo systemctl enable bind9 && sudo systemctl restart bind9

# Test DNS setup
nslookup $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN
dig $ZIMBRA_DOMAIN mx
