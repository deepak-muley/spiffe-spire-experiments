# SPIRE Installation with Helm

This guide covers installing SPIRE on Kubernetes using the official **Helm Charts Hardened** repository. Suitable for both demo (KIND) and production-like setups.

## Helm Chart Overview

As of 2024, the SPIFFE project provides:

| Chart Repo | Purpose |
|------------|---------|
| **helm-charts-hardened** | Production-ready, opinionated configuration |
| **helm-charts-flex** | Flexible, customizable configuration |

We use **helm-charts-hardened** for simplicity and best practices.

**Repository:** https://github.com/spiffe/helm-charts-hardened

---

## Alternative: spire-tutorials (Raw YAML)

For a **guaranteed hostPath-based** setup that works with the sample client in this repo, you can use the [spire-tutorials](https://github.com/spiffe/spire-tutorials) quickstart YAML instead of Helm:

```bash
git clone https://github.com/spiffe/spire-tutorials
cd spire-tutorials/k8s/quickstart
kubectl apply -f spire-namespace.yaml
kubectl apply -f server-account.yaml -f spire-bundle-configmap.yaml -f server-cluster-role.yaml
kubectl apply -f server-configmap.yaml -f server-statefulset.yaml -f server-service.yaml
kubectl apply -f agent-account.yaml -f agent-cluster-role.yaml
kubectl apply -f agent-configmap.yaml -f agent-daemonset.yaml
```

Then follow the registration steps in the [official quickstart](https://spiffe.io/docs/latest/try/getting-started-k8s/). The `manifests/client-deployment.yaml` in this repo is compatible with that setup.

---

## Quick Install (Demo / Non-Production)

For a fast demo on KIND or Minikube:

```bash
# Add Helm repo (optional - we use --repo directly)
helm repo add spiffe https://spiffe.github.io/helm-charts-hardened/
helm repo update

# Install CRDs first
helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
  --repo https://spiffe.github.io/helm-charts-hardened/

# Install SPIRE (server + agent)
helm upgrade --install -n spire spire spire \
  --repo https://spiffe.github.io/helm-charts-hardened/
```

### Verify Installation

```bash
# Check SPIRE Server
kubectl get statefulset -n spire
kubectl get pods -n spire
kubectl get svc -n spire

# Check SPIRE Agent (DaemonSet - one per node)
kubectl get daemonset -n spire

# Wait for pods to be Ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=spire-server -n spire --timeout=120s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=spire-agent -n spire --timeout=120s
```

Expected output:
```
NAME           READY   AGE
spire-server   1/1     Xm

NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
spire-agent   N         N         N       N            N           <none>          Xm
```

---

## Production-Like Install (Custom Values)

For a more controlled deployment, use a values file.

### 1. Create `spire-values.yaml`

```yaml
# spire-values.yaml
global:
  openshift: false
  spire:
    recommendations:
      enabled: true
    namespaces:
      create: true
    ingressControllerType: ""  # Set to "ingress-nginx" if exposing services
    clusterName: spire-demo    # Match your cluster name
    trustDomain: example.org
    caSubject:
      country: ARPA
      organization: Example
      commonName: example.org
```

### 2. Install with Values

```bash
# Install CRDs
helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
  --repo https://spiffe.github.io/helm-charts-hardened/

# Install SPIRE with custom values
helm upgrade --install -n spire spire spire \
  --repo https://spiffe.github.io/helm-charts-hardened/ \
  -f spire-values.yaml
```

### 3. Optional: Custom Storage Class

If your cluster uses a non-default StorageClass for persistence:

```yaml
# Add to spire-values.yaml under spire-server
spire-server:
  persistence:
    storageClass: your-storage-class
```

---

## What Gets Installed

| Component | Type | Purpose |
|-----------|------|---------|
| **spire-server** | StatefulSet | Central authority; issues SVIDs |
| **spire-agent** | DaemonSet | Per-node Workload API; attestation |
| **spire-crds** | CustomResourceDefinitions | For advanced configurations |
| **ConfigMaps, Services, RBAC** | Various | Configuration and access control |

---

## Workload Registration (Required for Workloads)

After installation, you must **register** workloads so SPIRE knows which SPIFFE ID to issue.

### 1. Register the SPIRE Agent (Node)

Get your cluster name (often from `kubectl config current-context` or your values). Example: `spire-demo` or `kind-spire-demo`.

```bash
# Replace demo-cluster with your actual cluster name from spire-values.yaml
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s_psat:cluster:spire-demo \
  -selector k8s_psat:agent_ns:spire \
  -selector k8s_psat:agent_sa:spire-agent \
  -node
```

**Note:** The cluster name in selectors must match `global.spire.clusterName` in your Helm values (e.g., `spire-demo`). Check agent logs if attestation fails:
```bash
kubectl logs -n spire -l app.kubernetes.io/name=spire-agent --tail=50
```

**Helm Charts Hardened:** The chart deploys SPIRE Controller Manager, which may automatically create registration entries via ClusterSPIFFEID. In that case, manual registration may not be needed. See [07 - Advanced Topics](./07-advanced-topics.md#1-spire-controller-manager--clusterspiffeid).

### 2. Register a Workload (e.g., default namespace + default SA)

```bash
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry create \
  -spiffeID spiffe://example.org/ns/default/sa/default \
  -parentID spiffe://example.org/ns/spire/sa/spire-agent \
  -selector k8s:ns:default \
  -selector k8s:sa:default
```

### 3. List Registration Entries

```bash
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry show
```

---

## Accessing the Workload API from Pods

Pods need access to the SPIRE Agent's Unix socket. The Helm chart typically configures this via:

1. **CSI Driver** (if using SPIFFE CSI driver)
2. **Volume mount** of the agent socket (hostPath or similar)

For the **quickstart / spire-tutorials** approach, you mount the agent socket from the host. The agent runs as a DaemonSet, so the socket is at a predictable path on each node.

Example pod spec (conceptual):

```yaml
volumeMounts:
  - name: agent-socket
    mountPath: /run/spire/agent-sockets
    readOnly: true
volumes:
  - name: agent-socket
    hostPath:
      path: /run/spire/agent-sockets  # Helm chart (helm-charts-hardened) socket path
      type: DirectoryOrCreate
```

**Note:** The exact path depends on your Helm chart configuration. Check the agent ConfigMap or chart values for `socketPath`.

---

## Uninstall

```bash
# Remove SPIRE
helm uninstall spire -n spire
helm uninstall spire-crds -n spire

# Remove namespace
kubectl delete namespace spire

# If you created ClusterRoles/ClusterRoleBindings manually (quickstart), remove them:
kubectl delete clusterrole spire-server-trust-role spire-agent-cluster-role 2>/dev/null || true
kubectl delete clusterrolebinding spire-server-trust-role-binding spire-agent-cluster-role-binding 2>/dev/null || true
```

---

## Next Steps

- **Deploy a sample app** → [05 - Sample Application](./05-sample-app.md)
- **Verify identity** → [06 - Verification](./06-verification.md)
