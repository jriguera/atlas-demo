module "ssh_keys" {
  source = "../ssh_keys"
  name   = "demo"
}

resource "aws_instance" "web" {
  count = 5
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${module.ssh_keys.key_name}"
  subnet_id     = "${aws_subnet.demo.id}"

  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags { Name = "web-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${module.ssh_keys.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install apache2",
      "echo \"<h1>${self.public_dns}</h1>\" | sudo tee /var/www/html/index.html",
      "echo \"<h2>${self.public_ip}</h2>\"  | sudo tee -a /var/www/html/index.html",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "local-exec" {
    command = "echo $ATLAS_TOKEN > ${path.module}/tmp/atlas-token"
  }

  provisioner "file" {
    source      = "${path.module}/tmp/atlas-token"
    destination = "/tmp/atlas-token"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/web.json"
    destination = "/tmp/web.json"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/index.html.ctmpl"
    destination = "/tmp/index.html.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-apache.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}

resource "aws_instance" "haproxy" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${module.ssh_keys.key_name}"
  subnet_id     = "${aws_subnet.demo.id}"

  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags { Name = "haproxy" }

  connection {
    user     = "ubuntu"
    key_file = "${module.ssh_keys.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "local-exec" {
    command = "echo $ATLAS_TOKEN > ${path.module}/tmp/atlas-token"
  }

  provisioner "file" {
    source      = "${path.module}/tmp/atlas-token"
    destination = "/tmp/atlas-token"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.json"
    destination = "/tmp/haproxy.json"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${module.consul.address} > /tmp/consul-address",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install haproxy",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.cfg.ctmpl"
    destination = "/tmp/haproxy.cfg.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-haproxy.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}

output "haproxy-address" { value = "${aws_instance.haproxy.public_dns}" }
