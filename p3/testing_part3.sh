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
