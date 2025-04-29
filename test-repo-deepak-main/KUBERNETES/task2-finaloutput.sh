#!/bin/bash

# Set variables for namespaces and pods
NAMESPACE1="namespace1"
NAMESPACE2="namespace2"
POD1="alpine-pod"
NGINX_SERVICE="nginx-service"

echo "Starting test for NetworkPolicy..."

# Test connectivity from alpine pod in namespace1 to its own nginx-service (port 80 and 8080)
echo "Testing connectivity from $POD1 in $NAMESPACE1 to nginx-service in $NAMESPACE1..."

echo "Testing port 80..."
kubectl exec -n $NAMESPACE1 $POD1 -- curl -s -o /dev/null -w "%{http_code}" $NGINX_SERVICE.$NAMESPACE1.svc.cluster.local:80
echo "Testing port 8080..."
kubectl exec -n $NAMESPACE1 $POD1 -- curl -s -o /dev/null -w "%{http_code}" $NGINX_SERVICE.$NAMESPACE1.svc.cluster.local:8080

# Test connectivity from alpine pod in namespace1 to nginx-service in namespace2 (port 80 and 8080)
echo "Testing connectivity from $POD1 in $NAMESPACE1 to nginx-service in $NAMESPACE2..."

echo "Testing port 80..."
kubectl exec -n $NAMESPACE1 $POD1 -- curl -s -o /dev/null -w "%{http_code}" $NGINX_SERVICE.$NAMESPACE2.svc.cluster.local:80
echo "Testing port 8080..."
kubectl exec -n $NAMESPACE1 $POD1 -- curl -s -o /dev/null -w "%{http_code}" $NGINX_SERVICE.$NAMESPACE2.svc.cluster.local:8080

echo "Test complete."
