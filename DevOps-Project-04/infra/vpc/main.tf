provider "aws" {}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = merge(var.common_tags,{
    Name = "MyVPC"
  })
}


#IGW
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

#NAT
# resource "aws_eip" "nat" {
#   domain = "vpc"
# }

# resource "aws_nat_gateway" "nat" {
#   subnet_id     = aws_subnet.public_a.id
#   allocation_id = aws_eip.nat.id
# }