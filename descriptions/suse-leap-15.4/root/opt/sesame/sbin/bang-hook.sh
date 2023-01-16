#!/bin/bash -x

# specific IP for server
addr=$(sed -n '/pxeaddr=/p' /proc/cmdline |sed -re 's/^.*pxeaddr=(\S+).*$/\1/')
server=bang              # hostname for link local IP via DNS
posttgz=post.tgz         # target to fetch via HTTP
postexe=post.sh          # file expected in the tgz to run
ldir=/opt/sesame         # where to play with the tgz

if ! [ -z "$addr" ]
then
    cnt=6
    goodtogo=0
    while [ $cnt -gt 0 ]
    do
        ping -c1 -i1 -W1 -q $addr 2>&1 >/dev/null
        if [ $? -eq 0 ]
        then
            goodtogo=1
            break
        fi
        sleep 10
        cnt=$((cnt-1))
    done
    if [ $goodtogo -eq 0 ]
    then
        echo "Unable to ping PXE server ... rebooting"
        reboot -f
    fi
fi

function recon_discover()
{
    # if no addr on cmdline then start server now
    if [ -z "$addr" ]; then
        # start the server
        echo "starting server because: "
        echo "  /etc/cmdline has no pxeaddr="
        return 0
    else
        echo "$addr bang bang.sesame.dev" >> /etc/hosts
        echo "nameserver $addr" >> /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi

    # Test networking through DNS
    digit=$(dig +short -x $addr)
    digserver=${digit%%.*}
    digdomroot=${digit%%.}
    digdomroot=${digdomroot##*.}
    
    if [ a"$server" != a"$digserver" ] || ( [ adev != a"$digdomroot" ] && [ alab != a"$digdomroot" ]); then
        # start the server
        echo "starting server because: "
        echo "  $server + $domroot != $digserver + $digdomroot"
        echo "192.168.219.1 recon recon.sesame.dev" >> /etc/hosts
        return 0
    fi
    # get the inventory to the server
    echo "starting inventory because:"
    echo "  $server + $domroot == $digserver + $digdomroot"

    return 1
}

function recon_server()
{
    cp -r /root/recon/dhcpd* /root/recon/hostname /etc/.
    cp /root/recon/ifcfg-lan0 /etc/sysconfig/network/.
    ifdown lan0
    ifup lan0
    sed -i -re 's/^(NETCONFIG_DNS_STATIC_SERVERS)=".*$/\1="192.168.219.1"/' /etc/sysconfig/network/config
    netconfig update -f
    hostname $(cat /etc/hostname)
    systemctl stop salt-minion
    systemctl start salt-master dhcpd dhcpd6 dnsmasq apache2
}

function client_inventory()
{
    # Test for target tgz availability on HTTP server
    is200=$(curl -o /dev/null --silent -Iw '%{http_code}' \
                 http://${server}/${posttgz})
    
    if [ $is200 -ne 200 ]; then
        echo "No posttgz file exists to fetch."
        exit 1
    fi
    
    [ -d $ldir ] || mkdir -p $ldir
    pushd $ldir
    curl -kOLJ http://${server}/${posttgz}
    tar xf ${posttgz}
    if [ ! -f ${postexe} ]; then
        echo "No ${postexe} in the ${posttgz} to run."
        exit 1
    fi    
    chmod +x ${postexe}
    ./${postexe}
    popd
}

if recon_discover ; then
    echo "No recon server running so starting it!"
    recon_server
else
    echo "Recon server discovered. Doing inventory."
    client_inventory
fi
