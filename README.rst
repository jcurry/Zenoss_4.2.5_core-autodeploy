============================================================
Zenoss Core 4.2.5 updated auto deploy script - December 2018
============================================================

The Zenoss wiki has a link to deploy Zenoss Core 4.2.5 with an auto deploy script - 
http://wiki.zenoss.org/Install_Zenoss#Auto-deploy_Installation 

Unfortunately some of the pre-req / co-req chain appears to have broken as at
December 2016.  There is a forum append documenting some of the issues at
http://www.zenoss.org/forum/146626  (sorry this appears to have completely vanished by Dec 2018).

This git repository contains a new version, core-autodeploy.sh_update_20181208_zenup ,
which should replace the core-autodeploy.sh file that is downloaded with the package documented
on the wiki.  Other than that, the wiki article remains the same. Thus, as the root user, change
to a suitable directory (may well be root's home directory), and:

  * wget https://github.com/zenoss/core-autodeploy/tarball/4.2.5 -O auto.tar.gz
  * tar -xzvf auto.tar.gz                           (this unpacks the download)
  * cd zenoss-core-autodeploy-aeb5289               (change to the unpacked directory)
  * cp <path to new script>/core-autodeploy.sh_update_20190110_zenup .
  * cp <path to new script>/pre_req_downloads/``*``.patch .
  * ./core-autodeploy.sh_update_20190110_zenup

Code is pulled from the Zenoss project at SourceForge; note that the location of Zenoss code
changed in December 2018 so earlier versions of the autodeploy script will fail.

The pre-requisites for Zenoss Core 4.2.5 are automatically installed by the script but some of
the versions of packages need to be rather older than the latest.  Packages that are obtained by
wget are put under the /tmp directory in a random-name subdirectory.  Those packages are included
in this repository in the pre_req_downloads subdirectory.  You should not need them but it may
help someone digging around in the future if stuff changes / moves again.

The script now also installs zenup, the latest pristine file and the latest SUP update file
(as of Dec 18th, 2018) - SUP743.

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
the four MySQL packages installed.  To be sure, you might want to remove all of the following:

  * yum remove MySQL*
  * yum remove mysql*
  * yum remove zenoss*
  * yum remove nagios*
  * yum remove epel*
  * yum clean all

There is a small yum_removes.sh script to help do this.

The new install script will install and enable the epel-release repository.

Output is tee'ed to /tmp/zenoss425_install.out .

I have tested this script against a CentOS 6.3 system.

I would appreciate feedback from anyone else who uses it.

Ubuntu
------
(Not updated in 2018)

The equivalent script for Ubuntu was built by Zenoss Master "hydruid" and although he has
now largely moved away from Zenoss, his auto-install script is still available in GitHub at
https://github.com/hydruid/zenoss/blob/master/core-autodeploy/4.2.5/zo425_ubuntu-debian.sh .
There is also a copy of a useful blog item on the wayback machine at
https://web.archive.org/web/20140701000137/http://hydruid-blog.com/?p=710

Note that the location of the zenoss rpm in hydruid's autodeploy script needs to be changed from
http://softlayer-dal.dl.sourceforge.net/project/zenossforubuntu/zenoss-core-425-2108_03c_amd64.deb to
https://sourceforge.net/projects/zenossforubuntu/files/zenoss-core-425-2108_03c_amd64.deb/download .

The ubuntu branch of this git repository contains a slightly modified version of his script.
Note that there is no requirement to run any of the commands at 
http://wiki.zenoss.org/Install_Zenoss#Auto-deploy_Installation   - this script downloads everything
required.

The original hydruid script had an incorporated zenup at version 1.0.  This script replaces the
zenup package with the latest zenup 1.1.0, installs the latest pristine and then applies the latest
(as of December 2016) SUP 671. The zenup package was converted from an rpm format to a deb format with
the "alien" utility and the --scripts parameter and  is available from the ubuntu branch of this repository.

SUP671 does not install cleanly under Ubuntu as it uses the dash shell rather than bash.  One of
the check scripts bundled into sup671, check_mibs, uses the "local" construct which dash interprets
differently and check_mibs does not have a #!/bin/bash shebang at the top.  I have exploded the
standard zup (it's just a tgz file), added the shebang to check_mibs, and repackaged it as
zenoss_core-4.2.5-SP671-zenup11_Ubuntu.zup which is available from the ubuntu branch of this
repository.

Run zo425_ubuntu-debian_with_zenup.sh as the root user (sudo bash).  Output goes to
/tmp/zenoss425_ubuntu_install.out .  Tested on Ubuntu 14.04.


With thanks to "baileytj", "dfrye" and "yuppie" for tidying and testing.

Cheers,

Jane    

jane.curry@skills-1st.co.uk

