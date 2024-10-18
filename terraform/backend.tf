terraform {
  backend "s3" {
    bucket = "jt-terraform-backend-bucket" # Replace with your own bucket
    key    = "EKS/terraform.tfstate"
    region = "us-east-1"
    }
}

