==============================================================
Zenoss Core 4.2.5 updated auto deploy script - March 31st 2022
==============================================================

On March 18th 2022 Zenoss suddenly announced that Zenoss Core is to be discountinued and
that the TechZen Community site will be shut down at the end of this month. It is unclear
quite what is meant by "discontinued" but I have done a quick review of this autodeploy
repository to check that it still works and that it is completely independent of any Zenoss site.
This is a quick check and update; no extra cleaning up has been done.

This git repository contains a new standalone version of the script, core-autodeploy_20220331.sh.
It uses a directory called *pre_req_downloads* to hold all the prereqs to build
Zenoss 4.2.5 with the latest zenup patch SUP SP743, plus a couple of later spot patches.

Unfortunately, the Zenoss Core rpm, zenoss_core-4.2.5-2108.el6.x86_64.rpm, is too big for
github at about 120MB.  This must be retrieved separately. We have provided a new
download site for it at https://www.skills-1st.co.uk/pub/zenoss/zenoss_core-4.2.5-2108.el6.x86_64.rpm 

Retrieving the build package
============================

Zenoss 4.2.5 can be retrieved in several ways:

*  If you are comfortable with git then clone this git directory
*  If you are not a happy git user: 
  *  Click the "Code" button from this page 
  *  Click the "Download ZIP" button. 
  *  The file Zenoss_4.2.5_core-autodeploy-master.zip should be downloaded.  Use:
  *       unzip Zenoss_4.2.5_core-autodeploy-master.zip
  *  This will unzip the file into the Zenoss_4.2.5_core-autodeploy-master subdirectory

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
*   
*   I also have Firefox 38.5.0 installed.


You need to build as the root user.  I created a directory, zb, under root's home directory
and dropped the package into that.  You need to start by changing directory to the
pre_req_downloads directory of the package - everything is in there 
except zenoss_core-4.2.5-2108.el6.x86_64.rpm .

To get the Zenoss core file, make sure you are in the pre_req_downloads directory and run::

    wget --no-check-certificate https://www.skills-1st.co.uk/pub/zenoss/zenoss_core-4.2.5-2108.el6.x86_64.rpm

You do not need any Zenoss GPG key.

You should now have a full build set.  From the pre_req_downloads directory, simply run::

    ./core-autodeploy_20220331.sh

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

If yum remove doesn't work, try rpm -e <package>

I have found what I think are time-dependent glitches with installation repos and with
yum_removes.sh . I have included yum.repos.d_backup.tar in the top-level directory as
this set of repo configurations has definitely worked.

The install script no longer installs the epel repository.  You should not need
epel hopefully as everything should be in the pre_req_downloads directory; however, if you do
need to get packages from epel and if it gives trouble, change directory to 
*/etc/yum.repos.d* and replace epel.repo and epel-testing.repo with the versions supplied
in the pre_req_downloads directory.

Completing the Zenoss installation
==================================

When the build is complete, check /tmp/zenoss425_install.out

Switch to the zenoss user (typically, the zenoss user cannot be logged into directly.)::

    su - zenoss

Check the status of zenoss; all daemons should be running ::

    zenoss status

The autodeploy script has built the environment to the same state that a native deployment would
have done.  Start your browser and point it at your Zenoss device, eg::

    http://zenny1.class.example.org:8080

This should take you through the Zenoss setup wizard.  I just configure a password for the admin
user and create a user/password for myself at this stage.  If your VM was configured with SNMP,
allowing access to the box with a community of "public", then the base device should be automatically
discovered and put into the /Server/Linux device class.

I have a report from someone in March 2022 that they have then used zenbatchload to import devices
from a Zenoss 6.2.3 system.

Beware that a kluge of ZenPacks are installed but they are very old versions - you may well wish
to update some.



Using the VMware Zenoss 4.2.5 VM
===================================

I have created a  zipped tarbundle of the VM that is created by this process.  It is too big to post
to github but I can make it available to people on request.

Unpack the file with::

    tar -czvf zenny1_ZenossCore425.tgz

It will unpack into the zenny1_ZenossCore425 directory.

If you take the Zenoss 4.2.5 VM then a number of things are already configured:

*  The root password for the VM is object00
*  There is a user jane with password object00
*  switch to the zenoss user by going via root, ie::

    su                    and give the root password
    su - zenoss

Typically, the zenoss user cannot be logged into directly.

*  The hostname of the box is zenny1.class.example.org.
*  The IP address is 192.168.10.133, with DNS server at 192.168.10.1 and default gateway of 192.168.10.2.
*  The box has a sample snmpd.conf file in /etc/snmpd such that it responds to a community of public with SNMP V1 and V2c.
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

*  As root. change to /etc/sysconfig and edit the *network* file.  Change the HOSTNAME to the fully-qualified domain name that you require.  Also change the GATEWAY line to match your default gateway.
* Change down to the network-scripts subdirectory and modify ifcfg-eth0::

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
a script, fix_rabbit.sh, in the Zenoss_4.2.5_core-autodeploy/pre_req_downloads directory. It must be 
run as the root user. *Note* that you will need to modify this script to make the PASS variable match
what is in your /opt/zenoss/etc/global.conf for the amqppassword password.

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

March 31st 2022

