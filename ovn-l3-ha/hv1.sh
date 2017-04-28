#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

sudo ovs-vsctl set open . external-ids:ovn-bridge=br-int
sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${gw1}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip


# naive way to wait for the GW1 node
sleep 20

add_phys_port internal1-switch vm1 00:00:01:01:02:0a 192.168.1.3 24 192.168.1.1
add_phys_port internal2-switch vm2 00:00:01:01:02:0b 192.168.2.3 24 192.168.2.1
