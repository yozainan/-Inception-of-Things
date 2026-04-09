#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 3: K3d + Argo CD Setup Script
#  This script installs ALL necessary tools and sets up the environment
#  Run this during defense to reproduce the setup from scratch
# ═══════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Inception-of-Things — Part 3 Setup                    ║"
echo "║      K3d + Argo CD + GitOps Deployment                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Install Docker (if not present) ───────────────────────────
echo ">>> [P3] Step 1: Checking Docker..."
if ! command -v docker &>/dev/null; then
    echo ">>> [P3] Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo ">>> [P3] Docker installed. You may need to log out/in for group changes."
else
    echo ">>> [P3] Docker already installed: $(docker --version)"
fi

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# ── Step 2: Install kubectl ──────────────────────────────────────────
echo ">>> [P3] Step 2: Installing kubectl..."
if ! command -v kubectl &>/dev/null; then
    curl -Lo /tmp/kubectl "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
    echo ">>> [P3] kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null)"
else
    echo ">>> [P3] kubectl already installed."
fi

# ── Step 3: Install K3d ──────────────────────────────────────────────
echo ">>> [P3] Step 3: Installing K3d..."
if ! command -v k3d &>/dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo ">>> [P3] K3d installed: $(k3d version)"
else
    echo ">>> [P3] K3d already installed: $(k3d version)"
fi

# ── Step 4: Install Helm ─────────────────────────────────────────────
echo ">>> [P3] Step 4: Installing Helm..."
if ! command -v helm &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo ">>> [P3] Helm installed: $(helm version --short)"
else
    echo ">>> [P3] Helm already installed."
fi

# ── Step 5: Delete existing K3d cluster (clean start) ────────────────
echo ">>> [P3] Step 5: Cleaning up any existing K3d cluster..."
k3d cluster delete iot-p3 2>/dev/null || true

# ── Step 6: Create K3d cluster with port mapping ─────────────────────
echo ">>> [P3] Step 6: Creating K3d cluster 'iot-p3'..."
k3d cluster create iot-p3 \
    --port "8888:8888@loadbalancer" \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --wait

echo ">>> [P3] K3d cluster created. Waiting for node to be Ready..."
TIMEOUT=120
ELAPSED=0
while ! kubectl get node 2>/dev/null | grep -q "Ready"; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [P3] ERROR: K3d node not Ready within ${TIMEOUT}s"
        kubectl get nodes 2>/dev/null || true
        exit 1
    fi
    echo "    Waiting for node... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ">>> [P3] K3d cluster is Ready!"

# ── Step 7: Create namespaces ────────────────────────────────────────
echo ">>> [P3] Step 7: Creating namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
echo ">>> [P3] Namespaces 'argocd' and 'dev' created."

# ── Step 8: Install Argo CD in 'argocd' namespace ────────────────────
echo ">>> [P3] Step 8: Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ">>> [P3] Waiting for Argo CD pods to be Running..."
TIMEOUT=300
ELAPSED=0
while true; do
    TOTAL=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
    READY=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep "Running" | wc -l)
    if [ "$TOTAL" -gt 0 ] && [ "$TOTAL" -eq "$READY" ]; then
        break
    fi
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [P3] WARNING: Not all Argo CD pods Ready within ${TIMEOUT}s"
        kubectl get pods -n argocd 2>/dev/null || true
        echo ">>> [P3] Continuing anyway — some pods may still be initializing..."
        break
    fi
    echo "    Argo CD pods: ${READY}/${TOTAL} Running... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done
echo ">>> [P3] Argo CD installed!"

# ── Step 9: Configure Argo CD — disable TLS for simplicity ───────────
echo ">>> [P3] Step 9: Patching Argo CD server for insecure access..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Patch the argocd-server deployment to add --insecure flag
kubectl -n argocd patch deployment argocd-server --type='json' \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--insecure"}]' 2>/dev/null || \
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
    -p '{"data": {"server.insecure": "true"}}' 2>/dev/null || true

# Wait for argocd-server to restart
echo ">>> [P3] Waiting for Argo CD server to restart..."
sleep 10
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s 2>/dev/null || true

# ── Step 10: Get Argo CD admin password ──────────────────────────────
echo ">>> [P3] Step 10: Retrieving Argo CD admin credentials..."
ARGOCD_PASSWORD=""
TIMEOUT=60
ELAPSED=0
while [ -z "$ARGOCD_PASSWORD" ]; do
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || true)
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [P3] WARNING: Could not retrieve ArgoCD password within ${TIMEOUT}s"
        break
    fi
    if [ -z "$ARGOCD_PASSWORD" ]; then
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Argo CD Admin Credentials                                 ║"
echo "║  Username: admin                                           ║"
echo "║  Password: ${ARGOCD_PASSWORD:-<check manually>}            ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Save password for testing script
echo "$ARGOCD_PASSWORD" > "$PROJECT_DIR/confs/.argocd-password"

# ── Step 11: Port-forward Argo CD (background) ──────────────────────
echo ">>> [P3] Step 11: Setting up port-forward for Argo CD UI..."
# Kill any existing port-forwards
pkill -f "port-forward.*argocd" 2>/dev/null || true
sleep 2

# Start port-forward in background
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 \
    > /tmp/argocd-portforward.log 2>&1 &
echo ">>> [P3] Argo CD UI available at: https://localhost:8080"

# ── Step 12: Port-forward the dev app (background) ───────────────────
echo ">>> [P3] Step 12: Will set up app port-forward after deployment..."

# ── Step 13: Apply Argo CD Application CRD ───────────────────────────
echo ">>> [P3] Step 13: Applying Argo CD Application..."
kubectl apply -f "$PROJECT_DIR/confs/argocd-app.yaml"

echo ">>> [P3] Waiting for Argo CD to sync the application..."
TIMEOUT=180
ELAPSED=0
while true; do
    POD_COUNT=$(kubectl get pods -n dev --no-headers 2>/dev/null | wc -l)
    POD_RUNNING=$(kubectl get pods -n dev --no-headers 2>/dev/null | grep "Running" | wc -l)
    if [ "$POD_COUNT" -gt 0 ] && [ "$POD_COUNT" -eq "$POD_RUNNING" ]; then
        echo ">>> [P3] Application pod is Running in 'dev' namespace!"
        break
    fi
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [P3] WARNING: App pod not Ready within ${TIMEOUT}s"
        kubectl get pods -n dev 2>/dev/null || true
        kubectl get application -n argocd 2>/dev/null || true
        break
    fi
    echo "    Waiting for app pod in 'dev'... pods: ${POD_RUNNING}/${POD_COUNT} (${ELAPSED}s/${TIMEOUT}s)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

# ── Step 14: Port-forward the dev app ────────────────────────────────
echo ">>> [P3] Step 14: Setting up port-forward for dev app..."
pkill -f "port-forward.*8888" 2>/dev/null || true
sleep 2

nohup kubectl port-forward svc/wil-playground-svc -n dev 8888:8888 --address 0.0.0.0 \
    > /tmp/app-portforward.log 2>&1 &

# Wait for port-forward to establish
sleep 5

# ── Step 15: Verify deployment ───────────────────────────────────────
echo ">>> [P3] Step 15: Verifying deployment..."
echo ""
echo "── Namespaces ─────────────────────────────────────────────────"
kubectl get namespaces | grep -E "argocd|dev"
echo ""
echo "── Pods in 'argocd' ─────────────────────────────────────────"
kubectl get pods -n argocd
echo ""
echo "── Pods in 'dev' ────────────────────────────────────────────"
kubectl get pods -n dev
echo ""
echo "── Application Status ───────────────────────────────────────"
echo -n "  curl http://localhost:8888/ → "
curl -s http://localhost:8888/ 2>/dev/null || echo "(not responding yet — may need a moment)"
echo ""

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Part 3 — Setup COMPLETE                               ║"
echo "║                                                            ║"
echo "║  Argo CD UI:  https://localhost:8080                       ║"
echo "║  App:         http://localhost:8888                         ║"
echo "║  Admin:       admin / ${ARGOCD_PASSWORD:-<see above>}      ║"
echo "║                                                            ║"
echo "║  To test v1→v2 upgrade:                                    ║"
echo "║  1. Edit p3/confs/app/deployment.yaml                      ║"
echo "║  2. Change 'wil42/playground:v1' to 'wil42/playground:v2'  ║"
echo "║  3. git add + commit + push                                ║"
echo "║  4. Wait for Argo CD to sync (~3 min)                      ║"
echo "║  5. curl http://localhost:8888/ → should show v2           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
