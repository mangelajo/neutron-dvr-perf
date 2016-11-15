#!/bin/sh

echo local.sh executed
echo primary: $primary
echo subnode1: $subnode1


echo as root:

sudo bash << EOF


echo primary: $primary
echo subnode1: $subnode1

EOF
