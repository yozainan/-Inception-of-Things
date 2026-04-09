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

# K3s lowercases hostnames for node names — must use lowercase grep
vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep -i "yozainan-s" | grep -q "Ready"
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
# jsonpath with single-quotes breaks through vagrant ssh -c; use -o json | python/grep workaround
APP1_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-one -o json" 2>/dev/null | grep '"replicas"' | head -1 | tr -d ' 
' | grep -o '[0-9]*')
[ "$APP1_REPLICAS" = "1" ]
check "app-one has 1 replica (got: $APP1_REPLICAS)" $?

APP2_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-two -o json" 2>/dev/null | grep '"replicas"' | head -1 | tr -d ' 
' | grep -o '[0-9]*')
[ "$APP2_REPLICAS" = "3" ]
check "app-two has 3 replicas (got: $APP2_REPLICAS) ← SUBJECT REQUIREMENT" $?

APP3_REPLICAS=$(vagrant ssh yozainan-S -c "kubectl get deployment app-three -o json" 2>/dev/null | grep '"replicas"' | head -1 | tr -d ' 
' | grep -o '[0-9]*')
[ "$APP3_REPLICAS" = "1" ]
check "app-three has 1 replica (got: $APP3_REPLICAS)" $?

# Check all pods Running — count pods in Running state (init containers don't count separately)
TOTAL_PODS=$(vagrant ssh yozainan-S -c "kubectl get pods --no-headers 2>/dev/null | grep -v 'Completed' | wc -l" 2>/dev/null | tr -d '\r\n ')
RUNNING_PODS=$(vagrant ssh yozainan-S -c "kubectl get pods --no-headers 2>/dev/null | grep -c 'Running'" 2>/dev/null | tr -d '\r\n ')
[ "$RUNNING_PODS" -eq 5 ] 2>/dev/null
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

# Use -o json + grep to safely extract fields through vagrant ssh (no single-quote jsonpath)
vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o json" 2>/dev/null | grep -q '"app1.com"'
check "Ingress has rule for host 'app1.com'" $?

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o json" 2>/dev/null | grep -q '"app2.com"'
check "Ingress has rule for host 'app2.com'" $?

vagrant ssh yozainan-S -c "kubectl get ingress main-ingress -o json" 2>/dev/null | grep -q '"app-three-svc"'
check "Ingress routes to app-three-svc as default fallback" $?

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
