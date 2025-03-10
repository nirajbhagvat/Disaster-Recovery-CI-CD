# Provider configuration for AWS
# provider "aws" {
#   region = "ap-south-1" # Change as per your AWS region requirement
# }

# ---------------------- VPC Configuration ----------------------
resource "aws_vpc" "dr_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dr-vpc"
  }
}

# Public Subnet (for EC2 & other public-facing resources)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a" # Ensure correct region

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet (for RDS & other internal services)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway (enables internet access for public resources)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name = "dr-igw"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Route all outbound traffic to IGW
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------- Security Group Configuration ----------------------
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.dr_vpc.id

  # Allow SSH Access (Restrict this to your IP in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CHANGE THIS TO YOUR IP
  }

  # Allow HTTP Traffic (for web servers, if needed)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# ---------------------- EC2 Configuration ----------------------
resource "aws_instance" "dr_ec2" {
  ami             = "ami-0f2ce9ce760bd7133" # Amazon Linux 2 AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "dr-ec2-instance"
  }
}

# ---------------------- S3 Bucket for Disaster Recovery ----------------------
resource "aws_s3_bucket" "dr_s3" {
  bucket = "disaster-recovery-backup-bucket"

  tags = {
    Name = "dr-s3-bucket"
  }
}

# ---------------------- RDS Database for Disaster Recovery ----------------------
resource "aws_db_instance" "dr_rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "drdb"
  username               = "admin"
  password               = "changeme123" # Use AWS Secrets Manager instead
  publicly_accessible    = false
  multi_az               = true # Enables automatic failover
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.dr_subnet_group.name

  tags = {
    Name = "dr-rds-instance"
  }
}

# RDS Subnet Group (for Multi-AZ failover support)
resource "aws_db_subnet_group" "dr_subnet_group" {
  name       = "dr-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]

  tags = {
    Name = "dr-db-subnet-group"
  }
}

# ---------------------- CloudWatch & Monitoring ----------------------
# CloudWatch Alarm for EC2 CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "HighCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Trigger when CPU usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
}

# SNS Topic for CloudWatch Alarms (to send notifications)
resource "aws_sns_topic" "alarm_notification" {
  name = "dr-alerts"
}

# Define Launch Template
resource "aws_launch_template" "dr_launch_template" {
  name_prefix   = "dr-launch-template"
  image_id      = "ami-014e2b14bdb83e8ca"  # Update to a valid AMI for ap-south-1
  instance_type = "t2.micro"
  key_name      = "MyKeyPair"  # Replace with your key pair
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "dr-ec2-instance"
    }
  }
}

# Auto Scaling Group using Launch Template
resource "aws_autoscaling_group" "dr_asg" {
  name                = "dr-asg"
  desired_capacity    = 1
  min_size           = 1
  max_size           = 3
  vpc_zone_identifier = [aws_subnet.public_subnet.id]

  launch_template {
    id      = aws_launch_template.dr_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dr-ec2-instance"
    propagate_at_launch = true
  }
}
