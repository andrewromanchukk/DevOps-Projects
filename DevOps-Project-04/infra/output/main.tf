data "aws_vpc" "vpc_name" {
  filter {
    name = "tag:Name"
    values = [ "MyVPC" ]
}
}

output "vpc_name" {
  value = data.aws_vpc.vpc_name.id
}