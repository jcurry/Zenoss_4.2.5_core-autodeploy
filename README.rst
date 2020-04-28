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

Retrieving the build package
============================

Zenoss 4.2.5 can be retrieved in several ways:

*  If you comfortable with git then clone this git directory
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
   Additional Development
   Base
   Compatibility libraries
   Debugging Tools
   Desktop
   Desktop Debugging and Performance Tools
   Development tools
   Dial-up Networking Support
   Directory Client
   E-mail server
   FTP server
   Fonts
   General Purpose Desktop
   Graphical Administration Tools
   Graphics Creation Tools
   Hardware monitoring utilities
   Input Methods
   Internet Applications
   Internet Browser
   Legacy UNIX compatibility
   Legacy X Window System compatibility
   Network Infrastructure Server
   Network file system client
   Networking Tools
   Performance Tools
   Perl Support
   PostgreSQL Database client
   Print Server
   Printing client
   Ruby Support
   SNMP Support
   Scientific support
   Security Tools
   System administration tools
   Web Server
   X Window System


You need to build as the root user.  I created a directory, zb, under root's home directory
and dropped the package into that.  You need to start by changing directory to the
pre_req_downloads directory of the package - everything is in there. Simply run::

    core-autodeploy_20200428.sh


The only user interaction is right at the start where you have to accept the Oracle Java
license (with an ENTER and a "yes").  After that, it should run through standalone.

Output is tee'ed into /tmp/zenoss425_install.out so you can inspect progress by checking
that file (a copy of my output file is in the top directory of this package).

The script now also installs zenup, the latest pristine file and the latest SUP update file
 - SUP743.

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

There is a small yum_removes.sh script to do this.

The new install script will install and enable the epel-release repository.


I would appreciate feedback from anyone else who uses it.


With thanks to "baileytj", "dfrye" and "yuppie" for tidying and testing.

Cheers,

Jane    

jane.curry@skills-1st.co.uk

