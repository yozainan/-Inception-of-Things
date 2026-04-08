# Part 1 — K3s and Vagrant: Complete Implementation Plan

> **Purpose**: This plan is written so that ANY model (even a small/cheap one) can follow
> it step-by-step and produce a correct, fully-working Part 1. Every instruction is
> explicit. Copy-paste the code blocks exactly. Do not improvise.

---

## 🎯 What Part 1 Must Do (from the subject)

Create **two virtual machines** with Vagrant + VirtualBox:

| Property           | Machine 1 (Server)        | Machine 2 (ServerWorker)   |
|--------------------|---------------------------|----------------------------|
| VM name            | `yozainan-S`              | `yozainan-SW`              |
| Hostname           | `yozainan-S`              | `yozainan-SW`              |
| IP (private)       | `192.168.56.110`          | `192.168.56.111`           |
| CPU                | 1                         | 1                          |
| RAM                | 1024 MB (or 512 MB)       | 1024 MB (or 512 MB)        |
| K3s role           | **controller** (server)   | **agent** (worker)         |
| SSH                | passwordless (Vagrant)    | passwordless (Vagrant)     |
| kubectl            | installed ✅              | not needed                 |
| OS                 | `debian/bookworm64`       | `debian/bookworm64`        |

---

## 📋 Subject Rules Checklist (ALL must pass)

These are **mandatory hard constraints** extracted from `en.subject.txt`:

- [x] Use the **latest stable version** of a Linux distribution → `debian/bookworm64` (Debian 12)
- [x] Allow only **bare minimum resources**: 1 CPU and 512 MB or 1024 MB RAM
- [x] Machine names = **login** of team member → `yozainan`
- [x] First machine hostname ends with **S** (Server) → `yozainan-S`
- [x] Second machine hostname ends with **SW** (ServerWorker) → `yozainan-SW`
- [x] **Dedicated IP** on primary network interface:
  - Server: `192.168.56.110`
  - ServerWorker: `192.168.56.111`
- [x] **SSH without password** on both machines
- [x] Vagrantfile follows **modern practices**
- [x] K3s on first machine (yozainan-S) in **controller mode**
- [x] K3s on second machine (yozainan-SW) in **agent mode**
- [x] **kubectl** installed and functional (on server)
- [x] Folder structure: `p1/Vagrantfile`, `p1/scripts/`, `p1/confs/`

---

## 📁 Required Folder Structure

```
p1/
├── Vagrantfile                # VM definitions (2 VMs)
├── scripts/
│   ├── server.sh              # Provisions yozainan-S (K3s server)
│   └── worker.sh              # Provisions yozainan-SW (K3s agent)
├── confs/
│   ├── .gitkeep               # Keeps folder in git
│   └── node-token             # ⚠️ Generated at runtime — DO NOT commit
├── testing_part1.sh           # Automated test script for validation
├── logs.txt                   # ⚠️ Generated at runtime by vagrant up
├── README.md                  # Documentation for Part 1
└── plan.md                    # This file
```

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

> **INSTRUCTIONS FOR CHEAPER MODELS**: Execute each step in order. Do NOT skip steps.
> Do NOT modify the code blocks unless explicitly told to. Each step is self-contained.

---

### STEP 0 — Prerequisites (run ONCE on the host machine)

> Skip this step if VirtualBox and Vagrant are already installed.

```bash
# Check if already installed
VBoxManage --version
vagrant --version
```

If either command fails, install them:

```bash
# Install VirtualBox
sudo apt-get update
sudo apt-get install -y wget gnupg2 software-properties-common
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo gpg --dearmor -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt-get update
sudo apt-get install -y virtualbox-7.1
sudo usermod -aG vboxusers $USER
sudo modprobe vboxdrv

# Install Vagrant
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y vagrant
```

---

### STEP 1 — Create the Vagrantfile

> **File**: `p1/Vagrantfile`
> **Action**: Create this file with EXACTLY this content.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 1: K3s Cluster with Vagrant
#  Server:       yozainan-S   (192.168.56.110) — K3s controller mode
#  ServerWorker: yozainan-SW  (192.168.56.111) — K3s agent mode
# ═══════════════════════════════════════════════════════════════════════

VM_MEMORY   = ENV["VM_MEMORY"] || "1024"   # "512" or "1024"
VM_CPUS     = 1

SERVER_IP   = "192.168.56.110"
WORKER_IP   = "192.168.56.111"
SERVER_NAME = "yozainan-S"
WORKER_NAME = "yozainan-SW"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  # ──────────────────────────────────────────────
  #  yozainan-S — K3s Server (Controller Mode)
  # ──────────────────────────────────────────────
  config.vm.define SERVER_NAME do |server|
    server.vm.hostname = SERVER_NAME
    server.vm.network "private_network", ip: SERVER_IP

    server.vm.provider "virtualbox" do |v|
      v.memory = VM_MEMORY
      v.cpus   = VM_CPUS
      v.customize ["modifyvm", :id, "--name", SERVER_NAME]
    end

    server.vm.provision "shell", path: "scripts/server.sh", args: [SERVER_IP]
  end

  # ──────────────────────────────────────────────
  #  yozainan-SW — K3s Agent (Worker Mode)
  # ──────────────────────────────────────────────
  config.vm.define WORKER_NAME do |worker|
    worker.vm.hostname = WORKER_NAME
    worker.vm.network "private_network", ip: WORKER_IP

    worker.vm.provider "virtualbox" do |v|
      v.memory = VM_MEMORY
      v.cpus   = VM_CPUS
      v.customize ["modifyvm", :id, "--name", WORKER_NAME]
    end

    worker.vm.provision "shell", path: "scripts/worker.sh", args: [SERVER_IP]
  end
end
```

**Key facts about this Vagrantfile:**
- `VM_MEMORY` can be set via environment variable: `VM_MEMORY=512 vagrant up`
- Server is defined FIRST so it starts before worker (Vagrant processes sequentially)
- Both VMs get a `private_network` with static IPs
- The `--name` VirtualBox customize sets the VM name in VirtualBox GUI
- Provisioning scripts are in `scripts/` folder as required by the subject

---

### STEP 2 — Create the Server Provisioning Script

> **File**: `p1/scripts/server.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p1/scripts/server.sh`

```bash
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
echo "║      IP:       ${SERVER_IP}                           ║"
echo "║      Role:     K3s Controller (Server)                      ║"
echo "║      kubectl:  installed ✅                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
```

**What each K3s flag does (for defense):**
| Flag | Purpose |
|------|---------|
| `--write-kubeconfig-mode 644` | kubeconfig readable without sudo |
| `--node-ip` | Advertise the private IP, not the NAT interface |
| `--bind-address` | API server listens on the private IP |
| `--advertise-address` | Other nodes connect via this IP |
| `--disable traefik` | Saves memory (not needed in Part 1) |
| `--disable servicelb` | Saves memory (not needed in Part 1) |
| `--disable metrics-server` | Saves memory (not needed in Part 1) |
| `--kubelet-arg=fail-swap-on=false` | Allows K3s to run with swap enabled |

---

### STEP 3 — Create the Worker Provisioning Script

> **File**: `p1/scripts/worker.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p1/scripts/worker.sh`

```bash
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
```

---

### STEP 4 — Create the confs directory

> **File**: `p1/confs/.gitkeep`
> **Action**: Create this file (it may already exist).

```
# This directory stores runtime config files:
# - node-token: K3s join token (generated during vagrant up — DO NOT commit)
# - server_key.pub: SSH public key from server (generated during vagrant up)
```

---

### STEP 5 — Create/Update .gitignore

> **File**: `.gitignore` (at the repository root, i.e., `IOT/.gitignore`)
> **Action**: Add these lines.

```
# Runtime secrets — generated by vagrant up
p1/confs/node-token
p1/confs/server_key.pub
p1/logs.txt
p1/.vagrant/
*.log
```

---

### STEP 6 — Create the Testing Script

> **File**: `p1/testing_part1.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p1/testing_part1.sh`
>
> **How to use**: From your host machine, run `cd p1 && bash testing_part1.sh`

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 1 Automated Testing Script
#  Run from: the p1/ directory on the HOST machine
#  Usage:    cd p1 && bash testing_part1.sh
# ═══════════════════════════════════════════════════════════════════════

PASS=0
FAIL=0
TOTAL=0

check() {
    local desc="$1"
    local result="$2"
    TOTAL=$((TOTAL + 1))
    if [ "$result" -eq 0 ]; then
        echo "  ✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Inception-of-Things — Part 1 — Automated Test Suite      ║"
echo "║   Testing: yozainan-S and yozainan-SW                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Test Group 1: VM Status ──────────────────────────────────────────
echo "─── 1. VM STATUS ─────────────────────────────────────────────"

vagrant status yozainan-S 2>/dev/null | grep -q "running"
check "yozainan-S is running" $?

vagrant status yozainan-SW 2>/dev/null | grep -q "running"
check "yozainan-SW is running" $?

# ── Test Group 2: Hostnames ──────────────────────────────────────────
echo ""
echo "─── 2. HOSTNAMES ─────────────────────────────────────────────"

SERVER_HOSTNAME=$(vagrant ssh yozainan-S -c "hostname" 2>/dev/null | tr -d '\r\n')
[ "$SERVER_HOSTNAME" = "yozainan-S" ]
check "yozainan-S hostname is 'yozainan-S' (got: '$SERVER_HOSTNAME')" $?

WORKER_HOSTNAME=$(vagrant ssh yozainan-SW -c "hostname" 2>/dev/null | tr -d '\r\n')
[ "$WORKER_HOSTNAME" = "yozainan-SW" ]
check "yozainan-SW hostname is 'yozainan-SW' (got: '$WORKER_HOSTNAME')" $?

# ── Test Group 3: IP Addresses ───────────────────────────────────────
echo ""
echo "─── 3. IP ADDRESSES ─────────────────────────────────────────"

vagrant ssh yozainan-S -c "ip a" 2>/dev/null | grep -q "192.168.56.110"
check "yozainan-S has IP 192.168.56.110" $?

vagrant ssh yozainan-SW -c "ip a" 2>/dev/null | grep -q "192.168.56.111"
check "yozainan-SW has IP 192.168.56.111" $?

# ── Test Group 4: SSH Access ─────────────────────────────────────────
echo ""
echo "─── 4. SSH ACCESS (no password) ─────────────────────────────"

vagrant ssh yozainan-S -c "echo 'ssh-ok'" 2>/dev/null | grep -q "ssh-ok"
check "SSH to yozainan-S works without password" $?

vagrant ssh yozainan-SW -c "echo 'ssh-ok'" 2>/dev/null | grep -q "ssh-ok"
check "SSH to yozainan-SW works without password" $?

# ── Test Group 5: K3s Roles ──────────────────────────────────────────
echo ""
echo "─── 5. K3s ROLES ────────────────────────────────────────────"

vagrant ssh yozainan-S -c "systemctl is-active k3s" 2>/dev/null | grep -q "active"
check "K3s SERVER service is active on yozainan-S" $?

vagrant ssh yozainan-SW -c "systemctl is-active k3s-agent" 2>/dev/null | grep -q "active"
check "K3s AGENT service is active on yozainan-SW" $?

# ── Test Group 6: Cluster State ──────────────────────────────────────
echo ""
echo "─── 6. CLUSTER STATE ────────────────────────────────────────"

NODE_COUNT=$(vagrant ssh yozainan-S -c "kubectl get nodes --no-headers 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r\n ')
[ "$NODE_COUNT" = "2" ]
check "Cluster has exactly 2 nodes (got: $NODE_COUNT)" $?

vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep "yozainan-S" | grep -q "Ready"
check "yozainan-S node is Ready" $?

vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep "yozainan-SW" | grep -q "Ready"
check "yozainan-SW node is Ready" $?

vagrant ssh yozainan-S -c "kubectl get nodes -o wide" 2>/dev/null | grep "yozainan-S" | grep -q "192.168.56.110"
check "yozainan-S node IP is 192.168.56.110 in cluster" $?

vagrant ssh yozainan-S -c "kubectl get nodes -o wide" 2>/dev/null | grep "yozainan-SW" | grep -q "192.168.56.111"
check "yozainan-SW node IP is 192.168.56.111 in cluster" $?

# ── Test Group 7: kubectl ────────────────────────────────────────────
echo ""
echo "─── 7. KUBECTL ──────────────────────────────────────────────"

vagrant ssh yozainan-S -c "which kubectl" 2>/dev/null | grep -q "kubectl"
check "kubectl is installed on yozainan-S" $?

vagrant ssh yozainan-S -c "kubectl version --short 2>/dev/null || kubectl version 2>/dev/null" 2>/dev/null | grep -qi "server\|client"
check "kubectl can communicate with the cluster" $?

# ── Test Group 8: Resources ──────────────────────────────────────────
echo ""
echo "─── 8. RESOURCES ────────────────────────────────────────────"

SERVER_MEM=$(vagrant ssh yozainan-S -c "free -m | awk '/Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r\n ')
check "yozainan-S RAM allocation (${SERVER_MEM} MB)" 0

WORKER_MEM=$(vagrant ssh yozainan-SW -c "free -m | awk '/Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r\n ')
check "yozainan-SW RAM allocation (${WORKER_MEM} MB)" 0

SERVER_CPU=$(vagrant ssh yozainan-S -c "nproc" 2>/dev/null | tr -d '\r\n ')
[ "$SERVER_CPU" = "1" ]
check "yozainan-S has 1 CPU (got: $SERVER_CPU)" $?

WORKER_CPU=$(vagrant ssh yozainan-SW -c "nproc" 2>/dev/null | tr -d '\r\n ')
[ "$WORKER_CPU" = "1" ]
check "yozainan-SW has 1 CPU (got: $WORKER_CPU)" $?

# ── Test Group 9: Folder Structure ───────────────────────────────────
echo ""
echo "─── 9. FOLDER STRUCTURE ─────────────────────────────────────"

[ -f "Vagrantfile" ]
check "p1/Vagrantfile exists" $?

[ -d "scripts" ]
check "p1/scripts/ directory exists" $?

[ -d "confs" ]
check "p1/confs/ directory exists" $?

[ -f "scripts/server.sh" ]
check "p1/scripts/server.sh exists" $?

[ -f "scripts/worker.sh" ]
check "p1/scripts/worker.sh exists" $?

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed, $TOTAL total"
echo "══════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "  🎉  ALL TESTS PASSED — Part 1 is ready for defense!"
    echo ""
else
    echo ""
    echo "  ⚠️   $FAIL test(s) FAILED — review the failures above."
    echo ""
    exit 1
fi
```

---

### STEP 7 — Boot the Cluster (with logging)

> **Action**: Run these commands from the `p1/` directory.
> The `> logs.txt 2>&1` redirects ALL output (stdout + stderr) into `logs.txt`.

```bash
cd p1/

# Destroy any existing VMs first (clean start)
vagrant destroy -f 2>/dev/null

# Boot with logging — all output goes to logs.txt
VM_MEMORY=1024 vagrant up 2>&1 | tee logs.txt
```

**What happens:**
1. Vagrant creates `yozainan-S` → runs `server.sh` → K3s server starts
2. `server.sh` saves `node-token` to `/vagrant/confs/node-token`
3. Vagrant creates `yozainan-SW` → runs `worker.sh` → reads token → joins cluster
4. Everything is logged to `logs.txt`

---

### STEP 8 — Run Tests

```bash
cd p1/
bash testing_part1.sh
```

**Expected output:** All tests should show ✅ PASS.

---

### STEP 9 — Verify Manually (for defense preparation)

Run each of these commands and understand their output:

```bash
# 1. Check both nodes are Ready
vagrant ssh yozainan-S -c "kubectl get nodes -o wide"
# EXPECTED:
#   yozainan-S    Ready    control-plane,master   ...   192.168.56.110
#   yozainan-SW   Ready    <none>                 ...   192.168.56.111

# 2. Check IPs on private interface
vagrant ssh yozainan-S -c "ip a show enp0s8"
# EXPECTED: inet 192.168.56.110/24

vagrant ssh yozainan-SW -c "ip a show enp0s8"
# EXPECTED: inet 192.168.56.111/24

# 3. Check hostnames
vagrant ssh yozainan-S -c "hostname"
# EXPECTED: yozainan-S

vagrant ssh yozainan-SW -c "hostname"
# EXPECTED: yozainan-SW

# 4. Check K3s services
vagrant ssh yozainan-S -c "systemctl status k3s --no-pager"
vagrant ssh yozainan-SW -c "systemctl status k3s-agent --no-pager"

# 5. Check RAM
vagrant ssh yozainan-S -c "free -m"
vagrant ssh yozainan-SW -c "free -m"

# 6. Check CPU
vagrant ssh yozainan-S -c "nproc"
# EXPECTED: 1
```

---

## 🛠️ Troubleshooting Guide

| Problem | Solution |
|---------|----------|
| `vagrant up` fails — VirtualBox not found | Run the install steps from STEP 0 |
| `vboxdrv` module not loaded | `sudo modprobe vboxdrv` — if fails: `sudo apt install linux-headers-$(uname -r)` |
| Agent can't join server | Check token: `vagrant ssh yozainan-S -c "cat /var/lib/rancher/k3s/server/node-token"` |
| Node stuck in `NotReady` | Wait 2-3 min; check: `vagrant ssh yozainan-S -c "sudo systemctl status k3s"` |
| OOM kills with 512 MB | Switch to 1024 MB: `vagrant destroy -f && VM_MEMORY=1024 vagrant up` |
| Host-only network error | `VBoxManage hostonlyif create && VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1` |
| Port 2222 collision | Vagrant auto-resolves to 2200+. Check `vagrant port yozainan-SW` |
| K3s download timeout | Retry: `vagrant provision yozainan-S` or `vagrant provision yozainan-SW` |
| Logs don't show in logs.txt | Use `tee`: `vagrant up 2>&1 | tee logs.txt` |

---

## 🗂️ Execution Order for Cheaper Models

> **IMPORTANT**: Feed these prompts one at a time. Wait for each to complete before proceeding.

| # | Instruction | Files |
|---|-------------|-------|
| 1 | Create `p1/Vagrantfile` with EXACT content from STEP 1 | `p1/Vagrantfile` |
| 2 | Create `p1/scripts/server.sh` with EXACT content from STEP 2. Run `chmod +x p1/scripts/server.sh` | `p1/scripts/server.sh` |
| 3 | Create `p1/scripts/worker.sh` with EXACT content from STEP 3. Run `chmod +x p1/scripts/worker.sh` | `p1/scripts/worker.sh` |
| 4 | Create `p1/confs/.gitkeep` with content from STEP 4 | `p1/confs/.gitkeep` |
| 5 | Add the lines from STEP 5 to the root `.gitignore` | `.gitignore` |
| 6 | Create `p1/testing_part1.sh` with EXACT content from STEP 6. Run `chmod +x p1/testing_part1.sh` | `p1/testing_part1.sh` |
| 7 | Run: `cd p1 && vagrant destroy -f 2>/dev/null; VM_MEMORY=1024 vagrant up 2>&1 \| tee logs.txt` | runtime |
| 8 | Wait for vagrant up to finish. Check `tail -20 p1/logs.txt` for completion | runtime |
| 9 | Run: `cd p1 && bash testing_part1.sh` — confirm ALL tests pass | runtime |

---

## ✅ Defense Checklist

Before presenting Part 1, verify ALL of these:

- [ ] `vagrant up` from `p1/` creates both VMs from scratch without errors
- [ ] `vagrant ssh yozainan-S -c "kubectl get nodes"` shows **2 nodes**, both **Ready**
- [ ] yozainan-S hostname is exactly `yozainan-S`
- [ ] yozainan-SW hostname is exactly `yozainan-SW`
- [ ] yozainan-S IP is `192.168.56.110` on private interface (check with `ip a show enp0s8`)
- [ ] yozainan-SW IP is `192.168.56.111` on private interface (check with `ip a show enp0s8`)
- [ ] SSH to both machines works without password
- [ ] VMs use 1 CPU and correct RAM (512 or 1024 MB)
- [ ] K3s is in **controller mode** on yozainan-S (`systemctl status k3s`)
- [ ] K3s is in **agent mode** on yozainan-SW (`systemctl status k3s-agent`)
- [ ] `kubectl` is installed and works on yozainan-S
- [ ] `p1/` contains: `Vagrantfile`, `scripts/`, `confs/`
- [ ] `logs.txt` exists and contains the full provisioning log
- [ ] `testing_part1.sh` passes all tests
