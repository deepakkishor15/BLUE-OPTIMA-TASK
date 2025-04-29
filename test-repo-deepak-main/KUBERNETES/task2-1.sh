#!/bin/bash

set -e

# Variables
USER1=user1
USER2=user2
NS1=namespace1
NS2=namespace2
CLUSTER_NAME=minikube

# Create namespaces
kubectl create namespace $NS1
kubectl create namespace $NS2

# Generate certificate for user1
openssl genrsa -out ${USER1}.key 2048
openssl req -new -key ${USER1}.key -out ${USER1}.csr -subj "/CN=${USER1}"
openssl x509 -req -in ${USER1}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out ${USER1}.crt -days 365

# Generate certificate for user2
openssl genrsa -out ${USER2}.key 2048
openssl req -new -key ${USER2}.key -out ${USER2}.csr -subj "/CN=${USER2}"
openssl x509 -req -in ${USER2}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out ${USER2}.crt -days 365

# Set Kubernetes credentials
kubectl config set-credentials ${USER1} --client-certificate=${USER1}.crt --client-key=${USER1}.key
kubectl config set-credentials ${USER2} --client-certificate=${USER2}.crt --client-key=${USER2}.key

kubectl config set-context ${USER1}-context --cluster=${CLUSTER_NAME} --namespace=${NS1} --user=${USER1}
kubectl config set-context ${USER2}-context --cluster=${CLUSTER_NAME} --namespace=${NS2} --user=${USER2}

# Role binding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NS1
  name: ${USER1}-role
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER1}-binding
  namespace: $NS1
subjects:
- kind: ServiceAccount
  name: ${USER1}
  namespace: $NS1
roleRef:
  kind: Role
  name: ${USER1}-role
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NS2
  name: ${USER2}-role
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER2}-binding
  namespace: $NS2
subjects:
- kind: ServiceAccount
  name: ${USER2}
  namespace: $NS2
roleRef:
  kind: Role
  name: ${USER2}-role
  apiGroup: rbac.authorization.k8s.io
EOF
