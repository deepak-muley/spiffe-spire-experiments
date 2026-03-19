#!/bin/bash
# SPIFFE/SPIRE Demo Setup Script
# Prerequisites: kind, kubectl, helm
# Creates KIND cluster, installs SPIRE via Helm, registers workloads, deploys sample app

set -e

CLUSTER_NAME="${CLUSTER_NAME:-spire-demo}"
TRUST_DOMAIN="${TRUST_DOMAIN:-example.org}"

# For KIND: cluster name in k8s_psat may be "kind-<name>". If attestation fails, try:
# CLUSTER_NAME=kind-spire-demo ./scripts/setup-demo.sh

echo "=== SPIFFE/SPIRE Demo Setup (Helm) ==="
echo "Cluster: $CLUSTER_NAME"
echo "Trust Domain: $TRUST_DOMAIN"
echo ""

# 1. Create KIND cluster
echo ">>> Creating KIND cluster..."
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
else
  kind create cluster --name "$CLUSTER_NAME"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"

# 2. Install SPIRE via Helm
echo ">>> Installing SPIRE..."
helm repo add spiffe https://spiffe.github.io/helm-charts-hardened/ 2>/dev/null || true
helm repo update

helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
  --repo https://spiffe.github.io/helm-charts-hardened/

helm upgrade --install -n spire spire spire \
  --repo https://spiffe.github.io/helm-charts-hardened/ \
  --set "global.spire.clusterName=$CLUSTER_NAME" \
  --set "global.spire.trustDomain=$TRUST_DOMAIN"

# 3. Wait for SPIRE to be ready
echo ">>> Waiting for SPIRE Server..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=spire-server -n spire --timeout=120s 2>/dev/null || true

echo ">>> Waiting for SPIRE Agent..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=spire-agent -n spire --timeout=120s 2>/dev/null || true

# 4. Register agent (node) - may fail if controller manager already did it
echo ">>> Registering SPIRE Agent (node)..."
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID "spiffe://${TRUST_DOMAIN}/ns/spire/sa/spire-agent" \
  -selector "k8s_psat:cluster:${CLUSTER_NAME}" \
  -selector "k8s_psat:agent_ns:spire" \
  -selector "k8s_psat:agent_sa:spire-agent" \
  -node 2>/dev/null || echo "Agent entry may already exist (ok if using controller manager)"

# 5. Register workload (default ns, default SA)
echo ">>> Registering workload (default/default)..."
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID "spiffe://${TRUST_DOMAIN}/ns/default/sa/default" \
  -parentID "spiffe://${TRUST_DOMAIN}/ns/spire/sa/spire-agent" \
  -selector "k8s:ns:default" \
  -selector "k8s:sa:default" 2>/dev/null || echo "Workload entry may already exist"

# 6. Deploy sample client
echo ">>> Deploying sample workload..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$(dirname "$SCRIPT_DIR")/manifests"
kubectl apply -f "$MANIFESTS_DIR/client-deployment.yaml"

# 7. Wait for client pod
echo ">>> Waiting for client pod..."
kubectl wait --for=condition=ready pod -l app=client --timeout=60s 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Verify with:"
echo "  kubectl exec -it \$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}') -- \\"
echo "    /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock"
echo ""
echo "Note: Helm charts (helm-charts-hardened) use /run/spire/agent-sockets/spire-agent.sock"
echo ""
