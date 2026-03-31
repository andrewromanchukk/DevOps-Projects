resource "aws_ecs_cluster" "my_first_ecs_cluster" {
  name = "ecs-ec2-cluster"
}


## Launch template
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-"
  image_id      = data.aws_ami.ecs.id # ECS-optimized AMI (check region!)
  instance_type = "t2.micro"

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.my_first_ecs_cluster.name} >> /etc/ecs/ecs.config
EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }
}

## IAM role for EC2

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  role = aws_iam_role.ecs_instance_role.name
}

## Auto Scailing Group

data "aws_subnet" "priv_sub_a" {
  filter {
    name = "tag:Name"
    values = [ "Private_A" ]
}
}

data "aws_subnet" "priv_sub_b" {
  filter {
    name = "tag:Name"
    values = [ "Private_B" ]
}
}

resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = [
    data.aws_subnet.priv_sub_a.id,
    data.aws_subnet.priv_sub_b.id
  ]

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
}

## Capacity Provider (connect ASG to ECS)

resource "aws_ecs_capacity_provider" "my_capacity_provider" {
  name = "my-ecs-asg-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status = "ENABLED"
      target_capacity = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.my_first_ecs_cluster.name

  capacity_providers = [
    aws_ecs_capacity_provider.my_capacity_provider.name
  ]
}

## Task Definition (2 containers)

resource "aws_ecs_task_definition" "task_app" {
  family                   = "multi-container"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([
    {
      name  = "django-app"
      image = "048266892098.dkr.ecr.eu-central-1.amazonaws.com/django-hujango"
      cpu   = 128
      memory = 256
      portMappings = [{
        containerPort = 8000
        hostPort      = 80
      }]
    },
    {
      name  = "sidecar"
      image = "busybox"
      cpu   = 64
      memory = 128
      command = ["sh", "-c", "while true; do echo hello; sleep 10; done"]
    }
  ])
}

## ECS Service

resource "aws_ecs_service" "ecs_service_app" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.my_first_ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_app.id
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.my_capacity_provider.name
    weight            = 1
  }
}

