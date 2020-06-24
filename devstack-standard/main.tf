resource "openstack_compute_keypair_v2" "devstack-standard" {
  name       = "devstack-standard"
  public_key = "${file("key/id_rsa.pub")}"
}

resource "openstack_compute_instance_v2" "devstack-standard" {
  name        = "devstack-standard"
  image_name  = "Ubuntu 16.04"
  flavor_name = "m1.xlarge"

  key_pair        = "${openstack_compute_keypair_v2.devstack-standard.name}"
  security_groups = ["default", "AllowAll"]

  network {
    name = "default"
  }
}

resource "null_resource" "devstack-standard" {
  connection {
    user        = "ubuntu"
    private_key = "${file("key/id_rsa")}"
    host        = "${openstack_compute_instance_v2.devstack-standard.access_ip_v6}"
  }

  provisioner file {
    source      = "deploy.sh"
    destination = "/home/ubuntu/deploy.sh"
  }

  provisioner file {
    source      = "local.sh"
    destination = "/home/ubuntu/local.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/deploy.sh",
      "bash /home/ubuntu/local.sh",
    ]
  }
}

output "ipv6" {
  value = "${openstack_compute_instance_v2.devstack-standard.access_ip_v6}"
}
