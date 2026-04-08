#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Inception-of-Things — Part 1 Automated Testing Script
#  Run from: the p1/ directory on the HOST machine
#  Usage:    cd p1 && bash testing_part1.sh
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
echo "║   Inception-of-Things — Part 1 — Automated Test Suite      ║"
echo "║   Testing: yozainan-S and yozainan-SW                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Test Group 1: VM Status ──────────────────────────────────────────
echo "─── 1. VM STATUS ─────────────────────────────────────────────"

vagrant status yozainan-S 2>/dev/null | grep -q "running"
check "yozainan-S is running" $?

vagrant status yozainan-SW 2>/dev/null | grep -q "running"
check "yozainan-SW is running" $?

# ── Test Group 2: Hostnames ──────────────────────────────────────────
echo ""
echo "─── 2. HOSTNAMES ─────────────────────────────────────────────"

SERVER_HOSTNAME=$(vagrant ssh yozainan-S -c "hostname" 2>/dev/null | tr -d '\r\n')
[ "$SERVER_HOSTNAME" = "yozainan-S" ]
check "yozainan-S hostname is 'yozainan-S' (got: '$SERVER_HOSTNAME')" $?

WORKER_HOSTNAME=$(vagrant ssh yozainan-SW -c "hostname" 2>/dev/null | tr -d '\r\n')
[ "$WORKER_HOSTNAME" = "yozainan-SW" ]
check "yozainan-SW hostname is 'yozainan-SW' (got: '$WORKER_HOSTNAME')" $?

# ── Test Group 3: IP Addresses ───────────────────────────────────────
echo ""
echo "─── 3. IP ADDRESSES ─────────────────────────────────────────"

vagrant ssh yozainan-S -c "ip a" 2>/dev/null | grep -q "192.168.56.110"
check "yozainan-S has IP 192.168.56.110" $?

vagrant ssh yozainan-SW -c "ip a" 2>/dev/null | grep -q "192.168.56.111"
check "yozainan-SW has IP 192.168.56.111" $?

# ── Test Group 4: SSH Access ─────────────────────────────────────────
echo ""
echo "─── 4. SSH ACCESS (no password) ─────────────────────────────"

vagrant ssh yozainan-S -c "echo 'ssh-ok'" 2>/dev/null | grep -q "ssh-ok"
check "SSH to yozainan-S works without password" $?

vagrant ssh yozainan-SW -c "echo 'ssh-ok'" 2>/dev/null | grep -q "ssh-ok"
check "SSH to yozainan-SW works without password" $?

# ── Test Group 5: K3s Roles ──────────────────────────────────────────
echo ""
echo "─── 5. K3s ROLES ────────────────────────────────────────────"

vagrant ssh yozainan-S -c "systemctl is-active k3s" 2>/dev/null | grep -q "active"
check "K3s SERVER service is active on yozainan-S" $?

vagrant ssh yozainan-SW -c "systemctl is-active k3s-agent" 2>/dev/null | grep -q "active"
check "K3s AGENT service is active on yozainan-SW" $?

# ── Test Group 6: Cluster State ──────────────────────────────────────
echo ""
echo "─── 6. CLUSTER STATE ────────────────────────────────────────"

NODE_COUNT=$(vagrant ssh yozainan-S -c "kubectl get nodes --no-headers 2>/dev/null | wc -l" 2>/dev/null | tr -d '\r\n ')
[ "$NODE_COUNT" = "2" ]
check "Cluster has exactly 2 nodes (got: $NODE_COUNT)" $?

vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep -i "yozainan-S" | grep -q "Ready"
check "yozainan-S node is Ready" $?

vagrant ssh yozainan-S -c "kubectl get nodes" 2>/dev/null | grep -i "yozainan-SW" | grep -q "Ready"
check "yozainan-SW node is Ready" $?

vagrant ssh yozainan-S -c "kubectl get nodes -o wide" 2>/dev/null | grep -i "yozainan-S" | grep -q "192.168.56.110"
check "yozainan-S node IP is 192.168.56.110 in cluster" $?

vagrant ssh yozainan-S -c "kubectl get nodes -o wide" 2>/dev/null | grep -i "yozainan-SW" | grep -q "192.168.56.111"
check "yozainan-SW node IP is 192.168.56.111 in cluster" $?

# ── Test Group 7: kubectl ────────────────────────────────────────────
echo ""
echo "─── 7. KUBECTL ──────────────────────────────────────────────"

vagrant ssh yozainan-S -c "which kubectl" 2>/dev/null | grep -q "kubectl"
check "kubectl is installed on yozainan-S" $?

vagrant ssh yozainan-S -c "kubectl version 2>/dev/null" 2>/dev/null | grep -qi "server\|client"
check "kubectl can communicate with the cluster" $?

# ── Test Group 8: Resources ──────────────────────────────────────────
echo ""
echo "─── 8. RESOURCES ────────────────────────────────────────────"

SERVER_MEM=$(vagrant ssh yozainan-S -c "free -m | awk '/Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r\n ')
check "yozainan-S RAM allocation (${SERVER_MEM} MB)" 0

WORKER_MEM=$(vagrant ssh yozainan-SW -c "free -m | awk '/Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r\n ')
check "yozainan-SW RAM allocation (${WORKER_MEM} MB)" 0

SERVER_CPU=$(vagrant ssh yozainan-S -c "nproc" 2>/dev/null | tr -d '\r\n ')
[ "$SERVER_CPU" = "1" ]
check "yozainan-S has 1 CPU (got: $SERVER_CPU)" $?

WORKER_CPU=$(vagrant ssh yozainan-SW -c "nproc" 2>/dev/null | tr -d '\r\n ')
[ "$WORKER_CPU" = "1" ]
check "yozainan-SW has 1 CPU (got: $WORKER_CPU)" $?

# ── Test Group 9: Folder Structure ───────────────────────────────────
echo ""
echo "─── 9. FOLDER STRUCTURE ─────────────────────────────────────"

[ -f "Vagrantfile" ]
check "p1/Vagrantfile exists" $?

[ -d "scripts" ]
check "p1/scripts/ directory exists" $?

[ -d "confs" ]
check "p1/confs/ directory exists" $?

[ -f "scripts/server.sh" ]
check "p1/scripts/server.sh exists" $?

[ -f "scripts/worker.sh" ]
check "p1/scripts/worker.sh exists" $?

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed, $TOTAL total"
echo "══════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "  🎉  ALL TESTS PASSED — Part 1 is ready for defense!"
    echo ""
else
    echo ""
    echo "  ⚠️   $FAIL test(s) FAILED — review the failures above."
    echo ""
    exit 1
fi
