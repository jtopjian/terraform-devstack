resource "openstack_compute_keypair_v2" "packstack-legacy" {
  name = "packstack-legacy"
  public_key = "${file("key/id_rsa.pub")}"
}

resource "openstack_compute_instance_v2" "packstack-legacy" {
  name = "packstack-legacy"
  image_id = "5f2ba379-4c0e-4600-8c7b-9d8aadfaddae"
  flavor_name = "m1.xlarge"

  key_pair = "${openstack_compute_keypair_v2.packstack-legacy.name}"
  security_groups = ["default", "AllowAll"]

  block_device {
    boot_index = 0
    delete_on_termination = true
    destination_type = "local"
    source_type = "image"
    uuid = "5f2ba379-4c0e-4600-8c7b-9d8aadfaddae"
  }

  block_device {
    boot_index = 1
    delete_on_termination = true
    destination_type = "volume"
    source_type = "blank"
    volume_size = 100
  }
}

data "template_file" "packstack-answers" {
  template = "${file("files/packstack-answers.tpl")}"

  vars {
    ACCESS_IP_V4 = "${openstack_compute_instance_v2.packstack-legacy.access_ip_v4}"
  }
}

resource "null_resource" "packstack-legacy" {
  connection {
    user = "centos"
    private_key = "${file("key/id_rsa")}"
    host = "${openstack_compute_instance_v2.packstack-legacy.access_ip_v6}"
  }

  provisioner file {
    content = "${data.template_file.packstack-answers.rendered}"
    destination = "/home/centos/packstack-answers.txt"
  }

  provisioner file {
    source = "files"
    destination = "/home/centos/files"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/centos/files/deploy.sh",
      "sudo bash /home/centos/files/local.sh",
    ]
  }
}

output "ipv6" {
  value = "${openstack_compute_instance_v2.packstack-legacy.access_ip_v6}"
}

output "ipv4" {
  value = "${openstack_compute_instance_v2.packstack-legacy.access_ip_v4}"
}
