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
