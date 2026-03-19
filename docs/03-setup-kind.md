# KIND Cluster Setup

This guide walks you through creating a Kubernetes cluster using [KIND](https://kind.sigs.k8s.io/) (Kubernetes in Docker) for SPIFFE/SPIRE experiments.

## Prerequisites

Install the following before proceeding:

| Tool | Purpose | Install |
|------|---------|---------|
| **Docker** | Container runtime for KIND | [docker.com](https://docs.docker.com/get-docker/) |
| **kubectl** | Kubernetes CLI | `brew install kubectl` (macOS) or [kubectl docs](https://kubernetes.io/docs/tasks/tools/) |
| **kind** | Create K8s clusters in Docker | `brew install kind` (macOS) or [kind docs](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) |
| **Helm** | Package manager for K8s | `brew install helm` (macOS) or [helm.sh](https://helm.sh/docs/intro/install/) |

### Verify Installation

```bash
docker --version
kubectl version --client
kind version
helm version
```

---

## Create a KIND Cluster

### Basic Cluster (Single Node)

```bash
# Create cluster named 'spire-demo'
kind create cluster --name spire-demo

# Verify
kubectl cluster-info --context kind-spire-demo
kubectl get nodes
```

### Recommended: Multi-Node Cluster (Optional)

For a more realistic setup with multiple worker nodes:

```bash
# Create config file
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

# Create cluster
kind create cluster --name spire-demo --config kind-config.yaml

# Verify
kubectl get nodes
```

### Important: Service Account Configuration for SPIRE

SPIRE uses Kubernetes Service Account tokens for node attestation. Some environments (e.g., older Minikube) require extra API server flags. **KIND** typically works out of the box with default configuration.

If you encounter attestation issues, ensure your cluster has:
- Service account token signing enabled
- Appropriate API audiences

For KIND, the default configuration is usually sufficient. For **Minikube**, see the [SPIRE Quickstart notes](https://spiffe.io/docs/latest/try/getting-started-k8s/#considerations-when-using-minikube).

---

## Set kubectl Context

```bash
# Use the spire-demo cluster
kubectl config use-context kind-spire-demo

# Confirm
kubectl config current-context
```

---

## Optional: Install Metrics Server (for demos)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## Cluster Ready Checklist

- [ ] KIND cluster created
- [ ] `kubectl` can reach the cluster
- [ ] Nodes are in `Ready` state
- [ ] Helm is installed

---

## Next Steps

- **Install SPIRE** → [04 - Installation with Helm](./04-installation-helm.md)

---

## Troubleshooting

### Cluster creation fails

```bash
# Ensure Docker is running
docker info

# Delete and recreate
kind delete cluster --name spire-demo
kind create cluster --name spire-demo
```

### kubectl connection refused

```bash
# Check Docker containers
docker ps | grep spire-demo

# Restart the cluster
kind delete cluster --name spire-demo
kind create cluster --name spire-demo
```

### Clean up

```bash
kind delete cluster --name spire-demo
```
