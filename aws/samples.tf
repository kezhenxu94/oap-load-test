resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
    labels = {
      "istio-injection" : "enabled"
    }
  }
}

data "template_file" "sample_configmap" {
  count    = var.services_count
  template = file(count.index == var.services_count - 1 ? "${path.module}/../kubernetes/sample-conf-leaf.tpl.yaml" : "${path.module}/../kubernetes/sample-conf.tpl.yaml")
  vars = {
    configmap_name = "service${count.index}-conf"
    namespace      = kubernetes_namespace.test.metadata[0].name
    next_service   = "service${count.index + 1}"
  }
}
data "template_file" "sample_deployment" {
  count    = var.services_count
  template = file("${path.module}/../kubernetes/sample-deployment.tpl.yaml")
  vars = {
    service_name = "service${count.index}"
    namespace    = kubernetes_namespace.test.metadata[0].name
    configmap    = "service${count.index}-conf"
    replicas     = lookup(var.services_replicas, "service${count.index}", var.services_default_replicas)
  }
}
data "template_file" "sample_service" {
  depends_on = [helm_release.istiod]
  count      = var.services_count
  template   = file("${path.module}/../kubernetes/sample-service.tpl.yaml")
  vars = {
    service_name = "service${count.index}"
    namespace    = kubernetes_namespace.test.metadata[0].name
  }
}

resource "kubectl_manifest" "sample_service" {
  count     = var.services_count
  yaml_body = data.template_file.sample_service[count.index].rendered
}
resource "kubectl_manifest" "sample_configmap" {
  count     = var.services_count
  yaml_body = data.template_file.sample_configmap[count.index].rendered
}
resource "kubectl_manifest" "sample_deployment" {
  depends_on = [helm_release.istiod, kubectl_manifest.sample_service]
  count      = var.services_count
  yaml_body  = data.template_file.sample_deployment[var.services_count - count.index - 1].rendered
}
