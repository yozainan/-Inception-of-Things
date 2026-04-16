# Part 2 — K3s and Three Simple Applications

This folder contains the complete deployment for **Inception-of-Things (IoT) - Part 2**.
It defines a single virtual machine running Kubernetes (K3s in server mode) and deploys three sample web applications exposed via **Ingress host-based routing**.

## Environment Details

| Component        | Specification                             |
|------------------|-------------------------------------------|
| **OS**           | Debian 12 (latest stable `bookworm64`)    |
| **VM Name / Hostname** | `yozainan-S`                        |
| **Resources**    | 1 CPU, 1024 MB RAM                        |
| **IP Address**   | `192.168.56.110` (Private Network)        |
| **Kubernetes**   | K3s (Server mode, with Traefik enabled)   |
| **Orchestrator** | VirtualBox & Vagrant                      |

---

## Deployed Applications & Routing

The cluster hosts three simple web applications. Routing is handled by Traefik Ingress based on the `Host` header of the HTTP request.

| Host Header          | Target Application | Replicas | Expected Output                |
|----------------------|--------------------|----------|--------------------------------|
| `app1.com`           | `app1`             | 1        | "Hello from app-one!"          |
| `app2.com`           | `app2`             | 3        | "Hello from app-two!"          |
| *(anything else)*    | `app3` (default)   | 1        | "Hello from app-three!"        |

> **Note on Replicas**: Application 2 explicitly requires 3 replicas based on the architectural diagram strictly defined in the project subject.

---

## Directory Structure

```
p2/
├── Vagrantfile              # One VM definition for yozainan-S
├── scripts/
│   └── server.sh            # Installs K3s, waits for readiness, applies apps.yaml + ingress.yaml
├── confs/
│   ├── apps.yaml            # Deployments, Services, and InitContainers for all 3 applications
│   └── ingress.yaml         # Traefik Ingress rules with defaultBackend configurations
├── testing_part2.sh         # Automated validation script matching subject prerequisites
└── logs.txt                 # Auto-generated runtime logs from VM provisioning
```

---

## Execution & Defense Testing

### 1. Start the Environment
Ensure your terminal is located in the `p2` directory and that any previous VMs utilizing `.110` (from Part 1) are halted:
```bash
cd p1 && vagrant halt
cd p2 && vagrant up
```

### 2. Validation / Automated Testing
Run the provided test script to ensure all components pass the subject requirements strictly before evaluation:
```bash
bash testing_part2.sh
```

### 3. Manual Ingress Verification
Test the applications routing using `curl` with manipulated Host headers from within the VM or Host:
```bash
vagrant ssh yozainan-S
curl -H 'Host: app1.com' http://192.168.56.110
curl -H 'Host: app2.com' http://192.168.56.110
curl -H 'Host: whatever.com' http://192.168.56.110
curl http://192.168.56.110
```

To test from your host system browser, map them in your host's `/etc/hosts`:
```
192.168.56.110 app1.com app2.com
```

### 4. Demonstrating the Ingress Object to Evaluators
As required by the subject specifications ("The Ingress is not displayed here on purpose. You will have to show it to your evaluators."):
```bash
vagrant ssh yozainan-S -c "kubectl describe ingress main-ingress"
```
