#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Bonus Testing Script
# ═══════════════════════════════════════════════════════════════════════

PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo "  ✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Inception-of-Things — Bonus Part Automated Test Suite    ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# 1. Check VM is running
vagrant status yozainan-bonus 2>/dev/null | grep -q "running"
check "yozainan-bonus VM is running" $?

# 2. Check namespaces
vagrant ssh yozainan-bonus -c "kubectl get ns argocd" 2>/dev/null | grep -q "argocd"
check "Namespace 'argocd' exists" $?

vagrant ssh yozainan-bonus -c "kubectl get ns dev" 2>/dev/null | grep -q "dev"
check "Namespace 'dev' exists" $?

vagrant ssh yozainan-bonus -c "kubectl get ns gitlab" 2>/dev/null | grep -q "gitlab"
check "Namespace 'gitlab' exists" $?

# 3. Check GitLab is Running
vagrant ssh yozainan-bonus -c "kubectl get pods -n gitlab" 2>/dev/null | grep gitlab | grep -q "Running"
check "GitLab pod is Running" $?

# 4. Check ArgoCD is Running
vagrant ssh yozainan-bonus -c "kubectl get pods -n argocd" 2>/dev/null | grep argocd-server | grep -q "Running"
check "ArgoCD Server pod is Running" $?

# 5. Check Dev Application is Running
vagrant ssh yozainan-bonus -c "kubectl get pods -n dev" 2>/dev/null | grep wil-playground | grep -q "Running"
check "wil-playground pod is Running in dev namespace" $?

# 6. Verify curl output gives "v1"
CURL_OUT=$(vagrant ssh yozainan-bonus -c "curl -s http://localhost:8888" 2>/dev/null)
echo "$CURL_OUT" | grep -q "v1"
check "Playground App returns 'v1' on port 8888" $?

echo "══════════════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════════════"
