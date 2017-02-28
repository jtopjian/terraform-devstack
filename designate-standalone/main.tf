# Keypair
resource "openstack_compute_keypair_v2" "designate-standalone" {
    name = "designate-standalone"
    public_key = "${file("key/id_rsa.pub")}"
}

resource "openstack_compute_instance_v2" "designate-standalone" {
  name = "designate-standalone"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.medium"
  key_pair = "${openstack_compute_keypair_v2.designate-standalone.name}"
  security_groups = ["default", "AllowAll"]
  user_data = "#cloud-config\ndisable_root: false"
}

resource "null_resource" "designate-standalone" {
  connection {
    user = "root"
    private_key = "${file("key/id_rsa")}"
    host = "${openstack_compute_instance_v2.designate-standalone.access_ip_v6}"
  }

  provisioner file {
    source = "files"
    destination = "/home/ubuntu/files"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/ubuntu/files/deploy.sh",
      "bash /home/ubuntu/files/local.sh"
    ]
  }
}


output "ipv6" {
  value = "${openstack_compute_instance_v2.designate-standalone.access_ip_v6}"
}

output "ipv4" {
  value = "${openstack_compute_instance_v2.designate-standalone.access_ip_v4}"
}

