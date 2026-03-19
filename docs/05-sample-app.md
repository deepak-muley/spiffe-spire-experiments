# Sample Application Deployment

This guide deploys a simple workload that obtains its SPIFFE identity from SPIRE and demonstrates the Workload API.

## Two Installation Paths

| Path | Registration | Best For |
|------|--------------|----------|
| **Helm Charts Hardened** | Automatic (ClusterSPIFFEID) | Production, full automation |
| **spire-tutorials / Manual** | Manual `spire-server entry create` | Learning, quickstart |

This doc covers the **manual registration** path, which works with both Helm-installed SPIRE and the raw YAML quickstart. If using Helm with Controller Manager, the default ClusterSPIFFEID may already assign identities to pods in `default` namespace—see [04 - Installation](./04-installation-helm.md#workload-registration-required-for-workloads).

---

## Prerequisites

- KIND cluster created ([03 - Setup](./03-setup-kind.md))
- SPIRE installed via Helm ([04 - Installation](./04-installation-helm.md))
- Agent and workload registration entries created

---

## Step 1: Verify Agent Socket Path

The sample workload mounts the SPIRE Agent's Unix socket. The Helm chart (helm-charts-hardened) uses `/run/spire/agent-sockets` on the host.

**Helm Charts Hardened:** The chart may use the **SPIFFE CSI driver** or a different volume strategy. If workloads get the socket via CSI, the `hostPath` approach in `manifests/client-deployment.yaml` may not work. In that case:

1. Check the chart's workload configuration (values, examples)
2. Use the CSI volume type if the chart supports it
3. Or use the [spire-tutorials](https://github.com/spiffe/spire-tutorials) raw YAML quickstart for a guaranteed hostPath-based setup

To verify the agent's socket path:

```bash
kubectl get configmap -n spire -l app.kubernetes.io/name=spire-agent -o yaml | grep -A5 socket
kubectl get daemonset -n spire spire-agent -o yaml | grep -A10 volumes
```

If your agent uses a different host path, update the `hostPath` in the deployment manifest accordingly.

---

## Step 2: Register Workload (If Not Using Controller Manager)

If you installed SPIRE with default Helm and have Controller Manager, it may auto-register workloads. Skip to Step 3 and deploy; if SVID fetch fails, come back and add manual registration.

### Register Agent (Node) First

```bash
# Get your cluster name - often from kubectl config or values
CLUSTER_NAME="spire-demo"  # or "kind-spire-demo" - check your spire-values.yaml

kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s_psat:cluster:${CLUSTER_NAME} \
  -selector k8s_psat:agent_ns:spire \
  -selector k8s_psat:agent_sa:spire-agent \
  -node
```

**Troubleshooting:** If agent attestation fails, check agent logs for the cluster name it reports:
```bash
kubectl logs -n spire -l app.kubernetes.io/name=spire-agent --tail=100
```

### Register Workload (default namespace, default SA)

```bash
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/default/sa/default \
  -parentID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s:ns:default \
  -selector k8s:sa:default
```

### Register Custom Workload (e.g., client app with dedicated SA)

For the `client` deployment, create a ServiceAccount and register it:

```bash
# Create namespace and service account
kubectl create namespace default 2>/dev/null || true
kubectl create serviceaccount client -n default 2>/dev/null || true

# Register workload for client SA
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/default/sa/client \
  -parentID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s:ns:default \
  -selector k8s:sa:client
```

---

## Step 3: Deploy Sample Workload

We use a minimal deployment that runs `spire-agent api watch` to demonstrate SVID issuance. The manifest is in `manifests/client-deployment.yaml`.

### Option A: Use default ServiceAccount (simplest)

Edit the deployment to use `serviceAccountName: default` (or omit it). Ensure you registered `k8s:sa:default` as above.

### Option B: Use dedicated client ServiceAccount

Update the deployment to use `serviceAccountName: client` and register `k8s:sa:client` as above.

### Deploy

```bash
# From project root
kubectl apply -f manifests/client-deployment.yaml
```

### Verify Pod is Running

```bash
kubectl get pods -l app=client
kubectl get deployment client
```

---

## Step 4: Fetch SVID (Verification)

Once the pod is running, fetch the SVID to verify SPIRE is issuing identities:

```bash
# Get pod name
POD=$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}')

# Fetch X.509 SVID via Workload API
kubectl exec -it $POD -- /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock
```

**Expected output (success):**
```
Received 1 svid(s)

SPIFFE ID: spiffe://example.org/ns/default/sa/default
SVID Valid After: 2024-03-19T12:00:00Z
SVID Valid Until: 2024-03-19T13:00:00Z
...
```

**Common errors:**
- `connection refused` / `no such file or directory` → Agent socket not mounted or agent not running on that node
- `no identity issued` → Registration entry missing or selectors don't match (check namespace, service account)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Pod: client                                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  spire-agent api watch                                │   │
│  │  (calls Workload API at /run/spire/agent-sockets/spire-agent.sock)│   │
│  └──────────────────────────┬────────────────────────────┘   │
│                             │ mount                          │
└─────────────────────────────┼───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Node (host)                                                 │
│  /run/spire/agent-sockets/spire-agent.sock  ◄── SPIRE Agent (DaemonSet)  │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

- **Verify end-to-end** → [06 - Verification](./06-verification.md)
- **Add mTLS between services** → See [07 - Advanced Topics](./07-advanced-topics.md) (Envoy + SPIRE)
