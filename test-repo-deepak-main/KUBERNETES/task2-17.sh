#!/bin/bash

# Define the namespaces and pod names for both namespaces
NAMESPACE1="namespace1"
POD_NAME1="nginx-5946ff57f4-nllzg"
NAMESPACE2="namespace2"
POD_NAME2="nginx-5946ff57f4-82fqj"
CONFIG_FILE="/etc/nginx/conf.d/custom_port_8080.conf"

# Command to create the server block configuration for port 8080
CONFIG_CONTENT="server {
    listen 8080;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}"

# Function to add the configuration and reload Nginx for a given namespace and pod
add_nginx_config() {
    local NAMESPACE="$1"
    local POD_NAME="$2"

    echo "Accessing the Nginx pod in $NAMESPACE..."
    kubectl exec -n "$NAMESPACE" -it "$POD_NAME" -- echo "Pod accessible" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to access the Nginx pod in $NAMESPACE. Please check if the pod is running."
        return 1
    fi

    echo "Adding the configuration for port 8080 in $NAMESPACE..."
    kubectl exec -n "$NAMESPACE" -it "$POD_NAME" -- sh -c "echo \"$CONFIG_CONTENT\" > $CONFIG_FILE"

    echo "Reloading Nginx configuration in $NAMESPACE..."
    kubectl exec -n "$NAMESPACE" -it "$POD_NAME" -- nginx -s reload

    # Verify the new configuration by making a request to localhost:8080 inside the pod
    echo "Verifying if Nginx is listening on port 8080 in $NAMESPACE..."
    kubectl exec -n "$NAMESPACE" -it "$POD_NAME" -- curl -s localhost:8080

    if [ $? -eq 0 ]; then
        echo "Nginx is now successfully serving on port 8080 in $NAMESPACE."
    else
        echo "Failed to connect to Nginx on port 8080 in $NAMESPACE."
        return 1
    fi
}

# Add Nginx configuration for namespace1 and namespace2
add_nginx_config "$NAMESPACE1" "$POD_NAME1"
if [ $? -ne 0 ]; then
    echo "Failed to configure Nginx in $NAMESPACE1."
    exit 1
fi

add_nginx_config "$NAMESPACE2" "$POD_NAME2"
if [ $? -ne 0 ]; then
    echo "Failed to configure Nginx in $NAMESPACE2."
    exit 1
fi

echo "Script execution completed successfully for both namespaces."




kubectl exec -n namespace1 -it nginx-5946ff57f4-nllzg -- nginx -s reload
kubectl logs -n namespace1 nginx-5946ff57f4-nllzg
kubectl exec -n namespace1 -it alpine-pod -- curl nginx-service:8080

