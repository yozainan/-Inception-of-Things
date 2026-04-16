#!/bin/bash
set -eo pipefail

export KUBECONFIG=/home/vagrant/.kube/config

# Configuration
GITLAB_URL="http://gitlab-svc.gitlab.svc.cluster.local"
PASS="rootuserpassword123"

echo ">>> [GitLab Seeder] Verifying GitLab API readiness..."
TIMEOUT=300
ELAPSED=0
while true; do
  HTTP_STATUS=$(kubectl exec -n gitlab deployment/gitlab -- curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v4/version || echo "000")
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "GitLab API is up!"
    break
  fi
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ">>> [GitLab Seeder] ERROR: GitLab API failed to respond..."
    exit 1
  fi
  echo "    Waiting for GitLab API... (${ELAPSED}s/${TIMEOUT}s)"
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

echo ">>> [GitLab Seeder] Creating Personal Access Token via REST API..."
# Create Personal Access Token manually using a secure workaround (rails runner script)
kubectl exec -n gitlab deployment/gitlab -- gitlab-rails runner "user = User.find_by_username('root'); token = user.personal_access_tokens.create(scopes: ['api', 'write_repository', 'read_repository'], name: 'Automation Token'); token.set_token('glpat-secrettoken12345678'); token.save!"

export PAT="glpat-secrettoken12345678"

echo ">>> [GitLab Seeder] Creating 'iot-app' Project..."
kubectl exec -n gitlab deployment/gitlab -- curl -s --request POST --header "PRIVATE-TOKEN: $PAT" \
  --url "http://localhost/api/v4/projects" \
  --data "name=iot-app&visibility=public" || true

echo ">>> [GitLab Seeder] Configuring local git and pushing manifests..."
mkdir -p /tmp/git-repo
cp -r /vagrant/confs/app-manifests /tmp/git-repo/
cd /tmp/git-repo/app-manifests
git init
git config --global user.email "admin@example.com"
git config --global user.name "Administrator"
git config --global http.sslVerify false

git branch -m master || true
git add .
git commit -m "Initial commit - v1"

# We must push from inside the cluster OR via nodeport since gitlab-svc is internal Kubernetes DNS
kubectl exec -n gitlab deployment/gitlab -- bash -c "rm -rf /tmp/repo && git clone http://root:${PAT}@localhost/root/iot-app.git /tmp/repo"

# Copy files explicitly to the cloned repo inside the pod and push
kubectl cp /tmp/git-repo/app-manifests/deployment.yaml gitlab/$(kubectl get pod -n gitlab -l app=gitlab -o jsonpath='{.items[0].metadata.name}'):/tmp/repo/deployment.yaml
kubectl exec -n gitlab deployment/gitlab -- bash -c "cd /tmp/repo && git config user.email 'admin@example.com' && git config user.name 'Admin' && git add . && git commit -m 'Release v1' && git push origin HEAD:master"

echo ">>> [GitLab Seeder] Seed process complete!"
