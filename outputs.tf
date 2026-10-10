output "public_ips" {
  value = aws_instance.ubuntu[*].public_ip
}

output "ssh_commands" {
  value = [
    for instance in aws_instance.ubuntu :
    "ssh -i ${var.private_key_path} ubuntu@${instance.public_ip}"
  ]
}