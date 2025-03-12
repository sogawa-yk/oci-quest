output "lb_public_url" {
  value = format("http://%s", lookup(oci_load_balancer_load_balancer.mushop_lb.ip_address_details[0], "ip_address"))
}

output "bastion_ip" {
  value = oci_core_instance.mushop_bastion.public_ip
}
