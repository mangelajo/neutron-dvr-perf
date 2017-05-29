#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

sudo ovs-vsctl set open . external-ids:ovn-bridge=br-int
sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${ctl}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip

sudo ovs-vsctl list open

ovs-vsctl --may-exist add-br br-ext
ovs-vsctl br-set-external-id br-ext bridge-id br-ext
ovs-vsctl br-set-external-id br-int bridge-id br-int
move_eth2_to_br_ext

sleep 10 # wait on ctl

ovn-nbctl $OVN_NBDB ls-add internal1-switch
ovn-nbctl $OVN_NBDB ls-add internal2-switch
ovn-nbctl $OVN_NBDB ls-add external1-switch

# map br-ext as "ext" localnet, and add a localnet port to external1-switch
# connected to such network, in flat, no vlan tagging

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext:br-ext
ovn-nbctl $OVN_NBDB lsp-add external1-switch external1-localnet
ovn-nbctl $OVN_NBDB lsp-set-addresses external1-localnet unknown
ovn-nbctl $OVN_NBDB lsp-set-type external1-localnet localnet
ovn-nbctl $OVN_NBDB lsp-set-options external1-localnet network_name=ext



# create a distributed router with a redirect-chassis on gw1 to reach
# external1-switch

ovn-nbctl $OVN_NBDB lr-add R1


ovn-nbctl $OVN_NBDB lrp-add R1 internal1-port 00:00:01:01:02:03 192.168.1.1/24
ovn-nbctl $OVN_NBDB lrp-add R1 internal2-port 00:00:01:01:02:04 192.168.2.1/24
ovn-nbctl $OVN_NBDB lrp-add R1 external1-port  00:00:01:01:02:05 10.0.0.1/24

ovn-nbctl $OVN_NBDB lsp-add internal1-switch r1-internal1-port \
          -- lsp-set-options r1-internal1-port router-port=internal1-port \
          -- lsp-set-type r1-internal1-port router \
          -- lsp-set-addresses r1-internal1-port router

ovn-nbctl $OVN_NBDB lsp-add internal2-switch r1-internal2-port \
          -- lsp-set-options r1-internal2-port router-port=internal2-port \
          -- lsp-set-type r1-internal2-port router \
          -- lsp-set-addresses r1-internal2-port router


ovn-nbctl $OVN_NBDB lsp-add external1-switch r1-external1-port \
          -- lsp-set-options r1-external1-port router-port=external1-port \
          -- lsp-set-type r1-external1-port router \
          -- lsp-set-addresses r1-external1-port router

sleep 30 # sleep a bit with the hope of finding gw2, we will retry on gw2.sh
gw1_chassis=$(ovn-sbctl $OVN_SBDB --bare --columns=name find Chassis hostname=gw1)
gw2_chassis=$(ovn-sbctl $OVN_SBDB --bare --columns=name find Chassis hostname=gw2)
ovn-nbctl $OVN_NBDB set Logical_Router_Port external1-port \
          options:redirect-chassis=${gw1_chassis}:20,${gw2_chassis}:10


# add some basic NAT rules

ovn-nbctl $OVN_NBDB lr-nat-add R1 snat 10.0.0.1 192.168.0.0/16
ovn-nbctl $OVN_NBDB lr-nat-add R1 dnat_and_snat 10.0.0.16 192.168.1.3
ovn-nbctl $OVN_NBDB lr-nat-add R1 dnat_and_snat 10.0.0.17 192.168.1.4

