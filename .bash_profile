# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

export ZENHOME=/usr/local/zenoss
export PYTHONPATH=/usr/local/zenoss/lib/python
export PATH=/usr/local/zenoss/bin:$PATH
export INSTANCE_HOME=$ZENHOME
export PATH=/opt/zenup/bin:$PATH
# Following value required for Windows ZenPack
export KRB5_CONFIG="/usr/local/zenoss/var/krb5/krb5.conf"
export DEFAULT_ZEP_JVM_ARGS="-Djetty.host=localhost -server"

PATH=$PATH:$HOME/bin

export PATH

