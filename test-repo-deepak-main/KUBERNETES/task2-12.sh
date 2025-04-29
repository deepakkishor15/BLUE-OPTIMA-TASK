#!/bin/bash

# Define namespaces
namespaces=("namespace1" "namespace2")

# Define deployment and service names
deployment="nginx-service"
service="nginx-service"
image="nginx:latest"

# Loop through the namespaces
for namespace in "${namespaces[@]}"; do
  echo "Checking services in namespace $namespace..."

  # Check if the service exists in the current namespace
  echo "Checking $service in namespace $namespace..."
  service_exists=$(kubectl get service $service -n $namespace --ignore-not-found)

  if [[ -z "$service_exists" ]]; then
    echo "Service $service not found in namespace $namespace."
  else
    echo "Service $service found in namespace $namespace."
  fi

  # Check if the deployment exists in the current namespace
  echo "Checking if deployment $deployment exists in namespace $namespace..."
  deployment_exists=$(kubectl get deployment $deployment -n $namespace --ignore-not-found)

  if [[ -z "$deployment_exists" ]]; then
    echo "Deployment $deployment does not exist in namespace $namespace."
    echo "Creating deployment $deployment in namespace $namespace..."

    # Create a deployment for nginx-service
    kubectl create deployment $deployment --image=$image -n $namespace

    # Check if service exists and expose if not
    service_exists=$(kubectl get service $service -n $namespace --ignore-not-found)
    if [[ -z "$service_exists" ]]; then
      kubectl expose deployment $deployment --port=80 --target-port=80 --name=$service -n $namespace
      echo "Service $service exposed for deployment $deployment in namespace $namespace."
    else
      echo "Service $service already exists in namespace $namespace."
    fi

    echo "Deployment $deployment created in namespace $namespace."
  else
    echo "Deployment $deployment already exists in namespace $namespace."
  fi

  echo "--------------------------------------------"
done

echo "All checks complete."
