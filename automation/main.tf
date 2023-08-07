terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-gov-west-1"
}



### Variables ###

variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["us-gov-west-1a", "us-gov-west-1b", "us-gov-west-1c"]
}


### Infrastructure Resources ###
#################            

#### VPC ###

resource "aws_vpc" "repo-sync-tf-vpc" {
  cidr_block    = "172.16.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
   tags = {
    Name = "repo-sync-tf"
  }
}

### subnets ###
resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.repo-sync-tf-vpc.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "repo-sync-tf-public-subnet-${count.index + 1}"
 }
}
 
resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.repo-sync-tf-vpc.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "repo-sync-tf-private-subnet-${count.index + 1}"
 }
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.repo-sync-tf-vpc.id
 
 tags = {
   Name = "repo-sync-tf-gw"
 }
}

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.repo-sync-tf-vpc.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "repo-sync-2nd-Route-table"
 }
}


### associate public subnets to the s2nd route table

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}


### ECS ###
###########




resource "aws_ecs_cluster" "repo-sync-tf-cluster" {
  name = "repo-sync-tf-cluster"
  
  tags = {
    Name = "repo-sync-tf-cluster"
  }
    
}
## create resource provider for fargate
resource "aws_ecs_cluster_capacity_providers" "repo-sync-tf-capacity-provider" {
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  cluster_name        = aws_ecs_cluster.repo-sync-tf-cluster.name
  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = "FARGATE"
  } 

} 

resource "aws_network_acl" "repo-sync-acl" {
   vpc_id     = aws_vpc.repo-sync-tf-vpc.id
   count = length(var.public_subnet_cidrs)
   subnet_ids      = [aws_subnet.public_subnets[count.index].id, aws_subnet.private_subnets[count.index].id] 
   egress {
      action          =   "allow"
      cidr_block      =   "0.0.0.0/0"
      from_port       =   0
      icmp_code       =   0
      icmp_type       =   0
      protocol        =  "-1"
      rule_no         = 100
      to_port         =   0
   }
   
   ingress  {
      action              = "allow"
      cidr_block          = "0.0.0.0/0"
      from_port           = 0
      icmp_code           = 0
      icmp_type           = 0
      protocol            = "-1"
      rule_no             = 100
      to_port             = 0
  }
   tags = {
    Name = "repo-sync-acl"
  }
}

 
 
resource "aws_security_group" "repo-sync-tf-sg-v1" {
  name_prefix = "repo-sync-tf-sg-v1"
  description = "tf generated"

  vpc_id = aws_vpc.repo-sync-tf-vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "repo-sync-tf-sg-v1"
  }
}
##############################################################################################################
### ECS Service and ALB Configuration ###
##############################################################################################################

## ECS Task Definition ###

resource "aws_ecs_task_definition" "repo-sync-tf-task-definiton" {
  family                   = "repo-sync-tf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws-us-gov:iam::141078740716:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name  = "repo-sync",
      image = "141078740716.dkr.ecr.us-gov-west-1.amazonaws.com/repo-sync:latest",
      cpu   = 0,
      portMappings = [
        {
          containerPort = 9000,
          hostPort      = 9000,
          protocol      = "tcp",
        },
      ],
      essential = true,
      environment = [],
      environmentFiles = [],
      mountPoints = [],
      volumesFrom = [],
      ulimits = [],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-create-group"   = "true",
          "awslogs-group"          = "/ecs/",
          "awslogs-region"         = "us-gov-west-1",
          "awslogs-stream-prefix"  = "ecs",
        },
        secretOptions = [],
      },
      "healthCheck": {
                "command": [
                    "CMD-SHELL",
                    "curl -f http://localhost:9000/health || exit 1"
                ],
                "interval": 30,
                "timeout": 5,
                "retries": 3,
                "startPeriod": 20
            }
    },
  ])

  cpu    = "1024"
  memory = "3072"
}

### ECS Service ###

resource "aws_ecs_service" "repo-sync-tf-service" {
  name            = "repo-sync-tf-service"
  cluster         = aws_ecs_cluster.repo-sync-tf-cluster.id
  task_definition = aws_ecs_task_definition.repo-sync-tf-task-definiton.arn
  desired_count   = 1

  
  network_configuration {
    subnets = aws_subnet.public_subnets[*].id
    security_groups = [aws_security_group.repo-sync-tf-sg-v1.id]
    assign_public_ip = true

  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.repo-sync-tf-target-group.arn
    container_name   = "repo-sync"
    container_port   = 9000
  }
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
  }
  
  depends_on = [
    aws_lb_listener_rule.repo-sync-https-listener-rule,
  ]
  
  tags = {
    Name = "repo-sync-service"
  }
}

### ALB ###
resource "aws_lb" "repo-sync-tf-lb" {
  name               = "repo-sync-tf-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.repo-sync-tf-sg-v1.id]
  subnets            = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false
  
  tags = {
    Name = "repo-sync-lb"
  }
}
resource "aws_lb_listener" "repo-sync-https-listener" {
  load_balancer_arn = aws_lb.repo-sync-tf-lb.arn
  port              = 443
  protocol          = "HTTPS"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.repo-sync-tf-target-group.arn
  }



  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws-us-gov:acm:us-gov-west-1:141078740716:certificate/0ebfd66a-6241-4c13-b0c6-cc7a182d1f90"
}

resource "aws_lb_target_group" "repo-sync-tf-target-group" {
  name        = "repo-sync-tf-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.repo-sync-tf-vpc.id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "9000"
  }

  tags = {
    Name = "repo-sync-target-group"
  }
}


resource "aws_lb_listener_rule" "repo-sync-https-listener-rule" {
  listener_arn = aws_lb_listener.repo-sync-https-listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.repo-sync-tf-target-group.arn
  }
 condition {
    path_pattern {
      values = ["/"]
    }
  }

  priority = 100

  
}