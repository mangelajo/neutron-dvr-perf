#!/bin/sh

echo local.compute.sh executed!
sudo ovs-vsctl remove Open_vSwitch . external-ids ovn-bridge-mappings

