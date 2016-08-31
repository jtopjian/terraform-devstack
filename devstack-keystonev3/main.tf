resource "openstack_compute_keypair_v2" "devstack-standard" {
  name = "devstack-standard"
  public_key = "${file("key/id_rsa.pub")}"
}

resource "openstack_blockstorage_volume_v1" "devstack-standard" {
  name = "devstack-standard"
  size = 100
}

resource "openstack_compute_secgroup_v2" "devstack-standard" {
  name = "devstack-standard"
  description = "devstack-standard"

  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }

  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "::/0"
  }
}

resource "openstack_compute_instance_v2" "devstack-standard" {
  name = "devstack-standard"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.xlarge"

  key_pair = "${openstack_compute_keypair_v2.devstack-standard.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.devstack-standard.name}"]

  volume {
    volume_id = "${openstack_blockstorage_volume_v1.devstack-standard.id}"
  }

  connection {
    user = "ubuntu"
    key_file = "key/id_rsa"
    host = "${openstack_compute_instance_v2.devstack-standard.access_ip_v6}"
  }

  provisioner file {
    source = "deploy.sh"
    destination = "/home/ubuntu/deploy.sh"
  }

  provisioner file {
    source = "volume.sh"
    destination = "/home/ubuntu/volume.sh"
  }

  provisioner file {
    source = "local.sh"
    destination = "/home/ubuntu/local.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/deploy.sh",
      "sudo bash /home/ubuntu/volume.sh",
      "bash /home/ubuntu/local.sh",
    ]
  }
}

output "ipv6" {
  value = "${openstack_compute_instance_v2.devstack-standard.access_ip_v6}"
}
