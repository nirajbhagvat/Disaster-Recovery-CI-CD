# 🚀 AWS Disaster Recovery (DR) Setup with Terraform

## 📌 Project Overview  
This project sets up an **AWS Disaster Recovery (DR) Infrastructure** using **Terraform**, ensuring high availability, automatic failover, and backup mechanisms.  

### 🔹 Features  
- **AWS VPC** with Public and Private Subnets  
- **EC2 Instances** with Auto Scaling and Security Groups  
- **RDS (MySQL) with Multi-AZ Failover**  
- **S3 Bucket for Backup Storage**  
- **CloudWatch Monitoring & SNS Alerts**  
- **Auto Scaling for EC2**  

---

## 🛠️ Prerequisites  
Ensure you have the following installed:  
- ✅ [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)  
- ✅ [Terraform](https://developer.hashicorp.com/terraform/downloads)  
- ✅ AWS IAM User with `AdministratorAccess`  

---

## ⚡ Deployment Steps  

### 1️⃣ Configure AWS CLI  
Run the following and enter your AWS credentials:  
\`\`\`
aws configure
\`\`\`

### 2️⃣ Clone the Repository
\`\`\`
git clone <your-github-repo-url>
cd dr-project
\`\`\`

### 3️⃣ Initialize Terraform
\`\`\`
terraform init
\`\`\`

### 4️⃣ Review the Execution Plan
\`\`\`
terraform plan
\`\`\`

### 5️⃣ Apply Terraform to Deploy Infrastructure
\`\`\`
terraform apply -auto-approve
\`\`\`
✅ Once applied, Terraform will create your AWS **VPC, EC2, RDS, S3, CloudWatch, and Auto Scaling resources**.  

---

## 🧪 Testing Disaster Recovery  

### 🔹 Test EC2 Auto Recovery  
Terminate an EC2 instance:
\`\`\`
aws ec2 terminate-instances --instance-ids <INSTANCE_ID> --region ap-south-1
\`\`\`
✅ Auto Scaling should launch a new instance.  

### 🔹 Simulate RDS Failover  
\`\`\`
aws rds reboot-db-instance --db-instance-identifier <RDS_INSTANCE_ID> --region ap-south-1 --force-failover
\`\`\`
✅ RDS should failover to standby.  

### 🔹 Check CloudWatch Alarms  
\`\`\`
aws cloudwatch describe-alarms --region ap-south-1 --query "MetricAlarms[*].{Name:AlarmName,State:StateValue}"
\`\`\`
✅ CPU alerts should trigger as expected.  

---

## 🧹 Cleanup (Destroy Infrastructure)  
To remove all resources:
\`\`\`
terraform destroy -auto-approve
\`\`\`

---

## 🔗 Useful Links  
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)  
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2.html)  
- [AWS Auto Scaling Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)  

---

## 👨‍💻 Author  
🚀 Developed by **Niraj Bhagvat**  
📧 Contact: **nirajbhagvat123@gmail.com**  
🔗 GitHub: **@nirajbhagvat**
