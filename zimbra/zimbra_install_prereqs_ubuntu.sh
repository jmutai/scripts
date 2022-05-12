#!/bin/bash - 
#===============================================================================
#
#          FILE: zimbra_install_prereqs_ubuntu.sh
# 
#         USAGE: ./zimbra_install_prereqs_ubuntu.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/11/2022 15:42
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#!/bin/bash
# Install required packages
sudo apt update && sudo apt -y full-upgrade
sudo apt install -y net-tools netcat-openbsd libidn11 libpcre3 libgmp10 libexpat1 libstdc++6 libperl5* libaio1 resolvconf unzip pax sysstat sqlite3

# Disable any mail services if running
sudo systemctl disable --now postfix 2>/dev/null

## Input required variables
echo ""
read -p "Input Zimbra Base Domain. E.g example.com : " ZIMBRA_DOMAIN
read -p "Input Zimbra Mail Server hostname (first part of FQDN). E.g mail : " ZIMBRA_HOSTNAME
read -p "Input Zimbra Server IP Address : " ZIMBRA_SERVERIP
echo ""

#Configure /etc/hosts file
sudo cp /etc/hosts /etc/hosts.backup
sudo tee /etc/hosts<<EOF
127.0.0.1       localhost
$ZIMBRA_SERVERIP   $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN       $ZIMBRA_HOSTNAME
EOF

##Update system hostname."
sudo hostnamectl set-hostname $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN

##Validate
echo ""
hostnamectl
echo ""
echo "Zimbra server hostname is:"
hostname -f

## Configure timezone
read -p "Input your timezone value, example Africa/Nairobi : " TimeZone
sudo timedatectl set-timezone $TimeZone
sudo timedatectl set-ntp yes

## Configure Chrony ntp
###  Remove ntp package if installed
sudo apt remove ntp -y 2>/dev/null
sudo apt -y install chrony
sudo systemctl restart chrony
sudo chronyc sources

echo ""
echo "Necessary pre-reqs satisfied, you can now install Zimbra server.."
