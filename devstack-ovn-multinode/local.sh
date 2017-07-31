#!/bin/bash

set -x

echo primary: $primary
echo subnode1: $subnode1

fip_interface=$(ip a | grep 10.127.0.130 | grep brd  | cut -d\  -f11)


primary_chassis=$(ovn-sbctl show | grep primary -B 1 | head -n 1 | cut -d\" -f 2)
subnode1_chassis=$(ovn-sbctl show | grep subnode1 -B 1 | head -n 1 | cut -d\" -f 2)

sudo ovs-vsctl add-br br-$fip_interface
sudo ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=dataNet:br-$fip_interface
ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=dataNet
sudo ip addr del $floating_primary/24 dev $fip_interface
sudo ovs-vsctl add-port br-$fip_interface $fip_interface

sudo ip addr add $floating_primary/25 dev br-$fip_interface
sudo ip link set dev br-$fip_interface up


