#!/bin/bash
set -x

cd
sudo apt-get update
sudo apt-get install -y git make mercurial

git clone https://opendev.org/openstack/devstack
cd devstack
cat >local.conf <<EOF
[[local|localrc]]
#OPENSTACK_VERSION="mitaka"
enable_service neutron-ext magnum
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
SWIFT_HASH=\$ADMIN_PASSWORD
EOF

./stack.sh

# Prep the testing environment by creating the required testing resources and environment variables
source openrc admin
openstack flavor create --id 99 --ram 512 --disk 5 --vcpu 1 --ephemeral 10 m1.acctest
openstack flavor create --id 98 --ram 512 --disk 6 --vcpu 1 --ephemeral 10 m1.resize
_NETWORK_ID=$(openstack network show private -c id -f value)
_EXTGW_ID=$(openstack network show public -c id -f value)
_IMAGE_ID=$(openstack image show cirros-0.4.0-x86_64-disk -c id -f value)
echo export OS_IMAGE_NAME="cirros-0.4.0-x86_64-disk" >> openrc
echo export OS_IMAGE_ID="$_IMAGE_ID" >> openrc
echo export OS_NETWORK_ID=$_NETWORK_ID >> openrc
echo export OS_EXTGW_ID=$_EXTGW_ID >> openrc
echo export OS_POOL_NAME="public" >> openrc
echo export OS_FLAVOR_ID=99 >> openrc
echo export OS_FLAVOR_ID_RESIZE=98 >> openrc
echo export OS_DOMAIN_ID=default >> /openrc
source openrc demo
