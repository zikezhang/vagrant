#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export COMPOSER_ALLOW_SUPERUSER=1
export ZEPHIRDIR=/usr/share/zephir
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#
# Add Swap
#
dd if=/dev/zero of=/swapspace bs=1M count=4000
mkswap /swapspace
swapon /swapspace
echo "/swapspace none swap defaults 0 0" >> /etc/fstab

echo nameserver 8.8.8.8 > /etc/resolv.conf
echo nameserver 8.8.4.4 > /etc/resolv.conf

#
# Add PHP and PostgreSQL repositories
#
LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
apt-add-repository -y ppa:chris-lea/libsodium
add-apt-repository -y ppa:chris-lea/redis-server
touch /etc/apt/sources.list.d/pgdg.list
echo -e "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list &>/dev/null
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Cleanup package manager
apt-get clean -y
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

apt-get update -qq
apt-get upgrade -y
apt-get install -y build-essential software-properties-common python-software-properties

#
# Setup locales
#
echo -e "LC_CTYPE=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8\nLANGUAGE=en_US.UTF-8" | tee -a /etc/environment &>/dev/null
locale-gen en_US en_US.UTF-8
dpkg-reconfigure locales

#
# Base system
#
apt-get install -yq --no-install-suggests --no-install-recommends \
  mysql-server-5.6 \
  mysql-client-5.6 \
  apache2 \
  libapache2-mod-php5.6 \
  memcached \
  mongodb-clients \
  mongodb-server \
  postgresql-9.4 \
  sqlite3 \
  beanstalkd \
  libyaml-dev \
  libsodium-dev \
  curl \
  htop \
  git \
  dos2unix \
  unzip \
  vim \
  mc \
  grc \
  gcc \
  make \
  re2c \
  libpcre3 \
  libpcre3-dev \
  lsb-core \
  autoconf \
  redis-server \
  redis-tools

#
# Base PHP
#
apt-get install -yq --no-install-suggests --no-install-recommends \
  php5.6 \
  php5.6-apcu \
  php5.6-bcmath \
  php5.6-bz2 \
  php5.6-cli \
  php5.6-common \
  php5.6-curl \
  php5.6-dba \
  php5.6-dev \
  php5.6-gd \
  php5.6-gearman \
  php5.6-gettext \
  php5.6-gmp \
  php5.6-imagick \
  php5.6-imap \
  php5.6-intl \
  php5.6-json \
  php5.6-mbstring \
  php5.6-memcached \
  php5.6-memcache \
  php5.6-mcrypt \
  php5.6-mongo \
  php5.6-mongodb \
  php5.6-mysql \
  php-pear \
  php5.6-odbc \
  php5.6-pgsql \
  php5.6-ps \
  php5.6-pspell \
  php5.6-redis \
  php5.6-readline \
  php5.6-recode \
  php5.6-soap \
  php5.6-sqlite3 \
  php5.6-tidy \
  php5.6-xdebug \
  php5.6-xmlrpc \
  php5.6-xsl \
  php5.6-zip

echo "apc.enable_cli = 1" >> /etc/php/5.6/mods-available/apcu.ini

#
# Update PECL channel
#
pecl channel-update pecl.php.net

#
# Tune Up Postgres
#
cp /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.bkup.conf
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres'" &>/dev/null
sed -i.bak -E 's/local\s+all\s+postgres\s+peer/local\t\tall\t\tpostgres\t\ttrust/g' /etc/postgresql/9.4/main/pg_hba.conf

#
# YAML
#
(CFLAGS="-O1 -g3 -fno-strict-aliasing"; pecl install yaml < /dev/null &)
touch /etc/php/5.6/mods-available/yaml.ini
echo 'extension=yaml.so' | tee /etc/php/5.6/mods-available/yaml.ini &>/dev/null

#
# Libsodium
#
pecl install -a libsodium < /dev/null &
touch /etc/php/5.6/mods-available/libsodium.ini
echo 'extension=libsodium.so' | tee /etc/php/5.6/mods-available/libsodium.ini &>/dev/null

#
# Zephir
#
echo "export ZEPHIRDIR=/usr/share/zephir" >> /home/vagrant/.bashrc
mkdir -p ${ZEPHIRDIR}
phpdismod xdebug redis
(cd /tmp && git clone git://github.com/phalcon/zephir.git && cd zephir && ./install -c)
chown -R vagrant:vagrant ${ZEPHIRDIR}

#
# Install Phalcon Framework
#
git clone --depth=1 git://github.com/phalcon/cphalcon.git
(cd cphalcon && zephir build)
touch /etc/php/5.6/mods-available/phalcon.ini
echo -e "extension=phalcon.so" | tee /etc/php/5.6/mods-available/phalcon.ini &>/dev/null

#
# Tune Up Redis
#
cp /etc/redis/redis.conf /etc/redis/redis.bkup.conf
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf

#
# Tune Up MySQL
#
cp /etc/mysql/my.cnf /etc/mysql/my.bkup.cnf
sed -i 's/bind-address/bind-address = 0.0.0.0#/' /etc/mysql/my.cnf
mysql -u root -Bse "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"

#
# Composer for PHP
#
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

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

mv vagrant.conf /etc/apache2/sites-available
a2enmod rewrite

#
# Install Phalcon DevTools
#
cd ~
echo '{"require": {"phalcon/devtools": "dev-master"}}' > composer.json
composer install --ignore-platform-reqs
rm composer.json
mkdir /opt/phalcon-tools
mv ~/vendor/phalcon/devtools/* /opt/phalcon-tools
rm -rf ~/vendor
echo "export PTOOLSPATH=/opt/phalcon-tools/" >> /home/vagrant/.bashrc
echo "export PATH=\$PATH:/opt/phalcon-tools/" >> /home/vagrant/.bashrc
chmod +x /opt/phalcon-tools/phalcon.sh
ln -s /opt/phalcon-tools/phalcon.sh /usr/bin/phalcon

#
# Tune UP PHP
#
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php/5.6/apache2/php.ini
sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' /etc/php/5.6/apache2/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /etc/php/5.6/apache2/php.ini
sed -i '/\[Session\]/a session.save_path = "/tmp"' /etc/php/5.6/apache2/php.ini
phpenmod -v 5.6 -s ALL yaml mcrypt intl curl libsodium phalcon soap redis xdebug

#
# Tune Up Apache
#
sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars

#
# Reload apache
#
a2ensite vagrant
a2dissite 000-default

#
#  Cleanup
#
apt-get autoremove -y
apt-get autoclean -y

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
