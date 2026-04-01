

data "aws_availability_zones" "zones" {}

# public subnets 

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.zones.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public_A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public_B"
  }
}


# private subnets 

resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.zones.names[0]
  

  tags = {
    Name = "Private_A"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.zones.names[1]
  
  
  tags = {
    Name = "Private_B"
  }
}