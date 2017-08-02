#!/bin/bash

set -x

echo primary: $primary

fip_interface=$(ip a | grep 172\.24\.4 | awk '/brd/{ print $NF }')
fip_ip_mask=$(ip a | grep 172\.24\.4 | awk '/brd/{ print $2 }')

sudo ovs-vsctl add-br br-$fip_interface
sudo ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=public:br-$fip_interface

ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=public

sudo ip addr del $fip_ip_mask dev $fip_interface
sudo ovs-vsctl add-port br-$fip_interface $fip_interface

sudo ip addr add $fip_ip_mask dev br-$fip_interface
sudo ip link set dev br-$fip_interface up


