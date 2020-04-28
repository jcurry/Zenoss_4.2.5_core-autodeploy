============================================================
Zenoss Core 4.2.5 updated auto deploy script - April 2020
============================================================

The Zenoss wiki has a (somewhat hidden)link to deploy Zenoss Core 4.2.5 with an auto deploy script - 
http://wiki.zenoss.org/index.php?title=Install_Zenoss&oldid=17203 

Unfortunately some of the pre-req / co-req chain appears to have broken as at
December 2016.  There is a forum append documenting some of the issues at
http://www.zenoss.org/forum/146626  (sorry this appears to have completely vanished by Dec 2018).

This git repository contains a new standalone version of the script, core-autodeploy_20200428.sh.
It uses a directory called *pre_req_downloads* to hold all the prereqs to build
Zenoss 4.2.5 with the latest zenup patch SUP SP743, plus a couple of later spot patches.

Unfortunately, the Zenoss Core rpm, zenoss_core-4.2.5-2108.el6.x86_64.rpm, is too big for
github at about 120MB.  This must be retrieved separately.

Retrieving the build package
============================

Zenoss 4.2.5 can be retrieved in several ways:

*  If you are comfortable with git then clone this git directory
*  If you are not a happy git user: 
  *  Click the "Clone or download" button from this page 
  *  Click the "Download ZIP" button. 
  *  The file Zenoss_4.2.5_core-autodeploy-master.zip should be downloaded.  Use:
  *       unzip Zenoss_4.2.5_core-autodeploy-master.zip
  *  This will unzip the file into the Zenoss_4.2.5_core-autodeploy-master subdirectory
*  Install the VMware OVA virtual machine which should be ready-to-go

Building Zenoss 4.2.5
======================

You need to start with a Centos6.3 operating system. I started with the following groups installed:

Installed Groups:

*   Additional Development
*   Base
*   Compatibility libraries
*   Debugging Tools
*   Desktop
*   Desktop Debugging and Performance Tools
*   Development tools
*   Dial-up Networking Support
*   Directory Client
*   E-mail server
*   FTP server
*   Fonts
*   General Purpose Desktop
*   Graphical Administration Tools
*   Graphics Creation Tools
*   Hardware monitoring utilities
*   Input Methods
*   Internet Applications
*   Internet Browser
*   Legacy UNIX compatibility
*   Legacy X Window System compatibility
*   Network Infrastructure Server
*   Network file system client
*   Networking Tools
*   Performance Tools
*   Perl Support
*   PostgreSQL Database client
*   Print Server
*   Printing client
*   Ruby Support
*   SNMP Support
*   Scientific support
*   Security Tools
*   System administration tools
*   Web Server
*   X Window System


You need to build as the root user.  I created a directory, zb, under root's home directory
and dropped the package into that.  You need to start by changing directory to the
pre_req_downloads directory of the package - everything is in there 
except zenoss_core-4.2.5-2108.el6.x86_64.rpm .

To get the Zenoss core file, make sure you are in the pre_req_downloads directory and run::

    wget --no-check-certificate -N https://sourceforge.net/projects/zenoss/files/Community%20Edition%20v4%20%28final%29/zenoss_core-4.2.5-2108.el6.x86_64.rpm

You should also get the Zenoss GPG key::

  zenoss_gpg_key="http://wiki.zenoss.org/download/core/gpg/RPM-GPG-KEY-zenoss"
  if [ `rpm -qa gpg-pubkey* | grep -c "aa5a1ad7-4829c08a"` -eq 0  ]
  then
     echo "Importing Zenoss GPG Key"
     rpm --import $zenoss_gpg_key
  fi

You should now have a full build set.  Simply run::

    core-autodeploy_20200428.sh


The only user interaction is right at the start where you have to accept the Oracle Java
license (with an ENTER and a "yes").  After that, it should run through standalone.

Output is tee'ed into /tmp/zenoss425_install.out so you can inspect progress by checking
that file (a copy of my output file is in the top directory of this package).

The script now also installs zenup, the latest pristine file and the latest SUP update file - SUP743.

There are two known glitches with SUP743 which are patched by this auto-deploy script.  One is to
do with production status being changed WTHOUT needing to restart daemons.  It is documented in
JIRA ticket ZEN-30167; it arrived with SUP732 and was not fixed by SUP743. A patch, 
ZEN-30167_for_SUP743_from_opt_zenoss.patch, is included in the pre_req_downloads directory and is
deployed at the end of the auto-deploy script.  

The second glitch affects some paging notifications
and was introduced in SUP743. The actions_skipfails_for_SUP743_from_opt_zenoss.patch file
addresses this issue and is also invoked at the end of the deployment.  Enormous thanks to
Jay Stanley for diagnosing these issues and providing the patches.

If you need to re-run the script, note that you will need to use "yum remove" to remove
the four MySQL packages, Zenoss, nagios modules and epel.

  * yum remove MySQL*
  * yum remove mysql*
  * yum remove zenoss*
  * yum remove nagios*
  * yum remove epel*
  * yum clean all

There is a small yum_removes.sh script to do this in the top directory of this package.

The new install script will install and disable the epel-release repository.  You should not need
epel hopefully as everything should be in the pre_req_downloads directory; however, if you do
need to get packages from epel and if it gives trouble, change directory to 
*/etc/yum.repos.d* and replace epel.repo and epel-testing.repo with the versions supplied
in the pre_req_downloads directory.

Using the VMware Zenoss 4.2.5
=============================

If you take the Zenoss 4.2.5 VM then a number of things are already configured:

*  The root password for the VM is object00
*  There is a user jane with password object00
*  switch to the zenoss user by going via root, ie::

    su                    and give the root password
    su - zenoss

Typically, the zenoss user cannot be logged into directly.

*  The hostname of the box is zenny1.class.example.org.
*  The IP address is 192.168.10.133, with DNS server at 192.168.10.1 and default gateway of 192.168.10.2.
*  The box has a sample snmpd.conf file in /etc/snmpd such that it responds to a community of public with
SNMP V1 and V2c.
*  The Zenoss GUI is reached with::

    http://zenny1.class.example.org:8080

* Zenoss GUI users are configured as:

  *  admin / zenoss
  *  jane / object00

The initial GUI setup phase has been executed and zenny1.class.example.org shows under /Server/Linux .

Modifying the VM configuration
------------------------------

You will probably want to change the hostname and IP details for your VM.  This is a relatively simple
Operating System procedure and requires one action so that Zenoss copes with the name / address change.

*  As root. change to /etc/sysconfig and edit the *network* file.  Change the HOSTNAME to 
fully-qualified domain name that you require.  Also change the GATEWAY line to match your default gateway.
* Chnage down to the network-scripts subdirectory and modify ifcfg-eth0::

    IPADDR=                   new IP address
    PREFIX=                   this is the length of the subnet mask so 24 is a Class C network
    GATEWAY=                  your default gateway
    DNS1=                     your DNS server
    DOMAIN=                   your search path of domains to add to short hostnames

*  Modify the /etc/hosts file and replace::

    192.168.10.133      zenny1.class.example.org zenny1
    with  your IP address, your fully-qualified domain name and your short hostname

Reboot the system

Zenoss itself copes with host / ip changes but the underlying RabbitMQ system needs help. There is
a script, fix_rabbit.sh, in /opt/zenoss/local.  It must be run as the root user.

Then, as the zenoss user, restart zenoss::

    zenoss restart

New rabbit queues for the event subsytem should be created.  You can check these, as the root user, with::

    rabbitmqctl -p /zenoss list_queues

There should be 9 queues, probably all with nothing in them.

Check (with *zenoss status* as the zenoss user), that all the zenoss processes are running.

Check that the GUI can be started.  Remember to change your url to::

http:// <your new fully qualified domain name>:8080
 
The zenny1.class.example.org device will still be under /Server/Linux but will (obviously) be down.
It can be deleted and add your new Zenoss server in.

I would appreciate feedback from anyone else who uses it.


With thanks to "baileytj", "dfrye" and "yuppie" for tidying and testing.

Cheers,

Jane    

jane.curry@skills-1st.co.uk

