#!/usr/bin/env bash
# 驗證 hello-web 服務已正常部署且可運作
set -euo pipefail

DEPLOY=hello-web
SVC=hello-web
EXPECT="Hello from Kubernetes on kind!"

fail() { echo "❌ $1"; exit 1; }

echo "== 1. 等待 Deployment 部署完成 =="
kubectl rollout status deployment/"$DEPLOY" --timeout=120s || fail "Deployment 未在時限內就緒"

echo "== 2. 檢查 Pod 就緒數量 =="
WANT=$(kubectl get deploy "$DEPLOY" -o jsonpath='{.spec.replicas}')
READY=$(kubectl get deploy "$DEPLOY" -o jsonpath='{.status.readyReplicas}')
echo "期望 ${WANT} 個，就緒 ${READY:-0} 個"
[ "${READY:-0}" = "$WANT" ] || fail "就緒 Pod 數量不足"
kubectl get pods -l app="$DEPLOY" -o wide

echo "== 3. 檢查 Service 有對應的 Endpoints =="
EP=$(kubectl get endpoints "$SVC" -o jsonpath='{.subsets[*].addresses[*].ip}')
[ -n "$EP" ] || fail "Service 沒有可用的 Endpoints"
echo "Endpoints: $EP"

echo "== 4. 透過 port-forward 發送 HTTP 請求 =="
kubectl port-forward svc/"$SVC" 8080:80 >/tmp/pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT

CODE=000
for i in $(seq 1 10); do
  CODE=$(curl -s -o /tmp/body.html -w '%{http_code}' http://localhost:8080 || true)
  [ "$CODE" = "200" ] && break
  echo "第 ${i} 次嘗試，HTTP ${CODE}，2 秒後重試..."
  sleep 2
done
[ "$CODE" = "200" ] || fail "HTTP 狀態碼為 ${CODE}，預期 200"
echo "HTTP 狀態碼：${CODE}"

echo "== 5. 檢查回應內容 =="
cat /tmp/body.html
grep -q "$EXPECT" /tmp/body.html || fail "回應內容不符合預期"

echo "✅ 所有檢查通過：服務已正常部署且可運作"
