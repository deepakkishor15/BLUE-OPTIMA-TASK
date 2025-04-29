#!/bin/bash

# Create alpine pods named "alpine-pod" in both namespaces
for ns in namespace1 namespace2; do
  cat <<EOF | kubectl apply -n $ns -f -
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod
spec:
  containers:
  - name: alpine
    image: alpine
    command: ["sh", "-c", "sleep 3600"]
EOF
done

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod/alpine-pod -n namespace1 --timeout=30s
kubectl wait --for=condition=Ready pod/alpine-pod -n namespace2 --timeout=30s

echo "✅ Alpine pods created and ready."
