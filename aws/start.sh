set -e

export ACCOUNT_ID
export REGION=ap-east-1
export CLUSTER=skywalking-test
export LOCUST_IMAGE=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/locust:latest

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker build --no-cache --push -t $LOCUST_IMAGE locust

aws eks --region $REGION update-kubeconfig --name $CLUSTER

kubectl label namespace test istio-injection=enabled --overwrite

for manifest in $(ls kubernetes/*.yaml); do
  cat "$manifest" | envsubst | kubectl -n locust apply -f -
done

kubectl apply -f monitoring

sh sample/deploy.sh

kubectl -n locust scale deployment/locust-worker --replicas 10
kubectl -n test scale deployment/service1 --replicas 30
kubectl -n test scale deployment/service2 --replicas 10

helm -n istio-system upgrade --install skywalking \
  oci://ghcr.io/apache/skywalking-kubernetes/skywalking-helm \
  --version "0.0.0-b670c41d94a82ddefcf466d54bab5c492d88d772" \
  --set elasticsearch.enabled=false \
  --set oap.replicas=2 \
  --set ui.image.repository=ghcr.io/apache/skywalking/ui \
  --set ui.image.tag=2fa821d9f5b6ace1d510db79d5a9e47fad7f78b3 \
  --set oap.image.tag=2fa821d9f5b6ace1d510db79d5a9e47fad7f78b3 \
  --set oap.image.repository=ghcr.io/apache/skywalking/oap \
  --set oap.storageType=postgresql \
  --set oap.env.SW_TELEMETRY=prometheus \
  --set oap.env.SW_ENVOY_METRIC_ALS_HTTP_ANALYSIS="mx-mesh\,k8s-mesh" \
  --set oap.env.SW_ENVOY_METRIC_ALS_TCP_ANALYSIS="mx-mesh\,k8s-mesh" \
  --set oap.envoy.als.enabled=true \
  --set oap.ports.http-monitoring=1234 \
  --set postgresql.config.host="$PSQL_HOST" \
  --set postgresql.auth.password="$PSQL_PASSWORD"
