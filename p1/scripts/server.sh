#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  yozainan-S — K3s Server (Controller Mode) Provisioning
# ═══════════════════════════════════════════════════════════════════════

SERVER_IP="$1"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           yozainan-S — K3s Server Provisioning              ║"
echo "║           Role: Controller (Server Mode)                    ║"
echo "║           IP:   ${SERVER_IP}                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Install dependencies ──────────────────────────────────────
echo ">>> [yozainan-S] Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl

# ── Step 2: Create swap (helps with low-RAM setups) ───────────────────
echo ">>> [yozainan-S] Setting up swap space..."
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

# ── Step 3: Install K3s in SERVER mode ────────────────────────────────
echo ">>> [yozainan-S] Installing K3s in SERVER mode..."
export INSTALL_K3S_EXEC="server \
  --write-kubeconfig-mode 644 \
  --node-ip ${SERVER_IP} \
  --bind-address ${SERVER_IP} \
  --advertise-address ${SERVER_IP} \
  --disable traefik \
  --disable servicelb \
  --disable metrics-server \
  --kubelet-arg=fail-swap-on=false"

curl -sfL https://get.k3s.io | sh -

# ── Step 4: Wait for K3s to become ready ──────────────────────────────
echo ">>> [yozainan-S] Waiting for K3s to become ready..."
TIMEOUT=120
ELAPSED=0
while ! kubectl get node 2>/dev/null | grep -q "Ready"; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo ">>> [yozainan-S] ERROR: K3s did not become ready within ${TIMEOUT}s"
        systemctl status k3s --no-pager || true
        journalctl -u k3s --no-pager -n 30 || true
        exit 1
    fi
    echo "    Waiting for K3s node to be Ready... (${ELAPSED}s/${TIMEOUT}s)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ">>> [yozainan-S] K3s server node is Ready!"

# ── Step 5: Export node-token for the agent ───────────────────────────
echo ">>> [yozainan-S] Exporting node-token to shared folder..."
cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token

# ── Step 6: Setup kubectl for vagrant user ────────────────────────────
echo ">>> [yozainan-S] Setting up kubectl for vagrant user..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
sed -i "s/127.0.0.1/${SERVER_IP}/g" /home/vagrant/.kube/config

# ── Step 7: Add kubectl alias ─────────────────────────────────────────
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# ── Step 8: Setup SSH key for cross-VM access ─────────────────────────
echo ">>> [yozainan-S] Generating SSH key for cross-VM access..."
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f /home/vagrant/.ssh/id_rsa -N ""
    chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
fi
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/confs/server_key.pub

# ── Done ──────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  yozainan-S — K3s Server provisioning COMPLETE          ║"
echo "║      Hostname: $(hostname)                                  ║"
echo "║      IP:       ${SERVER_IP}                                 ║"
echo "║      Role:     K3s Controller (Server)                      ║"
echo "║      kubectl:  installed ✅                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"