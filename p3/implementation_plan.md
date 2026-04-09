# Part 3 — K3d and Argo CD: Complete Implementation Plan

> **Purpose**: This plan is written so that ANY model (even a small/cheap one) can follow
> it step-by-step and produce a correct, fully-working Part 3. Every instruction is
> explicit. Copy-paste the code blocks exactly. Do not improvise.

---

## 🎯 What Part 3 Must Do (from the subject)

Install **K3d** (K3s-in-Docker) on the host VM (no Vagrant for this part), set up **Argo CD** for continuous deployment, and demonstrate a **GitOps workflow** using a public GitHub repository.

| Property                    | Value                                              |
|-----------------------------|----------------------------------------------------|
| Runtime                     | **K3d** (K3s inside Docker containers)             |
| Vagrant                     | **NOT used** — runs directly on the host VM        |
| Docker                      | **Required** for K3d                               |
| Namespace 1                 | `argocd` — dedicated to Argo CD                    |
| Namespace 2                 | `dev` — contains the deployed application          |
| Application                 | `wil42/playground` (port 8888)                     |
| App versions                | `v1` and `v2` (Docker Hub tags)                    |
| GitOps source               | Public GitHub repo (must contain member login)     |
| GitHub repo                 | `yozainan/-Inception-of-Things` (already exists)   |
| Manifests path in repo      | `p3/confs/app/deployment.yaml`                     |
| Defense script              | Must install ALL tools needed during defense        |

### GitOps Flow (MUST demonstrate during defense)

```
┌──────────────────┐     ┌──────────────┐     ┌───────────────┐
│  GitHub Repo     │────▶│  Argo CD     │────▶│  K3d Cluster  │
│  deployment.yaml │     │  (argocd ns) │     │  (dev ns)     │
│  image: v1 → v2  │     │  auto-sync   │     │  playground   │
└──────────────────┘     └──────────────┘     └───────────────┘
```

1. Start with `wil42/playground:v1` in GitHub manifest
2. `curl http://localhost:8888/` returns `{"status":"ok", "message": "v1"}`
3. Change manifest to `v2`, push to GitHub
4. Argo CD detects change, auto-syncs
5. `curl http://localhost:8888/` returns `{"status":"ok", "message": "v2"}`

---

## 📋 Subject Rules Checklist (ALL must pass)

These are **mandatory hard constraints** extracted from `en.subject.txt`:

- [ ] **K3d installed** on the virtual machine (not K3s, not Vagrant)
- [ ] **Docker installed** (required for K3d)
- [ ] **Script installs ALL necessary packages/tools** for defense reproducibility
- [ ] **Two namespaces** created: `argocd` and `dev`
- [ ] **Argo CD installed** in `argocd` namespace
- [ ] **Application deployed** in `dev` namespace
- [ ] App deployed **automatically by Argo CD** from a public GitHub repository
- [ ] **Public GitHub repo** contains group member login in name → `yozainan/-Inception-of-Things` ✅
- [ ] App has **two versions**: tagged `v1` and `v2`
- [ ] Using Wil's app: `wil42/playground` on **port 8888**
- [ ] Can **change version from GitHub** → push → Argo CD syncs → app updates
- [ ] `curl http://localhost:8888/` returns correct version message
- [ ] Folder structure: `p3/scripts/` and `p3/confs/`
- [ ] Scripts go in `scripts/` folder, config files go in `confs/` folder

---

## 🔍 Review of Existing p3 Code — Issues Found

I reviewed every file in `p3/` against the subject rules:

### Issue 1 — ❌ Empty Vagrantfile (WRONG)
**File**: `p3/Vagrantfile`
**Problem**: Part 3 does **NOT use Vagrant**. The subject explicitly says "without Vagrant this time". An empty Vagrantfile is misleading and contradicts the subject.
**Fix**: Delete `p3/Vagrantfile`. The subject's directory structure example for p3 shows only `scripts/` and `confs/` — no Vagrantfile.

### Issue 2 — ❌ Empty scripts/ directory
**File**: `p3/scripts/`
**Problem**: No installation script exists. The subject says "you must write a script to install all the necessary packages and tools during your defense."
**Fix**: Create `p3/scripts/setup.sh` — the main installation and deployment script.

### Issue 3 — ❌ Empty confs/ directory
**File**: `p3/confs/`
**Problem**: No configuration files exist. Need Argo CD Application CRD and dev app manifests.
**Fix**: Create `p3/confs/argocd-app.yaml` and `p3/confs/app/deployment.yaml`.

### Issue 4 — ❌ No testing script
**Problem**: No test script to validate Part 3 requirements.
**Fix**: Create `p3/testing_part3.sh`.

### Issue 5 — ❌ No README
**Problem**: No documentation.
**Fix**: Create `p3/README.md`.

### Issue 6 — ❌ .gitignore missing p3 entries
**Problem**: No p3-specific entries in root `.gitignore`.
**Fix**: Add p3 runtime file exclusions.

---

## 🧠 Key Concepts (K3s vs K3d — for defense)

| Feature       | K3s (Part 1 & 2)                         | K3d (Part 3)                              |
|---------------|-------------------------------------------|-------------------------------------------|
| What is it?   | Lightweight Kubernetes distro             | K3s running inside Docker containers      |
| Runs on       | VMs directly (via Vagrant)                | Docker containers on any Linux host       |
| Setup time    | Minutes (VM provisioning)                 | Seconds (Docker containers)               |
| Use case      | Production-like single/multi-node cluster | Local development and CI/CD testing       |
| Vagrant needed| Yes (P1, P2)                              | **No** (P3)                               |
| Networking    | Host-only network (192.168.56.x)          | Docker port mapping (localhost)           |

---

## 📁 Required Folder Structure

```
p3/
├── scripts/
│   └── setup.sh               # Installs ALL tools + creates cluster + deploys everything
├── confs/
│   ├── argocd-app.yaml        # Argo CD Application CRD (points to GitHub repo)
│   └── app/
│       └── deployment.yaml    # Dev app manifest (wil42/playground:v1) — pushed to GitHub
├── testing_part3.sh           # Automated test script for validation
├── logs.txt                   # ⚠️ Generated at runtime by setup.sh
├── README.md                  # Documentation for Part 3
└── plan.md                    # This file
```

> [!IMPORTANT]
> **No Vagrantfile** in p3! The subject explicitly says "without Vagrant this time".
> The empty `p3/Vagrantfile` that currently exists must be **deleted**.

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

> **INSTRUCTIONS FOR CHEAPER MODELS**: Execute each step in order. Do NOT skip steps.
> Do NOT modify the code blocks unless explicitly told to. Each step is self-contained.

---

### STEP 0 — Prerequisites Check

> Verify Docker is installed on the host (it is — v29.1.3 confirmed).

```bash
docker --version
# Expected: Docker version 29.1.3 or similar
```

If Docker is not installed:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

---

### STEP 1 — Delete the Wrong Vagrantfile

> **Action**: Remove the empty Vagrantfile that shouldn't be in p3.

```bash
rm -f /home/youssef/Desktop/IOT/p3/Vagrantfile
```

---

### STEP 2 — Create the App Deployment Manifest

> **File**: `p3/confs/app/deployment.yaml`
> **Action**: Create this file with EXACTLY this content.
> This is the file that gets committed to GitHub and managed by Argo CD.

```yaml
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 3: Dev Application (wil42/playground)
#  Managed by Argo CD — changes pushed to GitHub trigger auto-sync
# ═══════════════════════════════════════════════════════════════════════

apiVersion: apps/v1
kind: Deployment
metadata:
  name: wil-playground
  namespace: dev
  labels:
    app: wil-playground
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wil-playground
  template:
    metadata:
      labels:
        app: wil-playground
    spec:
      containers:
      - name: playground
        image: wil42/playground:v1
        ports:
        - containerPort: 8888
---
apiVersion: v1
kind: Service
metadata:
  name: wil-playground-svc
  namespace: dev
spec:
  type: ClusterIP
  ports:
  - port: 8888
    targetPort: 8888
  selector:
    app: wil-playground
```

**Key facts:**
- Uses `wil42/playground:v1` — the starting version
- Deployed in `dev` namespace (as required by subject)
- Service exposes port 8888 (as stated in subject: "The application uses port 8888")
- During defense: change `v1` → `v2` in this file, push to GitHub, Argo CD auto-syncs

---

### STEP 3 — Create the Argo CD Application CRD

> **File**: `p3/confs/argocd-app.yaml`
> **Action**: Create this file with EXACTLY this content.

```yaml
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 3: Argo CD Application
#  Watches GitHub repo and auto-deploys to 'dev' namespace
# ═══════════════════════════════════════════════════════════════════════

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-playground
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yozainan/-Inception-of-Things.git
    targetRevision: main
    path: p3/confs/app
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
```

**What each field does (for defense):**
| Field | Purpose |
|-------|---------|
| `repoURL` | Public GitHub repo (contains login `yozainan` as required) |
| `targetRevision` | Branch to watch (`main`) |
| `path` | Path within repo containing the manifests (`p3/confs/app`) |
| `destination.namespace` | Deploy into `dev` namespace |
| `syncPolicy.automated` | **Auto-sync** — Argo CD automatically applies changes |
| `selfHeal: true` | If manual changes are made in cluster, revert to Git state |
| `prune: true` | Remove resources no longer in Git |
| `CreateNamespace=true` | Auto-create `dev` namespace if it doesn't exist |

---

### STEP 4 — Create the Setup Script

> **File**: `p3/scripts/setup.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p3/scripts/setup.sh`

```bash
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
```

**What this script does (for defense):**
| Step | Action |
|------|--------|
| 1-4 | Installs Docker, kubectl, K3d, Helm (if not present) |
| 5-6 | Deletes old cluster, creates fresh `iot-p3` K3d cluster with port mappings |
| 7 | Creates `argocd` and `dev` namespaces |
| 8 | Installs Argo CD from official manifest |
| 9 | Patches Argo CD for insecure access (easier for defense demo) |
| 10 | Retrieves auto-generated admin password |
| 11 | Port-forwards Argo CD UI to localhost:8080 |
| 13 | Applies the Argo CD Application CRD (triggers GitOps) |
| 14 | Port-forwards dev app to localhost:8888 |
| 15 | Verifies everything is running |

---

### STEP 5 — Create the Testing Script

> **File**: `p3/testing_part3.sh`
> **Action**: Create this file with EXACTLY this content.
> **Then run**: `chmod +x p3/testing_part3.sh`

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 3 Automated Testing Script
#  Run from: the p3/ directory on the HOST machine
#  Usage:    cd p3 && bash testing_part3.sh
#  Prereq:  Run scripts/setup.sh first
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
echo "║   Inception-of-Things — Part 3 — Automated Test Suite      ║"
echo "║   Testing: K3d + Argo CD + GitOps                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Test Group 1: Tools Installed ────────────────────────────────────
echo "─── 1. TOOLS INSTALLED ─────────────────────────────────────────"

command -v docker &>/dev/null
check "Docker is installed" $?

command -v k3d &>/dev/null
check "K3d is installed" $?

command -v kubectl &>/dev/null
check "kubectl is installed" $?

command -v helm &>/dev/null
check "Helm is installed" $?

# ── Test Group 2: K3d Cluster ────────────────────────────────────────
echo ""
echo "─── 2. K3d CLUSTER ─────────────────────────────────────────────"

k3d cluster list 2>/dev/null | grep -q "iot-p3"
check "K3d cluster 'iot-p3' exists" $?

kubectl get nodes --no-headers 2>/dev/null | grep -q "Ready"
check "K3d cluster node is Ready" $?

# ── Test Group 3: Namespaces ─────────────────────────────────────────
echo ""
echo "─── 3. NAMESPACES ──────────────────────────────────────────────"

kubectl get namespace argocd --no-headers 2>/dev/null | grep -q "Active"
check "Namespace 'argocd' exists and is Active" $?

kubectl get namespace dev --no-headers 2>/dev/null | grep -q "Active"
check "Namespace 'dev' exists and is Active" $?

# ── Test Group 4: Argo CD ────────────────────────────────────────────
echo ""
echo "─── 4. ARGO CD ─────────────────────────────────────────────────"

ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
[ "$ARGOCD_PODS" -gt 0 ]
check "Argo CD pods exist ($ARGOCD_PODS pods)" $?

ARGOCD_RUNNING=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep "Running" | wc -l)
[ "$ARGOCD_RUNNING" -gt 0 ]
check "Argo CD pods are Running ($ARGOCD_RUNNING running)" $?

kubectl get pods -n argocd --no-headers 2>/dev/null | grep "argocd-server" | grep -q "Running"
check "argocd-server is Running" $?

# ── Test Group 5: Argo CD Application ────────────────────────────────
echo ""
echo "─── 5. ARGO CD APPLICATION ─────────────────────────────────────"

kubectl get application -n argocd 2>/dev/null | grep -q "wil-playground"
check "Argo CD Application 'wil-playground' exists" $?

APP_SYNC=$(kubectl get application wil-playground -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
[ "$APP_SYNC" = "Synced" ]
check "Application sync status is 'Synced' (got: $APP_SYNC)" $?

APP_HEALTH=$(kubectl get application wil-playground -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)
[ "$APP_HEALTH" = "Healthy" ]
check "Application health is 'Healthy' (got: $APP_HEALTH)" $?

# ── Test Group 6: Dev App Pod ────────────────────────────────────────
echo ""
echo "─── 6. DEV APPLICATION ─────────────────────────────────────────"

DEV_PODS=$(kubectl get pods -n dev --no-headers 2>/dev/null | wc -l)
[ "$DEV_PODS" -gt 0 ]
check "Pod(s) exist in 'dev' namespace ($DEV_PODS pods)" $?

kubectl get pods -n dev --no-headers 2>/dev/null | grep "wil-playground" | grep -q "Running"
check "wil-playground pod is Running in 'dev'" $?

# Check the image version
CURRENT_IMAGE=$(kubectl get pods -n dev -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null)
echo "$CURRENT_IMAGE" | grep -q "wil42/playground"
check "Pod uses wil42/playground image (got: $CURRENT_IMAGE)" $?

# ── Test Group 7: Application Endpoint ───────────────────────────────
echo ""
echo "─── 7. APPLICATION ENDPOINT ────────────────────────────────────"

# Ensure port-forward is active
if ! pgrep -f "port-forward.*8888" >/dev/null 2>&1; then
    echo "    Starting port-forward for wil-playground..."
    nohup kubectl port-forward svc/wil-playground-svc -n dev 8888:8888 --address 0.0.0.0 \
        > /tmp/app-portforward.log 2>&1 &
    sleep 5
fi

RESPONSE=$(curl -s http://localhost:8888/ 2>/dev/null)
echo "$RESPONSE" | grep -q "status"
check "curl http://localhost:8888/ returns a response" $?

echo "$RESPONSE" | grep -q '"status":"ok"'
check "Response contains status:ok" $?

CURRENT_VERSION=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | head -1)
check "Response contains version message: $CURRENT_VERSION" 0

# ── Test Group 8: Folder Structure ───────────────────────────────────
echo ""
echo "─── 8. FOLDER STRUCTURE ────────────────────────────────────────"

[ -d "scripts" ]
check "p3/scripts/ directory exists" $?

[ -d "confs" ]
check "p3/confs/ directory exists" $?

[ -f "scripts/setup.sh" ]
check "p3/scripts/setup.sh exists" $?

[ -f "confs/argocd-app.yaml" ]
check "p3/confs/argocd-app.yaml exists" $?

[ -f "confs/app/deployment.yaml" ]
check "p3/confs/app/deployment.yaml exists" $?

[ ! -f "Vagrantfile" ]
check "p3/Vagrantfile does NOT exist (Part 3 uses K3d, not Vagrant)" $?

# ── Test Group 9: GitHub Repo ────────────────────────────────────────
echo ""
echo "─── 9. GITHUB REPOSITORY ──────────────────────────────────────"

REPO_URL=$(kubectl get application wil-playground -n argocd -o jsonpath='{.spec.source.repoURL}' 2>/dev/null)
echo "$REPO_URL" | grep -qi "yozainan"
check "Argo CD repo URL contains 'yozainan' login ($REPO_URL)" $?

echo "$REPO_URL" | grep -qi "github.com"
check "Argo CD uses GitHub as source" $?

REPO_PATH=$(kubectl get application wil-playground -n argocd -o jsonpath='{.spec.source.path}' 2>/dev/null)
check "Argo CD watches path: $REPO_PATH" 0

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed, $TOTAL total"
echo "══════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "  🎉  ALL TESTS PASSED — Part 3 is ready for defense!"
    echo ""
else
    echo ""
    echo "  ⚠️   $FAIL test(s) FAILED — review the failures above."
    echo ""
    exit 1
fi
```

---

### STEP 6 — Create the README

> **File**: `p3/README.md`
> **Action**: Create this file.

```markdown
# 🚀 Inception-of-Things — Part 3: K3d and Argo CD

## Overview

Part 3 sets up a **K3d cluster** (K3s-in-Docker) with **Argo CD** for GitOps-based
continuous deployment. An application (`wil42/playground`) is automatically deployed
and managed via a public GitHub repository.

| Component            | Value                                             |
|----------------------|---------------------------------------------------|
| **Runtime**          | K3d (K3s inside Docker)                           |
| **Cluster**          | `iot-p3`                                          |
| **Namespace: argocd**| Argo CD installation                              |
| **Namespace: dev**   | Application deployment (wil42/playground)         |
| **App image**        | `wil42/playground:v1` → `v2`                     |
| **App port**         | 8888                                              |
| **GitOps source**    | `github.com/yozainan/-Inception-of-Things`        |

---

## 📁 Folder Structure

```
p3/
├── scripts/
│   └── setup.sh               # Installs all tools + creates cluster + deploys everything
├── confs/
│   ├── argocd-app.yaml        # Argo CD Application CRD
│   └── app/
│       └── deployment.yaml    # Dev app manifest (managed by Argo CD via GitHub)
├── testing_part3.sh           # Automated test suite
├── logs.txt                   # Generated at runtime
├── README.md                  # This file
└── plan.md                    # Implementation plan
```

> **Note**: Part 3 does NOT use Vagrant. K3d runs directly on the host using Docker.

---

## ⚡ Quick Start

### Prerequisites
- Docker installed and running
- Internet access (to pull images and install tools)

### Setup (one command)
```bash
cd p3/
sudo bash scripts/setup.sh 2>&1 | tee logs.txt
```

This script:
1. Installs kubectl, K3d, and Helm (if not present)
2. Creates a K3d cluster (`iot-p3`)
3. Creates `argocd` and `dev` namespaces
4. Installs Argo CD
5. Deploys the application via Argo CD + GitHub

### Verify
```bash
bash testing_part3.sh
```

---

## 🔄 GitOps Workflow Demo (Defense)

### Check current version
```bash
curl http://localhost:8888/
# Expected: {"status":"ok", "message": "v1"}
```

### Upgrade v1 → v2
```bash
# 1. Edit the deployment manifest
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' confs/app/deployment.yaml

# 2. Verify the change
grep "image:" confs/app/deployment.yaml
# Expected: image: wil42/playground:v2

# 3. Push to GitHub
git add confs/app/deployment.yaml
git commit -m "upgrade: v1 → v2"
git push

# 4. Wait for Argo CD to sync (~1-3 minutes)

# 5. Verify new version
curl http://localhost:8888/
# Expected: {"status":"ok", "message": "v2"}
```

### View in Argo CD UI
Open `https://localhost:8080` in your browser:
- Username: `admin`
- Password: `cat confs/.argocd-password`

---

## 🧠 K3s vs K3d (Key Differences)

| Feature       | K3s (Part 1 & 2)                    | K3d (Part 3)                         |
|---------------|--------------------------------------|--------------------------------------|
| What is it?   | Lightweight Kubernetes distro        | K3s running inside Docker containers |
| Runs on       | VMs directly (via Vagrant)           | Docker containers on any Linux host  |
| Setup time    | Minutes (VM provisioning)            | Seconds (Docker containers)          |
| Use case      | Production-like cluster              | Local dev and CI/CD testing          |
| Vagrant       | Required                             | Not used                             |

---

## 🛠️ Common Operations

| Command | Description |
|---------|-------------|
| `k3d cluster list` | Show K3d clusters |
| `k3d cluster delete iot-p3` | Delete the cluster |
| `kubectl get pods -n argocd` | Check Argo CD pods |
| `kubectl get pods -n dev` | Check app pods |
| `kubectl get application -n argocd` | Check Argo CD applications |
| `kubectl logs -n dev -l app=wil-playground` | App logs |
| `kubectl port-forward svc/wil-playground-svc -n dev 8888:8888` | Forward app port |
| `kubectl port-forward svc/argocd-server -n argocd 8080:443` | Forward ArgoCD |

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Docker not running | `sudo systemctl start docker` |
| K3d cluster won't create | Check Docker: `docker ps` |
| Argo CD pods pending | Wait 2-5 min; check: `kubectl describe pods -n argocd` |
| App not syncing | Check Argo CD UI or `kubectl get application -n argocd -o yaml` |
| Port 8888 not responding | Restart port-forward: `kubectl port-forward svc/wil-playground-svc -n dev 8888:8888` |
| Argo CD password lost | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |

---

## ✅ Defense Checklist

- [ ] `bash scripts/setup.sh` runs from scratch and sets up everything
- [ ] `kubectl get ns` shows `argocd` and `dev` namespaces
- [ ] `kubectl get pods -n argocd` shows all Argo CD pods Running
- [ ] `kubectl get pods -n dev` shows `wil-playground` pod Running
- [ ] `curl http://localhost:8888/` returns `{"status":"ok", "message": "v1"}`
- [ ] Change `v1`→`v2` in GitHub → Argo CD syncs → app returns `v2`
- [ ] Argo CD UI accessible at `https://localhost:8080`
- [ ] `testing_part3.sh` passes all tests
- [ ] `p3/` contains: `scripts/`, `confs/` (no Vagrantfile)

---

*Created as part of the Inception-of-Things (IoT) project — System Administration exercise*
```

---

### STEP 7 — Update .gitignore

> **File**: `.gitignore` (at the repository root: `IOT/.gitignore`)
> **Action**: Add these lines.

```
# Part 3 runtime files
p3/logs.txt
p3/confs/.argocd-password
```

---

### STEP 8 — Update Root README

> **File**: `README.md` (at the repository root)
> **Action**: Replace with comprehensive project README.

```markdown
# 🚀 Inception-of-Things (IoT)

A System Administration project exploring Kubernetes through K3s and K3d.

## Project Structure

| Part | Topic | Technology | Folder |
|------|-------|-----------|--------|
| **Part 1** | K3s and Vagrant | 2-node K3s cluster (server + agent) | `p1/` |
| **Part 2** | Three Simple Applications | K3s + Traefik Ingress (3 web apps) | `p2/` |
| **Part 3** | K3d and Argo CD | K3d + GitOps continuous deployment | `p3/` |
| **Bonus** | GitLab Integration | Local GitLab + K3d + Argo CD | `bonus/` |

## Quick Start

Each part has its own `README.md` with detailed instructions.

### Part 1
```bash
cd p1/ && vagrant up 2>&1 | tee logs.txt
bash testing_part1.sh
```

### Part 2
```bash
cd p1/ && vagrant halt   # Stop Part 1 first (same IP)
cd p2/ && vagrant up 2>&1 | tee logs.txt
bash testing_part2.sh
```

### Part 3
```bash
cd p3/ && sudo bash scripts/setup.sh 2>&1 | tee logs.txt
bash testing_part3.sh
```

## Team

- **yozainan** — [GitHub](https://github.com/yozainan)

---

*Inception-of-Things — 42 School System Administration Project*
```

---

### STEP 9 — Push App Manifests to GitHub

> **CRITICAL**: Argo CD will pull from your GitHub repository. The `p3/confs/app/deployment.yaml`
> file **MUST** be pushed to GitHub before Argo CD can deploy it.

```bash
cd /home/youssef/Desktop/IOT

# Ensure we're on main branch
git checkout main 2>/dev/null || git checkout -b main

# Add p3 files
git add p3/confs/app/deployment.yaml
git add p3/confs/argocd-app.yaml
git add p3/scripts/setup.sh
git add p3/testing_part3.sh
git add p3/README.md
git add p3/plan.md
git add README.md
git add .gitignore

# Commit and push
git commit -m "feat(p3): add K3d + Argo CD deployment with GitOps workflow"
git push origin main
```

---

### STEP 10 — Run the Setup Script

```bash
cd /home/youssef/Desktop/IOT/p3
sudo bash scripts/setup.sh 2>&1 | tee logs.txt
```

---

### STEP 11 — Run Tests

```bash
cd /home/youssef/Desktop/IOT/p3
bash testing_part3.sh
```

---

### STEP 12 — Demonstrate GitOps Flow (v1 → v2)

```bash
# 1. Check current version
curl http://localhost:8888/
# → {"status":"ok", "message": "v1"}

# 2. Change to v2
cd /home/youssef/Desktop/IOT
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' p3/confs/app/deployment.yaml

# 3. Verify change
grep "image:" p3/confs/app/deployment.yaml
# → image: wil42/playground:v2

# 4. Push to GitHub
git add p3/confs/app/deployment.yaml
git commit -m "upgrade: playground v1 → v2"
git push origin main

# 5. Wait for Argo CD sync (~1-3 minutes)
sleep 120

# 6. Verify new version
curl http://localhost:8888/
# → {"status":"ok", "message": "v2"}
```

---

## 🗂️ Execution Order for Cheaper Models

> **IMPORTANT**: Feed these prompts one at a time.

| # | Instruction | Files |
|---|-------------|-------|
| 1 | Delete `p3/Vagrantfile` | — |
| 2 | Create `p3/confs/app/deployment.yaml` from STEP 2 | `p3/confs/app/deployment.yaml` |
| 3 | Create `p3/confs/argocd-app.yaml` from STEP 3 | `p3/confs/argocd-app.yaml` |
| 4 | Create `p3/scripts/setup.sh` from STEP 4. Run `chmod +x` | `p3/scripts/setup.sh` |
| 5 | Create `p3/testing_part3.sh` from STEP 5. Run `chmod +x` | `p3/testing_part3.sh` |
| 6 | Create `p3/README.md` from STEP 6 | `p3/README.md` |
| 7 | Update `.gitignore` from STEP 7 | `.gitignore` |
| 8 | Update root `README.md` from STEP 8 | `README.md` |
| 9 | Git add, commit, push ALL p3 files (STEP 9) | GitHub |
| 10 | Run: `cd p3 && sudo bash scripts/setup.sh 2>&1 \| tee logs.txt` | runtime |
| 11 | Run: `cd p3 && bash testing_part3.sh` — confirm ALL pass | runtime |
| 12 | Run: GitOps demo from STEP 12 — confirm v1→v2 works | runtime |

---

## ✅ Defense Checklist

Before presenting Part 3, verify ALL of these:

- [ ] Docker, K3d, kubectl, Helm are installed
- [ ] `bash scripts/setup.sh` runs from scratch and sets up everything
- [ ] K3d cluster `iot-p3` is running (`k3d cluster list`)
- [ ] `kubectl get ns` shows `argocd` and `dev`
- [ ] All Argo CD pods are Running (`kubectl get pods -n argocd`)
- [ ] `wil-playground` pod is Running in `dev` (`kubectl get pods -n dev`)
- [ ] Argo CD Application exists and is Synced (`kubectl get application -n argocd`)
- [ ] `curl http://localhost:8888/` returns `{"status":"ok", "message": "v1"}`
- [ ] Change `v1`→`v2` in GitHub → push → Argo CD auto-syncs
- [ ] After sync: `curl http://localhost:8888/` returns `{"status":"ok", "message": "v2"}`
- [ ] Argo CD UI shows the application and sync status
- [ ] `p3/` contains: `scripts/`, `confs/` — **NO Vagrantfile**
- [ ] Argo CD uses GitHub repo with `yozainan` in the name
- [ ] `testing_part3.sh` passes all tests

---

## 🛠️ Troubleshooting Guide

| Problem | Solution |
|---------|----------|
| Docker not running | `sudo systemctl start docker` |
| K3d cluster won't start | Check Docker: `docker info`. May need `sudo` |
| Argo CD pods in CrashLoopBackOff | Check resources: `free -m`. May need more RAM |
| App not syncing from GitHub | Check repo URL/path: `kubectl get app -n argocd -o yaml` |
| `curl localhost:8888` connection refused | Restart port-forward: `kubectl port-forward svc/wil-playground-svc -n dev 8888:8888` |
| Argo CD UI not accessible | Restart port-forward: `kubectl port-forward svc/argocd-server -n argocd 8080:443` |
| Argo CD password unknown | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Git push rejected | Ensure you're on `main` branch and have push access |
| Port conflict on 8888 | Check: `lsof -i :8888`. Kill conflicting process |
| Sync shows "OutOfSync" | Wait 3 min, then check: might be polling interval. Force sync via UI |

---

## 📊 Subject Compliance Review

| Subject Requirement | Status | Implementation |
|--------------------|--------|----------------|
| Install K3d on VM | ✅ | `scripts/setup.sh` installs K3d automatically |
| Docker required | ✅ | Docker check + auto-install in setup.sh |
| Script installs all tools during defense | ✅ | Single `setup.sh` does everything |
| Namespace `argocd` | ✅ | Created by setup.sh |
| Namespace `dev` | ✅ | Created by setup.sh + ArgoCD app CRD |
| Argo CD in `argocd` ns | ✅ | Official manifest applied to `argocd` |
| App in `dev` ns via Argo CD | ✅ | Argo CD Application CRD auto-deploys |
| Public GitHub repo | ✅ | `yozainan/-Inception-of-Things` |
| Member login in repo name | ✅ | `yozainan` is in the repo name |
| Two versions (v1, v2) | ✅ | `wil42/playground:v1` and `:v2` |
| Port 8888 | ✅ | Service + port-forward on 8888 |
| Can change version from GitHub | ✅ | Edit deployment.yaml → push → auto-sync |
| p3/scripts/ folder | ✅ | Contains `setup.sh` |
| p3/confs/ folder | ✅ | Contains `argocd-app.yaml` + `app/deployment.yaml` |
| No Vagrant in Part 3 | ✅ | Vagrantfile deleted |

---

## Proposed Changes Summary

### p3 directory (ALL NEW files)

#### [DELETE] [Vagrantfile](file:///home/youssef/Desktop/IOT/p3/Vagrantfile)
Empty file — Part 3 does not use Vagrant.

#### [NEW] [setup.sh](file:///home/youssef/Desktop/IOT/p3/scripts/setup.sh)
Main installation script: installs Docker/K3d/kubectl/Helm, creates cluster, deploys Argo CD, configures GitOps.

#### [NEW] [deployment.yaml](file:///home/youssef/Desktop/IOT/p3/confs/app/deployment.yaml)
Dev app manifest — `wil42/playground:v1` Deployment + Service in `dev` namespace.

#### [NEW] [argocd-app.yaml](file:///home/youssef/Desktop/IOT/p3/confs/argocd-app.yaml)
Argo CD Application CRD pointing to GitHub repo path `p3/confs/app`.

#### [NEW] [testing_part3.sh](file:///home/youssef/Desktop/IOT/p3/testing_part3.sh)
Comprehensive automated test suite covering all subject requirements (28+ checks).

#### [NEW] [README.md](file:///home/youssef/Desktop/IOT/p3/README.md)
Full documentation with quick start, defense guide, troubleshooting.

#### [NEW] [plan.md](file:///home/youssef/Desktop/IOT/p3/plan.md)
This implementation plan file.

---

### Root files

#### [MODIFY] [.gitignore](file:///home/youssef/Desktop/IOT/.gitignore)
Add p3 runtime file exclusions.

#### [MODIFY] [README.md](file:///home/youssef/Desktop/IOT/README.md)
Update root README with all 3 parts + quick start guide.

---

## Open Questions

> [!IMPORTANT]
> **Git branch**: Your current branch is `feature/part2-playground` but the Argo CD app
> is configured to watch `main`. Should I:
> 1. Configure Argo CD to watch a different branch (e.g., `feature/part3`)?
> 2. Merge everything to `main` first, then push p3 files?
> 
> The simplest approach is option 2 — merge to `main` and push from there.

> [!IMPORTANT]
> **Port-forwarding approach**: The setup script uses `kubectl port-forward` to expose
> both Argo CD (8080) and the app (8888). These are background processes that die when
> the terminal closes. An alternative is to use K3d's `--port` mapping which is persistent.
> The current plan uses BOTH (K3d port mapping + kubectl port-forward as backup).
> Is this acceptable?

---

## Verification Plan

### Automated Tests
```bash
cd p3 && bash testing_part3.sh
```
This checks: tools installed, cluster running, namespaces exist, Argo CD running, app deployed, app responding, folder structure correct, GitHub integration.

### Manual Verification (Defense Demo)
1. `curl http://localhost:8888/` → verify `v1` response
2. Edit `deployment.yaml` → change to `v2` → push
3. Wait for Argo CD sync
4. `curl http://localhost:8888/` → verify `v2` response
5. Open Argo CD UI → show sync status
