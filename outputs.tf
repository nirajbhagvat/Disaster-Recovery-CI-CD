output "ec2_public_ip" {
  value = aws_instance.dr_ec2.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.dr_rds.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.dr_s3.id
}
