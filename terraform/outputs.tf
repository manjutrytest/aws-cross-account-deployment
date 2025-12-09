output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_eip.main.public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = aws_instance.main.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2.id
}
