#!/bin/bash
################################################################################
#
# A simple script to auto-install Zenoss Core 4.2a.5
#
# This script should be run on a base install of
# CentOS 6 or RHEL 6.
# JC - Added --no-check-certificate to all wget lines
# JC - major updates April 2020
# JC - updated 31 March 2022 to add "--disablerepo=*" to all yum statements
#      Script should now run completely standalone
#      If yum remove doesn't work, try rpm -e <package>
#
################################################################################

# Tee everything to /tmp/zenoss425_install.out
(
cat <<EOF
Welcome to the Zenoss Core auto-deploy script!

This auto-deploy script installs the Oracle Java Runtime Environment (JRE).
To continue, please review and accept the Oracle Binary Code License Agreement
for Java SE. 

Press Enter to continue.
EOF
read
less licenses/Oracle-BCLA-JavaSE
while true; do
    read -p "Do you accept the Oracle Binary Code License Agreement for Java SE?" yn
    case $yn in
        [Yy]* ) echo "Install continues...."; break;;
        [Nn]* ) echo "Installation aborted."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

umask 022
# this may or may not be helpful for an install issue some people are having, but shouldn't hurt:
unalias -a

if [ -L /opt/zenoss ]; then
	echo "/opt/zenoss appears to be a symlink. Please remove and re-run this script."
	exit 1
fi

if [ `rpm -qa | egrep -c -i "^mysql-"` -gt 0 ]; then
cat << EOF

It appears that the distro-supplied version of MySQL is at least partially installed,
or a prior installation attempt failed.

Please remove these packages, as well as their dependencies (often postfix), and then
retry this script:

$(rpm -qa | egrep -i "^mysql-")

EOF
exit 1
fi

try() {
	"$@"
	if [ $? -ne 0 ]; then
		echo "Command failure: $@"
		exit 1
	fi
}

die() {
	echo $*
	exit 1
}

disable_repo() {
	local conf=/etc/yum.repos.d/$1.repo
	if [ ! -e "$conf" ]; then
		echo "Yum repo config $conf not found"
	else
		sed -i -e 's/^enabled.*/enabled = 0/g' $conf
	fi
}

enable_repo() {
	local conf=/etc/yum.repos.d/$1.repo
	if [ ! -e "$conf" ]; then
		die "Yum repo config $conf not found -- exiting."
	else
		sed -i -e 's/^enabled.*/enabled = 1/g' $conf
	fi
}

enable_service() {
	try /sbin/chkconfig $1 on
	try /sbin/service $1 start
}

#Now that RHEL6 RPMs are released, lets try to be smart and pick RPMs based on that
if [ -f /etc/redhat-release ]; then
	elv=`cat /etc/redhat-release | gawk 'BEGIN {FS="release "} {print $2}' | gawk 'BEGIN {FS="."} {print $1}'`
	#EnterpriseLinux Version String. Just a shortcut to be used later
	els=el$elv
else
	#Bail
	die "Unable to determine version. I can't continue"
fi

echo "Ensuring Zenoss RPMs are not already present"
if [ `rpm -qa | grep -c -i ^zenoss` -gt 0 ]; then
	die "I see Zenoss Packages already installed. I can't handle that"
fi

# JC - 20200424 - Let's install everything from the pre_req_downloads directory
MYTMP="$SCRIPTPATH"
cd $MYTMP || die "Couldn't change to temporary directory"
#Disable SELinux:

echo "Disabling SELinux..."
if [ -e /selinux/enforce ]; then
	echo 0 > /selinux/enforce
fi

if [ -e /etc/selinux/config ]; then
	sed -i -e 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

openjdk="$(rpm -qa | grep java.*openjdk)"
if [ -n "$openjdk" ]; then
	echo "Attempting to remove existing OpenJDK..."
	try rpm -e $openjdk
fi

# Auto-detect latest build:
build=4.2.5-2108
rmqv=2.8.7
# SourceForge directory hierarchy changed December 2018.....
#zenoss_base_url="https://downloads.sourceforge.net/project/zenoss/zenoss-4.2/zenoss-4.2.5/"
zenoss_base_url="https://sourceforge.net/projects/zenoss/files/Community%20Edition%20v4%20%28final%29"
zenoss_rpm_file="zenoss_core-$build.$els.x86_64.rpm"


#MySQL 5.29 creates dependancy issues, we'll force 5.28 for the remainder of the life of 4.2 - ?? from original script
mysql_v="5.5.37-1"
echo "Using MySQL Community Release version $mysql_v"

jre_file="jre-6u31-linux-x64-rpm.bin"
jre_url="http://javadl.sun.com/webapps/download/AutoDL?BundleId=59622"
mysql_client_rpm="MySQL-client-$mysql_v.linux2.6.x86_64.rpm"
mysql_server_rpm="MySQL-server-$mysql_v.linux2.6.x86_64.rpm"
mysql_shared_rpm="MySQL-shared-$mysql_v.linux2.6.x86_64.rpm"
mysql_compat_rpm="MySQL-shared-compat-$mysql_v.linux2.6.x86_64.rpm"
epel_rpm_url=http://dl.fedoraproject.org/pub/epel/$elv/x86_64

#JC - disable rpmforge repo if present - it can cause problems
disable_repo rpmforge

# JC - get the zenoss deps (which sorts the rpmforge requirement)
#wget --no-check-certificate http://deps.zenoss.com/yum/zenossdeps-4.2.x-1.$els.noarch.rpm
echo Install the Zenoss dependencies -  zenossdeps-4.2.x-1.$els.noarch.rpm
try yum -y localinstall --disablerepo=* zenossdeps-4.2.x-1.$els.noarch.rpm

echo "Installing EPEL Repo"
# JC - the regex epel* in the following wget also gets epel-rpm-macro which has new prereqs
#   (as of October 2016) of 3 python-rpm-macros packages (see http://www.zenoss.org/forum/146626 )
# In fact,  the epel-release package is in the 'extras' repo that comes with a minimal install of
#   centos so you can just do `yum install epel-release` and avoid the wget too. (thanks baileytj)

yum -y localinstall --disablerepo=* epel-release-6-8.noarch.rpm
disable_repo epel

echo "Installing erlang-R14B-04.3.el6.x86_64.rpm"
# tk-8.5.7-5.el6.x86_64.rpm and unixODBC-2.2.14-14.el6.x86_64.rpm are prereqs and wx packages
try yum -y localinstall --disablerepo=* tk-8.5.7-5.el6.x86_64.rpm
try yum -y localinstall --disablerepo=* unixODBC-2.2.14-14.el6.x86_64.rpm
try yum -y localinstall --disablerepo=* wxBase-2.8.12-1.el6.centos.x86_64.rpm wxGTK-2.8.12-1.el6.centos.x86_64.rpm wxGTK-gl-2.8.12-1.el6.centos.x86_64.rpm
ERLANGPREREQFILES="erlang-appmon-R14B-04.3.el6.x86_64.rpm           erlang-kernel-R14B-04.3.el6.x86_64.rpm
erlang-asn1-R14B-04.3.el6.x86_64.rpm             erlang-megaco-R14B-04.3.el6.x86_64.rpm
erlang-common_test-R14B-04.3.el6.x86_64.rpm      erlang-mnesia-R14B-04.3.el6.x86_64.rpm
erlang-compiler-R14B-04.3.el6.x86_64.rpm         erlang-observer-R14B-04.3.el6.x86_64.rpm
erlang-cosEventDomain-R14B-04.3.el6.x86_64.rpm   erlang-odbc-R14B-04.3.el6.x86_64.rpm
erlang-cosEvent-R14B-04.3.el6.x86_64.rpm         erlang-orber-R14B-04.3.el6.x86_64.rpm
erlang-cosFileTransfer-R14B-04.3.el6.x86_64.rpm  erlang-os_mon-R14B-04.3.el6.x86_64.rpm
erlang-cosNotification-R14B-04.3.el6.x86_64.rpm  erlang-otp_mibs-R14B-04.3.el6.x86_64.rpm
erlang-cosProperty-R14B-04.3.el6.x86_64.rpm      erlang-parsetools-R14B-04.3.el6.x86_64.rpm
erlang-cosTime-R14B-04.3.el6.x86_64.rpm          erlang-percept-R14B-04.3.el6.x86_64.rpm
erlang-cosTransactions-R14B-04.3.el6.x86_64.rpm  erlang-pman-R14B-04.3.el6.x86_64.rpm
erlang-crypto-R14B-04.3.el6.x86_64.rpm           erlang-public_key-R14B-04.3.el6.x86_64.rpm
erlang-debugger-R14B-04.3.el6.x86_64.rpm
erlang-dialyzer-R14B-04.3.el6.x86_64.rpm         erlang-reltool-R14B-04.3.el6.x86_64.rpm
erlang-diameter-R14B-04.3.el6.x86_64.rpm         erlang-runtime_tools-R14B-04.3.el6.x86_64.rpm
erlang-docbuilder-R14B-04.3.el6.x86_64.rpm       erlang-sasl-R14B-04.3.el6.x86_64.rpm
erlang-edoc-R14B-04.3.el6.x86_64.rpm             erlang-snmp-R14B-04.3.el6.x86_64.rpm
erlang-erl_docgen-R14B-04.3.el6.x86_64.rpm       erlang-ssh-R14B-04.3.el6.x86_64.rpm
erlang-erl_interface-R14B-04.3.el6.x86_64.rpm    erlang-ssl-R14B-04.3.el6.x86_64.rpm
erlang-erts-R14B-04.3.el6.x86_64.rpm             erlang-stdlib-R14B-04.3.el6.x86_64.rpm
erlang-et-R14B-04.3.el6.x86_64.rpm               erlang-syntax_tools-R14B-04.3.el6.x86_64.rpm
erlang-eunit-R14B-04.3.el6.x86_64.rpm            erlang-test_server-R14B-04.3.el6.x86_64.rpm
erlang-toolbar-R14B-04.3.el6.x86_64.rpm
erlang-gs-R14B-04.3.el6.x86_64.rpm               erlang-tools-R14B-04.3.el6.x86_64.rpm
erlang-hipe-R14B-04.3.el6.x86_64.rpm             erlang-tv-R14B-04.3.el6.x86_64.rpm
erlang-ic-R14B-04.3.el6.x86_64.rpm               erlang-typer-R14B-04.3.el6.x86_64.rpm
erlang-inets-R14B-04.3.el6.x86_64.rpm            erlang-webtool-R14B-04.3.el6.x86_64.rpm
erlang-inviso-R14B-04.3.el6.x86_64.rpm           erlang-wx-R14B-04.3.el6.x86_64.rpm
erlang-jinterface-R14B-04.3.el6.x86_64.rpm       erlang-xmerl-R14B-04.3.el6.x86_64.rpm"

try yum -y localinstall --disablerepo=* $ERLANGPREREQFILES

try yum -y localinstall --disablerepo=* erlang-R14B-04.3.el6.x86_64.rpm erlang-examples-R14B-04.3.el6.x86_64.rpm

echo "Installing RabbitMQ"
# JC - rabbitmq-server-2.8.7-1.noarch requires a prereq of erlang >= R12B-3

try yum -y localinstall --disablerepo=* rabbitmq-server-2.8.7-1.noarch.rpm

# Scientific Linux 6 includes AMQP daemon -> qpidd stop it before starting rabbitmq
if [ -e /etc/init.d/qpidd ]; then
       try /sbin/service qpidd stop
       try /sbin/chkconfig qpidd off
fi
enable_service rabbitmq-server

echo "Downloading Files"
if [ ! -f $jre_file ];then
	echo "Downloading Oracle JRE"
	try wget --no-check-certificate -N -O $jre_file $jre_url
	try chmod +x $jre_file
fi
echo "Installing JRE"
try ./$jre_file

echo "Downloading and installing MySQL RPMs"
for file in $mysql_client_rpm $mysql_server_rpm $mysql_shared_rpm $mysql_compat_rpm;
do
	try yum -y localinstall --disablerepo=* $file
done

echo "Installing optimal /etc/my.cnf settings"
cat >> /etc/my.cnf << EOF
[mysqld]
max_allowed_packet=16M
innodb_buffer_pool_size = 256M
innodb_additional_mem_pool_size = 20M
EOF

echo "Configuring MySQL"
enable_service mysql
/usr/bin/mysqladmin -u root password ''
/usr/bin/mysqladmin -u root -h localhost password ''

# set up rrdtool, etc.
# JC - rrdtool is dependent on the zenossdeps repo

echo "Installing rrdtool"
# Install pre-reqs for rrdtool
#  ruby-libs-1.8.7.374-5.el6.x86_64.rpm
#  ruby-1.8.7.374-5.el6.x86_64.rpm
#  libdbi-0.8.3-4.el6.x86_64.rpm
#   And post-req, perl-rrdtool-1.4.7-1.el6.rfx.x86_64.rpm

try yum -y localinstall --disablerepo=* ruby-libs-1.8.7.374-5.el6.x86_64.rpm
try yum -y localinstall --disablerepo=* ruby-1.8.7.374-5.el6.x86_64.rpm
try yum -y localinstall --disablerepo=* libdbi-0.8.3-4.el6.x86_64.rpm
try yum -y  localinstall --disablerepo=* rrdtool-1.4.7-1.el6.rfx.x86_64.rpm perl-rrdtool-1.4.7-1.el6.rfx.x86_64.rpm


# JC - need perl-common-sense module
echo "===wget perl-common-sense.noarch===="
try yum -y localinstall --disablerepo=* perl-common-sense-3.5-1.$els.noarch.rpm

echo "Installing Zenoss prereqs"
echo "Installing Zenoss"
# Loads of prereqs - with prereqs...
PREREQFILES="perl-Async-Interrupt-1.05-1.el6.rf.x86_64.rpm perl-JSON-XS-2.27-2.el6.x86_64.rpm
		tzdata-java-2019c-1.el6.noarch.rpm perl-TermReadKey-2.30-13.el6.x86_64.rpm exim-4.92.3-1.el6.x86_64.rpm
		sysstat-9.0.4-33.el6_9.1.x86_64.rpm 
		nagios-common-4.4.3-3.el6.x86_64.rpm nagios-plugins-2.3.3-1.el6.x86_64.rpm
		nagios-plugins-perl-2.3.3-1.el6.x86_64.rpm nagios-plugins-ircd-2.3.3-1.el6.x86_64.rpm
		nagios-plugins-rpc-2.3.3-1.el6.x86_64.rpm nagios-plugins-http-2.3.3-1.el6.x86_64.rpm
		nagios-plugins-tcp-2.3.3-1.el6.x86_64.rpm nagios-plugins-dig-2.3.3-1.el6.x86_64.rpm
		nagios-plugins-ntp-2.3.3-1.el6.x86_64.rpm nagios-plugins-ldap-2.3.3-1.el6.x86_64.rpm
		nagios-plugins-dns-2.3.3-1.el6.x86_64.rpm nagios-plugins-ping-2.3.3-1.el6.x86_64.rpm
		lksctp-tools-1.0.10-7.el6.x86_64.rpm 
		jemalloc-3.6.0-1.el6.x86_64.rpm
		redis-3.2.12-2.el6.x86_64.rpm perl-EV-4.03-6.el6.x86_64.rpm perl-JSON-2.50-1.el6.rfx.noarch.rpm
		perl-Guard-1.022-1.el6.x86_64.rpm perl-AnyEvent-5.340-1.el6.rf.x86_64.rpm perl-YAML-0.72-1.el6.rfx.noarch.rpm
		memcached-1.4.14-1.el6.rfx.x86_64.rpm"
# Install / update packages that have more than one architecture
try yum -y localinstall --disablerepo=* nspr-4.21.0-1.el6_10.x86_64.rpm nspr-4.21.0-1.el6_10.i686.rpm nspr-devel-4.21.0-1.el6_10.x86_64.rpm
try yum -y localinstall --disablerepo=* nss-util-3.44.0-1.el6_10.x86_64.rpm nss-util-3.44.0-1.el6_10.i686.rpm nss-util-devel-3.44.0-1.el6_10.x86_64.rpm
try yum -y localinstall --disablerepo=* nss-softokn-3.44.0-6.el6_10.x86_64.rpm nss-softokn-3.44.0-6.el6_10.i686.rpm nss-softokn-devel-3.44.0-6.el6_10.x86_64.rpm nss-softokn-freebl-3.44.0-6.el6_10.x86_64.rpm nss-softokn-freebl-3.44.0-6.el6_10.i686.rpm nss-softokn-freebl-devel-3.44.0-6.el6_10.x86_64.rpm
try yum -y localinstall --disablerepo=* nss-3.44.0-7.el6_10.x86_64.rpm nss-3.44.0-7.el6_10.i686.rpm nss-sysinit-3.44.0-7.el6_10.x86_64.rpm nss-devel-3.44.0-7.el6_10.x86_64.rpm nss-tools-3.44.0-7.el6_10.x86_64.rpm
try yum -y localinstall --disablerepo=* crontabs-1.10-33.el6.noarch.rpm cronie-1.4.4-16.el6_8.2.x86_64.rpm cronie-anacron-1.4.4-16.el6_8.2.x86_64.rpm postfix-2.6.6-8.el6.x86_64.rpm

for file in $PREREQFILES;
do
  try yum -y localinstall --disablerepo=* $file
done

try yum -y localinstall --disablerepo=* $zenoss_rpm_file

try cp $SCRIPTPATH/secure_zenoss.sh /opt/zenoss/bin/ 
try chown zenoss:zenoss /opt/zenoss/bin/secure_zenoss.sh
try chmod 0700 /opt/zenoss/bin/secure_zenoss.sh

echo "Securing Zenoss"
try su -l -c /opt/zenoss/bin/secure_zenoss.sh zenoss

try cp $SCRIPTPATH/zenpack_actions.txt /opt/zenoss/var

echo "Configuring and Starting some Base Services and Zenoss..."
for service in memcached snmpd zenoss; do
	try /sbin/chkconfig $service on
	try /sbin/service $service start
done

echo "Securing configuration files..."
try chmod -R go-rwx /opt/zenoss/etc


echo "====================== Installing zenup and SUP 743 ======================="
# Get zenup package and install - downloads go in the temporary directory created under /tmp
# For some reason - not sure why - you really do need to copy the code to /tmp in the following installs
# Install zenup and SUP from MYTMP

zenuprpm="zenup-1.1.0.267.869d67a-1.el6.x86_64.rpm"
try yum -y localinstall --disablerepo=* $zenuprpm

#Get pristine and SUP743

pristine="zenoss_core-4.2.5-2108.el6-pristine-SP743.tgz"
zenoss_zup_file="zenoss_core-4.2.5-SP743-zenup11.zup"

# Copy the pristine and zup files to /tmp and change ownership to zenoss
cp $pristine /tmp
try chown zenoss:zenoss /tmp/$pristine
cp $zenoss_zup_file /tmp
try chown zenoss:zenoss /tmp/$zenoss_zup_file

#  Copy pristine to $ZENHOME/../zenup  and run zenup init
su -l -c "cp /tmp/$pristine \$ZENHOME/../zenup && zenup init \$ZENHOME/../zenup/$pristine \$ZENHOME" zenoss
echo "Pristine file $pristine installed"

#  Copy sup file to $ZENHOME/../zenup  and run zenup install
# Install SUP743 supply ENTER to respond with default to 2 questions
# Note that there will be an ERROR line with:
# ERROR: Wrong privileges in database for zenoss user
#   Attempt to grant privileges...
#   Privileges added successfully
# This is benign
# Also:
# ERROR: Issues were found - executing the following commands
#   mkdir -p /home/zenoss/zenoss-core-4.2.5-saved/
#   mv /opt/zenoss/Products/ZenUtils/redis.py /home/zenoss/zenoss-core-4.2.5-saved/
# also benign and can be ignored

su -l -c "cp /tmp/$zenoss_zup_file \$ZENHOME/../zenup && (echo ''; echo '') | zenup install \$ZENHOME/../zenup/$zenoss_zup_file" zenoss
echo "SUP file $zenoss_zup_file  installed"

# There is an issue with code from SUP732 (see ticket ZEN-30167, which affects the propagation of
#    a change in production status.  Thanks to Jay for the patch.  It only affects /opt/zenoss/Products/ZenModel/Device.py (see line 1345).
#    This file changed between SUP732 and SUP743 but not to fix this production status issue.

echo "Fixing Device.py for production state change - see ticket ZEN-30167."
cp "ZEN-30167_for_SUP743_from_opt_zenoss.patch" /tmp
su -l -c "cp /tmp/ZEN-30167_for_SUP743_from_opt_zenoss.patch \$ZENHOME &&  cd \$ZENHOME && patch -p0 < ZEN-30167_for_SUP743_from_opt_zenoss.patch" zenoss


# There is an issue with code from SUP743 that affects some paging notifications.
#    Thanks to Jay for the patch.  It only affects /opt/zenoss/products/ZenModel/actions.py.
#  See https://github.com/jstanley23/zenoss_patches/blob/master/actions_skipfails.patch 

echo "Fixing actions.py for paging notification issue with SUP743"
cp "actions_skipfails_for_SUP743_from_opt_zenoss.patch" /tmp
su -l -c "cp /tmp/actions_skipfails_for_SUP743_from_opt_zenoss.patch \$ZENHOME &&  cd \$ZENHOME && patch -p0 < actions_skipfails_for_SUP743_from_opt_zenoss.patch" zenoss


# Check zenup status - verbose flag gives ALL patches - LOTS of output
#su -l -c "zenup status --verbose" zenoss
su -l -c "zenup status " zenoss

#Start zenoss daemons
su -l -c "zenoss start" zenoss

cat << EOF
Zenoss Core $build install completed successfully!

Please visit http://127.0.0.1:8080 in your favorite Web browser to complete
setup.

NOTE: You may need to disable or modify this server's firewall to access port
8080. To disable this system's firewall, type:

# service iptables save
# service iptables stop
# chkconfig iptables off

Alternatively, you can modify your firewall to enable incoming connections to
port 8080. Here is a full list of all the ports Zenoss accepts incoming
connections from, and their purpose:

	8080 (TCP)                 Web user interface
	11211 (TCP and UDP)        memcached
	514 (UDP)                  syslog
	162 (UDP)                  SNMP traps


If you encounter problems with this script, please report them on the
following wiki page:

http://wiki.zenoss.org/index.php?title=Talk:Install_Zenoss

Thank you for using Zenoss. Happy monitoring!
EOF

) | tee /tmp/zenoss425_install.out 2>&1

