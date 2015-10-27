# Vagrant Phalcon

Phalcon strives to get closer to developers, providing flexible, powerful and simple tools.
We would like a Phalcon development process to be effortless and pleasant
from deployment of the development environment to the programming in Zephir language.

[Vagrant][1] provides a simple, elegant way to manage and provision Virtual Machines and
this is a *recommended* Vagrant setup to get loaded with core development tools
to build a powerful PHP application focused on [Phalcon Framework][2].

## Index
- [Landing Page](#landing-page)
- [Overview](#overview)
- [Packages Included](#packages-included)
- [Requirements](#requirements)
- [Installation](#installation)
- [Vagrant Credentials](#vagrant-credentials)
- [Create a Phalcon Project](#create-a-phalcon-project)
- [Create a VHost Record](#create-a-vhost-record)
- [Local Editing](#local-editing)
- [Using SSH](#using-ssh)
- [Troubleshooting Vagrant Ubuntu](#troubleshooting-vagrant-ubuntu)
- [Troubleshooting Phalcon](#troubleshooting-phalcon)
- [Software Suggestions](#software-suggestions)

# Landing Page
This is the default page for the Phalcon Vagrant Setup. This page will be empty at the beginning until
you start adding VirtualHosts and content to the `/www/` folder. 
<img src="http://static.jream.com/img/github-phalcon-vagrant.jpg" alt="Phalcon Vagrant">

## Overview

We use the default Ubuntu trusty64 ISO from Vagrant for compatibility.
If you choose to use a 64-bit ISO you may need to update your BIOS to enable virtualization with AMD-V or Intel VT.

When you provision Vagrant for the first time it's always the longest procedure (`$ vagrant up`).
Vagrant will download the entire Linux OS if you've never used Vagrant or the ubuntu/trusty64 Box.
Afterwards, booting time is fast.

By default this setup uses 500MB RAM. You can change this in `Vagrantfile` and simply run `$ vagrant reload`.
You can also use more than one core if you like, simply uncomment these two lines in the same file:

```yaml
v.customize ["modifyvm", :id, "--cpus", "2"]
v.customize ["modifyvm", :id, "--ioapic", "on"]
```

## Packages Included

- LAMP Stack
  - Ubuntu 14.04.3 LTS
  - Apache 2.4
  - PHP 5.5
  - MySQL 5.6
- Git 1.9
- Memcached 1.4
- [Beanstalkd][11] 1.9
- [Zephir][10] 0.8
- [SQLite][8] 2.8
- [PostgreSQL][9] 9.4
- [Phalcon][2] (latest stable)
- [Phalcon Dev Tools][3] (latest stable)
- [Redis][4] 2.8
- [MongoDB][5] 2.0
- [Composer][6] (latest stable)

## Requirements

- Operating System: Windows, Linux, or OSX.
- [Virtualbox][7] >= 4.3.10
- [Vagrant][1] >= 1.4.1

If you have issues with Windows and `vbguest` additions, use the following versions:
- Virtualbox version 4.2.*
- Vagrant 1.4.1

## Installation

First you need a [Git enabled terminal](#software-suggestions). Then you should **clone this repository** locally.

```sh
$ git clone https://github.com/phalcon/vagrant.git
```

For newer versions of Vagrant and VirtualBox you may need **guest additions**, so install the plugin:

```sh
# For Linux/OSX
$ vagrant plugin install vagrant-vbguest

# For Windows
$ vagrant plugin install vagrant-windows
```

Now you are ready to provision your Virtual Machine, run:

```sh
$ vagrant up
```

The `init.sh` script will provision the system with everything needed. Take a look
inside if you want to change any default settings. Once provisioned, to access the box, simply type:

```sh
$ vagrant ssh

# To exit type:
$ exit
```

If you want to change your bound address (`192.168.50.4`), edit `Vagrantfile`, change the ip and run:

```sh
$ vagrant reload
```

If you want to point your Guest Machine (The Virtual Machine OS) to a friendly URL,
you could modify your `etc/hosts` file and add the following:

```
192.168.50.4  your-server-name
```

## Vagrant Credentials

These are credentials setup by default:

- **Host Address**: 192.168.50.4 _(Change in Vagrantfile if you like)_
- **SSH**: vagrant / vagrant _(If root password fails, run `$ sudo passwd` and set one)_
- **MySQL**: root / (none)
- **PostgreSQL**: postgres / postgres _(We have disabled the password promt for `psql -U postgres` command)_
- **Redis**: (none)

## Create a Phalcon Project

To create your Phalcon project, head over to the default working directory:

```sh
$ cd /vagrant/www
```

Then run the following command using the Phalcon Dev Tools to see your options:

```sh
$ phalcon
```

To create a project type the following, I'll create one called `superstar` for this example:

```sh
$ phalcon project superstar
```

This will create a folder called `superstar` with all your Phalcon files. At this
point you have a folder at `/vagrant/www/superstar` and your VirtualHost will need
to point to `/vagrant/www/superstar/public`

## Create a VHost Record

You can have multiple Phalcon projects in subfolders. Make sure to keep your base
VirtualHost enabled, in our case it's the `vagrant.conf` enabled by default.
Then follow the instructions below and take note, you must include the `ServerPath /project/` in your VirtualHost's.

**Do not include a ServerPath for the base vagrant.conf VirtualHost.**

```sh
$ touch superstar.conf
```

Then include the following data (Notice the two directory paths with `superstar`)
```apache
<VirtualHost *:80>
    DocumentRoot /vagrant/www/superstar/public
    ServerPath /superstar
</VirtualHost>

<Directory "/vagrant/www/superstar/public">
    Options Indexes Followsymlinks
    AllowOverride All
    Require all granted
</Directory>
```

Next move your VirtualHost configuration file to sites-available in Apache:

```sh
$ sudo mv superstar.conf /etc/apache2/sites-available
```

Lastly, you must enable your configuration file and restart apache

```sh
$ sudo a2ensite superstar
$ sudo service apache2 reload
```

If you wanted to disable a site:

```sh
$ sudo a2dissite superstar
$ sudo service apache2 reload
```

You should be able to access the following URL's:

```
http://192.168.50.4/
http://192.168.50.4/superstar
```

## Local Editing

On your Host computer open any file explorer or IDE and navigate to `/www/`. 
This folder is mounted to the Virtual Machine. Any changes to files within here will reflect
realtime changes in the Virtual Machine.

If you are using .git you should initialize your repository locally rather than on the server.
This way you will not have to import keys into your Virtual Machine.

## Using SSH

Files in the shared directory of `www` are by default given ownership of `www-data:www-data` so
that you will have no problems with saving cached files. Even with the `vagrant` user within
the `www-data` group, and even with `0777` write permissions I could't get the cache to save.

So this simply means, if you edit things in the `www` folder you must run `sudo command` to do so.


## Troubleshooting Vagrant Ubuntu

If you are using Linux such as Ubuntu, you may have to set a different IP that doesn't interfere with DHCP in linux, here is a safe bet:
- `192.168.50.4`

If you are using the latest VirtualBox with Ubuntu 14, after installing guest additions (below),
to fix the error message you will get due to a bug in the guest additions do the following after you run `$ vagrant up`.

```sh
$ vagrant ssh
$ sudo ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
$ vagrant reload
```

## Troubleshooting Phalcon

If you are having trouble with Phalcon in this Vagrant Project (Or on your live server),
try compiling in [safe mode](https://github.com/phalcon/cphalcon/issues/2336#issuecomment-40333421).

If you are having problems with guest-additions on linux with mounting folders run this command in the guest machine:

```sh
    $ sudo ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
```

## Software Suggestions

If you are using Linux you can use the built in Terminal to do everything.
The same goes with OSX.

For Windows, you can use [Git SCM](http://git-scm.com/) and Bash.

[1]: http://vagrantup.com/
[2]: https://phalconphp.com/
[3]: https://github.com/phalcon/phalcon-devtools
[4]: http://redis.io/
[5]: https://www.mongodb.org/
[6]: https://getcomposer.org
[7]: https://www.virtualbox.org
[8]: https://www.sqlite.org/
[9]: http://www.postgresql.org/
[10]: http://zephir-lang.com/
[11]: http://kr.github.io/beanstalkd/
