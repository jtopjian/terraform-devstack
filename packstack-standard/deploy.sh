#!/bin/bash
set -x

cd /root
yum install -y -q lvm2
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

yum install -y -q centos-release-openstack-mitaka
yum update -y -q
yum install -y -q openstack-packstack
packstack --answer-file /home/centos/packstack-answers.txt

# Configure LBaaSv2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins lbaasv2,router,firewall
crudini --set /etc/neutron/neutron.conf service_providers service_provider LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver neutron_lbaas.drivers.haproxy.namespace_driver.HaproxyNSDriver

neutron-db-manage --service lbaas upgrade head
systemctl disable neutron-lbaas-agent.service
systemctl stop neutron-lbaas-agent.service
systemctl restart neutron-server.service
systemctl enable neutron-lbaasv2-agent.service
systemctl start neutron-lbaasv2-agent.service

# Prep the testing environment by creating the required testing resources and environment variables
source /root/keystonerc_admin
nova flavor-create m1.acctest 99 512 5 1 --ephemeral 10
nova flavor-create m1.resize 98 512 6 1 --ephemeral 10
_NETWORK_ID=$(nova net-list | grep private | awk -F\| '{print $2}' | tr -d ' ')
_EXTGW_ID=$(nova net-list | grep public | awk -F\| '{print $2}' | tr -d ' ')
_IMAGE_ID=$(openstack image show cirros -c id -f value)
echo export OS_IMAGE_NAME="cirros" >> /root/keystonerc_admin
echo export OS_IMAGE_ID="$_IMAGE_ID" >> /root/keystonerc_admin
echo export OS_NETWORK_ID=$_NETWORK_ID >> /root/keystonerc_admin
echo export OS_EXTGW_ID=$_EXTGW_ID >> /root/keystonerc_admin
echo export OS_POOL_NAME="public" >> /root/keystonerc_admin
echo export OS_FLAVOR_ID=99 >> /root/keystonerc_admin
echo export OS_FLAVOR_ID_RESIZE=98 >> /root/keystonerc_admin

sudo yum install -y -q wget
sudo yum install -y -q git
sudo yum install -y -q vim
sudo wget -O /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
sudo chmod +x /usr/local/bin/gimme
/usr/local/bin/gimme 1.7 >> .bashrc

mkdir ~/go
eval "$(/usr/local/bin/gimme 1.7)"
echo 'export GOPATH=$HOME/go' >> .bashrc
export GOPATH=$HOME/go

export PATH=$PATH:$HOME/terraform:$HOME/go/bin
echo 'export PATH=$PATH:$HOME/terraform:$HOME/go/bin' >> .bashrc
source .bashrc

go get github.com/hashicorp/terraform
go get github.com/gophercloud/gophercloud
