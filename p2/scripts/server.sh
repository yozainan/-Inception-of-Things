#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  yozainan-S — K3s Server + Three Apps Provisioning (Part 2)
# ═══════════════════════════════════════════════════════════════════════

SERVER_IP="$1"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   yozainan-S — Part 2: K3s Server + 3 Apps Provisioning    ║"
echo "║   Role: Server Mode + Ingress + 3 Web Applications        ║"
echo "║   IP:   ${SERVER_IP}                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Install dependencies ──────────────────────────────────────
echo ">>> [yozainan-S] Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl net-tools

# ── Step 2: Create swap (idempotent — safe for re-provision) ──────────
echo ">>> [yozainan-S] Setting up swap space..."
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

# ── Step 3: Install K3s in SERVER mode ────────────────────────────────
#    NOTE: Traefik is KEPT ENABLED (needed for Ingress routing)
#    NOTE: No version pin — installs latest stable
echo ">>> [yozainan-S] Installing K3s in SERVER mode (with Traefik)..."
export INSTALL_K3S_EXEC="server \
  --write-kubeconfig-mode 644 \
  --node-ip ${SERVER_IP} \
  --bind-address ${SERVER_IP} \
  --advertise-address ${SERVER_IP} \
  --kubelet-arg=fail-swap-on=false"

curl -sfL https://get.k3s.io | sh -

# ── Step 4: Wait for K3s node to become Ready ─────────────────────────
echo ">>> [yozainan-S] Waiting for K3s node to become Ready..."
# KUBECONFIG already exported at top of script
TIMEOUT=180
ELAPSED=0
while ! kubectl get node 2>/dev/null | grep -q "Ready"; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [yozainan-S] ERROR: K3s node not Ready within ${TIMEOUT}s"
        systemctl status k3s --no-pager || true
        journalctl -u k3s --no-pager -n 30 || true
        exit 1
    fi
    echo "    Waiting for K3s node to be Ready... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ">>> [yozainan-S] K3s node is Ready!"

# ── Step 5: Wait for Traefik Ingress Controller ──────────────────────
echo ">>> [yozainan-S] Waiting for Traefik Ingress Controller..."
TIMEOUT=180
ELAPSED=0
# Use the instance label which is consistent across K3s Traefik versions
while ! kubectl get pods -n kube-system 2>/dev/null | grep -E "traefik" | grep -q "Running"; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [yozainan-S] ERROR: Traefik not Running within ${TIMEOUT}s"
        kubectl get pods -n kube-system --no-headers || true
        exit 1
    fi
    echo "    Waiting for Traefik to be Running... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ">>> [yozainan-S] Traefik Ingress Controller is Running!"
# Give Traefik 5s to fully bind its ports before we apply ingress rules
sleep 5

# ── Step 6: Deploy the three web applications ─────────────────────────
echo ">>> [yozainan-S] Deploying 3 web applications..."
kubectl apply -f /vagrant/confs/apps.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

# ── Step 7: Wait for all pods to be Ready ─────────────────────────────
echo ">>> [yozainan-S] Waiting for all app pods to be Ready..."
TIMEOUT=120
ELAPSED=0
while true; do
    TOTAL=$(kubectl get pods --no-headers 2>/dev/null | wc -l)
    READY=$(kubectl get pods --no-headers 2>/dev/null | grep "Running" | wc -l)
    if [ "$TOTAL" -gt 0 ] && [ "$TOTAL" -eq "$READY" ]; then
        break
    fi
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [yozainan-S] WARNING: Not all pods Ready within ${TIMEOUT}s"
        kubectl get pods --no-headers || true
        break
    fi
    echo "    Pods: ${READY}/${TOTAL} Running... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

# ── Step 8: Setup kubectl for vagrant user ────────────────────────────
echo ">>> [yozainan-S] Setting up kubectl for vagrant user..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
sed -i "s/127.0.0.1/${SERVER_IP}/g" /home/vagrant/.kube/config

# ── Step 9: Add kubectl alias ─────────────────────────────────────────
grep -q "alias k=" /home/vagrant/.bashrc 2>/dev/null || \
    echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# ── Step 10: Print final status ───────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  yozainan-S — Part 2 Provisioning COMPLETE             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "── Nodes ──────────────────────────────────────────────────────"
kubectl get nodes -o wide
echo ""
echo "── Pods ───────────────────────────────────────────────────────"
kubectl get pods -o wide
echo ""
echo "── Services ──────────────────────────────────────────────────"
kubectl get svc
echo ""
echo "── Ingress ──────────────────────────────────────────────────"
kubectl get ingress
echo ""
echo "── Routing Summary ──────────────────────────────────────────"
echo "  Host: app1.com  →  app1 (1 replica)"
echo "  Host: app2.com  →  app2 (3 replicas)"
echo "  Default         →  app3 (1 replica)"
echo "═══════════════════════════════════════════════════════════════"
