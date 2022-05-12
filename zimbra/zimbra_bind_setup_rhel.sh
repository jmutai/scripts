#!/bin/bash - 
#===============================================================================
#
#          FILE: zimbra_bind_setup_rhel.sh
# 
#         USAGE: ./zimbra_bind_setup_rhel.sh 
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

## Update system
sudo yum update -y
sudo yum -y install bind bind-utils net-tools sysstat

# Configure Bind DNS Server
## Input required variables
echo ""
read -p "Input Zimbra Base Domain. E.g example.com : " ZIMBRA_DOMAIN
read -p "Input Zimbra Mail Server hostname (first part of FQDN). E.g mail : " ZIMBRA_HOSTNAME
read -p "Input Zimbra Server IP Address : " ZIMBRA_SERVERIP
echo ""

## Configure Bind DNS Server
echo ""
echo -e "[INFO] : Configuring DNS Server"
sleep 3
### Backup configs
BIND_CONFIG=$(ls /etc/ | grep named.conf.back);
if [ "$BIND_CONFIG" == "named.conf.back" ]; then
    sudo cp /etc/named.conf.back /etc/named.conf
else
    sudo cp /etc/named.conf /etc/named.conf.back
fi

# Update DNS listen address
# If remote update address accordingly
sed -i s/"listen-on port 53 { 127.0.0.1; };"/"listen-on port 53 { 127.0.0.1; any; };"/g /etc/named.conf

### Configure DNS Zone
sudo tee -a /etc/named.conf<<EOF
zone "$ZIMBRA_DOMAIN" IN {
type master;
allow-update { none; };
file "db.$ZIMBRA_DOMAIN";
};
EOF

# Create Zone database file
sudo touch /var/named/db.$ZIMBRA_DOMAIN
sudo chgrp named /var/named/db.$ZIMBRA_DOMAIN

sudo tee /var/named/db.$ZIMBRA_DOMAIN<<EOF
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

# Update /etc/resolv.conf file
#sudo sed -i '1 s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf
sudo tee /etc/resolv.conf<<EOF
search $ZIMBRA_DOMAIN
nameserver 127.0.0.1
nameserver $ZIMBRA_SERVERIP
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Restart Service & Check results configuring DNS Server
sudo systemctl enable named
sudo systemctl restart named

# Test DNS setup
nslookup $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN
dig $ZIMBRA_DOMAIN mx
