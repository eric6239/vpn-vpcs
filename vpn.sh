#!/bin/bash
# Configure LOCAL VPC net, REMOTE VPC net and REMOTE VPN instance bound EIP
LOCAL_NET=
REMOTE_NET=
REMOTE_EIP=

LOCAL_TUN=0
LOCAL_TIP=169.254.0.1
REMOTE_TUN=0
REMOTE_TIP=169.254.0.2
PING_TIMEOUT=3
CHECK_INTERVAL=5

if [ x"$LOCAL_NET" == x"" -o x"$REMOTE_NET" == x"" -o x"$REMOTE_EIP" == x"" ]; then
    echo "If you want me to act like VPN client, you should set LOCAL_NET, REMOTE_NET and REMOTE_EIP."
    exit 0
fi

while [ . ]
    do
    # check connectivity
    /bin/ping -W $PING_TIMEOUT -c 1 $REMOTE_TIP 2>&1 > /dev/null
    if [ $? != 0 ]; then
        echo $(date)
        echo "VPN Disconnected. Start to create VPN ..."
        echo '1' > /proc/sys/net/ipv4/ip_forward
        # create ssh tunnel
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error $REMOTE_EIP "ps ax | grep 'sshd.*root@notty' | grep -v grep | awk '{print $1}' | xargs --no-run-if-empty -n 1 kill;"
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -f -w $LOCAL_TUN:$REMOTE_TUN $REMOTE_EIP "echo '1' > /proc/sys/net/ipv4/ip_forward;/sbin/ifconfig tun$REMOTE_TUN up;/sbin/ifconfig tun$REMOTE_TUN $REMOTE_TIP netmask 255.255.255.0 pointopoint $LOCAL_TIP;/sbin/route add -net $LOCAL_NET gw $REMOTE_TIP;"
        sleep 5
        /sbin/ifconfig tun0 up
        /sbin/ifconfig tun0 $LOCAL_TIP netmask 255.255.255.0 pointopoint $REMOTE_TIP
        /sbin/route add -net $REMOTE_NET gw $LOCAL_TIP
        # check connectivity
        /bin/ping -W $PING_TIMEOUT -c 1 $REMOTE_TIP 2>&1 > /dev/null
        if [ $? == 0 ]; then
            echo "VPN has connected!"
        else
            echo "VPN still can't connect!"
        fi
    fi
    sleep $CHECK_INTERVAL
done
