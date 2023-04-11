## How to use

### Create a `.tfvars` and put your configurations

```shell
cat <<EOF > terraform.tfvars
aws_access_key = ""
aws_secret_key = ""
cluster_name   = "skywalking-load-test"
region         = "ap-east-1"
EOF
```

All available variables can be found in [`variables.tf`](variables.tf).

### Initialize Terraform

```shell
terraform init
```

### Apply the resources

```shell
terraform apply -var-file=terraform.tfvars -auto-approve
```

Wait for the command to finish, and open locust in your browser.

```shell
open http://$(kubectl get svc -n locust -l app=locust-master -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'):8089
```

Fill the form and click "Start swarming".

Port forward the SkyWalking UI to your local machine and check the SkyWalking data is correct.

```shell
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=skywalking -l component=ui -o name) 8080:8080
```
