## General
variable "aws_access_key" {
  type        = string
  description = "AWS access key"
  default     = ""
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key"
  default     = ""
}

variable "region" {
  default     = "ap-east-1"
  description = "AWS region"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

## EKS
variable "cluster_name" {
  type    = string
  default = "skywalking-load-test"
}

variable "cluster_node_instance_types" {
  type    = list(string)
  default = ["m6i.2xlarge"]
}

variable "cluster_node_size" {
  type = map(number)
  default = {
    min     = 1
    max     = 3
    desired = 3
  }
}

## Database

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database root password"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "skywalking"
}

variable "db_type" {
  description = "Database type, RDS postgresql or Aurora postgresql"
  type        = string
  default     = "rds-postgresql"

  validation {
    condition     = contains(["aurora-postgresql", "rds-postgresql"], var.db_type)
    error_message = "Database type must be either aurora-postgresql or rds-postgresql."
  }
}

## VPC
variable "cidr" {
  description = "CIDR for database tier"
  default     = "11.0.0.0/16"
}

variable "private_subnets" {
  description = "CIDR used for db private subnets"
  default     = ["11.0.1.0/24", "11.0.2.0/24", "11.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR used for db public subnets"
  default     = ["11.0.101.0/24", "11.0.102.0/24", "11.0.103.0/24"]
}

## Services
variable "services_count" {
  default = 2
}

variable "services_default_replicas" {
  default = 10
}

variable "services_replicas" {
  type    = map(number)
  default = {}
}

variable "locust_master_replicas" {
  default = 1
}
variable "locust_worker_replicas" {
  default = 20
}
variable "locust_users" {
  default = 100
}
