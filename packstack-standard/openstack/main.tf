variable "key_name" {}
variable "private_key" {}
variable "network_id" {}

variable "flavor" {
  default = "jt.large2"
}

data "openstack_images_image_v2" "packstack_standard" {
  name = "packstack-standard-ocata"
  most_recent = true
}

resource "openstack_networking_secgroup_v2" "openstack_acc_tests" {
  name = "openstack_acc_tests"
  description = "Rules for openstack acceptance tests"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_1" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 1
  port_range_max = 65535
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_2" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv6"
  protocol = "tcp"
  port_range_min = 1
  port_range_max = 65535
  remote_ip_prefix = "::/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_3" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  port_range_min = 1
  port_range_max = 65535
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_4" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv6"
  protocol = "udp"
  port_range_min = 1
  port_range_max = 65535
  remote_ip_prefix = "::/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_5" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_6" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction = "ingress"
  ethertype = "IPv6"
  protocol = "icmp"
  remote_ip_prefix = "::/0"
}

resource "openstack_compute_instance_v2" "openstack_acc_tests" {
  name = "openstack_acc_tests"
  image_id = "${data.openstack_images_image_v2.packstack_standard.id}"
  flavor_name = "${var.flavor}"
  key_pair = "${var.key_name}"

  security_groups = ["${openstack_networking_secgroup_v2.openstack_acc_tests.name}"]

  network {
    uuid = "${var.network_id}"
  }
}

resource "null_resource" "openstack_acc_tests" {
  connection {
    host = "${openstack_compute_instance_v2.openstack_acc_tests.access_ip_v6}"
    user = "centos"
    private_key = "${file(var.private_key)}"
  }

  provisioner "local-exec" {
    command = <<EOF
      while true ; do
        wget http://${openstack_compute_instance_v2.openstack_acc_tests.access_ip_v6}/keystonerc_demo 2> /dev/null
        if [ $? = 0 ]; then
          break
        fi
        sleep 20
      done
      rm keystonerc_demo
    EOF
  }

  provisioner "remote-exec" {
    scripts = ["../../local.sh"]
  }
}
