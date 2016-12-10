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

echo "====================== Installing zenup and SUP 671 ======================="

# Installer variables
ZENOSSHOME="/home/zenoss"
DOWNDIR="/tmp"
UPGRADE="no" # Valid options are "yes" and "no"
ZVER="425"
ZVERb="4.2.5"
ZVERc="2108"
DVER="03c"
PACKAGECLEANUP="yes" # Valid options are "yes" and "no"


# Get .bash_profile for zenoss user
wget -O $DOWNDIR/.bash_profile  https://github.com/jcurry/Zenoss_4.2.5_core-autodeploy/tree/ubuntu/.bash_profile
cp $DOWNDIR/.bash_profile /home/zenoss
chown zenoss:zenoss .bash_profile

# zenup installed as part of Zenoss install - but old version. Get zenup for deb from github
# deb version of zenup created using the alien utility in Ubuntu to convert rpm to deb
#   alien requires --scripts parameter to convert scripts

wget -O  $DOWNDIR/zenup_1.1.0.267.869d67a-2_amd64.deb --no-check-certificate  https://github.com/jcurry/Zenoss_4.2.5_core-autodeploy/tree/ubuntu/zenup_1.1.0.267.869d67a-2_amd64.deb

#Get pristine 
echo " Getting pristine SP203"
wget -O $DOWNDIR/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz --no-check-certificate  http://sourceforge.net/projects/zenoss/files/zenoss-4.2/zenoss-4.2.5/updates/2014-08-06/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz/download

# JC - zup file needs modification.  Check_mibs script has no bash shebang so runs under Ubuntu
#   native dash (not bash) where "local" is interpreted differently and fails.
#  I have exploded the standard zup and modified check_mibs to add a bash shebang.
#  Get zup from git hub repo not from sourceforge.

echo " Getting ZUP 671 for Ubuntu"
wget -O $DOWNDIR/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup --no-check-certificate https://github.com/jcurry/Zenoss_4.2.5_core-autodeploy/tree/ubuntu/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup 


# Need to remove old version of zenup - it is installed under /usr/local/zenoss and linked to /opt/zenup

echo "Removing old zenup and installing zenup 1.1.0"
rm -rf $ZENHOME/zenup
rm /opt/zenup
dpkg -i $DOWNDIR/zenup_1.1.0.267.869d67a-2_amd64.deb
cp $DOWNDIR/zenup_1.1.0.267.869d67a-2_amd64.deb /opt/zenup

# JC Fix problems that will be found by zenup....  To be run by zenoss user
su -l -c 'find /usr/local/zenoss -type f ! \( -name pyraw -o -name zensocket -o -name nmap -o -name nginx -o -name nginx.pid -o -name zodbpack.pyc -o -name zone.tab -o -name iso3166.tab -o -name libpython2.7.so.1.0 \) ! \( -user zenoss -group zenoss -perm -u+rw \) -exec chown zenoss:zenoss {} \; -exec chmod u+rw {} \;' zenoss


#  Copy pristine to /opt/zenup  and run zenup init
cp $DOWNDIR/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz /opt/zenup 
chown zenup:zenoss /opt/zenup/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz

# Note that su -l .... zenoss construct only seems to work if zenoss user has 
#  a .bash_profile that has the usual Zenoss environment vars in it.  
#  Sourcing .bashrc from .bash_profile doesnt seem to work

su -l -c "/opt/zenup/bin/zenup init /opt/zenup/zenoss_core-4.2.5-2108.el6-pristine-SP203.tgz \$ZENHOME" zenoss

#  Copy sup file to /opt/zenup  and run zenup install
# Install SUP671 supply ENTER to respond with default to 2 questions
cp $DOWNDIR/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup /opt/zenup  
chown zenup:zenoss /opt/zenup/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup

su -l -c "/opt/zenup/bin/zenup install /opt/zenup/zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup" zenoss
#su -l -c "cp \$DOWNDIR/zenoss_core-4.2.5-SP671-zenup11.zup /opt/zenup && (echo ''; echo '') | zenup install /opt/zenup/zenoss_core-4.2.5-SP671-zenup11.zup" zenoss

# Check zenup status
su -l -c "/opt/zenup/bin/zenup status --verbose" zenoss

#Start zenoss daemons
su -l -c "ZENHOME=/usr/local/zenoss && zenoss start" zenoss

exit 0
) | tee /tmp/zenoss425_ubuntu_install_zup.out 2>&1
