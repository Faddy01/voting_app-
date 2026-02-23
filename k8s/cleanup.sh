#!/bin/bash
# ========================================
# Voting App Cleanup Script
# ========================================

# --- CONFIG ---
NAMESPACE="vote-app"                  # Namespace where your app is deployed
DOCKER_IMAGES=("vote" "result" "worker") # Your Docker images to remove
DOCKER_USER="yourdockerhubusername"      # Docker Hub username

echo "=== STEP 1: Delete Kubernetes namespace ==="
kubectl delete namespace $NAMESPACE --ignore-not-found
echo "Namespace $NAMESPACE deleted (if it existed)."

echo
echo "=== STEP 2: Prune all Docker images, containers, volumes ==="
docker system prune -a --volumes -f
echo "Docker environment cleaned."

echo
echo "=== STEP 3: Remove specific Docker images from Docker Hub username ==="
for img in "${DOCKER_IMAGES[@]}"; do
    docker rmi $DOCKER_USER/$img:latest 2>/dev/null || echo "$img not found locally."
done

echo
echo "✅ Cleanup complete! Your cluster and local Docker environment are now clean."