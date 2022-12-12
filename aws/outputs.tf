output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "database_address" {
  value = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_address : module.aurora[0].cluster_endpoint
}

output "database_port" {
  value = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_port : module.aurora[0].cluster_port
}
