#!/bin/bash

# Step 1: Create Services in each namespace to expose nginx ports 80 and 8080
for ns in namespace1 namespace2; do
  cat <<EOF | kubectl apply -n $ns -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx-dual
  ports:
  - name: http-80
    port: 80
    targetPort: 80
  - name: http-8080
    port: 8080
    targetPort: 8080
EOF
done

# Step 2: Apply NetworkPolicy to restrict port 8080 cross-namespace
for ns in namespace1 namespace2; do
  cat <<EOF | kubectl apply -n $ns -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-8080-access
spec:
  podSelector:
    matchLabels:
      app: nginx-dual
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: $ns
    ports:
    - port: 80
    - port: 8080
  - from:
    - namespaceSelector: {}
    ports:
    - port: 80
EOF
done

echo "✅ Services created and network policies applied."
echo "🧪 You can now test using the alpine pods in each namespace."
