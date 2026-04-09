# Inception-of-Things (IoT) - Chronological Task List (Debian Host)

## Extracted Hard Constraints From the Subject
- [ ] VM resource target for Part 1: 1 CPU and 512 MB RAM (or 1024 MB).
- [ ] Part 1 dedicated IP for Server node: 192.168.56.110.
- [ ] Part 1 dedicated IP for ServerWorker node: 192.168.56.111.
- [ ] Hostname rule for first node: login + S.
- [ ] Hostname rule for second node: login + SW.
- [ ] Hostnames with your login (khalil): khalilS and khalilSW.
- [ ] Part 1 node roles: first machine in controller mode, second machine in agent mode.
- [ ] Part 2 runs on one VM with K3s in server mode.
- [ ] Part 2 access IP: 192.168.56.110.
- [ ] Part 2 ingress rule: Host app1.com routes to app1.
- [ ] Part 2 ingress rule: Host app2.com routes to app2.
- [ ] Part 2 ingress default behavior: if host does not match app1.com or app2.com, route to app3.
- [ ] Part 2 replica requirement explicitly shown: application 2 has 3 replicas.
- [ ] Part 3 required namespaces: argocd and dev.
- [ ] Bonus required namespace: gitlab.
- [ ] Part 3 app versioning requirement: two versions, tagged v1 and v2.
- [ ] If using Wil's sample app: image wil42/playground, application port 8888.
- [ ] Bonus grading rule: bonus is evaluated only if all mandatory requirements are fully completed and flawless.

## Phase 0: Learning and Preparation
### Networking Concepts To Review
- [ ] Private VM networking with static addressing (192.168.56.0/24 context used by the subject examples).
- [ ] Primary network interface identification on modern Linux (predictable names such as enp0s8, enp0s9).
- [ ] Host header based routing and why the same IP can serve multiple apps through Ingress.
- [ ] Basic SSH key authentication for passwordless access.
- [ ] Linux network inspection commands: ip a and ip a show <interface_name>.

### Container Orchestration Concepts To Review
- [ ] Kubernetes core objects: Namespace, Deployment, Service, Ingress, Pod, ReplicaSet.
- [ ] K3s architecture basics and node roles (controller/server vs agent/worker).
- [ ] kubectl usage for validation and troubleshooting.
- [ ] Ingress matching order and default backend behavior.
- [ ] Image tags and rollout behavior when changing from v1 to v2.

### Virtualization and Lab Operations To Review
- [ ] Vagrantfile structure and modern provisioning practices.
- [ ] VM sizing strategy under low resources (1 CPU, 512 MB or 1024 MB RAM).
- [ ] Scripted provisioning in scripts folders and split configuration in confs folders.
- [ ] Difference between K3s (lightweight Kubernetes distribution) and K3d (K3s inside Docker).
- [ ] Defense-time reproducibility: one-command or scripted environment setup.

## Part 1: K3s and Vagrant (p1)
- [ ] Step 1: Create p1 workspace files with at least p1/Vagrantfile, p1/scripts, and p1/confs.
- [ ] Step 2: Define two VMs in Vagrant using a latest stable Linux distribution.
- [ ] Step 3: Apply minimal resources per VM: 1 CPU and 512 MB RAM (or 1024 MB).
- [ ] Step 4: Set VM names and hostnames using your login exactly as required.
- [ ] Step 5: Use khalilS for Server and khalilSW for ServerWorker.
- [ ] Step 6: Configure dedicated primary-interface IPs exactly: khalilS -> 192.168.56.110 and khalilSW -> 192.168.56.111.
- [ ] Step 7: Configure SSH so both machines are reachable without password.
- [ ] Step 8: Provision K3s on khalilS in controller mode.
- [ ] Step 9: Provision K3s on khalilSW in agent mode and join it to the controller.
- [ ] Step 10: Install kubectl and validate cluster visibility from the controller.
- [ ] Step 11: Validate interfaces and IP assignment with ip a before defense.

## Part 2: K3s and Three Simple Applications (p2)
- [ ] Step 1: Create p2 workspace files with at least p2/Vagrantfile, p2/scripts, and p2/confs.
- [ ] Step 2: Provision one VM (latest stable Linux) with K3s in server mode.
- [ ] Step 3: Name the machine khalilS and ensure it serves requests on 192.168.56.110.
- [ ] Step 4: Deploy three web applications in the cluster (app1, app2, app3 or equivalents).
- [ ] Step 5: Define Service objects so each app is reachable internally.
- [ ] Step 6: Define Deployment replica counts.
- [ ] Step 7: Set app2 replicas to 3 (explicitly required in the subject diagram).
- [ ] Step 8: Keep app1 and app3 as single replicas unless you intentionally choose otherwise.
- [ ] Step 9: Implement Ingress host routing exactly as described.
- [ ] Step 10: Route Host app1.com to app1.
- [ ] Step 11: Route Host app2.com to app2.
- [ ] Step 12: Configure default backend/fallback route to app3 when host does not match.
- [ ] Step 13: Prepare defense proof for Ingress because evaluators must see the Ingress object explicitly.

## Part 3: K3d and Argo CD (p3)
- [ ] Step 1: Create p3 workspace files with at least p3/scripts and p3/confs.
- [ ] Step 2: Install Docker and K3d on your Debian host VM.
- [ ] Step 3: Write a script that installs all required tools and packages for reproducibility during defense.
- [ ] Step 4: Create and start a K3d cluster.
- [ ] Step 5: Create namespace argocd.
- [ ] Step 6: Create namespace dev.
- [ ] Step 7: Install Argo CD in namespace argocd.
- [ ] Step 8: Create a public GitHub repository for manifests; include a group member login in the repository name.
- [ ] Step 9: Add deployment manifests for the dev application in that repository.
- [ ] Step 10: Configure Argo CD to automatically deploy and synchronize the app from GitHub into namespace dev.
- [ ] Step 11: Use an image strategy with two tags: v1 and v2.
- [ ] Step 12: If using Wil's app, use wil42/playground and expose/verify behavior on port 8888.
- [ ] Step 13: Validate GitOps flow end-to-end.
- [ ] Step 14: Confirm v1 is running.
- [ ] Step 15: Change manifest image tag to v2 in GitHub, commit, and push.
- [ ] Step 16: Confirm Argo CD syncs and the running app updates to v2.

## Bonus: Local GitLab Integration (bonus)
- [ ] Step 1: Create bonus workspace files with at least bonus/Vagrantfile, bonus/scripts, and bonus/confs.
- [ ] Step 2: Install the latest official GitLab version locally.
- [ ] Step 3: Ensure the GitLab instance runs locally on your lab machine.
- [ ] Step 4: Integrate GitLab with your cluster setup.
- [ ] Step 5: Create namespace gitlab in the cluster.
- [ ] Step 6: Reproduce Part 3 behavior with local GitLab as the Git source for your GitOps workflow. 
- [ ] Step 7: Confirm Argo CD driven deploy/update still works under this local GitLab flow.
- [ ] Step 8: Re-check mandatory part quality before defense.
- [ ] Step 9: Remember strict grading prerequisite: if mandatory is not flawless, bonus is not evaluated at all.

## Final Submission Checklist
- [ ] Confirm repository root contains p1, p2, p3.
- [ ] If you submit bonus, confirm bonus is also present at repository root.
- [ ] Confirm p1 contains Vagrantfile, scripts folder, confs folder.
- [ ] Confirm p2 contains Vagrantfile, scripts folder, confs folder.
- [ ] Confirm p3 contains scripts folder and confs folder.
- [ ] Confirm bonus contains Vagrantfile, scripts folder, confs folder.
- [ ] Confirm all automation scripts are in scripts folders.
- [ ] Confirm all configuration files are in confs folders.
- [ ] Confirm folder and file names match the subject exactly before peer-evaluation.
