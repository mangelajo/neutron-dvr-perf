#!/bin/sh

echo "[controllers]" > inventory
../lib/Vagrant2Inventory.py -s subnode >> inventory
echo "" >> inventory
echo "[computes]" >> inventory
../lib/Vagrant2Inventory.py -s primary >> inventory
cat >> inventory << EOF

[localhost]
127.0.0.1

[localhost:vars]
ansible_python_interpreter=/usr/bin/python

[all:vars]
git_refspec=refs/changes/64/509764/6

EOF

echo "======== ansible inventory generated ========="
cat inventory
