#!/bin/bash
set -xe

sudo hostnamectl set-hostname localhost
sudo yum -y update

cd
sudo yum install -y -q nfs-utils wget yum-utils device-mapper-persistent-data lvm2
#sudo yum groups mark install "Development Tools"
#sudo yum groups mark convert "Development Tools"
#sudo yum group install -y -q "Development Tools"
sudo yum install -y -q python-devel

sudo mkdir /mnt/nfs
sudo chown nfsnobody:nfsnobody /mnt/nfs
sudo chmod 777 /mnt/nfs
echo "/mnt/nfs 127.0.0.1(rw,sync,no_root_squash,no_subtree_check)" | sudo tee /etc/exports
sudo exportfs -a

sudo yum install -y -q centos-release-openstack-pike
sudo yum update -y -q
sudo yum install -y -q openstack-packstack crudini
sudo yum install -y -q python-pip

# Run packstack
sudo packstack --answer-file /home/centos/files/packstack-answers.txt

# Move findmnt to allow multiple mounts to 127.0.0.1:/mnt
sudo mv /bin/findmnt{,.orig}

# Prep the testing environment by creating the required testing resources and environment variables
sudo cp /root/keystonerc_demo /home/centos
sudo cp /root/keystonerc_admin /home/centos
sudo chown centos: /home/centos/keystonerc*
source /home/centos/keystonerc_admin
_NETWORK_ID=$(openstack network show private -c id -f value)
_SUBNET_ID=$(openstack subnet show private_subnet -c id -f value)
_EXTGW_ID=$(openstack network show public -c id -f value)
_IMAGE_ID=$(openstack image show cirros -c id -f value)

echo "" >> /home/centos/keystonerc_admin
echo export OS_AUTH_TYPE="password" >> /home/centos/keystonerc_admin
echo export OS_IMAGE_NAME="cirros" >> /home/centos/keystonerc_admin
echo export OS_IMAGE_ID="$_IMAGE_ID" >> /home/centos/keystonerc_admin
echo export OS_NETWORK_ID=$_NETWORK_ID >> /home/centos/keystonerc_admin
echo export OS_EXTGW_ID=$_EXTGW_ID >> /home/centos/keystonerc_admin
echo export OS_POOL_NAME="public" >> /home/centos/keystonerc_admin
echo export OS_FLAVOR_ID=99 >> /home/centos/keystonerc_admin
echo export OS_FLAVOR_ID_RESIZE=98 >> /home/centos/keystonerc_admin

echo "" >> /home/centos/keystonerc_demo
echo export OS_AUTH_TYPE="password" >> /home/centos/keystonerc_demo
echo export OS_IMAGE_NAME="cirros" >> /home/centos/keystonerc_demo
echo export OS_IMAGE_ID="$_IMAGE_ID" >> /home/centos/keystonerc_demo
echo export OS_NETWORK_ID=$_NETWORK_ID >> /home/centos/keystonerc_demo
echo export OS_EXTGW_ID=$_EXTGW_ID >> /home/centos/keystonerc_demo
echo export OS_POOL_NAME="public" >> /home/centos/keystonerc_demo
echo export OS_FLAVOR_ID=99 >> /home/centos/keystonerc_demo
echo export OS_FLAVOR_ID_RESIZE=98 >> /home/centos/keystonerc_demo

# Update subnet DNS
openstack subnet set --dns-nameserver 8.8.8.8 private_subnet

# Install Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y -q install docker-ce
sudo systemctl start docker

sudo groupadd --system zun
sudo useradd --home-dir "/var/lib/zun" --create-home --system --shell /bin/false -g zun zun
sudo mkdir -p /etc/zun
sudo chown zun:zun /etc/zun

sudo mkdir /etc/systemd/system/docker.service.d

echo "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --group zun -H tcp://127.0.0.1:2375 -H unix:///var/run/docker.sock --cluster-store etcd://127.0.0.1:2379" | sudo tee -a /etc/systemd/system/docker.service.d/docker.conf

sudo systemctl daemon-reload
sudo systemctl restart docker.service

# Install etcd
sudo docker run -d --net=host --name etcd quay.io/coreos/etcd:v3.0.13 \
  /usr/local/bin/etcd \
  --data-dir=data.etcd \
  --name node0 \
  --initial-advertise-peer-urls http://127.0.0.1:2380 \
  --listen-peer-urls http://127.0.0.1:2380 \
  --advertise-client-urls http://127.0.0.1:2379 \
  --listen-client-urls http://127.0.0.1:2379 \
  --initial-cluster node0=http://127.0.0.1:2380 \
  --initial-cluster-state new \
  --initial-cluster-token etcd-token

# Install Kuryr
sudo docker pull kuryr/libnetwork:latest
sudo mkdir -p /usr/lib/docker/plugins/kuryr
sudo curl -o /usr/lib/docker/plugins/kuryr/kuryr.spec https://raw.githubusercontent.com/openstack/kuryr-libnetwork/master/etc/kuryr.spec
sudo service docker restart
sudo docker run -d --name kuryr-libnetwork \
  --net=host \
  --cap-add=NET_ADMIN \
  -e SERVICE_USER=admin \
  -e SERVICE_PROJECT_NAME=admin \
  -e SERVICE_PASSWORD=$OS_PASSWORD \
  -e SERVICE_DOMAIN_NAME=Default \
  -e USER_DOMAIN_NAME=Default \
  -e IDENTITY_URL=http://127.0.0.1:35357/v3 \
  -v /var/log/kuryr:/var/log/kuryr \
  -v /var/run/openvswitch:/var/run/openvswitch \
  kuryr/libnetwork

# Install Zun
sudo mysql -e "CREATE DATABASE zun"
sudo mysql -e "GRANT ALL PRIVILEGES ON zun.* TO 'zun'@'localhost' IDENTIFIED BY 'password'"
sudo mysql -e "GRANT ALL PRIVILEGES ON zun.* TO 'zun'@'%' IDENTIFIED BY 'password'"

openstack user create --domain default --password password zun
openstack role add --project services --user zun admin

openstack service create --name zun --description "Container Service" container
openstack endpoint create --region RegionOne container public http://127.0.0.1:9517/v1
openstack endpoint create --region RegionOne container internal http://127.0.0.1:9517/v1
openstack endpoint create --region RegionOne container admin http://127.0.0.1:9517/v1

openstack service create --name zun-experimental --description "Container Service" container-experimental
openstack endpoint create --region RegionOne container-experimental public http://127.0.0.1:9517/experimental
openstack endpoint create --region RegionOne container-experimental internal http://127.0.0.1:9517/experimental
openstack endpoint create --region RegionOne container-experimental admin http://127.0.0.1:9517/experimental

cd
git clone https://git.openstack.org/openstack/python-zunclient.git
sudo chown -R zun:zun python-zunclient
pushd python-zunclient
sudo pip install -r requirements.txt
sudo python setup.py install

cd
git clone https://git.openstack.org/openstack/zun.git
sudo chown -R zun:zun zun
pushd zun
sudo pip install -r requirements.txt
sudo python setup.py install

sudo service openstack-cinder-api.service restart
sudo service openstack-cinder-scheduler.service restart
sudo service openstack-cinder-volume.service restart
sudo service openstack-heat-api-cfn.service restart
sudo service openstack-heat-api.service restart
sudo service openstack-heat-engine.service  restart
sudo service httpd restart

sudo cp /usr/share/glance/glance-api-dist-paste.ini /etc/glance/glance-api-paste.ini
sudo cp /usr/share/glance/glance-registry-dist-paste.ini /etc/glance/glance-registry-paste.ini
sudo service openstack-glance-api restart
sudo service openstack-glance-registry restart

sudo oslo-config-generator --config-file etc/zun/zun-config-generator.conf
sudo mv etc/zun/zun.conf.sample /etc/zun/zun.conf
sudo cp etc/zun/api-paste.ini /etc/zun/
sudo chown -R zun: /etc/zun
sudo crudini --set /etc/zun/zun.conf DEFAULT transport_url rabbit://guest:guest@127.0.0.1:5672/
sudo crudini --set /etc/zun/zun.conf api host_ip ::
sudo crudini --set /etc/zun/zun.conf api port 9517
sudo crudini --set /etc/zun/zun.conf database connection mysql+pymysql://zun:password@127.0.0.1/zun
sudo crudini --set /etc/zun/zun.conf keystone_authtoken memcached_servers 127.0.0.1:11211
sudo crudini --set /etc/zun/zun.conf keystone_authtoken auth_uri http://127.0.0.1:5000
sudo crudini --set /etc/zun/zun.conf keystone_authtoken project_domain_name default
sudo crudini --set /etc/zun/zun.conf keystone_authtoken project_name services
sudo crudini --set /etc/zun/zun.conf keystone_authtoken user_domain_name default
sudo crudini --set /etc/zun/zun.conf keystone_authtoken password password
sudo crudini --set /etc/zun/zun.conf keystone_authtoken username zun
sudo crudini --set /etc/zun/zun.conf keystone_authtoken auth_url http://127.0.0.1:35357
sudo crudini --set /etc/zun/zun.conf keystone_authtoken auth_type password
sudo crudini --set /etc/zun/zun.conf keystone_authtoken auth_version v3
sudo crudini --set /etc/zun/zun.conf keystone_authtoken auth_protocol http
sudo crudini --set /etc/zun/zun.conf keystone_authtoken service_token_roles_required True
sudo crudini --set /etc/zun/zun.conf keystone_authtoken endpoint_type internalURL
sudo crudini --set /etc/zun/zun.conf keystone_auth auth_type password
sudo crudini --set /etc/zun/zun.conf keystone_auth username zun
sudo crudini --set /etc/zun/zun.conf keystone_auth password password
sudo crudini --set /etc/zun/zun.conf keystone_auth project_name services
sudo crudini --set /etc/zun/zun.conf keystone_auth project_domain_id default
sudo crudini --set /etc/zun/zun.conf keystone_auth user_domain_id default
sudo crudini --set /etc/zun/zun.conf keystone_auth auth_url http://127.0.0.1:35357
sudo crudini --set /etc/zun/zun.conf oslo_concurrency lock_path /var/lib/zun/tmp
sudo crudini --set /etc/zun/zun.conf oslo_messaging_notifications driver messaging
sudo crudini --set /etc/zun/zun.conf websocket_proxy wsproxy_host 127.0.0.1
sudo crudini --set /etc/zun/zun.conf websocket_proxy wsproxy_port 6784
sudo crudini --set /etc/zun/zun.conf websocket_proxy base_url ws://127.0.0.1:6784/
sudo crudini --set /etc/zun/zun.conf docker docker_remote_api_host 127.0.0.1

sudo -u zun zun-db-manage upgrade

echo "[Unit]
Description = OpenStack Container Service API

[Service]
ExecStart = /usr/bin/zun-api
User = zun

[Install]
WantedBy = multi-user.target" | sudo tee /etc/systemd/system/zun-api.service

echo "[Unit]
Description = OpenStack Container Service Websocket Proxy

[Service]
ExecStart = /usr/bin/zun-wsproxy
User = zun

[Install]
WantedBy = multi-user.target" | sudo tee /etc/systemd/system/zun-wsproxy.service

sudo systemctl enable zun-api
sudo systemctl enable zun-wsproxy

sudo systemctl start zun-api
sudo systemctl start zun-wsproxy

echo "[Unit]
Description = OpenStack Container Service Compute Agent

[Service]
ExecStart = /usr/bin/zun-compute
User = zun

[Install]
WantedBy = multi-user.target" | sudo tee -a /etc/systemd/system/zun-compute.service

sudo systemctl enable zun-compute
sudo systemctl start zun-compute

exit 0

# Clean up the currently running services
sudo systemctl stop openstack-cinder-backup.service
sudo systemctl stop openstack-cinder-scheduler.service
sudo systemctl stop openstack-cinder-volume.service
sudo systemctl stop neutron-dhcp-agent.service
sudo systemctl stop neutron-l3-agent.service
sudo systemctl stop neutron-lbaasv2-agent.service
sudo systemctl stop neutron-metadata-agent.service
sudo systemctl stop neutron-openvswitch-agent.service
sudo systemctl stop neutron-metering-agent.service

sudo mysql -e "update services set deleted_at=now(), deleted=id" cinder
for i in $(openstack network agent list -c ID -f value); do
  neutron agent-delete $i
done

sudo systemctl stop httpd

# Copy rc.local for post-boot configuration
sudo cp /home/centos/files/rc.local /etc
sudo chmod +x /etc/rc.local
