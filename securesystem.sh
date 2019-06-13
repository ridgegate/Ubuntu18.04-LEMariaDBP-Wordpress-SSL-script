#!/bin/bash
# This script install the secure your WordPress Installation with the following modifications
# 
#  1) Install Sendmail for sending Fail2Ban Alerts
#  2) Install IPTable for banning IP 
#  3) Install Fail2Ban
#  4) Remove root login and create new user
# 
# ****Commands for testing******:
# Basic Fail2Ban Commands
# - service fail2ban stop
# - service fail2ban start
# - fail2ban-client set <jail name> banip <ip>
# - fail2ban-client set <jail name> unbanip <ip>
# - sudo fail2ban-client status <jail name>
# - sudo iptables -S
#
# Sendmail Commands 
# - echo "$(date) Test Email sendmail" | mail -s "Is it working-changed root" RECIEVER_EMAIL_ADDR
# * Replace RECIEVER_EMAIL_ADDR with valid email address
#
# NOTE: 
# 
# This requires WP Fail2Ban Plugin
# https://en-ca.wordpress.org/plugins/wp-fail2ban/
#
# Credit:
# https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04
# https://bjornjohansen.no/using-fail2ban-with-wordpress
# https://www.kazimer.com/fail2ban-action-for-cloudflare-rest-api-v4/
# https://guides.wp-bullet.com/integrate-fail2ban-cloudflare-api-v4-guide/
#
#
#
F2B_DEST_EMAIL="ys.tomliu@gmail.com"
F2B_SENDER_EMAIL="f2b@ridgegatetools.ca"
F2B_SENDER_PASS="hiwvbzcghrmkhuyq"
CF_ACC_EMAIL="wp@ridgegatetools.ca"
CF_API_KEY="751816f2efcfff1db3679b814c56a3996ca18"
ZONE_EXIST="y"
CF_ZONEID="a1c78d1ad2c61b795bdc31070abad32e"
FQDN_NAME="sprrivets.com"

# clear
# echo "Please provide destination email for Fail2Ban Notification"
# read -p "Enter destination email, then press [ENTER] : " F2B_DEST_EMAIL
# echo "Please provide sender email for Fail2Ban Notification"
# read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_EMAIL
# echo "Please provide sender email password"
# read -p "Enter sender email, then press [ENTER] : " F2B_SENDER_PASS
# echo "Please provide CloudFlare Email Address"
# read -p "Enter CloudFlare Account Email Address [ENTER] : " CF_ACC_EMAIL
# echo "Please provide CloudFlare Global API Key"
# read -p "Enter CloudFlare API Key: " CF_API_KEY
# 
# read -r -p "Do you have multiple URL on the same Cloudflare account? (Y/n):" ZONE_EXIST
# case "$ZONE_EXIST" in
#     [yY][eE][sS]|[yY]) 
#     read -p "Enter CloudFlare ZONEID: " CF_ZONEID
#     ;;
# esac
# echo "Please provide the domain name"
# read -p "Enter domain name: " FQDN_NAME
# clear
read -t 30 -p "Thank you. Please press [ENTER] continue or [Control]+[C] to cancel"
echo "Setting up Fail2Ban, Sendmail and iptables"


sudo apt-get update && sudo apt-get upgrade -y

#---------Sendmail Installation--------#

apt-get install -y sendmail mailutils sendmail-bin
mkdir /etc/mail/authinfo
chmod 700 /etc/mail/authinfo
touch /etc/mail/authinfo/smtpacct.txt
echo "AuthInfo: \"U:F2BAlert\" \"I:$F2B_SENDER_EMAIL\" \"P:$F2B_SENDER_PASS\"" > /etc/mail/authinfo/smtpacct.txt
makemap hash  /etc/mail/authinfo/smtpacct <  /etc/mail/authinfo/smtpacct.txt
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMariaDBP-Wordpress-SSL-script/master/resources/smtprelayinfo
sed -i '/MAILER_DEFINITIONS/r smtprelayinfo' /etc/mail/sendmail.mc

make -C /etc/mail
/etc/init.d/sendmail reload
# Remove login detail in plain text
rm -f /etc/mail/authinfo/smtpacct.txt

#---------Sendmail Installation Completed--------#


#---------IPTables Installation--------#
# Allow established connections, traffic generated by the server itself, 
# traffic destined for our SSH and web server ports. 
# https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04

sudo apt-get install -y iptables-persistent
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 25 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo dpkg-reconfigure iptables-persistent -u
#---------IPTables Installation Completed--------#

#---------Fail2Ban Installation-------#
sudo apt-get install fail2ban -y
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/resources/jail.local
mv ./jail.local /etc/fail2ban/jail.local
chmod 640 /etc/fail2ban/jail.local

## --Configure Filters and Jails
sed -i "s/F2B_DEST/$F2B_DEST_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/F2B_SENDER/$F2B_SENDER_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/CF_EMAIL/$CF_ACC_EMAIL/" /etc/fail2ban/jail.local
sed -i "s/CF_GLB_KEY/$CF_API_KEY/" /etc/fail2ban/jail.local

## --Move/download filter/action to proper location
sudo curl https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/resources/auth > /etc/logrotate.d/auth
sudo cp /etc/fail2ban/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.conf #enable bad-bots
sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-hard.conf > /etc/fail2ban/filter.d/wordpress-hard.conf
sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-soft.conf > /etc/fail2ban/filter.d/wordpress-soft.conf
sudo curl https://plugins.svn.wordpress.org/wp-fail2ban/trunk/filters.d/wordpress-extra.conf > /etc/fail2ban/filter.d/wordpress-extra.conf

sudo curl https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMariaDBP-Wordpress-SSL-script/master/resources/cloudflare-restv4.conf > /etc/fail2ban/action.d/cloudflare-restv4.conf
case "$ZONE_EXIST" in
  [yY][eE][sS]|[yY]) 
    CF_ZONEID="zones/$CF_ZONEID"
    sed -i "s|CF_ZONE|$CF_ZONEID|g" /etc/fail2ban/action.d/cloudflare-restv4.conf
    ;;
  *)
    sed -i "s|CF_ZONE|user|g" /etc/fail2ban/action.d/cloudflare-restv4.conf
    ;;    
esac
## --Activate Fail2Ban and restart syslog
sudo systemctl service enable fail2ban
sudo systemctl service start fail2ban
sudo service rsyslog restart
read -t 30 -p "Fail2Ban installation completed."
clear
#---------Fail2Ban Installation Completed-------#


echo "Please provide a user name for the system. This prevent brute for ROOT login attempt"
read -p "Type your system user name, then press [ENTER] : " sshuser
useradd -m -s /bin/bash $sshuser
usermod -aG sudo $sshuser
echo
echo
echo "Please choose user password options:"
echo
echo "*************************WARNING*************************"
echo "*"
echo "* If \"Option 3 - No Password\" is chosen,"
echo "* SUDO privilege could be invoked without password!"
echo "*"
echo "*************************WARNING*************************"
echo
echo
PS3="Enter Password options :"
select optpwd in "Generate Password" "Enter Password" "No Password" 
do
  case $optpwd in
    "Generate Password")
      sshuserpwd=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-10)
      echo "$sshuser:$sshuserpwd"|chpasswd
      break ;;
    "Enter Password")
      read -p "Please enter your password : " sshuserpwd
      echo "$sshuser:$sshuserpwd"|chpasswd
      break ;;
    "No Password") 
      # U6aMy0wojraho = hash for empty string
      echo "$sshuser:U6aMy0wojraho" | sudo chpasswd -e
      sudo sh -c "echo '$sshuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
      break ;;		
    *)		
      echo "Error: Please try again (select 1..3)!"
      ;;		
  esac
done

mkdir -p /home/$sshuser/.ssh 
cp /root/.ssh/authorized_keys /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh/authorized_keys
chown $sshuser:$sshuser /home/$sshuser/.ssh
chmod 700 /home/$sshuser/.ssh && chmod 600 /home/$sshuser/.ssh/authorized_keys


#------Modify nginx.conf to include cloudflareip file for the newest ips------
touch /etc/nginx/cloudflareip
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline
sed -i '/http {/a\       include /etc/nginx/cloudflareip;' /etc/nginx/nginx.conf
sed -i '/http {/a\       ## Include Cloudflare IP ##' /etc/nginx/nginx.conf
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline
sed -i '/http {/a\  ' /etc/nginx/nginx.conf #add newline

## --Get CloudFlare IP and set up cronjob to run automatically
mkdir /home/$sshuser/scripts
wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMariaDBP-Wordpress-SSL-script/master/resources/auto-cf-ip-update.sh
mv ./auto-cf-ip-update.sh /home/$sshuser/auto-cf-ip-update.sh
sudo chmod +x /home/$sshuser/auto-cf-ip-update.sh
/bin/bash /home/$sshuser/auto-cf-ip-update.sh
# Added Cronjob to autoupdate IP list
(crontab -l && echo "# Update CloudFlare IP Ranges (every Sunday at 04:00)") | crontab -
(crontab -l && echo "* 4 * * 0 /bin/bash /home/$sshuser/auto-cf-ip-update.sh >/dev/null 2>&1") | crontab - 

#Disable Root Login
perl -pi -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
#------Modify nginx.conf to include cloudflareip file for the newest ips------
echo
echo
echo
echo "Here are System Login Detail"
echo
echo "System Username: $sshuser"
echo "System User Password: $sshuserpwd"
echo "Root login has beeen disabled. Please reconnect with the System user and password."
echo
echo
echo
echo
echo
echo
echo "All Done. You system should be secured."
