
# `Infrastructure Automation and Medusa Deployment on AWS EC2 using Terraform and GitHub Actions`

This Project shows the CI-CD Automation using Github Actions , where we automate the provisioning of AWS EC2 instances using Terraform, configure security groups, and deploy the Medusa backend. The entire process is automated using GitHub Actions, including infrastructure setup and application deployment. Additionally, Terraform outputs are captured and used dynamically in the deployment pipeline..



## `Project Objectives`

- Automate EC2 provisioning on AWS using Terraform.

- Configure security groups to allow HTTP, HTTPS, SSH, and Medusa port (9000).

- Deploy Medusa e-commerce backend on the EC2 instance.

- Use GitHub Actions to automate the entire deployment pipeline from infrastructure setup to application deployment.

- Capture Terraform outputs (like EC2 public IP) in GitHub Actions and store them in the environment variables for later use.
 


## 🔗 `Links`

[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sathish-gurka)


## `Authors`

- [@GurkaSathish](https://github.com/sathishyadav024)


## `Pre-Requisites`

- `GitHub`  

- `AWS account (user)`

- `Keypair (EC2_PRIVATE_KEY)`

- `Terraform`

- `GitHub repository with the necessary secrets configured." AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, EC2_PRIVATE_KEY"`

## `Repository Structure`

- `terraform/`: Contains Terraform scripts to provision AWS EC2 and configure security groups `main.tf`. Includes `output.tf` for capturing and exporting EC2 details.

- `.github/workflows/`: GitHub Actions workflows for automating infrastructure provisioning, capturing Terraform outputs, and deploying Medusa.
## `Terraform/`

`main.tf`

```
provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "medusa_instance" {
  ami           = "ami-0522ab6e1ddcc7055"  # Choose an appropriate AMI ID based on your region
  instance_type = "t2.large"
  key_name      = "sathishgurka1"

  tags = {
    Name = "Medusa-Headless"
  }
}

resource "aws_security_group" "new_security_group" {
  name        = "medusa_security_group"
  description = "Allow HTTP, HTTPS, SSH, and Medusa traffic"
  vpc_id      = "vpc-011fe7489b720ff86"  # Replace with your VPC ID
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_medusa" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

```

`output.tf`

```
output "ec2_instance_public_ip" {
  description = "The public IP address of the Medusa EC2 instance"
  value       = aws_instance.medusa_instance.public_ip
}
```
# `GitHub Actions Workflow`

## `.github/workflows`

`main.yml`

```
name: Terraform and Deploy Medusa

on:
  push:
    branches:
      - main  # Trigger on push to the main branch
  workflow_dispatch:  # Allow manual trigger
permissions:
 contents: write

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0  # Use your Terraform version

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-south-1  # Your specified region

      - name: Terraform Init
        run: |
          cd Terraform
          terraform init

      - name: Terraform Plan
        run: |
          cd Terraform
          terraform plan

      - name: Terraform Apply
      
        run: |
         cd Terraform
         terraform apply -auto-approve
        
      # Step 4: Capture Terraform Outputs
      - name: Capture Terraform Outputs
        id: tf_output
        working-directory: Terraform
        run: terraform output -raw ec2_instance_public_ip > output.txt

      - name: Extract EC2 Public IP using grep
        working-directory: Terraform
        run: |
         echo "Checking contents of output.txt:"
         cat output.txt  # Debugging: Check the contents of output.txt
         EC2_IP=$(grep -oP '^\d+\.\d+\.\d+\.\d+' output.txt | xargs)  # Use grep to find the IP address
         echo "Extracted IP: $EC2_IP"
         echo "EC2_IP=$EC2_IP" >> $GITHUB_ENV  # Append to GitHub Actions environment
         
      - name: Wait for EC2 to be ready
        run: sleep 60  # Wait for the EC2 instance to boot up

      - name: Install SSH Client
        run: sudo apt-get install -y openssh-client

      - name: SSH into EC2 and deploy Medusa
        env:
          EC2_IP: ${{ env.EC2_IP }}
          PRIVATE_KEY: ${{ secrets.EC2_PRIVATE_KEY }}  # Use the secret directly i
          
        run: |
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          ssh -o "StrictHostKeyChecking=no" -i private_key.pem ubuntu@${EC2_IP} << 'EOF'
            # Retry logic for apt commands
          MAX_TRIES=5
          for i in $(seq 1 $MAX_TRIES); do
          if sudo apt-get update; then
          break
          else
          echo "Waiting for apt to become available..."
          sleep 10
          fi
          done
             # Update system and install necessary dependencies
          sudo apt update && sudo apt upgrade -y
          sudo apt install -y git
          sudo apt install -y nodejs npm git postgresql redis-server
          sudo systemctl enable postgresql
          sudo systemctl start postgresql
          sudo systemctl enable redis-server

          # Set up PostgreSQL for Medusa-backend
          sudo -u postgres psql -c "CREATE USER medusa_user WITH PASSWORD 'sathish';" || true
          sudo -u postgres psql -c "CREATE DATABASE medusa_db;" || true
          sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE medusa_db TO medusa_user;" || true

           # Grant additional permissions to the user
          sudo -u postgres psql -d medusa_db -c "GRANT ALL PRIVILEGES ON SCHEMA public TO medusa_user;"

          # Configure PostgreSQL authentication method
          sudo sh -c 'echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/16/main/pg_hba.conf'

           # Reload PostgreSQL to apply configuration changes
          sudo systemctl reload postgresql


          # Install Medusa CLI
          sudo npm install -g @medusajs/medusa-cli

          # Create a new Medusa project
          mkdir medusa-backend && cd medusa-backend
          sudo medusa new . --skip-db

          # Update the .env file to connect to the correct PostgreSQL database
          echo "DATABASE_URL=postgres://medusa_user:sathish@localhost:5432/medusa_db" | sudo tee .env
          # Add Redis URL to the .env file
          echo "REDIS_URL=redis://localhost:6379" | sudo tee -a .env
          sudo chown $USER:$USER .env && chmod 644 .env
          
          # run migrations
          sudo medusa migrations run
          # set admin user-name and password 
          sudo medusa user --email sathishyadavdiploma@gmail.com --password sathish

          # Start Medusa backend
          nohup sudo medusa start &> medusa.log &
          EOF
```
##  `Run the Workflow`

Push code to the main branch of your repository:

```
git add .
git commit -m "Deploy Medusa to EC2"
git push origin main

```
## `Check Logs`

The output of the Medusa backend is saved to medusa.log on the EC2 instance. To view the logs:
```
ssh -i /path/to/id_rsa ubuntu@<EC2_IP>
cat /path/to/medusa-backend/medusa.log

```
## `Access Medusa Backend`

Once the deployment completes, you should be able to access the Medusa backend on port 9000 of the EC2 instance:
```
http://<EC2_IP>:9000/app/login

```
## `Technologies Used`

- `Terraform`: Infrastructure provisioning tool for AWS EC2.

- `GitHub Actions`: Automation tool for CI/CD pipelines.

- `AWS EC2`: Cloud-based compute resource.

- `Medusa`: E-commerce backend platform.

- `Linux`: For EC2 configuration and application deployment.
## `How It Works`

    1. Terraform provisions an EC2 instance and configures security groups with the necessary ports.

    2. GitHub Actions automates the process by:

        -  Running the Terraform scripts to create the EC2 instance.

        - Extracting Terraform output (e.g., EC2 public IP) and storing it in GITHUB_ENV for later use in subsequent steps.

        - Installing the necessary dependencies and setting up the Medusa backend on the EC2 instance.

        - Exposing Medusa on port 9000. 
## `Contact`


   For any inquiries or issues related to this project, please reach out via email:  
   
   
   Author: `Gurka Sathish`
   
   Email: ` sathishgurka@gmail.com `
## `Result`

`Successfully installed and deployed the Medusa-Backend using Github Actions on AWS-EC2` 
