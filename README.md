# tf-aws-docker-swarm
Deploy a Docker Swarm on AWS with Terraform

# Assumptions
- Your preferred AWS region is eu-west-1. If not, it's easy to change it in `variables.tf`
- You already have a private key pair generated through your AWS console, and you will be asked for its name before terraform starts applying changes
- You need 1 manager and 2 worker nodes
- You understand I created this for demostration purposes and therefore it should not be considered production ready

# Instructions
- Clone the repo
- `terraform init`
- Put your private key pair in the cloned repo dir and name it `key-pair.pem`
- `terraform plan`
- `terraform apply`
