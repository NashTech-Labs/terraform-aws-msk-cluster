resource "aws_cloudwatch_log_group" "kafka" {
  name              = var.cluster_name
  retention_in_days = 14
}

module "ec2_security_group" {
  source              = "./modules/security-group"
  name                = "${var.cluster_name}-msk"
  description         = "Security group for MSK "
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules = [
  "all-all"]
  egress_rules = [
  "all-all"]
}

resource "random_string" "random" {
  length  = 8
  special = false
}

resource "aws_msk_configuration" "configuration" {
  kafka_versions = [var.kafka_version]
  name           = "${var.cluster_name}-${random_string.random.result}"

  server_properties = <<PROPERTIES
auto.create.topics.enable = true
delete.topic.enable = true
group.max.session.timeout.ms = 18000
group.min.session.timeout.ms = 6000
transaction.max.timeout.ms = 6000
min.insync.replicas = 1
PROPERTIES
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = var.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = 2
  broker_node_group_info {
    client_subnets  = var.subnet_ids
    ebs_volume_size = 500
    instance_type   = "kafka.m5.large"
    security_groups = [module.ec2_security_group.this_security_group_id]
  }


  configuration_info {
    arn      = aws_msk_configuration.configuration.arn
    revision = 1
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.kafka.name
      }
    }
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.kafka.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.kafka.bootstrap_brokers_tls
}

