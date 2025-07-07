provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  token      = var.AWS_SESSION_TOKEN
}

module "domain_orders" {
  source = "./modules/microservice"
  name   = "domain-orders"
  image_order_create = "ievinan/microservice-order-create"
  port_order_create  = 4000
  image_order_read   = "ievinan/microservice-order-read"
  port_order_read    = 4001
  image_order_add    = "ievinan/microservice-order-add"
  port_order_add     = 4002
  image_order_delete = "ievinan/microservice-order-delete"
  port_order_delete  = 4003
  branch        = var.BRANCH_NAME
  mongo_url     = var.MONGO_URL
}

resource "aws_sns_topic" "asg_alerts" {
  name = "asg-alerts-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.asg_alerts.arn
  protocol  = "email"
  endpoint  = "ievinan@uce.edu.ec"
}

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "asg-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarma si el promedio de CPU de las instancias del ASG supera el 70%"
  dimensions = {
    AutoScalingGroupName = module.domain_orders.asg_name
  }
  alarm_actions = [aws_sns_topic.asg_alerts.arn]
}

resource "aws_cloudwatch_dashboard" "asg_dashboard" {
  dashboard_name = "asg-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" = "metric",
        "x" = 0,
        "y" = 0,
        "width" = 24,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.domain_orders.asg_name ]
          ],
          "period" = 300,
          "stat" = "Average",
          "region" = var.AWS_REGION,
          "title" = "ASG CPU Utilization"
        }
      }
    ]
  })
}