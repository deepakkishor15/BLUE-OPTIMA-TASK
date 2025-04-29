#!/bin/bash

NAMESPACES=("namespace1" "namespace2")
ALPINE_POD="alpine-pod"
SERVICE_NAME="nginx-service"

echo "===== NAMESPACE CONNECTIVITY TEST ====="

for i in 0 1; do
  user_ns="${NAMESPACES[$i]}"
  other_ns="${NAMESPACES[$((1-i))]}"

  echo
  echo "🔍 Checking from $ALPINE_POD in $user_ns"
  echo "----------------------------------------"

  # Own service - Port 80
  echo -n "Own service (port 80): "
  kubectl exec -n "$user_ns" "$ALPINE_POD" -- sh -c "curl -s http://$SERVICE_NAME.$user_ns.svc.cluster.local:80" >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Own service - Port 8080
  echo -n "Own service (port 8080): "
  kubectl exec -n "$user_ns" "$ALPINE_POD" -- sh -c "curl -s http://$SERVICE_NAME.$user_ns.svc.cluster.local:8080" >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Other user's service - Port 80 (should work)
  echo -n "Other user’s service (port 80): "
  kubectl exec -n "$user_ns" "$ALPINE_POD" -- sh -c "curl -s http://$SERVICE_NAME.$other_ns.svc.cluster.local:80" >/dev/null && \
    echo "✅ SUCCESS" || echo "❌ FAILED"

  # Other user's service - Port 8080 (should fail - blocked)
  echo -n "Other user’s service (port 8080 - should be blocked): "
  kubectl exec -n "$user_ns" "$ALPINE_POD" -- sh -c "curl -s --max-time 3 http://$SERVICE_NAME.$other_ns.svc.cluster.local:8080" >/dev/null && \
    echo "❌ UNEXPECTED SUCCESS (Check NetworkPolicy!)" || echo "✅ BLOCKED (Expected)"

done

echo
echo "===== TEST COMPLETE ====="
