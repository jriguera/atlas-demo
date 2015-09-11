module "consul" {
  source = "../consul"

  ami     = "${lookup(var.aws_amis, var.aws_region)}"
  servers = 3

  subnet_id      = "${aws_subnet.demo.id}"
  security_group = "${aws_security_group.demo.id}"

  key_name         = "${module.ssh_keys.key_name}"
  private_key_path = "${module.ssh_keys.private_key_path}"
}

output "consul-address" { value = "${module.consul.address}:8500" }
