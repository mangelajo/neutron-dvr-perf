#!/bin/bash

set -x

echo primary: $primary
echo subnode1: $subnode1

# http://blog.spinhirne.com/2016/09/an-introduction-to-ovn-routing.html

ovn-nbctl ls-add inside
ovn-nbctl ls-add dmz

# add the router
ovn-nbctl lr-add tenant1

# create router port for the connection to dmz
ovn-nbctl lrp-add tenant1 tenant1-dmz 02:ac:10:ff:01:29 172.16.255.129/26

# create the dmz switch port for connection to tenant1
ovn-nbctl lsp-add dmz dmz-tenant1
ovn-nbctl lsp-set-type dmz-tenant1 router
ovn-nbctl lsp-set-addresses dmz-tenant1 02:ac:10:ff:01:29
ovn-nbctl lsp-set-options dmz-tenant1 router-port=tenant1-dmz

# create router port for the connection to inside
ovn-nbctl lrp-add tenant1 tenant1-inside 02:ac:10:ff:01:93 172.16.255.193/26

# create the inside switch port for connection to tenant1
ovn-nbctl lsp-add inside inside-tenant1
ovn-nbctl lsp-set-type inside-tenant1 router
ovn-nbctl lsp-set-addresses inside-tenant1 02:ac:10:ff:01:93
ovn-nbctl lsp-set-options inside-tenant1 router-port=tenant1-inside

ovn-nbctl show

# DHCP 

ovn-nbctl lsp-add dmz dmz-vm1
ovn-nbctl lsp-set-addresses dmz-vm1 "02:ac:10:ff:01:30 172.16.255.130"
ovn-nbctl lsp-set-port-security dmz-vm1 "02:ac:10:ff:01:30 172.16.255.130"

ovn-nbctl lsp-add dmz dmz-vm2
ovn-nbctl lsp-set-addresses dmz-vm2 "02:ac:10:ff:01:31 172.16.255.131"
ovn-nbctl lsp-set-port-security dmz-vm2 "02:ac:10:ff:01:31 172.16.255.131"

ovn-nbctl lsp-add inside inside-vm3
ovn-nbctl lsp-set-addresses inside-vm3 "02:ac:10:ff:01:94 172.16.255.194"
ovn-nbctl lsp-set-port-security inside-vm3 "02:ac:10:ff:01:94 172.16.255.194"

ovn-nbctl lsp-add inside inside-vm4
ovn-nbctl lsp-set-addresses inside-vm4 "02:ac:10:ff:01:95 172.16.255.195"
ovn-nbctl lsp-set-port-security inside-vm4 "02:ac:10:ff:01:95 172.16.255.195"


export dmzDhcp="$(ovn-nbctl create DHCP_Options cidr=172.16.255.128/26 \
           options="\"server_id\"=\"172.16.255.129\" \"server_mac\"=\"02:ac:10:ff:01:29\" \
                   \"lease_time\"=\"3600\" \"router\"=\"172.16.255.129\"")"
echo $dmzDhcp

export insideDhcp="$(ovn-nbctl create DHCP_Options cidr=172.16.255.192/26 \
          options="\"server_id\"=\"172.16.255.193\" \"server_mac\"=\"02:ac:10:ff:01:93\" \
                  \"lease_time\"=\"3600\" \"router\"=\"172.16.255.193\"")"
echo $insideDhcp

ovn-nbctl dhcp-options-list

ovn-nbctl lsp-set-dhcpv4-options dmz-vm1 $dmzDhcp
ovn-nbctl lsp-get-dhcpv4-options dmz-vm1

ovn-nbctl lsp-set-dhcpv4-options dmz-vm2 $dmzDhcp
ovn-nbctl lsp-get-dhcpv4-options dmz-vm2

ovn-nbctl lsp-set-dhcpv4-options inside-vm3 $insideDhcp
ovn-nbctl lsp-get-dhcpv4-options inside-vm3

ovn-nbctl lsp-set-dhcpv4-options inside-vm4 $insideDhcp
ovn-nbctl lsp-get-dhcpv4-options inside-vm4


sudo bash << EOF

    ip netns add vm1
    ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
    ip link set vm1 address 02:ac:10:ff:01:30
    ip link set vm1 netns vm1
    ovs-vsctl set Interface vm1 external_ids:iface-id=dmz-vm1
    ip netns exec vm1 dhclient -I vm1 --no-pid vm1
    ip netns exec vm1 ip addr show vm1
    ip netns exec vm1 ip route show

    ip netns add vm3
    ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
    ip link set vm3 address 02:ac:10:ff:01:94
    ip link set vm3 netns vm3
    ovs-vsctl set Interface vm3 external_ids:iface-id=inside-vm3
    ip netns exec vm3 dhclient -I vm3 --no-pid vm3
    ip netns exec vm3 ip addr show vm3
    ip netns exec vm3 ip route show

EOF

# and now the L3 floating fun begins!

# http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html

primary_chassis=$(ovn-sbctl show | grep primary -B 1 | head -n 1 | cut -d\" -f 2)
subnode1_chassis=$(ovn-sbctl show | grep subnode1 -B 1 | head -n 1 | cut -d\" -f 2)

# create router edge1
ovn-nbctl create Logical_Router name=edge1 options:chassis=$primary_chassis

# create a new logical switch for connecting the edge1 and tenant1 routers
ovn-nbctl ls-add transit

# edge1 to the transit switch
ovn-nbctl lrp-add edge1 edge1-transit 02:ac:10:ff:00:01 172.16.255.1/30
ovn-nbctl lsp-add transit transit-edge1
ovn-nbctl lsp-set-type transit-edge1 router
ovn-nbctl lsp-set-addresses transit-edge1 02:ac:10:ff:00:01
ovn-nbctl lsp-set-options transit-edge1 router-port=edge1-transit

# tenant1 to the transit switch
ovn-nbctl lrp-add tenant1 tenant1-transit 02:ac:10:ff:00:02 172.16.255.2/30
ovn-nbctl lsp-add transit transit-tenant1
ovn-nbctl lsp-set-type transit-tenant1 router
ovn-nbctl lsp-set-addresses transit-tenant1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options transit-tenant1 router-port=tenant1-transit

# add static routes
ovn-nbctl lr-route-add edge1 "172.16.255.128/25" 172.16.255.2
ovn-nbctl lr-route-add tenant1 "0.0.0.0/0" 172.16.255.1

ovn-sbctl show


# create new port on router 'edge1'
ovn-nbctl lrp-add edge1 edge1-outside 02:0a:7f:00:01:29 10.127.0.129/25

# create new logical switch and connect it to edge1
ovn-nbctl ls-add outside
ovn-nbctl lsp-add outside outside-edge1
ovn-nbctl lsp-set-type outside-edge1 router
ovn-nbctl lsp-set-addresses outside-edge1 02:0a:7f:00:01:29
ovn-nbctl lsp-set-options outside-edge1 router-port=edge1-outside

# create a bridge for eth1
sudo ovs-vsctl add-br br-eth2

# create bridge mapping for eth1. map network name "dataNet" to br-eth2
sudo ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=dataNet:br-eth2

# create localnet port on 'outside'. set the network name to "dataNet"
ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=dataNet

# connect eth2 to br-eth2
#ovs-vsctl add-port br-eth2 eth2-internal -- set interface eth2-internal type=internal
sudo ip addr del $floating_primary/24 dev eth2
sudo ovs-vsctl add-port br-eth2 eth2

sudo ip addr add $floating_primary/25 dev br-eth2
sudo ip link set dev br-eth2 up

ovn-nbctl -- --id=@nat create nat type="snat" logical_ip=172.16.255.128/25 \
        external_ip=10.127.0.129 -- add logical_router edge1 nat @nat

# point floating IP to VM1
ovn-nbctl -- --id=@nat create nat type="dnat_and_snat" logical_ip=172.16.255.130 \
        external_ip=$floating_testip -- add logical_router edge1 nat @nat

sudo ping $floating_testip -i 0.01 -c 1000
