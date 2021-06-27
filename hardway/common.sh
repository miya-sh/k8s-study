#!/bin/bash

sed -i.org -e 's|archive.ubuntu.com|ubuntutym.u-toyama.ac.jp|g' /etc/apt/sources.list
apt update
apt upgrade -y

cat >> /etc/hosts <<EOF
${HOSTS}
EOF
