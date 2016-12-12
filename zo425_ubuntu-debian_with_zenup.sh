#!/bin/bash
##########################################
# Version: 03b
#  Status: Functional
#   Notes: 4.2.4 Upgrade Working & more 14.04 Support
#  Zenoss: Core 4.2.5 (v2108) + ZenPacks
#      OS: Ubuntu/Debian 64-Bit
##########################################

# Beginning Script Message
(
clear
echo && echo "Welcome to the Zenoss 4.2.5 core-autodeploy script for Ubuntu and Debian! (http://hydruid-blog.com/?p=710)" && echo
echo "*WARNING*: This script will update your OS and for Debian users it will install the "Testing" version of some packages."
echo "           Make sure to make a backup and/or take a snapshot!" && echo && sleep 5
echo "...Begin, we will, learn you must." && sleep 1

# Installer variables
ZENOSSHOME="/home/zenoss"
DOWNDIR="/tmp"
UPGRADE="no" # Valid options are "yes" and "no"
ZVER="425"
ZVERb="4.2.5"
ZVERc="2108"
DVER="03c"
PACKAGECLEANUP="yes" # Valid options are "yes" and "no"

# Upgrade Message
if [ $UPGRADE = "yes" ]; then
	echo && echo "...The upgrade process from 4.2.4 to 4.2.5 is still a work in progress. Use at your own risk and MAKE A BACKUP!" && sleep 5
fi

# Update OS
apt-get update && apt-get dist-upgrade -y
if [ $PACKAGECLEANUP = "yes" ]; then
        apt-get autoremove -y
fi

# Setup zenoss user and build environment
useradd -m -U -s /bin/bash zenoss
mkdir $ZENOSSHOME/zenoss$ZVER-srpm_install
rm -f $ZENOSSHOME/zenoss$ZVER-srpm_install/variables.sh
wget --no-check-certificate -N https://raw.github.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/variables.sh -P $ZENOSSHOME/zenoss$ZVER-srpm_install/
. $ZENOSSHOME/zenoss$ZVER-srpm_install/variables.sh
mkdir $ZENHOME && chown -cR zenoss:zenoss $ZENHOME

# OS compatibility tests
detect-os && detect-arch && detect-user && hostname-verify

# Upgrade Preparation
if [ $UPGRADE = "yes" ]; then
        /etc/init.d/zenoss stop
	cp $ZENHOME/etc/global.conf $ZENOSSHOME
fi

# Install Package Dependencies
if [ $curos = "ubuntu" ]; then
	multiverse-verify
	if [ $idos = "14" ]; then
		apt-get install software-properties-common -y && sleep 1
	else
		apt-get install python-software-properties -y && sleep 1
	fi	
	echo | add-apt-repository ppa:webupd8team/java && sleep 1 && apt-get update
	apt-get install rrdtool libmysqlclient-dev nagios-plugins erlang subversion autoconf swig unzip zip g++ libssl-dev maven libmaven-compiler-plugin-java build-essential libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev oracle-java7-installer python-twisted python-gnutls python-twisted-web python-samba libsnmp-base snmp-mibs-downloader snmpd bc rpm2cpio memcached libncurses5 libncurses5-dev libreadline6-dev libreadline6 librrd-dev python-setuptools python-dev erlang-nox redis-server -y
	pkg-fix
        # JC - install working snmpd.conf with public community for SNMP v1 and v2c
        wget -N --no-check-certificate  https://rawgithub.com/jcurry/Zenoss_4.2.5_core-autodeploy/ubuntu/snmpd.conf -P $DOWNDIR
        cp $DOWNDIR/snmpd.conf /etc/snmp
        service snmpd stop
        service snmpd start
	export DEBIAN_FRONTEND=noninteractive
	apt-get install mysql-server mysql-client mysql-common -y
	mysql-conn_test
	pkg-fix
fi
if [ $curos = "debian" ]; then
	apt-get install python-software-properties -y && sleep 1
	echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list
	echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
	apt-get update
	apt-get install rrdtool libmysqlclient-dev nagios-plugins erlang subversion autoconf swig unzip zip g++ libssl-dev maven libmaven-compiler-plugin-java build-essential libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev oracle-java7-installer python-twisted python-gnutls python-twisted-web python-samba libsnmp-base bc rpm2cpio memcached libncurses5 libncurses5-dev libreadline6-dev libreadline6 librrd-dev python-setuptools python-dev erlang-nox smistrip redis-server -y
	debian-testing-repo
	wget -N http://ftp.us.debian.org/debian/pool/non-free/s/snmp-mibs-downloader/snmp-mibs-downloader_1.1_all.deb
	dpkg -i snmp-mibs-downloader_1.1_all.deb
	export DEBIAN_FRONTEND=noninteractive
	apt-get install mysql-server mysql-client mysql-common -y
	mysql-conn_test
        pkg-fix
fi

# Download Zenoss DEB and install it
# JC - Location for Zenoss has changed....
#wget -N http://softlayer-dal.dl.sourceforge.net/project/zenossforubuntu/zenoss-core-425-2108_03c_amd64.deb -P $DOWNDIR/
wget -O $DOWNDIR/zenoss-core-425-2108_03c_amd64.deb -N https://sourceforge.net/projects/zenossforubuntu/files/zenoss-core-425-2108_03c_amd64.deb/download -P $DOWNDIR/
if [ $UPGRADE = "no" ]; then
	dpkg -i $DOWNDIR/zenoss-core-425-2108_03c_amd64.deb
fi
if [ $UPGRADE = "yes" ]; then
	echo "...The follow errors are normal, still working to suppress them" && sleep 5
	dpkg -r zenoss-core-424-1897
        dpkg -i $DOWNDIR/zenoss-core-425-2108_03c_amd64.deb
fi
rm -f $ZENOSSHOME/zenoss$ZVER-srpm_install/variables.sh
wget --no-check-certificate -N https://raw.github.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/variables.sh -P $ZENOSSHOME/zenoss$ZVER-srpm_install/
chown -R zenoss:zenoss $ZENHOME && chown -R zenoss:zenoss $ZENOSSHOME

# Import the MySQL Database and create users
if [ $UPGRADE = "no" ]; then
	if [ $mysqlcred = "yes" ]; then
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "create database zenoss_zep"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "create database zodb"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "create database zodb_session"
		echo && echo "...The 1305 MySQL import error below is safe to ignore"
		mysql -u$MYSQLUSER -p$MYSQLPASS zenoss_zep < $ZENOSSHOME/zenoss_zep.sql
		mysql -u$MYSQLUSER -p$MYSQLPASS zodb < $ZENOSSHOME/zodb.sql
		mysql -u$MYSQLUSER -p$MYSQLPASS zodb_session < $ZENOSSHOME/zodb_session.sql
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "CREATE USER 'zenoss'@'localhost' IDENTIFIED BY  'zenoss';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'localhost' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "CREATE USER 'zenoss'@'%' IDENTIFIED BY  'zenoss';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'%' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -p$MYSQLPASS -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'%';"
		rm $ZENOSSHOME/*.sql && echo 
	fi
        if [ $mysqlcred = "no" ]; then
		mysql -u$MYSQLUSER -e "create database zenoss_zep"
		mysql -u$MYSQLUSER -e "create database zodb"
		mysql -u$MYSQLUSER -e "create database zodb_session"
		echo && echo "...The 1305 MySQL import error below is safe to ignore"
		mysql -u$MYSQLUSER zenoss_zep < $ZENOSSHOME/zenoss_zep.sql
		mysql -u$MYSQLUSER zodb < $ZENOSSHOME/zodb.sql
		mysql -u$MYSQLUSER zodb_session < $ZENOSSHOME/zodb_session.sql
		mysql -u$MYSQLUSER -e "CREATE USER 'zenoss'@'localhost' IDENTIFIED BY  'zenoss';"
		mysql -u$MYSQLUSER -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'localhost' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'localhost';"
		mysql -u$MYSQLUSER -e "CREATE USER 'zenoss'@'%' IDENTIFIED BY  'zenoss';"
		mysql -u$MYSQLUSER -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'%' IDENTIFIED BY PASSWORD '*3715D7F2B0C1D26D72357829DF94B81731174B8C';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'%';"
		mysql -u$MYSQLUSER -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'%';"
		rm $ZENOSSHOME/*.sql && echo
	fi
fi

# Rabbit install and config
wget -N http://www.rabbitmq.com/releases/rabbitmq-server/v3.3.0/rabbitmq-server_3.3.0-1_all.deb -P $DOWNDIR/
dpkg -i $DOWNDIR/rabbitmq-server_3.3.0-1_all.deb
chown -R zenoss:zenoss $ZENHOME && echo
rabbitmqctl add_user zenoss zenoss
rabbitmqctl add_vhost /zenoss
rabbitmqctl set_permissions -p /zenoss zenoss '.*' '.*' '.*' && echo

# Post Install Tweaks
os-fixes
echo && ln -s /usr/local/zenoss /opt
apt-get install libssl1.0.0 libssl-dev -y
ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /usr/lib/libssl.so.10
ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /usr/lib/libcrypto.so.10
ln -s /usr/local/zenoss/zenup /opt
chmod +x /usr/local/zenoss/zenup/bin/zenup
echo 'watchdog True' >> $ZENHOME/etc/zenwinperf.conf
touch $ZENHOME/var/Data.fs && echo
# JC - Says it cant get this - 404 ??? - lose the "2" after "raw"
#wget --no-check-certificate -N https://raw2.github.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/zenoss -P $DOWNDIR/
wget --no-check-certificate -N https://raw.github.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/zenoss -P $DOWNDIR/
cp $DOWNDIR/zenoss /etc/init.d/zenoss
chmod 755 /etc/init.d/zenoss
update-rc.d zenoss defaults && sleep 2
echo && touch /etc/insserv/overrides/zenoss
cat > /etc/insserv/overrides/zenoss << EOL
### BEGIN INIT INFO
# Provides: zenoss-stack
# Required-Start: $local_fs $network $remote_fs
# Required-Stop: $local_fs $network $remote_fs
# Should-Start: $all
# Should-Stop: $all
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start/stop Zenoss-stack
# Description: Start/stop Zenoss-stack
### END INIT INFO
EOL
echo && chown -c root:zenoss /usr/local/zenoss/bin/pyraw
chown -c root:zenoss /usr/local/zenoss/bin/zensocket
chown -c root:zenoss /usr/local/zenoss/bin/nmap
chmod -c 04750 /usr/local/zenoss/bin/pyraw
chmod -c 04750 /usr/local/zenoss/bin/zensocket
chmod -c 04750 /usr/local/zenoss/bin/nmap && echo
wget --no-check-certificate -N https://raw.github.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/secure_zenoss_ubuntu.sh -P $ZENHOME/bin
chown -c zenoss:zenoss $ZENHOME/bin/secure_zenoss_ubuntu.sh && chmod -c 0700 $ZENHOME/bin/secure_zenoss_ubuntu.sh
su -l -c "$ZENHOME/bin/secure_zenoss_ubuntu.sh" zenoss
if [ $UPGRADE = "yes" ]; then
	su -l -c "zeneventserver stop && cd $ZENHOME/var/zeneventserver/index && rm -rf summary && rm -rf archive && zeneventserver start" zenoss
fi 
echo '#max_allowed_packet=16M' >> /etc/mysql/my.cnf
echo 'innodb_buffer_pool_size=256M' >> /etc/mysql/my.cnf
echo 'innodb_additional_mem_pool_size=20M' >> /etc/mysql/my.cnf
sed -i 's/mibs/#mibs/g' /etc/snmp/snmp.conf
wget --no-check-certificate -N https://raw.githubusercontent.com/hydruid/zenoss/master/core-autodeploy/$ZVERb/misc/backup.sh -P $ZENOSSHOME

# Check log for errors
check-log

# Get .bash_profile for zenoss user
echo "Getting .bash_profile for zenoss user for use in su"
wget -N --no-check-certificate  https://rawgithub.com/jcurry/Zenoss_4.2.5_core-autodeploy/ubuntu/.bash_profile -P $DOWNDIR/
cp $DOWNDIR/.bash_profile /home/zenoss
chown zenoss:zenoss /home/zenoss/.bash_profile

# zenup installed as part of Zenoss install - but old version. Get zenup for deb from github
# deb version of zenup created using the alien utility in Ubuntu to convert rpm to deb
#   alien requires --scripts parameter to convert scripts

echo "Getting Zenup debian package"
wget -N --no-check-certificate  https://raw.github.com/jcurry/Zenoss_4.2.5_core-autodeploy/ubuntu/zenup_1.1.0.267.869d67a-2_amd64.deb -P $DOWNDIR/

#Get pristine 
echo " Getting pristine SP203"
wget -O $DOWNDIR/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz --no-check-certificate  http://sourceforge.net/projects/zenoss/files/zenoss-4.2/zenoss-4.2.5/updates/2014-08-06/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz/download

# JC - zup file needs modification.  Check_mibs script has no bash shebang so runs under Ubuntu
#   native dash (not bash) where "local" is interpreted differently and fails.
#  I have exploded the standard zup and modified check_mibs to add a bash shebang.
#  Get zup from git hub repo not from sourceforge.

echo " Getting ZUP 671 for Ubuntu"
wget -N --no-check-certificate https://raw.github.com/jcurry/Zenoss_4.2.5_core-autodeploy/ubuntu/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup  -P $DOWNDIR

# Need to remove old version of zenup - it is installed under /usr/local/zenoss and linked to /opt/zenup

echo "Removing old zenup and installing zenup 1.1.0"
rm -rf /usr/local/zenoss/zenup
dpkg -i $DOWNDIR/zenup_1.1.0.267.869d67a-2_amd64.deb
# Put the zenup code into /opt/zenup in case it is wanted in the future
cp $DOWNDIR/zenup_1.1.0.267.869d67a-2_amd64.deb /opt/zenup
chown zenoss:zenoss /opt/zenup/zenup_1.1.0.267.869d67a-2_amd64.deb

# JC Fix problems that will be found by zenup....  To be run by zenoss user
su -l -c 'find /usr/local/zenoss -type f ! \( -name pyraw -o -name zensocket -o -name nmap -o -name nginx -o -name nginx.pid -o -name zodbpack.pyc -o -name zone.tab -o -name iso3166.tab -o -name libpython2.7.so.1.0 \) ! \( -user zenoss -group zenoss -perm -u+rw \) -exec chown zenoss:zenoss {} \; -exec chmod u+rw {} \;' zenoss


#  Copy pristine to /opt/zenup  and run zenup init
cp $DOWNDIR/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz /opt/zenup 
chown zenoss:zenoss /opt/zenup/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz

# Note that su -l .... zenoss construct only seems to work if zenoss user has 
#  a .bash_profile that has the usual Zenoss environment vars in it.  
#  Sourcing .bashrc from .bash_profile doesnt seem to work

su -l -c "(echo '') | /opt/zenup/bin/zenup init /opt/zenup/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz \$ZENHOME" zenoss

#  Copy sup file to /opt/zenup  and run zenup install
# Install SUP671 supply ENTER to respond with default to 2 questions
cp $DOWNDIR/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup /opt/zenup  
chown zenoss:zenoss /opt/zenup/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup

su -l -c "(echo ''; echo '') | /opt/zenup/bin/zenup install /opt/zenup/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup" zenoss
#su -l -c "cp \$DOWNDIR/zenoss_core-4.2.5-SP671-zenup11.zup /opt/zenup && (echo ''; echo '') | zenup install /opt/zenup/zenoss_core-4.2.5-SP671-zenup11.zup" zenoss

# Check zenup status
su -l -c "/opt/zenup/bin/zenup status --verbose" zenoss

#Start zenoss daemons
su -l -c "ZENHOME=/usr/local/zenoss && zenoss start" zenoss

# End of Script Message
FINDIP=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
echo && echo "The Zenoss $ZVERb core-autodeploy script for Ubuntu is complete!!!"
echo "A backup script (backup.sh) has been placed in the zenoss user home directory." && echo
echo "Browse to $FINDIP:8080 to access your new Zenoss install."
echo "The default login is:"
echo "  username: admin"
echo "  password: zenoss"


exit 0
) | tee /tmp/zenoss425_ubuntu_install.out 2>&1
