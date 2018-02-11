provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "packstack_zun" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "^packstack-zun-pike"
}

resource "random_id" "key_name" {
  prefix = "openstack_acc_tests_"
  bytes  = 8
}

resource "random_id" "security_group_name" {
  prefix = "openstack_acc_tests_"
  bytes  = 8
}

resource "aws_key_pair" "openstack_acc_tests" {
  key_name   = "${random_id.key_name.hex}"
  public_key = "${file("../key/id_rsa.pub")}"
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
  ami                  = "${data.aws_ami.packstack_zun.id}"
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
    Name = "OpenStack Acceptance Test Infra"
  }
}

resource "null_resource" "openstack_acc_tests" {
  connection {
    host        = "${aws_spot_instance_request.openstack_acc_tests.public_ip}"
    user        = "centos"
    private_key = "${file("../key/id_rsa")}"
  }

  provisioner "local-exec" {
    command = <<EOF
      while true ; do
        wget http://${aws_spot_instance_request.openstack_acc_tests.public_ip}/keystonerc_demo 2> /dev/null
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
