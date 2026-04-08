#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  yozainan-SW — K3s Agent (Worker Mode) Provisioning
# ═══════════════════════════════════════════════════════════════════════

SERVER_IP="$1"
TOKEN_FILE="/vagrant/confs/node-token"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          yozainan-SW — K3s Agent Provisioning               ║"
echo "║          Role: Worker (Agent Mode)                          ║"
echo "║          Server: ${SERVER_IP}                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Wait for token from server ────────────────────────────────
echo ">>> [yozainan-SW] Waiting for K3s server token..."
TIMEOUT=120
ELAPSED=0
while [ ! -f "$TOKEN_FILE" ]; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [yozainan-SW] ERROR: Token not found within ${TIMEOUT}s"
        exit 1
    fi
    echo "    Token not found yet, retrying... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ">>> [yozainan-SW] Token acquired!"

# ── Step 2: Install dependencies ──────────────────────────────────────
echo ">>> [yozainan-SW] Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl

# ── Step 3: Create swap (helps with low-RAM setups) ───────────────────
echo ">>> [yozainan-SW] Setting up swap space..."
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

# ── Step 4: Install K3s in AGENT mode ─────────────────────────────────
echo ">>> [yozainan-SW] Installing K3s in AGENT mode..."
K3S_TOKEN=$(cat "$TOKEN_FILE")
export K3S_URL="https://${SERVER_IP}:6443"
export K3S_TOKEN="${K3S_TOKEN}"
export INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --kubelet-arg=fail-swap-on=false"
curl -sfL https://get.k3s.io | sh -

# ── Step 5: Accept server SSH key ─────────────────────────────────────
echo ">>> [yozainan-SW] Setting up SSH cross-access..."
if [ -f /vagrant/confs/server_key.pub ]; then
    cat /vagrant/confs/server_key.pub >> /home/vagrant/.ssh/authorized_keys
    chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
fi

# ── Step 6: Add kubectl alias ─────────────────────────────────────────
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# ── Done ──────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  yozainan-SW — K3s Agent provisioning COMPLETE          ║"
echo "║      Hostname: $(hostname)                                  ║"
echo "║      IP:       192.168.56.111                               ║"
echo "║      Role:     K3s Agent (Worker)                           ║"
echo "║      Server:   ${SERVER_IP}                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
