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
└── implementation_plan.md     # Implementation plan
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
| Argo CD password lost | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d` |

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
