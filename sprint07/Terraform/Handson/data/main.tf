provider "aws" {
  region = "ap-northeast-1"
}

# data "aws_vpc" "existing_vpc" {
#   filter {
#     name   = "tag:Name"
#     values = ["handson-vpc"]
#   }
# }

# resource "aws_subnet" "data_subnet" {

#   vpc_id     = data.aws_vpc.existing_vpc.id
#   cidr_block = "10.0.0.0/24"

#   tags = {
#     Name = "handson-subnet"
#   }
# }
