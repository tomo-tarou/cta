provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket       = "handson-remote-bucket-tom"
    key          = "test/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}

# resource "aws_vpc" "remote_state_test_vpc" {
#   cidr_block = "10.0.0.0/24"
#   tags = {
#     Name = "remote_state_test_vpc"
#   }
# }
