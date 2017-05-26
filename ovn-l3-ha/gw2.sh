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

sleep 10


gw1_chassis=$(ovn-sbctl $OVN_SBDB --bare --columns=name find Chassis hostname=gw1)
gw2_chassis=$(ovn-sbctl $OVN_SBDB --bare --columns=name find Chassis hostname=gw2)

if [[ "z$gw1_chassis" != "z" ]] && [[ "z$gw2_chassis" != "z" ]]
then

    ovn-nbctl $OVN_NBDB set Logical_Router_Port external1-port \
              options:redirect-chassis=${gw1_chassis}:20,${gw2_chassis}:10

    echo set redirect-chassis to ${gw1_chassis}:20,${gw2_chassis}:10
fi
