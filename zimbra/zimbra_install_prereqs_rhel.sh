#!/bin/bash - 
#===============================================================================
#
#          FILE: zimbra_install_prereqs_rhel.sh
# 
#         USAGE: ./zimbra_install_prereqs_rhel.sh 
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
echo ""
echo -e "Internet connectivity is required for packages installation..."
echo ""
read -p "Press Enter key to continue:" presskey

#Update system and install key packages
sudo yum update -y
sudo yum -y install wget perl perl-core unzip screen openssh-clients openssh-server nmap nc sed sysstat libaio telnet rsync net-tools aspell 


# Disable firewall & SELinux
echo -e "[INFO] : Configuring Firewall"
# Stop firewalld iptables ip6tables
FIREWALLD_STATE=$(firewall-cmd --state 2>/dev/null)
if [[ $? -eq '0' ]]; then
    sudo systemctl enable --now firewalld
    sudo firewall-cmd --add-service={http,https,smtp,smtps,imap,imaps,pop3,pop3s} --permanent
    sudo firewall-cmd --add-port 7071/tcp --permanent
    sudo firewall-cmd --add-port 8443/tcp --permanent
    sudo firewall-cmd --reload
fi

# Configure /etc/hosts file
## Input required variables
echo ""
read -p "Input Zimbra Base Domain. E.g example.com : " ZIMBRA_DOMAIN
read -p "Input Zimbra Mail Server hostname (first part of FQDN). E.g mail : " ZIMBRA_HOSTNAME
read -p "Please insert your IP Address : " ZIMBRA_SERVERIP
echo ""

echo "Update  hostname and /etc/hosts file.."
##Update system hostname."
sudo hostnamectl set-hostname $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN
## /etc/hosts update
sudo cp /etc/hosts /etc/hosts.backup
sudo tee /etc/hosts<<EOF
127.0.0.1       localhost
$ZIMBRA_SERVERIP   $ZIMBRA_HOSTNAME.$ZIMBRA_DOMAIN       $ZIMBRA_HOSTNAME
EOF

##Validate
echo ""
hostnamectl
echo ""
echo "Zimbra server hostname is:"
hostname -f

echo -e "[INFO] : Disable mail services if active"
sudo systemctl disable --now postfix 2>/dev/null


## Configure timezone
read -p "Input your timezone value, example Africa/Nairobi: " TimeZone
sudo timedatectl set-timezone $TimeZone
sudo timedatectl set-ntp yes

## Configure Chrony ntp
###  Remove ntp package if installed
sudo yum remove ntp -y 2>/dev/null
sudo yum -y install chrony
sudo systemctl enable --now chronyd
sudo chronyc sources

echo ""
echo "Necessary pre-reqs satisfied, you can now install Zimbra server.."
