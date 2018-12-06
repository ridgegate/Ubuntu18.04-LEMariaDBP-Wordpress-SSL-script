# Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript
The following code is a combination of things I have found on the internet and combined them 
for a quick installation script to automate WordPress installation with Nginx, MariaDB 10.1, PHP7.2 on Ubuntu 18.04 Bionics.

<strong>Credit: </strong>
</br>Lee Wayward @ https://gitlab.com/thecloudorguk/server_install/ 
</br>Jeffrey B. Murphy @ https://www.jbmurphy.com/2015/10/29/bash-script-to-change-the-security-keys-and-salts-in-a-wp-config-php-file/

## Instructions
Run the following commands on your Ubuntu terminal to download the script and start the installation. </br>
* #### Script with prompts after individual component has been installed.
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/quickinstallscript.sh </br>
  * sudo chmod +x quickinstallscript.sh </br>
  * sudo ./quickinstallscript.sh </br>
* #### Complete automatic installation (Will still prompt for url and database name/user)
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/quickinstall_noprompt.sh  </br>
  * sudo chmod +x quickinstall_noprompt.sh </br>
  * sudo ./quickinstall_noprompt.sh </br>
* #### To install SSL and Firewall 
  * wget https://raw.githubusercontent.com/ridgegate/Ubuntu18.04-LEMP-Mariadb-Wordpress-bashscript/master/sslsetup.sh </br>
  * sudo chmod +x sslsetup.sh </br>
  * sudo ./sslsetup.sh </br>

## Environment
Tested on Ubuntu 18.04 Bionics (LTS)

## Included Software
* Nginx 1.14.0 (Ubuntu repository)
* PHP 7.2 (Ubuntu repository)
* MariaDB 10.3 (MariaDB repository)
* WordPress (Wordpress latest)

