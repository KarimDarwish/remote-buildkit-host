output "vpc_id" {
  value = aws_vpc.github_runner.id
}

output "subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "security_group_id" {
  value = aws_security_group.default.id
}