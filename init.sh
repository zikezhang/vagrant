#!/bin/bash
# Using Trusty64 Ubuntu

#
# Add PHP, Phalcon, PostgreSQL and libsodium repositories
#
#sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo apt-add-repository -y ppa:phalcon/stable
sudo apt-add-repository -y ppa:chris-lea/libsodium
sudo touch /etc/apt/sources.list.d/pgdg.list
echo -e "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list > /dev/null
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get update
sudo apt-get install -y python-software-properties

#
# Setup locales
#
echo -e "LC_CTYPE=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8\nLANGUAGE=en_US.UTF-8" | sudo tee -a /etc/environment > /dev/null
sudo locale-gen en_US en_US.UTF-8
sudo dpkg-reconfigure locales

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#
# Hostname
#
sudo hostnamectl set-hostname phalcon-vm

#
# MySQL with root:<no password>
#
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mysql-server-5.6 mysql-client-5.6 php5-mysql

#
# PHP
#
sudo apt-get install -y php5 php5-cli php5-dev php-pear php5-mcrypt php5-curl php5-intl php5-xdebug php5-gd php5-imagick

#
# Apache
#
sudo apt-get install -y apache2 libapache2-mod-php5

#
# Apc
#
sudo apt-get -y install php-apc php5-apcu

#
# Memcached
#
sudo apt-get install -y memcached php5-memcached php5-memcache

#
# MongoDB
#
sudo apt-get install -y mongodb-clients mongodb-server php5-mongo

#
# PostgreSQL with postgres:postgres
# but "psql -U postgres" command don't ask password
#
sudo apt-get install -y postgresql-9.4
cp /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.bkup.conf
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres'"
sudo sed -i.bak -E 's/local\s+all\s+postgres\s+peer/local\t\tall\t\tpostgres\t\ttrust/g'  /etc/postgresql/9.4/main/pg_hba.conf
sudo service postgresql restart

#
# SQLite
#
sudo apt-get -y install sqlite php5-sqlite

#
# Beanstalkd
#
sudo apt-get -y install beanstalkd

#
# Utilities
#
sudo apt-get install -y curl htop git dos2unix unzip vim grc gcc make re2c libpcre3 libpcre3-dev lsb-core

#
# Zephir
#
git clone https://github.com/phalcon/zephir
cd zephir
./install-json
./install -c

#
# Install Phalcon Framework
#
git clone --depth=1 git://github.com/phalcon/cphalcon.git
cd cphalcon/build
sudo ./install

#
# Libsodium
#
sudo apt-get install -y libsodium-dev
sudo pecl install libsodium

#
# Redis
#
# Allow us to remote from Vagrant with port
#
sudo apt-get install -y redis-server redis-tools php5-redis
sudo cp /etc/redis/redis.conf /etc/redis/redis.bkup.conf
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo /etc/init.d/redis-server restart

#
# MySQL configuration
# Allow us to remote from Vagrant with port
#
sudo cp /etc/mysql/my.cnf /etc/mysql/my.bkup.cnf
# Note: Since the MySQL bind-address has a tab cahracter I comment out the end line
sudo sed -i 's/bind-address/bind-address = 0.0.0.0#/' /etc/mysql/my.cnf

#
# Grant all priveleges to root for remote access
#
mysql -u root -Bse "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
sudo service mysql restart

#
# Composer for PHP
#
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

#
# Apache VHost
#
cd ~
echo '<VirtualHost *:80>
        DocumentRoot /vagrant/www
        ErrorLog  /vagrant/www/projects-error.log
        CustomLog /vagrant/www/projects-access.log combined
</VirtualHost>

<Directory "/vagrant/www">
        Options Indexes Followsymlinks
        AllowOverride All
        Require all granted
</Directory>' > vagrant.conf

sudo mv vagrant.conf /etc/apache2/sites-available
sudo a2enmod rewrite

#
# Enable PHP5 Mods
#
sudo touch /etc/php5/mods-available/libsodium.ini
sudo touch /etc/php5/mods-available/phalcon.ini
echo -e "extension=libsodium.so" | sudo tee /etc/php5/mods-available/libsodium.ini > /dev/null
echo -e "extension=phalcon.so" | sudo tee /etc/php5/mods-available/phalcon.ini > /dev/null
sudo php5enmod phalcon curl mcrypt intl libsodium

#
# Install Phalcon DevTools
#
cd ~
echo '{"require": {"phalcon/devtools": "dev-master"}}' > composer.json
composer install
rm composer.json

sudo mkdir /opt/phalcon-tools
sudo mv ~/vendor/phalcon/devtools/* /opt/phalcon-tools
sudo rm -rf ~/vendor
echo "export PTOOLSPATH=/opt/phalcon-tools/" >> /home/vagrant/.profile
echo "export PATH=\$PATH:/opt/phalcon-tools/" >> /home/vagrant/.profile
sudo chmod +x /opt/phalcon-tools/phalcon.sh
sudo ln -s /opt/phalcon-tools/phalcon.sh /usr/bin/phalcon

#
# Update PHP Error Reporting
#
sudo sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php5/apache2/php.ini
sudo sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' /etc/php5/apache2/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/apache2/php.ini
#  Append session save location to /tmp to prevent errors in an odd situation..
sudo sed -i '/\[Session\]/a session.save_path = "/tmp"' /etc/php5/apache2/php.ini

#
# Reload apache
#
sudo a2ensite vagrant
sudo a2dissite 000-default
sudo service apache2 restart
sudo service mongodb restart

#
#  Cleanup
#
sudo apt-get autoremove -y

echo -e "----------------------------------------"
echo -e "To create a Phalcon Project:\n"
echo -e "----------------------------------------"
echo -e "$ cd /vagrant/www"
echo -e "$ phalcon project <projectname>\n"
echo -e
echo -e "Then follow the README.md to copy/paste the VirtualHost!\n"

echo -e "----------------------------------------"
echo -e "Default Site: http://192.168.50.4"
echo -e "----------------------------------------"
