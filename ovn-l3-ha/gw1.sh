#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

sudo ovs-vsctl set open . external-ids:ovn-bridge=br-int
sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${gw1}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip

sudo ovs-vsctl list open

ovs-vsctl add-br br-ext
ovs-vsctl br-set-external-id br-ext bridge-id br-ext
ovs-vsctl br-set-external-id br-int bridge-id br-int

ip link set dev br-ext up
ip addr add 10.0.0.111/24 dev br-ext


ovn-nbctl ls-add internal1-switch
ovn-nbctl ls-add internal2-switch
ovn-nbctl ls-add external1-switch

# map br-ext as "ext" localnet, and add a localnet port to external1-switch
# connected to such network, in flat, no vlan tagging

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext:br-ext
ovn-nbctl lsp-add external1-switch external1-localnet
ovn-nbctl lsp-set-addresses external1-localnet unknown
ovn-nbctl lsp-set-type external1-localnet localnet
ovn-nbctl lsp-set-options external1-localnet network_name=ext


# create a distributed router with a redirect-chassis on gw1 to reach
# external1-switch

ovn-nbctl lr-add R1

gw1_chassis=$(ovn-sbctl --bare --columns=name find Chassis hostname=gw1)

ovn-nbctl lrp-add R1 internal1-port 00:00:01:01:02:03 192.168.1.1/24
ovn-nbctl lrp-add R1 internal2-port 00:00:01:01:02:04 192.168.2.1/24
ovn-nbctl lrp-add R1 external1-port  00:00:01:01:02:05 10.0.0.1/24 -- \
          set Logical_Router_Port external1-port \
          options:redirect-chassis=${gw1_chassis}


ovn-nbctl lsp-add internal1-switch r1-internal1-port \
          -- lsp-set-options r1-internal1-port router-port=internal1-port \
          -- lsp-set-type r1-internal1-port router \
          -- lsp-set-addresses r1-internal1-port router

ovn-nbctl lsp-add internal2-switch r1-internal2-port \
          -- lsp-set-options r1-internal2-port router-port=internal2-port \
          -- lsp-set-type r1-internal2-port router \
          -- lsp-set-addresses r1-internal2-port router


ovn-nbctl lsp-add external1-switch r1-external1-port \
          -- lsp-set-options r1-external1-port router-port=external1-port \
          -- lsp-set-type r1-external1-port router \
          -- lsp-set-addresses r1-external1-port router



# add some basic NAT rules

ovn-nbctl lr-nat-add R1 snat 10.0.0.1 192.168.0.0/16
ovn-nbctl lr-nat-add R1 dnat_and_snat 10.0.0.16 192.168.1.3

