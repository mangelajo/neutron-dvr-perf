#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

sudo ovs-vsctl set open . external-ids:ovn-bridge=br-int
sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${ctl}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip

sudo ovs-vsctl --may-exist add-br br-ext
ovs-vsctl br-set-external-id br-ext bridge-id br-ext
ovs-vsctl br-set-external-id br-int bridge-id br-int
ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext:br-ext
move_eth2_to_br_ext

