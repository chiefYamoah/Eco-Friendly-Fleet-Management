#Create EC2 instances and load balancer
provider "aws" {
  region = "us-east-1"
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Allow inbound HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 instances with predefined AMI
resource "aws_launch_template" "car_service_lt" {
  name = "car-service-launch-template"

  image_id      = "ami-0182f373e66f89c85"
  instance_type = "t2.micro"
  
  # This allows specifying network configuration with security group
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]  
  }

  # Tags
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "CarServiceInstance"
    }
  }
}



# Create Elastic Load Balancer
resource "aws_lb" "car_service_lb" {
  name               = "car-service-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = ["subnet-08f687dd930c1871d", "subnet-0a8afaff755c57d41"] 

  enable_deletion_protection = false
}

# Create Target Group for Load Balancer
resource "aws_lb_target_group" "car_service_tg" {
  name     = "car-service-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-05b79eb20cdbaf8e6"  

  health_check {
    path     = "/"
    protocol = "HTTP"
  }
}


# Create Listener for Load Balancer
resource "aws_lb_listener" "car_service_listener" {
  load_balancer_arn = aws_lb.car_service_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.car_service_tg.arn
  }
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "car_service_asg" {
  launch_template {
    id      = aws_launch_template.car_service_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = ["subnet-08f687dd930c1871d", "subnet-0a8afaff755c57d41"] 

  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 2
  target_group_arns         = [aws_lb_target_group.car_service_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "CarServiceInstance"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy based on CPU utilization
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.car_service_asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.car_service_asg.name
}

#Scaling based on cpu utilization
# CloudWatch Alarm to scale up when CPU > 70%
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high_cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.car_service_asg.name
  }
}

# CloudWatch Alarm to scale down when CPU < 30%
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "low_cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.car_service_asg.name
  }
}
