# You must run this as root
echo You must run this as root

export VHOST="/zenoss"
export USER="zenoss"
# The password is found in /opt/zenoss/etc/global.conf - the amqppassword
export PASS="jtP5PKCmPKgr9wA"
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
rabbitmqctl add_vhost "$VHOST"
rabbitmqctl add_user "$USER" "$PASS"
rabbitmqctl set_permissions -p "$VHOST" "$USER" '.*' '.*' '.*'

echo Stop Zenoss and restart it  - as the zenoss user - zenoss restart
echo The check queues - as the root user - with:
echo rabbitmqctl -p /zenoss list_queues
echo
echo You should see 9 queues
