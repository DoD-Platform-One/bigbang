output "instance_id" {
  value = aws_instance.bb-ci-airgap.id
}

output "ami_id" {
  value = data.aws_ami.airgap_ami.image_id
}
