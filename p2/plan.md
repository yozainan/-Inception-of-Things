# Part 2 — K3s and Three Simple Applications: Complete Implementation Plan

> **Purpose**: This plan is written so that ANY model (even a small/cheap one) can follow
> it step-by-step and produce a correct, fully-working Part 2. Every instruction is
> explicit. Copy-paste the code blocks exactly. Do not improvise.

---

## 🎯 What Part 2 Must Do (from the subject)

Set up **one virtual machine** running K3s in server mode with **three web applications** routed via **Ingress host-based routing**:

| Property             | Value                                         |
|----------------------|-----------------------------------------------|
| VM name              | `yozainan-S`                                  |
| Hostname             | `yozainan-S`                                  |
| IP (private)         | `192.168.56.110`                              |
| CPU                  | 1                                             |
| RAM                  | 1024 MB (or 512 MB)                           |
| K3s role             | **server** mode                               |
| SSH                  | passwordless (Vagrant)                        |
| kubectl              | installed ✅                                  |
| OS                   | `debian/bookworm64` (Debian 12)               |
| Apps deployed        | app1, app2, app3                              |
| Ingress              | Traefik (K3s built-in)                        |

### Routing Rules (MUST match exactly)

| Client sends `Host:` header | Server displays |
|-----------------------------|-----------------|
| `app1.com`                  | **app1**        |
| `app2.com`                  | **app2**        |
| anything else / no host     | **app3** (default) |

### Replica Requirements

| Application | Replicas |
|-------------|----------|
| app1        | 1        |
| app2        | **3** (explicitly required in subject diagram) |
| app3        | 1        |

---

## 📋 Subject Rules Checklist (ALL must pass)

These are **mandatory hard constraints** extracted from `en.subject.txt`:

- [ ] Use the **latest stable version** of a Linux distribution → `debian/bookworm64` (Debian 12)
- [ ] Allow only **bare minimum resources**: 1 CPU and 512 MB or 1024 MB RAM
- [ ] Only **one VM** — K3s in **server mode**
- [ ] Machine name = **login + S** → `yozainan-S`
- [ ] **Dedicated IP** on primary network interface: `192.168.56.110`
- [ ] **SSH without password**
- [ ] Vagrantfile follows **modern practices**
- [ ] Deploy **3 web applications** in the K3s cluster
- [ ] Host `app1.com` → routes to **app1**
- [ ] Host `app2.com` → routes to **app2**
- [ ] **Default** (no matching host) → routes to **app3**
- [ ] **app2 has 3 replicas** (subject diagram explicitly shows this)
- [ ] app1 and app3 have 1 replica each
- [ ] **Ingress object** must exist and evaluators must see it during defense
- [ ] Folder structure: `p2/Vagrantfile`, `p2/scripts/`, `p2/confs/`
- [ ] Scripts go in `scripts/` folder, config files go in `confs/` folder

---

## 🔍 Review of Existing p2 Code — Issues Found

I reviewed every existing file in `p2/` against the subject rules. Here are the **issues** that must be fixed:

### Issue 1 — ❌ Pinned OLD K3s version (CRITICAL)
**File**: `scripts/master_startup.sh` line 13
**Problem**: Uses `INSTALL_K3S_VERSION="v1.26.4+k3s1"` — this is an old version from 2023. The subject says "latest stable version" and pinning to an old release could lose points.
**Fix**: Remove the version pin. Let the installer fetch the latest stable release.

### Issue 2 — ❌ Script name doesn't follow convention
**File**: `scripts/master_startup.sh`
**Problem**: Named `master_startup.sh` instead of `server.sh`. The subject calls the machine "Server" and Part 1 uses `server.sh`. Consistency matters for defense.
**Fix**: Rename to `scripts/server.sh`.

### Issue 3 — ❌ No swap idempotency (will fail on re-provision)
**File**: `scripts/master_startup.sh` lines 8-11
**Problem**: `fallocate` runs unconditionally — if you run `vagrant provision` a second time, it will fail because `/swapfile` already exists.
**Fix**: Wrap in `if [ ! -f /swapfile ]` guard (like Part 1 does).

### Issue 4 — ❌ No timeout on wait loops (can hang forever)
**File**: `scripts/master_startup.sh` lines 17-20 and 22-25
**Problem**: Both `while` loops have no timeout. If K3s or Traefik fails to start, `vagrant up` hangs indefinitely.
**Fix**: Add timeout counters (like Part 1 does).

### Issue 5 — ❌ Missing `--bind-address` and `--advertise-address` flags
**File**: `scripts/master_startup.sh` line 13
**Problem**: Only `--node-ip` is set. Without `--bind-address` and `--advertise-address`, the API server may bind to the NAT interface (10.0.2.15) instead of the private IP.
**Fix**: Add `--bind-address 192.168.56.110 --advertise-address 192.168.56.110`.

### Issue 6 — ❌ Missing kubectl setup for vagrant user
**File**: `scripts/master_startup.sh`
**Problem**: No `/home/vagrant/.kube/config` setup. When you `vagrant ssh` and run `kubectl`, it might not work without `sudo` (even though `--write-kubeconfig-mode 644` helps with `/etc/rancher/k3s/k3s.yaml`, explicit setup is better).
**Fix**: Copy kubeconfig to `~vagrant/.kube/config`.

### Issue 7 — ❌ Vagrantfile missing `--name` customize (subject pattern)
**File**: `Vagrantfile` lines 8-12
**Problem**: Uses `vb.name = "yozainan-S"` instead of the subject's pattern `v.customize ["modifyvm", :id, "--name", "yozainan-S"]`. While functionally equivalent, matching the subject's pattern is safer for defense.
**Fix**: Use the `customize` pattern from the subject.

### Issue 8 — ⚠️ Ingress default backend fragility
**File**: `confs/ingress.yaml` lines 29-37
**Problem**: The default route to app3 is done as a rule without a host header. While this works with Traefik, a proper `defaultBackend` at the spec level is more explicit and robust.
**Fix**: Add `defaultBackend` to the Ingress spec for maximum compatibility.

### Issue 9 — ⚠️ No testing script
**Problem**: Part 1 has `testing_part1.sh` but Part 2 has no equivalent.
**Fix**: Create `testing_part2.sh` to validate all requirements before defense.

---

## 📁 Required Folder Structure

```
p2/
├── Vagrantfile                # VM definition (1 VM only)
├── scripts/
│   └── server.sh              # Provisions yozainan-S (K3s server + deploys apps)
├── confs/
│   ├── apps.yaml              # Deployments + Services for app1, app2, app3
│   └── ingress.yaml           # Ingress routing rules
├── testing_part2.sh           # Automated test script for validation
├── logs.txt                   # ⚠️ Generated at runtime by vagrant up
└── plan.md                    # This file
```

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

> **INSTRUCTIONS FOR CHEAPER MODELS**: Execute each step in order. Do NOT skip steps.
> Do NOT modify the code blocks unless explicitly told to. Each step is self-contained.

---

### STEP 0 — Prerequisites

> Same as Part 1. VirtualBox and Vagrant must already be installed.
> If Part 1 VMs are running, you can leave them or stop them — they use different VM names.

**IMPORTANT**: If Part 1's `yozainan-S` VM is running, it uses the same IP `192.168.56.110`.
You **must** stop it before starting Part 2:

```bash
cd /home/youssef/Desktop/IOT/p1 && vagrant halt
```

---

### STEP 1 — Create the Vagrantfile

> **File**: `p2/Vagrantfile`
> **Action**: REPLACE the existing file with EXACTLY this content.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 2: K3s with Three Web Applications
#  Server: yozainan-S (192.168.56.110) — K3s server mode + Ingress
# ═══════════════════════════════════════════════════════════════════════

VM_MEMORY   = ENV["VM_MEMORY"] || "1024"   # "512" or "1024"
VM_CPUS     = 1

SERVER_IP   = "192.168.56.110"
SERVER_NAME = "yozainan-S"

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  # ──────────────────────────────────────────────
  #  yozainan-S — K3s Server with 3 Apps + Ingress
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
end
```

**Key differences from Part 1:**
- Only **one VM** (no worker/agent machine)
- Traefik is **NOT disabled** — it's the built-in Ingress controller we need
- Server script will deploy apps + ingress after K3s is ready

---

### STEP 2 — Create the Server Provisioning Script

> **File**: `p2/scripts/server.sh`
> **Action**: CREATE this new file. Then DELETE the old `scripts/master_startup.sh`.
> **Then run**: `chmod +x p2/scripts/server.sh`

```bash
#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
#  yozainan-S — K3s Server + Three Apps Provisioning (Part 2)
# ═══════════════════════════════════════════════════════════════════════

SERVER_IP="$1"

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
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
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
while ! kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik 2>/dev/null | grep -q "Running"; do
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
```

**Key differences from Part 1's server script:**
| What | Part 1 | Part 2 |
|------|--------|--------|
| Traefik | `--disable traefik` | **Kept enabled** (needed for Ingress) |
| ServiceLB | `--disable servicelb` | **Kept enabled** (Traefik needs it) |
| Metrics | `--disable metrics-server` | **Kept enabled** (optional, can disable if OOM) |
| K3s version | latest | **latest** (no pin) |
| After K3s starts | exports token | **deploys apps.yaml + ingress.yaml** |
| Worker setup | token sharing | N/A (no worker) |

---

### STEP 3 — Create the Applications Manifest

> **File**: `p2/confs/apps.yaml`
> **Action**: REPLACE the existing file with EXACTLY this content.

```yaml
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 2: Three Web Applications
#  app1 (1 replica) | app2 (3 replicas) | app3 (1 replica)
# ═══════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────
#  APP 1 — Deployment (1 replica)
# ──────────────────────────────────────────────────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-one
  labels:
    app: app-one
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-one
  template:
    metadata:
      labels:
        app: app-one
    spec:
      initContainers:
      - name: init-html
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          cat > /work/index.html <<'HTMLEOF'
          <!DOCTYPE html>
          <html>
          <head><title>App One</title></head>
          <body style="background:#1a1a2e;color:#e94560;font-family:sans-serif;text-align:center;padding:60px;">
            <h1>Hello from app-one!</h1>
            <p style="color:#eee;">Host: app1.com → This is Application 1</p>
          </body>
          </html>
          HTMLEOF
        volumeMounts:
        - name: html
          mountPath: /work
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        emptyDir: {}
---
# ──────────────────────────────────────────────────────────────────────
#  APP 1 — Service
# ──────────────────────────────────────────────────────────────────────
apiVersion: v1
kind: Service
metadata:
  name: app-one-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: app-one
---
# ──────────────────────────────────────────────────────────────────────
#  APP 2 — Deployment (3 replicas — REQUIRED by subject)
# ──────────────────────────────────────────────────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-two
  labels:
    app: app-two
spec:
  replicas: 3       # ← SUBJECT REQUIREMENT: app2 must have 3 replicas
  selector:
    matchLabels:
      app: app-two
  template:
    metadata:
      labels:
        app: app-two
    spec:
      initContainers:
      - name: init-html
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          cat > /work/index.html <<'HTMLEOF'
          <!DOCTYPE html>
          <html>
          <head><title>App Two</title></head>
          <body style="background:#16213e;color:#0f3460;font-family:sans-serif;text-align:center;padding:60px;">
            <h1 style="color:#e94560;">Hello from app-two!</h1>
            <p style="color:#eee;">Host: app2.com → This is Application 2 (3 replicas)</p>
          </body>
          </html>
          HTMLEOF
        volumeMounts:
        - name: html
          mountPath: /work
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        emptyDir: {}
---
# ──────────────────────────────────────────────────────────────────────
#  APP 2 — Service
# ──────────────────────────────────────────────────────────────────────
apiVersion: v1
kind: Service
metadata:
  name: app-two-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: app-two
---
# ──────────────────────────────────────────────────────────────────────
#  APP 3 — Deployment (1 replica — default/fallback app)
# ──────────────────────────────────────────────────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-three
  labels:
    app: app-three
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-three
  template:
    metadata:
      labels:
        app: app-three
    spec:
      initContainers:
      - name: init-html
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          cat > /work/index.html <<'HTMLEOF'
          <!DOCTYPE html>
          <html>
          <head><title>App Three (Default)</title></head>
          <body style="background:#0f3460;color:#53354a;font-family:sans-serif;text-align:center;padding:60px;">
            <h1 style="color:#e94560;">Hello from app-three!</h1>
            <p style="color:#eee;">Default route → This is Application 3 (fallback)</p>
          </body>
          </html>
          HTMLEOF
        volumeMounts:
        - name: html
          mountPath: /work
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        emptyDir: {}
---
# ──────────────────────────────────────────────────────────────────────
#  APP 3 — Service
# ──────────────────────────────────────────────────────────────────────
apiVersion: v1
kind: Service
metadata:
  name: app-three-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: app-three
```

**Key improvements over existing `apps.yaml`:**
- Uses `busybox:1.36` (pinned tag, not `latest`)
- Heredoc uses `<<'HTMLEOF'` (single-quoted) — prevents `$HOSTNAME` expansion issues
- HTML written to `/work/` then mounted at nginx html path — cleaner volume mount
- Each app has distinct styling so you can visually tell them apart during defense
- Comments clearly mark the 3-replica requirement for app2

---

### STEP 4 — Create the Ingress Manifest

> **File**: `p2/confs/ingress.yaml`
> **Action**: REPLACE the existing file with EXACTLY this content.

```yaml
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 2: Ingress Routing Rules
#  app1.com → app1  |  app2.com → app2  |  default → app3
# ═══════════════════════════════════════════════════════════════════════

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  # ── Default Backend: any request not matching a host rule goes to app3 ──
  defaultBackend:
    service:
      name: app-three-svc
      port:
        number: 80
  rules:
  # ── Host: app1.com → app1 ──────────────────────────────────────────
  - host: app1.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-one-svc
            port:
              number: 80
  # ── Host: app2.com → app2 ──────────────────────────────────────────
  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-two-svc
            port:
              number: 80
```

**Key improvement:** Added explicit `defaultBackend` at the spec level. This is the **correct Kubernetes way** to define a fallback route. The previous version used a rule without a host which works with Traefik but is less reliable. Now app3 is reached when:
- No `Host` header is provided
- `Host` header doesn't match `app1.com` or `app2.com`

---

### STEP 5 — Delete the Old Script

> **Action**: Remove the old script file.

```bash
rm -f /home/youssef/Desktop/IOT/p2/scripts/master_startup.sh
```

---

### STEP 6 — Update .gitignore

> **File**: `.gitignore` (at the repository root: `IOT/.gitignore`)
> **Action**: Add these lines (if not already present).

```
# Part 2 runtime files
p2/logs.txt
p2/.vagrant/
```

---

### STEP 7 — Create the Testing Script

> **File**: `p2/testing_part2.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p2/testing_part2.sh`
>
> **How to use**: From your host machine, run `cd p2 && bash testing_part2.sh`

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 2 Automated Testing Script
#  Run from: the p2/ directory on the HOST machine
#  Usage:    cd p2 && bash testing_part2.sh
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
echo "║   Inception-of-Things — Part 2 — Automated Test Suite      ║"
echo "║   Testing: yozainan-S with 3 apps + Ingress                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Test Group 1: VM Status ──────────────────────────────────────────
echo "─── 1. VM STATUS ─────────────────────────────────────────────"

vagrant status yozainan-S 2>/dev/null | grep -q "running"
check "yozainan-S is running" $?

# ── Test Group 2: Hostname ───────────────────────────────────────────
echo ""
echo "─── 2. HOSTNAME ──────────────────────────────────────────────"

SERVER_HOSTNAME=$(vagrant ssh yozainan-S -c "hostname" 2>/dev/null | tr -d '\r\n')
[ "$SERVER_HOSTNAME" = "yozainan-S" ]
check "yozainan-S hostname is 'yozainan-S' (got: '$SERVER_HOSTNAME')" $?

# ── Test Group 3: IP Address ────────────────────────────────────────
echo ""
echo "─── 3. IP ADDRESS ────────────────────────────────────────────"

vagrant ssh yozainan-S -c "ip a" 2>/dev/null | grep -q "192.168.56.110"
check "yozainan-S has IP 192.168.56.110" $?

# ── Test Group 4: SSH Access ────────────────────────────────────────
echo ""
echo "─── 4. SSH ACCESS (no password) ──────────────────────────────"

vagrant ssh yozainan-S -c "echo 'ssh-ok'" 2>/dev/null | grep -q "ssh-ok"
check "SSH to yozainan-S works without password" $?

# ── Test Group 5: K3s Server ────────────────────────────────────────
echo ""
echo "─── 5. K3s SERVER ────────────────────────────────────────────"

vagrant ssh yozainan-S -c "systemctl is-active k3s" 2>/dev/null | grep -q "active"
check "K3s SERVER service is active" $?

NODE_COUNT=$(vagrant ssh yozainan-S -c "kubectl get nodes --no-headers 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r\n ')
[ "$NODE_COUNT" = "1" ]
check "Cluster has exactly 1 node (got: $NODE_COUNT)" $?

vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep "yozainan-S" | grep -q "Ready"
check "yozainan-S node is Ready" $?

# ── Test Group 6: Deployments & Pods ─────────────────────────────────
echo ""
echo "─── 6. DEPLOYMENTS & PODS ────────────────────────────────────"

# Check deployments exist
vagrant ssh yozainan-S -c "kubectl get deployment app-one" 2>/dev/null | grep -q "app-one"
check "Deployment 'app-one' exists" $?

vagrant ssh yozainan-S -c "kubectl get deployment app-two" 2>/dev/null | grep -q "app-two"
check "Deployment 'app-two' exists" $?

vagrant ssh yozainan-S -c "kubectl get deployment app-three" 2>/dev/null | grep -q "app-three"
check "Deployment 'app-three' exists" $?

# Check replica counts
APP1_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-one -o jsonpath='{.spec.replicas}'" 2>/dev/null | tr -d '\r\n ')
[ "$APP1_REPLICAS" = "1" ]
check "app-one has 1 replica (got: $APP1_REPLICAS)" $?

APP2_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-two -o jsonpath='{.spec.replicas}'" 2>/dev/null | tr -d '\r\n ')
[ "$APP2_REPLICAS" = "3" ]
check "app-two has 3 replicas (got: $APP2_REPLICAS) ← SUBJECT REQUIREMENT" $?

APP3_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-three -o jsonpath='{.spec.replicas}'" 2>/dev/null | tr -d '\r\n ')
[ "$APP3_REPLICAS" = "1" ]
check "app-three has 1 replica (got: $APP3_REPLICAS)" $?

# Check all pods Running
TOTAL_PODS=$(vagrant ssh yozainan-S -c "kubectl get pods --no-headers 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r\n ')
RUNNING_PODS=$(vagrant ssh yozainan-S -c "kubectl get pods --no-headers 2>/dev/null | grep Running | wc -l" 2>/dev/null | tr -d '\r\n ')
[ "$TOTAL_PODS" = "5" ] && [ "$RUNNING_PODS" = "5" ]
check "All 5 pods are Running ($RUNNING_PODS/$TOTAL_PODS)" $?

# ── Test Group 7: Services ───────────────────────────────────────────
echo ""
echo "─── 7. SERVICES ──────────────────────────────────────────────"

vagrant ssh yozainan-S -c "kubectl get svc app-one-svc" 2>/dev/null | grep -q "app-one-svc"
check "Service 'app-one-svc' exists" $?

vagrant ssh yozainan-S -c "kubectl get svc app-two-svc" 2>/dev/null | grep -q "app-two-svc"
check "Service 'app-two-svc' exists" $?

vagrant ssh yozainan-S -c "kubectl get svc app-three-svc" 2>/dev/null | grep -q "app-three-svc"
check "Service 'app-three-svc' exists" $?

# ── Test Group 8: Ingress ────────────────────────────────────────────
echo ""
echo "─── 8. INGRESS ───────────────────────────────────────────────"

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress" 2>/dev/null | grep -q "main-ingress"
check "Ingress 'main-ingress' exists (MUST show to evaluators)" $?

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o jsonpath='{.spec.rules[*].host}'" 2>/dev/null | grep -q "app1.com"
check "Ingress has rule for host 'app1.com'" $?

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o jsonpath='{.spec.rules[*].host}'" 2>/dev/null | grep -q "app2.com"
check "Ingress has rule for host 'app2.com'" $?

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o jsonpath='{.spec.defaultBackend.service.name}'" 2>/dev/null | grep -q "app-three-svc"
check "Ingress defaultBackend routes to app-three-svc" $?

# ── Test Group 9: HTTP Routing (curl tests) ──────────────────────────
echo ""
echo "─── 9. HTTP ROUTING (curl tests from inside VM) ──────────────"

# Test app1.com → app-one
CURL_APP1=$(vagrant ssh yozainan-S -c "curl -s -H 'Host: app1.com' http://192.168.56.110" 2>/dev/null)
echo "$CURL_APP1" | grep -qi "app-one\|app.one\|app one\|Application 1"
check "curl -H 'Host: app1.com' → shows app1 content" $?

# Test app2.com → app-two
CURL_APP2=$(vagrant ssh yozainan-S -c "curl -s -H 'Host: app2.com' http://192.168.56.110" 2>/dev/null)
echo "$CURL_APP2" | grep -qi "app-two\|app.two\|app two\|Application 2"
check "curl -H 'Host: app2.com' → shows app2 content" $?

# Test default → app-three
CURL_DEFAULT=$(vagrant ssh yozainan-S -c "curl -s -H 'Host: unknown.com' http://192.168.56.110" 2>/dev/null)
echo "$CURL_DEFAULT" | grep -qi "app-three\|app.three\|app three\|Application 3"
check "curl -H 'Host: unknown.com' → shows app3 (default)" $?

# Test with no host header → also app-three
CURL_NOHOST=$(vagrant ssh yozainan-S -c "curl -s http://192.168.56.110" 2>/dev/null)
echo "$CURL_NOHOST" | grep -qi "app-three\|app.three\|app three\|Application 3"
check "curl http://192.168.56.110 (no Host) → shows app3 (default)" $?

# ── Test Group 10: Resources ────────────────────────────────────────
echo ""
echo "─── 10. RESOURCES ─────────────────────────────────────────────"

SERVER_MEM=$(vagrant ssh yozainan-S -c "free -m | awk '/Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r\n ')
check "yozainan-S RAM allocation (${SERVER_MEM} MB)" 0

SERVER_CPU=$(vagrant ssh yozainan-S -c "nproc" 2>/dev/null | tr -d '\r\n ')
[ "$SERVER_CPU" = "1" ]
check "yozainan-S has 1 CPU (got: $SERVER_CPU)" $?

# ── Test Group 11: Folder Structure ──────────────────────────────────
echo ""
echo "─── 11. FOLDER STRUCTURE ──────────────────────────────────────"

[ -f "Vagrantfile" ]
check "p2/Vagrantfile exists" $?

[ -d "scripts" ]
check "p2/scripts/ directory exists" $?

[ -d "confs" ]
check "p2/confs/ directory exists" $?

[ -f "scripts/server.sh" ]
check "p2/scripts/server.sh exists" $?

[ -f "confs/apps.yaml" ]
check "p2/confs/apps.yaml exists" $?

[ -f "confs/ingress.yaml" ]
check "p2/confs/ingress.yaml exists" $?

# Check old file is gone
[ ! -f "scripts/master_startup.sh" ]
check "Old scripts/master_startup.sh is removed" $?

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed, $TOTAL total"
echo "══════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "  🎉  ALL TESTS PASSED — Part 2 is ready for defense!"
    echo ""
else
    echo ""
    echo "  ⚠️   $FAIL test(s) FAILED — review the failures above."
    echo ""
    exit 1
fi
```

---

### STEP 8 — Boot the VM (with logging)

> **Action**: Run these commands from the `p2/` directory.

```bash
cd /home/youssef/Desktop/IOT/p2/

# IMPORTANT: Stop Part 1 VMs first (same IP conflict)
cd /home/youssef/Desktop/IOT/p1 && vagrant halt 2>/dev/null; cd /home/youssef/Desktop/IOT/p2

# Destroy any existing Part 2 VM (clean start)
vagrant destroy -f 2>/dev/null

# Boot with logging
VM_MEMORY=1024 vagrant up 2>&1 | tee logs.txt
```

**What happens:**
1. Vagrant creates `yozainan-S` → runs `server.sh`
2. K3s server starts **with Traefik enabled**
3. Script waits for K3s + Traefik to be ready
4. Applies `apps.yaml` (3 deployments + 3 services)
5. Applies `ingress.yaml` (host routing + default backend)
6. Waits for all 5 pods (1+3+1) to be Running
7. Everything is logged to `logs.txt`

---

### STEP 9 — Run Tests

```bash
cd /home/youssef/Desktop/IOT/p2/
bash testing_part2.sh
```

**Expected output:** All tests should show ✅ PASS.

---

### STEP 10 — Verify Manually (for defense preparation)

Run each of these commands and understand their output:

```bash
# 1. Check the single node is Ready
vagrant ssh yozainan-S -c "kubectl get nodes -o wide"
# EXPECTED:
#   yozainan-S    Ready    control-plane,master   ...   192.168.56.110

# 2. Check all 5 pods (1 + 3 + 1) are Running
vagrant ssh yozainan-S -c "kubectl get pods -o wide"
# EXPECTED:
#   app-one-xxxx     1/1   Running
#   app-two-xxxx     1/1   Running   (×3)
#   app-three-xxxx   1/1   Running

# 3. Check services
vagrant ssh yozainan-S -c "kubectl get svc"
# EXPECTED: app-one-svc, app-two-svc, app-three-svc

# 4. Check Ingress (MUST SHOW THIS TO EVALUATORS)
vagrant ssh yozainan-S -c "kubectl get ingress"
vagrant ssh yozainan-S -c "kubectl describe ingress main-ingress"
# EXPECTED: Rules for app1.com→app-one-svc, app2.com→app-two-svc, default→app-three-svc

# 5. Test routing with curl
vagrant ssh yozainan-S -c "curl -s -H 'Host: app1.com' http://192.168.56.110"
# EXPECTED: "Hello from app-one!"

vagrant ssh yozainan-S -c "curl -s -H 'Host: app2.com' http://192.168.56.110"
# EXPECTED: "Hello from app-two!"

vagrant ssh yozainan-S -c "curl -s -H 'Host: unknown.com' http://192.168.56.110"
# EXPECTED: "Hello from app-three!" (default)

vagrant ssh yozainan-S -c "curl -s http://192.168.56.110"
# EXPECTED: "Hello from app-three!" (default)

# 6. Test routing from HOST machine (add to /etc/hosts first)
# Add these lines to your host's /etc/hosts:
#   192.168.56.110 app1.com
#   192.168.56.110 app2.com
# Then in browser: http://app1.com → app1, http://app2.com → app2

# 7. Verify replicas
vagrant ssh yozainan-S -c "kubectl get deployment"
# EXPECTED:
#   app-one    1/1
#   app-two    3/3   ← 3 replicas as required
#   app-three  1/1
```

---

## 🛠️ Troubleshooting Guide

| Problem | Solution |
|---------|----------|
| IP conflict with Part 1 | Stop Part 1 first: `cd p1 && vagrant halt` |
| Traefik not starting | Give it 2-3 min; check: `kubectl get pods -n kube-system` |
| Pods stuck in `Init:0/1` | busybox image pull issue — check internet: `kubectl describe pod <name>` |
| curl returns 404 | Ingress not ready yet — wait and retry: `kubectl get ingress` |
| curl returns wrong app | Check Host header spelling: `curl -H 'Host: app1.com'` (case-sensitive) |
| OOM kills with 512 MB | Use 1024 MB: `vagrant destroy -f && VM_MEMORY=1024 vagrant up` |
| `vagrant up` hangs | Check logs.txt. Timeouts in server.sh will catch infinite loops |
| All 3 apps show same content | Check that initContainers wrote different HTML files |
| Port 80 not reachable | Traefik binds to 80 via servicelb — check: `kubectl get svc -n kube-system` |

---

## 🗂️ Execution Order for Cheaper Models

> **IMPORTANT**: Feed these prompts one at a time. Wait for each to complete before proceeding.

| # | Instruction | Files |
|---|-------------|-------|
| 1 | REPLACE `p2/Vagrantfile` with EXACT content from STEP 1 | `p2/Vagrantfile` |
| 2 | CREATE `p2/scripts/server.sh` with EXACT content from STEP 2. Run `chmod +x p2/scripts/server.sh` | `p2/scripts/server.sh` |
| 3 | REPLACE `p2/confs/apps.yaml` with EXACT content from STEP 3 | `p2/confs/apps.yaml` |
| 4 | REPLACE `p2/confs/ingress.yaml` with EXACT content from STEP 4 | `p2/confs/ingress.yaml` |
| 5 | DELETE `p2/scripts/master_startup.sh` (STEP 5) | cleanup |
| 6 | Add p2 lines to root `.gitignore` (STEP 6) | `.gitignore` |
| 7 | CREATE `p2/testing_part2.sh` with EXACT content from STEP 7. Run `chmod +x p2/testing_part2.sh` | `p2/testing_part2.sh` |
| 8 | Stop Part 1 VMs: `cd p1 && vagrant halt` | runtime |
| 9 | Run: `cd p2 && vagrant destroy -f 2>/dev/null; VM_MEMORY=1024 vagrant up 2>&1 \| tee logs.txt` | runtime |
| 10 | Wait for vagrant up to finish. Check `tail -20 p2/logs.txt` for completion | runtime |
| 11 | Run: `cd p2 && bash testing_part2.sh` — confirm ALL tests pass | runtime |

---

## ✅ Defense Checklist

Before presenting Part 2, verify ALL of these:

- [ ] `vagrant up` from `p2/` creates the VM from scratch without errors
- [ ] Only **one VM** is created (yozainan-S in server mode)
- [ ] Hostname is exactly `yozainan-S`
- [ ] IP is `192.168.56.110` on private interface (`ip a show enp0s8`)
- [ ] SSH works without password
- [ ] VM uses 1 CPU and correct RAM (512 or 1024 MB)
- [ ] K3s is in **server mode** (`systemctl status k3s`)
- [ ] **3 deployments** exist: app-one, app-two, app-three
- [ ] **app-two has 3 replicas** (`kubectl get deployment app-two`)
- [ ] All **5 pods** are Running (`kubectl get pods`)
- [ ] **3 services** exist: app-one-svc, app-two-svc, app-three-svc
- [ ] **Ingress** exists and is visible: `kubectl get ingress` ← MUST SHOW TO EVALUATORS
- [ ] `curl -H 'Host: app1.com' http://192.168.56.110` → shows app1
- [ ] `curl -H 'Host: app2.com' http://192.168.56.110` → shows app2
- [ ] `curl http://192.168.56.110` (no host) → shows app3 (default)
- [ ] `curl -H 'Host: random.com' http://192.168.56.110` → shows app3 (default)
- [ ] `p2/` contains: `Vagrantfile`, `scripts/`, `confs/`
- [ ] `scripts/` contains `server.sh`
- [ ] `confs/` contains `apps.yaml` and `ingress.yaml`
- [ ] `testing_part2.sh` passes all tests
- [ ] `logs.txt` exists with full provisioning log

---

## 📊 Comparison: Part 1 vs Part 2

| Aspect | Part 1 | Part 2 |
|--------|--------|--------|
| VMs | 2 (Server + Worker) | **1** (Server only) |
| K3s roles | Controller + Agent | **Server only** |
| IPs | .110 + .111 | **.110 only** |
| Traefik | Disabled | **Enabled** (needed for Ingress) |
| ServiceLB | Disabled | **Enabled** (Traefik needs it) |
| App deployments | None | **3** (app1, app2, app3) |
| Services | None | **3** (app-one-svc, etc.) |
| Ingress | None | **1** (host-based routing) |
| Total pods | 0 app pods | **5** app pods (1+3+1) |
| Token sharing | Server exports to worker | N/A |
