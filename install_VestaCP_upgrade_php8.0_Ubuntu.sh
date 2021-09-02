#!/bin/bash

#default values

hostname="$(hostname)"
email="admin@$(hostname)"
password="VestaCP123!"

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

# Detect OS
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="debian" ;;
    Ubuntu)     type="ubuntu" ;;
    Amazon)     type="amazon" ;;
    *)          type="rhel" ;;
esac
if [  $type == 'ubuntu' ]; then
        echo " "
    else
        echo " "
        echo "This install script is for Ubuntu Only, use the standard VestaCP script";
        echo "https://vestacp.com/install/"
        exit 1;
fi;
# Check admin user account
if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ -z "$1" ]; then
    echo "Error: user admin exists"
    echo
    echo 'Please remove admin user before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

# Check admin group
if [ ! -z "$(grep ^admin: /etc/group)" ] && [ -z "$1" ]; then
    echo "Error: group admin exists"
    echo
    echo 'Please remove admin group before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi
ip=$(ip addr|grep 'inet '|grep global|head -n1|awk '{print $2}'|cut -f1 -d/)
logCredentials() {
    echo "========================"
    echo " "
    echo " https://$ip:8083"
    echo " username: admin"
    echo " Password: $password"  
    echo " "
    echo "========================"

}
echo "make sure the hostname is a Fully Qualified Domain Name if you want your emails to work properly."
echo "press enter if you wish to continue with '$hostname' as your hostname"
read enter
echo "Placing initial credentials into $(pwd)/login"
echo "This is to ensure access when script completes"
logCredentials >> $(pwd)/login

#define update function
update() {
    echo " "
    echo " "
    echo " "
    echo "==================================================================="
    echo " "
    echo " "
    
    echo "the next steps will upgrade from php7.2 to php8.0"
    echo "This will remove phpmyadmin, roundcube and a few other things"
    echo "be attentive to any prompts, if you do not wish to loose"
    echo "phpmyadmin or roundcube, press CTRL + C now. otherwise, press ENTER"
    echo " "
    echo " "
    echo "==================================================================="
    echo " "
    echo " "
    read consent

    echo "Adding repositories"
    add-apt-repository ppa:ondrej/php -y
    add-apt-repository ppa:ondrej/apache2 -y

    echo "Updating"
    apt update -y

    echo "removing php7 from apache2"
    a2dismod php7*
    systemctl restart apache2

    echo "removing php7 from server"
    apt remove --allow-downgrades --allow-remove-essential --allow-change-held-packages php7*

    echo "adding php8 to server"
    apt install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages php8.0
    apt install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages php8.0-common php8.0-mysql php8.0-xml php8.0-curl php8.0-gd php8.0-imagick php8.0-cli php8.0-dev php8.0-imap php8.0-mbstring php8.0-opcache php8.0-soap php8.0-zip php8.0-intl

    echo "adding php8 to apache2"
    a2enmod php8.0 -y
    systemctl restart apache2

    echo "upgrading all packages on server"
    apt update
    apt upgrade -y --allow-downgrades --allow-remove-essential --allow-change-held-packages
    echo "Running apt autoremove"
    apt autoremove -y --allow-downgrades --allow-remove-essential --allow-change-held-packages
}
# Check wget
if [ -e '/usr/bin/wget' ]; then
    wget http://vestacp.com/pub/vst-install-$type.sh -O vst-install-$type.sh
    if [ "$?" -eq '0' ]; then
        bash vst-install-$type.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous yes --mysql yes --postgresql no --hostname $(echo $hostname) --email $(echo $email) --password $(echo $password) -y no
        update
        exit
    else
        echo "Error: vst-install-$type.sh download failed."
        exit 1
    fi
fi

# Check curl
if [ -e '/usr/bin/curl' ]; then
    curl -O http://vestacp.com/pub/vst-install-$type.sh
    if [ "$?" -eq '0' ]; then
        
        bash vst-install-$type.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous yes --mysql yes --postgresql no --hostname $(echo $hostname) --email $(echo $email) --password $(echo $password) -y no
        update
        exit
    else
        echo "Error: vst-install-$type.sh download failed."
        exit 1
    fi
fi

exit
