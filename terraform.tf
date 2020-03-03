#create provider
provider "aws" {
  region                  = "eu-west-3"
  profile                 = "oussamaprofile"
}

# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["eu-west-3"]

    access_logs {
    bucket        = "foo"
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = ["${aws_instance.new.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 60
  connection_draining         = false
  connection_draining_timeout = 300

  tags = {
    Name = "foobar-terraform-elb"
  }
}

# Create a new AWS Instance
resource "aws_instance" "example" {
  ami           = "xxxx"
  instance_type = "t2.micro"
}

#Auto scaling
resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}
resource "aws_autoscaling_group" "bar" {
  name                      = "foobar-terraform-test"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = "${aws_placement_group.test.id}"
  launch_configuration      = "${aws_launch_configuration.foobar.name}"
  vpc_zone_identifier       = ["${aws_subnet.example1.id}", "${aws_subnet.example2.id}"]

  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
EOF

    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }


#ElastiCache
resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
}


