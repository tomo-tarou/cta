provider "aws" {
  region = "ap-northeast-1"
}

# resource "aws_vpc" "imported_vpc" {
#   cidr_block = "10.0.0.0/24"

#   tags = {
#     Name = "handson-vpc"
#   }
#   tags_all = {
#     Name = "handson-vpc"
#   }
# }
