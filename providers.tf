provider "aws" {
  region = local.aws_region

  // TODO maybe roles?
  // If you use roles with specific permissions please add your role
  // assume_role {
  //   role_arn = "arn:aws:iam::123456789012:role/MyAdminRole"
  // }
}

provider "random" {
}


terraform {
  required_version = "~> 1.0.1"
  required_providers {
    aws = {
      source = "hashicorp/aws",
      version = "~> 3.61.0"
    }
  }
  backend "s3" {
    bucket = "compiler-explorer"
    key    = "terraform/ce-ci.tfstate"
    region = "us-east-1"
  }
}
