output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "database_address" {
  value = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_address : module.aurora[0].cluster_endpoint
}

output "database_port" {
  value = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_port : module.aurora[0].cluster_port
}

output "locust_address" {
  value = "run command `open http://$(kubectl get svc -n locust -l app=locust-master -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'):8089`"
}

output "skywalking_ui_address" {
  value = "run command `kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=skywalking -l component=ui -o name) 8080:8080`"
}
