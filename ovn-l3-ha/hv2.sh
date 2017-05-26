#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

sudo ovs-vsctl set open . external-ids:ovn-bridge=br-int
sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${ctl}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip

# naive way to wait for the GW1 node
sleep 60 

add_phys_port internal1-switch vm3 00:00:01:01:02:08 192.168.1.4 24 192.168.1.1
add_phys_port internal2-switch vm4 00:00:01:01:02:09 192.168.2.4 24 192.168.2.1
