#!/bin/bash

# Set the namespaces and pod names
NAMESPACE1="namespace1"
NAMESPACE2="namespace2"
POD1="alpine-pod"
NGINX_SERVICE="nginx-service"

# Function to check pod and service status
check_pod_and_service() {
  local namespace=$1
  echo "Checking pods in namespace $namespace..."
  kubectl get pods -n "$namespace"
  
  echo "Checking services in namespace $namespace..."
  kubectl get svc -n "$namespace"
}

# Function to check if curl is installed
check_curl_installed() {
  echo "Checking if curl is installed in $POD1 in $NAMESPACE1..."
  kubectl exec -n "$NAMESPACE1" "$POD1" -- which curl
  if [ $? -ne 0 ]; then
    echo "❌ curl is not installed in $POD1 in $NAMESPACE1"
    exit 1
  fi
}

# Function to test connectivity
test_connectivity() {
  local from_namespace=$1
  local to_namespace=$2
  local port=$3

  echo "Testing connectivity from $POD1 in $from_namespace to $NGINX_SERVICE in $to_namespace on port $port..."
  
  kubectl exec -n "$from_namespace" "$POD1" -- curl -s -o /dev/null -w "%{http_code}" "$NGINX_SERVICE.$to_namespace.svc.cluster.local:$port"
  if [ $? -eq 0 ]; then
    echo "✅ SUCCESS"
  else
    echo "❌ FAILED - Service unreachable"
  fi
}

# Check if nginx service is running and exposed
check_pod_and_service "$NAMESPACE1"
check_pod_and_service "$NAMESPACE2"

# Check if curl is installed in alpine pod
check_curl_installed

# Test connectivity from alpine pod in namespace1 to own service and other service (namespace2)
test_connectivity "$NAMESPACE1" "$NAMESPACE1" 80
test_connectivity "$NAMESPACE1" "$NAMESPACE1" 8080
test_connectivity "$NAMESPACE1" "$NAMESPACE2" 80
test_connectivity "$NAMESPACE1" "$NAMESPACE2" 8080

# Test connectivity from alpine pod in namespace2 to own service and other service (namespace1)
test_connectivity "$NAMESPACE2" "$NAMESPACE2" 80
test_connectivity "$NAMESPACE2" "$NAMESPACE2" 8080
test_connectivity "$NAMESPACE2" "$NAMESPACE1" 80
test_connectivity "$NAMESPACE2" "$NAMESPACE1" 8080

echo "===== TEST COMPLETE ====="
