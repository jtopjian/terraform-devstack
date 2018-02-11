provider "aws" {
  region = "us-west-2"
}

resource "random_id" "key_name" {
  prefix      = "openstack_acc_tests_"
  byte_length = 8
}

resource "random_id" "security_group_name" {
  prefix      = "openstack_acc_tests_"
  byte_length = 8
}

resource "aws_key_pair" "openstack_acc_tests" {
  key_name   = "${random_id.key_name.hex}"
  public_key = "${file("../../key/id_rsa.pub")}"
}

resource "aws_security_group" "openstack_acc_tests" {
  name        = "${random_id.security_group_name.hex}"
  description = "Allow all inbound/outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_spot_instance_request" "openstack_acc_tests" {
  ami = "ami-0c2aba6c"

  spot_price           = "0.0580"
  instance_type        = "m3.xlarge"
  wait_for_fulfillment = true
  spot_type            = "one-time"
  key_name             = "${aws_key_pair.openstack_acc_tests.key_name}"

  security_groups = ["default", "${aws_security_group.openstack_acc_tests.name}"]

  root_block_device {
    volume_size           = 40
    delete_on_termination = true
  }

  tags {
    Name = "OpenStack Test Infra"
  }
}

resource "null_resource" "provisioner" {
  connection {
    user        = "centos"
    host        = "${aws_spot_instance_request.openstack_acc_tests.public_ip}"
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

output "ip" {
  value = "${aws_spot_instance_request.openstack_acc_tests.public_ip}"
}
