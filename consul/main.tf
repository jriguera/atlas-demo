resource "aws_instance" "server" {
  count         = "${var.servers}"
  ami           = "${var.ami}"

  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.subnet_id}"

  vpc_security_group_ids = ["${var.security_group}"]

  connection {
    user     = "ubuntu"
    key_file = "${var.private_key_path}"
  }

  tags { Name = "${var.name}-${count.index}" }

  provisioner "file" {
    source      = "${path.module}/scripts/upstart.conf"
    destination = "/tmp/upstart.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/consul-server-count",
    ]
  }

  provisioner "local-exec" {
    command = "echo $ATLAS_TOKEN > ${path.module}/tmp/atlas-token"
  }

  provisioner "file" {
    source      = "${path.module}/tmp/atlas-token"
    destination = "/tmp/atlas-token"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
      "${path.module}/scripts/server.sh",
      "${path.module}/scripts/service.sh",
    ]
  }
}

output "address" { value = "${aws_instance.server.0.public_dns}" }
output "ip" { value = "${aws_instance.server.0.public_ip}" }
