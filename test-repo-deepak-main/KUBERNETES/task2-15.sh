#!/bin/bash

# Set variables for namespaces and services
NAMESPACE1="namespace1"
NAMESPACE2="namespace2"
NGINX_SERVICE="nginx-service"

# Define the NetworkPolicy YAML files for each namespace
cat <<EOF > allow-http-namespace1.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-http
  namespace: $NAMESPACE1
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
    - ports:
        - protocol: TCP
          port: 80
EOF

cat <<EOF > allow-http-namespace2.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-http
  namespace: $NAMESPACE2
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
    - ports:
        - protocol: TCP
          port: 80
EOF

# Apply the NetworkPolicies
kubectl apply -f allow-http-namespace1.yaml
kubectl apply -f allow-http-namespace2.yaml

# Define nginx Deployment YAML
cat <<EOF > nginx-deployment-namespace1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: $NAMESPACE1
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
            - containerPort: 8080
EOF

cat <<EOF > nginx-deployment-namespace2.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: $NAMESPACE2
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
            - containerPort: 8080
EOF

# Apply the nginx Deployments
kubectl apply -f nginx-deployment-namespace1.yaml
kubectl apply -f nginx-deployment-namespace2.yaml

# Define nginx Service YAML
cat <<EOF > nginx-service-namespace1.yaml
apiVersion: v1
kind: Service
metadata:
  name: $NGINX_SERVICE
  namespace: $NAMESPACE1
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
      port: 8080
      targetPort: 8080
EOF

cat <<EOF > nginx-service-namespace2.yaml
apiVersion: v1
kind: Service
metadata:
  name: $NGINX_SERVICE
  namespace: $NAMESPACE2
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
      port: 8080
      targetPort: 8080
EOF

# Apply the nginx Services
kubectl apply -f nginx-service-namespace1.yaml
kubectl apply -f nginx-service-namespace2.yaml

# Deploy alpine pod and install curl
cat <<EOF > alpine-pod-namespace1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod
  namespace: $NAMESPACE1
spec:
  containers:
    - name: alpine
      image: alpine
      command: ["sleep", "3600"]
EOF

cat <<EOF > alpine-pod-namespace2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod
  namespace: $NAMESPACE2
spec:
  containers:
    - name: alpine
      image: alpine
      command: ["sleep", "3600"]
EOF

# Apply the alpine pods
kubectl apply -f alpine-pod-namespace1.yaml
kubectl apply -f alpine-pod-namespace2.yaml

# Install curl inside the alpine pods
kubectl exec -n $NAMESPACE1 alpine-pod -- apk add --no-cache curl
kubectl exec -n $NAMESPACE2 alpine-pod -- apk add --no-cache curl

# Run your connectivity test script
echo "===== NAMESPACE CONNECTIVITY TEST ====="

for ns in $NAMESPACE1 $NAMESPACE2; do
  echo "🔍 Checking from alpine-pod in $ns"
  echo "----------------------------------------"

  # Own service - Port 80
  echo -n "Own service (port 80): "
  kubectl exec -n "$ns" alpine-pod -- curl -s http://$NGINX_SERVICE.$ns.svc.cluster.local:80 >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Own service - Port 8080
  echo -n "Own service (port 8080): "
  kubectl exec -n "$ns" alpine-pod -- curl -s http://$NGINX_SERVICE.$ns.svc.cluster.local:8080 >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Other user's service - Port 80
  other_ns=$([ "$ns" == "$NAMESPACE1" ] && echo "$NAMESPACE2" || echo "$NAMESPACE1")
  echo -n "Other user’s service (port 80): "
  kubectl exec -n "$ns" alpine-pod -- curl -s http://$NGINX_SERVICE.$other_ns.svc.cluster.local:80 >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Other user's service - Port 8080 (should be blocked)
  echo -n "Other user’s service (port 8080 - should be blocked): "
  kubectl exec -n "$ns" alpine-pod -- curl -s --max-time 3 http://$NGINX_SERVICE.$other_ns.svc.cluster.local:8080 >/dev/null && \
    echo "❌ UNEXPECTED SUCCESS (Check NetworkPolicy!)" || echo "✅ BLOCKED (Expected)"
done

echo
echo "===== TEST COMPLETE ====="
