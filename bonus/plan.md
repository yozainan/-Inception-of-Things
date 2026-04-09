# Bonus Part — Local GitLab Integration: Complete Implementation Plan

> **Purpose**: This plan explicitly details how to implement the Bonus part of the IoT project. It incorporates K3d, ArgoCD, and a locally hosted GitLab instance within a Vagrant VM, ensuring reproducibility and strict adherence to the subject rules.

---

## 🎯 What the Bonus Part Must Do (from the subject)

- Add **GitLab** to the GitOps workflow completed in Part 3.
- Use the **latest version available** of GitLab.
- The GitLab instance must **run locally** and be integrated with the cluster.
- Create a dedicated namespace named `gitlab`.
- Everything from Part 3 (ArgoCD auto-syncing application versions) must work using your **local GitLab** instead of GitHub.
- Folder must be named `bonus` at the root of the repository.
- Task list requires `bonus/Vagrantfile`, `bonus/scripts/`, `bonus/confs/`.

---

## 📋 Architecture & Resource Allocation

GitLab is notoriously resource-intensive. To prevent out-of-memory (OOM) crashes and CPU bottlenecking while running K3d, ArgoCD, and GitLab concurrently, the Vagrant VM must be adequately provisioned.

| Component      | Specification                                |
|----------------|----------------------------------------------|
| **VM Name**    | `yozainan-bonus`                             |
| **Resources**  | 4 CPUs, **8192 MB RAM** minimum              |
| **IP Address** | `192.168.56.120`                             |
| **Cluster**    | K3d running on Docker inside the Vagrant VM  |
| **Namespaces** | `argocd`, `dev`, `gitlab`                    |
| **Routing**    | Port mappings for ArgoCD, local apps, GitLab |

---

## 📁 Required Folder Structure

```
bonus/
├── Vagrantfile                # Beefy VM definition
├── scripts/
│   ├── setup.sh               # Main installation & orchestration script
│   └── gitlab_seeder.sh     # Automates repo creation and pushing code to Gitlab
├── confs/
│   ├── gitlab.yaml            # Deployment & Service for gitlab/gitlab-ce:latest
│   ├── argocd-app.yaml        # ArgoCD Application CRD bridging to local GitLab
│   └── app-manifests/         # The dev app code that gets pushed to GitLab
│       └── deployment.yaml
├── testing_bonus.sh           # Test suite
├── logs.txt                   # Auto-generated provisioning logs
└── plan.md                    # This file
```

---

## 🚀 STEP-BY-STEP IMPLEMENTATION PLAN

### STEP 1 — Create the Vagrantfile
**File**: `bonus/Vagrantfile`
- Defines `yozainan-bonus` using Debian `bookworm64`.
- Allocates 8GB RAM + 4 CPU cores.
- Forwards necessary ports (8080 usually for web, 8888 for the playground app).
- Executes `scripts/setup.sh` upon provisioning.

### STEP 2 — Create GitLab Kubernetes Manifests
**File**: `bonus/confs/gitlab.yaml`
- Deploy `gitlab/gitlab-ce:latest` inside the `gitlab` namespace.
- Use a `Deployment` instead of a Helm chart for GitLab to lower the overhead and simplify configuration. (We'll use Helm for ArgoCD, proving we know how to use it, but raw manifests for GitLab are much more stable in a K3d environment).
- Define a `Service` (`gitlab-svc`) exposing port 80 and 22.

### STEP 3 — Create Setup Script (The Heavy Lifter)
**File**: `bonus/scripts/setup.sh`
- **Dependencies**: Install Docker, curl, Git.
- **Tools**: Install K3d, Helm, kubectl, ArgoCD CLI.
- **Cluster**: `k3d cluster create bonus-cluster -p "8888:8888@loadbalancer" -p "8080:80@loadbalancer"`
- **Namespaces**: Create `argocd`, `dev`, `gitlab`.
- **GitLab Deploy**: Apply `gitlab.yaml` and wait for readiness. *Caution: GitLab takes 5-10 minutes to boot.*
- **ArgoCD Deploy**: Install via Helm or official manifest. Wait for readiness. Disable auth for simplicity or auto-configure the admin password.

### STEP 4 — Automate GitLab Repository Seeding
**File**: `bonus/scripts/gitlab_seeder.sh`
- Once GitLab is Ready, extract its initial root password via `kubectl exec`.
- Use the GitLab REST API to create a Personal Access Token (PAT).
- Use the API to create a new repository called `iot-app`.
- Initialize a local git repo `confs/app-manifests/`, commit the v1 `deployment.yaml` (using Wil's `wil42/playground:v1`), and `git push` it directly into the local `gitlab-svc` using the PAT.

### STEP 5 — Configure ArgoCD to Track Local GitLab
**File**: `bonus/confs/argocd-app.yaml`
- Create an `Application` CRD.
- `repoURL`: `http://gitlab-svc.gitlab.svc.cluster.local/root/iot-app.git` (ArgoCD can route to it internally via K8s DNS!).
- `targetRevision`: `master` or `main`.
- `path`: `.`
- Apply this file so ArgoCD starts syncing the playground app into the `dev` namespace.

### STEP 6 — Testing and Validation Script
**File**: `bonus/testing_bonus.sh`
- Checks whether namespaces exist.
- Asserts that ArgoCD pods and GitLab pod are Running.
- Verifies the app is exposed on `http://192.168.56.120:8888` and returns `v1`.
- Tests changing the Git manifest dynamically to `v2` and pushing it to the local GitLab.
- Waits for ArgoCD auto-sync, then verifies the endpoint returns `v2`.

---

## 🛠️ Execution Strategy & Challenges

### The "Heavy Gitlab" Problem
GitLab requires enormous resources to boot quickly. If K3d is fighting for memory, it might `OOMKilled` Gitlab.
**Mitigation**: The Vagrantfile strictly assigns 8GB RAM. The `setup.sh` waits using robust loops with long timeouts for GitLab to signal readiness.

### The "GitOps Loop" Challenge
ArgoCD must know how to pull from the local GitLab. Since both live in the same K3d cluster, ArgoCD can bypass external networking and request internal Kubernetes DNS (`gitlab-svc.gitlab.svc.cluster.local`).
**Mitigation**: The seeding script handles repository scaffolding via cURL API calls before ArgoCD begins to watch it.

---

## ✅ Review Request
If this implementation design satisfies your expectations for the Bonus, please approve. Upon approval, I will execute this plan, write all concrete code blocks, build the files, start Vagrant, and generate the `README.md`.
