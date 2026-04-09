#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  yozainan-bonus — K3d + ArgoCD + Local GitLab CE
# ═══════════════════════════════════════════════════════════════════════

export DEBIAN_FRONTEND=noninteractive

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   yozainan-bonus — Bonus Part Initialization                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Install Dependencies ──────────────────────────────────────
echo ">>> [yozainan-bonus] Installing Docker & Dependencies..."
apt-get update -y
apt-get install -y curl net-tools apt-transport-https ca-certificates gnupg jq jq

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker vagrant
fi

# ── Step 2: Install K3d ───────────────────────────────────────────────
echo ">>> [yozainan-bonus] Installing K3d..."
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# ── Step 3: Install Kubectl & Helm ────────────────────────────────────
echo ">>> [yozainan-bonus] Installing kubectl & helm..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# ── Step 4: Create K3d Cluster ────────────────────────────────────────
echo ">>> [yozainan-bonus] Creating K3d Cluster..."
k3d cluster create bonus-cluster -p "8888:8888@loadbalancer" -p "8080:80@loadbalancer" --servers 1 --agents 0 || true

mkdir -p /home/vagrant/.kube
k3d kubeconfig get bonus-cluster > /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
export KUBECONFIG=/home/vagrant/.kube/config
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

# ── Step 5: Setup Namespaces ──────────────────────────────────────────
echo ">>> [yozainan-bonus] Setting up Namespaces..."
kubectl create namespace argocd || true
kubectl create namespace dev || true
kubectl create namespace gitlab || true

# ── Step 6: Install GitLab Local Instance ─────────────────────────────
echo ">>> [yozainan-bonus] Deploying GitLab CE to cluster..."
kubectl apply -f /vagrant/confs/gitlab.yaml

echo ">>> [yozainan-bonus] Waiting for GitLab to spin up (This takes ~10 minutes)..."
# GitLab initialization takes an extraordinarily long time
kubectl wait --for=condition=available deployment/gitlab -n gitlab --timeout=900s

echo ">>> [yozainan-bonus] Bootstrapping GitLab Repository..."
bash /vagrant/scripts/gitlab_seeder.sh

# ── Step 7: Install ArgoCD ────────────────────────────────────────────
echo ">>> [yozainan-bonus] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ">>> [yozainan-bonus] Waiting for ArgoCD Server to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# ── Step 8: Apply ArgoCD Application Mapping ──────────────────────────
echo ">>> [yozainan-bonus] Binding ArgoCD to local GitLab..."
kubectl apply -f /vagrant/confs/argocd-app.yaml

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Bonus setup completed successfully!                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
