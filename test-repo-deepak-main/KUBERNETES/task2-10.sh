#!/bin/bash

# Set namespaces
NS1=namespace1
NS2=namespace2

echo "Creating namespaces..."
kubectl create ns $NS1 --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns $NS2 --dry-run=client -o yaml | kubectl apply -f -

# Define the nginx + socat deployment YAML
DEPLOYMENT_YAML=$(cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
      - name: proxy-8080
        image: alpine/socat
        args: ["tcp-listen:8080,fork,reuseaddr", "tcp-connect:127.0.0.1:80"]
        ports:
        - containerPort: 8080
EOF
)

# Apply deployments in both namespaces
echo "Deploying nginx + socat in $NS1 and $NS2..."
echo "$DEPLOYMENT_YAML" | kubectl apply -n $NS1 -f -
echo "$DEPLOYMENT_YAML" | kubectl apply -n $NS2 -f -

# Expose as ClusterIP service
kubectl expose deployment nginx-deployment --port=80 --target-port=80 -n $NS1 --name=nginx-service
kubectl expose deployment nginx-deployment --port=80 --target-port=80 -n $NS2 --name=nginx-service

# Create alpine pod for testing
kubectl run alpine-pod -n $NS1 --image=alpine --restart=Never --command -- sleep 3600 || echo "alpine-pod already exists"

# Network policy to block ingress to port 8080 from other namespaces
cat <<EOF | kubectl apply -n $NS2 -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-8080-from-other-namespaces
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: $NS2
    ports:
    - protocol: TCP
      port: 8080
EOF

# Label namespace2 to match the policy
kubectl label namespace $NS2 name=$NS2 --overwrite

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/nginx-deployment -n $NS1
kubectl wait --for=condition=available --timeout=60s deployment/nginx-deployment -n $NS2

echo "Setup complete."

echo "Testing connections from $NS1 alpine pod..."

# Test 1: From alpine to nginx in same namespace (should work on both ports)
kubectl exec -n $NS1 alpine-pod -- curl -s -o /dev/null -w "%{http_code}" nginx-service.$NS1.svc.cluster.local:80
echo " <-- HTTP to port 80 in same namespace"

kubectl exec -n $NS1 alpine-pod -- curl -s -o /dev/null -w "%{http_code}" nginx-service.$NS1.svc.cluster.local:8080
echo " <-- HTTP to port 8080 in same namespace"

# Test 2: From alpine to nginx in other namespace
kubectl exec -n $NS1 alpine-pod -- curl -s -o /dev/null -w "%{http_code}" nginx-service.$NS2.svc.cluster.local:80
echo " <-- HTTP to port 80 in other namespace"

kubectl exec -n $NS1 alpine-pod -- curl -s -o /dev/null -w "%{http_code}" nginx-service.$NS2.svc.cluster.local:8080
echo " <-- HTTP to port 8080 in other namespace (should be blocked)"
