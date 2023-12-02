terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26.0"
    }
  }

  backend "s3" {
    bucket = "marvelchampions-terraformstate"
    key = "terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
    dynamodb_table = "TerraformState"
  }
}

provider "aws" {}
