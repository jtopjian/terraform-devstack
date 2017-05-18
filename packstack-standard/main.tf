resource "openstack_compute_keypair_v2" "packstack-standard" {
  name = "packstack-standard"
  public_key = "${file("key/id_rsa.pub")}"
}

resource "openstack_compute_instance_v2" "packstack-standard" {
  name = "packstack-standard"
  image_name = "packstack-standard-ocata"
  #image_name = "jtcentos"
  flavor_name = "jt.large2"
  key_pair = "${openstack_compute_keypair_v2.packstack-standard.name}"
  security_groups = ["default", "AllowAll"]
}

output "ipv6" {
  value = "${openstack_compute_instance_v2.packstack-standard.access_ip_v6}"
}

output "ipv4" {
  value = "${openstack_compute_instance_v2.packstack-standard.access_ip_v4}"
}
