data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "template_file" "helm_values_template" {
  template = file("${path.module}/templates/values.tpl.yaml")
  vars = {
    POSTGRESQL_HOST     = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_address : module.aurora[0].cluster_endpoint
    POSTGRESQL_PASSWORD = var.db_type == "rds-postgresql" ? module.rds[0].db_instance_password : module.aurora[0].cluster_master_password
  }
}

resource "local_file" "helm_values" {
  filename = "${path.module}/out/values.yaml"
  content  = data.template_file.helm_values_template.rendered
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
}
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  depends_on = [helm_release.istio_base]
  set {
    name  = "meshConfig.defaultConfig.envoyMetricsService.address"
    value = "${helm_release.skywalking.name}-skywalking-helm-oap.${helm_release.skywalking.namespace}:11800"
  }
  set {
    name  = "meshConfig.defaultConfig.envoyAccessLogService.address"
    value = "${helm_release.skywalking.name}-skywalking-helm-oap.${helm_release.skywalking.namespace}:11800"
  }
  set {
    name  = "meshConfig.enableEnvoyAccessLogService"
    value = true
  }
}
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata.0.name
  depends_on = [helm_release.istiod]
}

resource "helm_release" "skywalking" {
  name      = "skywalking"
  chart     = "oci://ghcr.io/apache/skywalking-kubernetes/skywalking-helm"
  version   = "0.0.0-b670c41d94a82ddefcf466d54bab5c492d88d772"
  namespace = kubernetes_namespace.istio_system.metadata.0.name
  values    = [data.template_file.helm_values_template.rendered]
  wait      = false
}

data "kubectl_path_documents" "locust_docs" {
  pattern = "${path.module}/../kubernetes/locust.yaml"
  vars = {
    "locust_master_replicas" = var.locust_master_replicas
    "locust_worker_replicas" = var.locust_worker_replicas
    "locust_users"           = var.locust_users
  }
}
resource "kubectl_manifest" "locust" {
  for_each  = toset(data.kubectl_path_documents.locust_docs.documents)
  yaml_body = each.value
}
