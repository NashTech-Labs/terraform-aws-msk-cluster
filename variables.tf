variable "subnet_ids" {
  type = "list"
}

variable "cluster_name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "environment" {
  type  = "string"
}

variable "ingress_cidr_blocks" {
  type = "list"
}

variable "kafka_version" {
  type = "string"
}
