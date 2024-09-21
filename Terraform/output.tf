output "ec2_instance_public_ip" {
  description = "The public IP address of the Medusa EC2 instance"
  value       = aws_instance.medusa_instance.public_ip
}
