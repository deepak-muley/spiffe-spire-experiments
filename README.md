# SPIFFE & SPIRE Experiments

A comprehensive guide and demo for learning SPIFFE/SPIRE on Kubernetes—from beginner to advanced.

## Quick Start

**Option A: Helm (recommended for production-like setup)**
```bash
# Prerequisites: Docker, kind, kubectl, helm
./scripts/setup-demo.sh
```

**Option B: spire-tutorials YAML (guaranteed compatibility)**
```bash
# Uses raw YAML from spire-tutorials - works with KIND out of the box
./scripts/setup-demo-tutorials.sh
```
*Note: Run `kind create cluster --name spire-demo` first. Use `CLUSTER_NAME=kind-spire-demo` if agent attestation fails.*

Then verify SVID issuance:

```bash
kubectl exec -it $(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}') -- \
  /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock
```

## Documentation

| Document | Description |
|----------|-------------|
| [docs/00-real-world-story.md](docs/00-real-world-story.md) | **Why?** Real-world use cases (Uber, Square, Anthem, etc.) |
| [docs/01-introduction.md](docs/01-introduction.md) | What is SPIFFE & SPIRE |
| [docs/02-security-concepts.md](docs/02-security-concepts.md) | Zero-trust, attestation, SVIDs |
| [docs/03-setup-kind.md](docs/03-setup-kind.md) | KIND cluster setup |
| [docs/04-installation-helm.md](docs/04-installation-helm.md) | SPIRE installation via Helm |
| [docs/05-sample-app.md](docs/05-sample-app.md) | Sample workload deployment |
| [docs/06-verification.md](docs/06-verification.md) | Verification steps |
| [docs/07-advanced-topics.md](docs/07-advanced-topics.md) | Federation, Controller Manager, mTLS |
| [docs/08-alternatives-and-comparison.md](docs/08-alternatives-and-comparison.md) | IRSA, Istio, Linkerd, cert-manager vs SPIFFE/SPIRE |
| [docs/09-sequence-flow-and-topology.md](docs/09-sequence-flow-and-topology.md) | Sequence flow; where to run Server (single/multi-cloud) |
| [docs/10-installed-components-outputs.md](docs/10-installed-components-outputs.md) | Real cluster outputs: pods, services, entries, SVID fetch—understand without running |

**Start here:** [docs/README.md](docs/README.md)

## Resources

- [SPIFFE Documentation](https://spiffe.io/docs/latest/)
- [SPIRE GitHub](https://github.com/spiffe/spire)
- [SPIRE Helm Charts (Hardened)](https://github.com/spiffe/helm-charts-hardened)
