#!/bin/bash
# Alternative: Use spire-tutorials raw YAML for guaranteed compatibility with client-deployment
# This uses hostPath for the agent socket, which works with manifests/client-deployment.yaml

set -e

# For KIND, the cluster name in k8s_psat is often "kind-<cluster-name>"
CLUSTER_NAME="${CLUSTER_NAME:-kind-spire-demo}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-spire-demo}"
TUTORIALS_DIR="${TUTORIALS_DIR:-/tmp/spire-tutorials}"

echo "=== SPIFFE/SPIRE Demo (spire-tutorials) ==="
echo "KIND cluster: $KIND_CLUSTER_NAME"
echo "Registration cluster name: $CLUSTER_NAME"
echo ""

# Create KIND cluster if it doesn't exist
if ! kind get clusters 2>/dev/null | grep -q "^${KIND_CLUSTER_NAME}$"; then
  echo ">>> Creating KIND cluster..."
  kind create cluster --name "$KIND_CLUSTER_NAME"
fi
kubectl config use-context "kind-${KIND_CLUSTER_NAME}"

# Clone spire-tutorials if needed
if [ ! -d "$TUTORIALS_DIR/k8s/quickstart" ]; then
  echo ">>> Cloning spire-tutorials..."
  git clone --depth 1 https://github.com/spiffe/spire-tutorials "$TUTORIALS_DIR"
fi

cd "$TUTORIALS_DIR/k8s/quickstart"

# Create namespace and server resources
echo ">>> Creating SPIRE namespace and server..."
kubectl apply -f spire-namespace.yaml
kubectl apply -f server-account.yaml -f spire-bundle-configmap.yaml -f server-cluster-role.yaml
kubectl apply -f server-configmap.yaml -f server-statefulset.yaml -f server-service.yaml

# Create agent
echo ">>> Creating SPIRE agent..."
kubectl apply -f agent-account.yaml -f agent-cluster-role.yaml
kubectl apply -f agent-configmap.yaml -f agent-daemonset.yaml

# Wait for SPIRE
echo ">>> Waiting for SPIRE..."
kubectl wait --for=condition=ready pod -l app=spire-server -n spire --timeout=120s 2>/dev/null || true
sleep 5

# Register agent (node)
echo ">>> Registering agent..."
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector "k8s_psat:cluster:${CLUSTER_NAME}" \
  -selector k8s_psat:agent_ns:spire \
  -selector k8s_psat:agent_sa:spire-agent \
  -node

# Register workload
echo ">>> Registering workload..."
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/default/sa/default \
  -parentID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s:ns:default \
  -selector k8s:sa:default

# Deploy client from this repo
echo ">>> Deploying sample client..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$(dirname "$SCRIPT_DIR")/manifests"
kubectl apply -f "$MANIFESTS_DIR/client-deployment.yaml"

echo ">>> Waiting for client pod..."
kubectl wait --for=condition=ready pod -l app=client --timeout=60s 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Verify with:"
echo "  kubectl exec -it \$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}') -- \\"
echo "    /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock"
echo ""
