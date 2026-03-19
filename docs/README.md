# SPIFFE & SPIRE Documentation

A comprehensive guide for learning and implementing SPIFFE/SPIRE in Kubernetes—from beginner to advanced.

## Documentation Structure

| Document | Level | Description |
|----------|-------|-------------|
| [00 - Real-World Story](./00-real-world-story.md) | **Start here** | Why SPIFFE/SPIRE? Uber, Square, Anthem, and more |
| [01 - Introduction to SPIFFE & SPIRE](./01-introduction.md) | Beginner | What they are, why they matter, core concepts |
| [02 - Security Concepts](./02-security-concepts.md) | Beginner-Intermediate | Zero-trust, attestation, SVIDs, trust domains |
| [03 - KIND Cluster Setup](./03-setup-kind.md) | Beginner | Create a local Kubernetes cluster for demos |
| [04 - Installation with Helm](./04-installation-helm.md) | Beginner-Intermediate | Install SPIRE using Helm charts |
| [05 - Sample Application](./05-sample-app.md) | Intermediate | Deploy and configure a workload with SPIRE |
| [06 - Verification](./06-verification.md) | Intermediate | Verify identity issuance and mTLS |
| [07 - Advanced Topics](./07-advanced-topics.md) | Advanced | Federation, nested SPIRE, production patterns |
| [08 - Alternatives & Comparison](./08-alternatives-and-comparison.md) | Reference | IRSA, Istio, Linkerd, cert-manager vs SPIFFE/SPIRE |
| [09 - Sequence Flow & Topology](./09-sequence-flow-and-topology.md) | Reference | Service→Server→Service flow; where to run Server (single/multi-cloud) |
| [10 - Installed Components & Outputs](./10-installed-components-outputs.md) | Reference | Real cluster outputs: pods, services, entries, SVID fetch—understand without running |

## Quick Start Path

1. **Want the "why" first?** → Start with [00 - Real-World Story](./00-real-world-story.md)
2. **New to SPIFFE?** → [01 - Introduction](./01-introduction.md)
3. **Ready to try it?** → [03 - KIND Setup](./03-setup-kind.md) → [04 - Helm Installation](./04-installation-helm.md)
4. **Want to see it work?** → [05 - Sample App](./05-sample-app.md) → [06 - Verification](./06-verification.md)
5. **Wondering about alternatives?** → [08 - Alternatives & Comparison](./08-alternatives-and-comparison.md)

## Prerequisites

- **Docker** - For KIND and container images
- **kubectl** - Kubernetes CLI
- **Helm 3** - Package manager for Kubernetes
- **kind** - Kubernetes in Docker (for local demos)

## External Resources

- [Official SPIFFE Documentation](https://spiffe.io/docs/latest/)
- [SPIRE GitHub](https://github.com/spiffe/spire)
- [SPIRE Helm Charts (Hardened)](https://github.com/spiffe/helm-charts-hardened)
- [SPIRE Tutorials](https://github.com/spiffe/spire-tutorials)
