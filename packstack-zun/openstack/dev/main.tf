variable "network_id" {}

variable "image_id" {}

variable "pool" {
  default = "public"
}

variable "flavor" {
  default = "m1.xlarge"
}

resource "random_id" "security_group_name" {
  prefix      = "openstack_acc_tests_"
  byte_length = 8
}

resource "random_id" "instance_name" {
  prefix      = "openstack_acc_tests_"
  byte_length = 8
}

resource "random_id" "key_name" {
  prefix      = "openstack_acc_tests_"
  byte_length = 8
}

resource "openstack_compute_keypair_v2" "openstack_acc_tests" {
  name       = "${random_id.key_name.hex}"
  public_key = "${file("../../key/id_rsa.pub")}"
}

resource "openstack_networking_secgroup_v2" "openstack_acc_tests" {
  name        = "${random_id.security_group_name.hex}"
  description = "Rules for openstack acceptance tests"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_1" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_2" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "::/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_3" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_4" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "::/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_5" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "openstack_acc_tests_rule_6" {
  security_group_id = "${openstack_networking_secgroup_v2.openstack_acc_tests.id}"
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_ip_prefix  = "::/0"
}

resource "openstack_compute_instance_v2" "openstack_acc_tests" {
  name        = "${random_id.instance_name.hex}"
  image_id    = "${var.image_id}"
  flavor_name = "${var.flavor}"
  key_pair    = "${var.key_name}"

  security_groups = ["${openstack_networking_secgroup_v2.openstack_acc_tests.name}"]

  network {
    uuid = "${var.network_id}"
  }
}

resource "null_resource" "provisioner" {
  connection {
    user        = "centos"
    host        = "${openstack_compute_instance_v2.openstack_acc_tests.access_ip_v6}"
    private_key = "${file("../../key/id_rsa")}"
  }

  provisioner "file" {
    source      = "../../files"
    destination = "/home/centos/files"
  }

  provisioner "remote-exec" {
    scripts = ["../../../local.sh"]
  }
}
