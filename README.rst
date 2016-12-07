============================================================
Zenoss Core 4.2.5 updated auto deploy script - December 2016
============================================================

The Zenoss wiki has a link to deploy Zenoss Core 4.2.5 with an auto deploy script - 
http://wiki.zenoss.org/Install_Zenoss#Auto-deploy_Installation 

Unfortunately some of the pre-req / co-req chain appears to have broken as at
December 2016.  There is a forum append documenting some of the issues at
http://www.zenoss.org/forum/146626 

This repository contains a new version, core-autodeploy.sh_update_20161207,
which should replace the core-autodeploy.sh file that is downloaded with the package documented
on the wiki.  Other than that, the wiki article remains the same.

The pre-requisites for Zenoss Core 4.2.5 are automatically installed by the script but some of
the versions of packages need to be rather older than the latest.  Packages that are obtained by
wget are put under the /tmp directory in a random-name subdirectory.  Those packages are included
in this repository in the pre_req_downloads subdirectory.  You should not need them but it may
help someone digging around in the future if stuff changes / moves again.

I have tested this script against a CentOS 6.3 system.

I would appreciate feedback from anyone else who uses it.

Cheers,
Jane    

jane.curry@skills-1st.co.uk

