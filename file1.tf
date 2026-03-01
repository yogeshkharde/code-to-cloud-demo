resource "aws_cloudtrail" "default" {
  name                          = "tf-trail-foobar"
  s3_bucket_name                = aws_s3_bucket.foo.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  enable_logging                = false  # cid 24 Ensure aws_cloudtrail resource has attribute enable_logging set to true.
  cloud_watch_logs_group_arn	= aws_cloudwatch_log_group.dada.arn
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "unauth" {
  name           = "unauthorized_api_calls_metric"
  pattern        = "{{($.eventName = \"ConsoleLoginjs\") && ($.additionalEventData.MFAUsed != \"Yes\")}}"
  log_group_name = aws_cloudwatch_log_group.dada.name

  metric_transformation {
    name      = "unauthorized_api_calls_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_group" "dada" {
  name = "MyApp/access.log"
}

resource "aws_sns_topic" "trail-unauthorised" {
  name="Unauthorised"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.trail-unauthorised.arn
  protocol  = "sms"
  endpoint	= var.endpoint
}

resource "aws_cloudwatch_metric_alarm" "unauth" {
  alarm_name          = "unauthorized_api_calls_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.unauth.metric_transformation.name
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.trail-unauthorised.arn]
}
