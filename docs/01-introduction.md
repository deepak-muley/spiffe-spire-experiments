# Introduction to SPIFFE & SPIRE

**Before you start:** Read [00 - Real-World Story](./00-real-world-story.md) to understand why this matters.

---

## What is SPIFFE?

**SPIFFE** (Secure Production Identity Framework for Everyone) is a set of open-source standards for securely identifying software systems in dynamic and heterogeneous environments. It provides a universal identity control plane for distributed systems implementing zero-trust security.

### The Problem SPIFFE Solves

Modern production environments are:
- **Dynamic** - Workloads scale up/down, move between nodes, get replaced
- **Heterogeneous** - Mix of VMs, containers, serverless, multi-cloud
- **Complex** - Microservices, service meshes, multi-cluster deployments

Traditional security approaches fail:
- **IP-based policies** - IPs change; workloads are ephemeral
- **Shared secrets** - Hard to rotate; high blast radius if compromised
- **Static certificates** - Don't scale; manual provisioning is error-prone

### The SPIFFE Solution

SPIFFE defines:
1. **SPIFFE ID** - A unique, cryptographically verifiable identity for each workload
2. **SVID** (SPIFFE Verifiable Identity Document) - Short-lived identity documents (X.509 or JWT)
3. **Workload API** - A simple API for workloads to obtain their identity

Workloads use SVIDs to authenticate to each other (e.g., mTLS, JWT validation) without shared secrets.

---

## What is SPIRE?

**SPIRE** (SPIFFE Runtime Environment) is a production-ready implementation of the SPIFFE specification. It performs **node** and **workload attestation** to securely issue SVIDs based on verifiable conditions.

### SPIRE vs. SPIFFE

| Concept | Description |
|---------|-------------|
| **SPIFFE** | The specification/standard (the "what") |
| **SPIRE** | An implementation (the "how") |

Other implementations exist: cert-manager, Consul, Istio, Dapr, and commercial offerings from GCP, Red Hat, Teleport, etc.

### SPIRE Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SPIRE Server (Control Plane)                   │
│  • Manages trust domain                                           │
│  • Stores registration entries (workload → SPIFFE ID mapping)     │
│  • Signs SVIDs                                                    │
│  • Performs node attestation                                      │
└───────────────────────────────┬───────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│ SPIRE Agent   │       │ SPIRE Agent   │       │ SPIRE Agent   │
│ (Node 1)      │       │ (Node 2)      │       │ (Node N)      │
│               │       │               │       │               │
│ • Workload API│       │ • Workload API│       │ • Workload API│
│ • Attestation │       │ • Attestation │       │ • Attestation │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        ▼                       ▼                       ▼
   [Workload A]            [Workload B]            [Workload C]
```

### Key Components

| Component | Role |
|-----------|------|
| **SPIRE Server** | Central authority; issues identities; runs as StatefulSet (typically on control plane) |
| **SPIRE Agent** | Per-node daemon; exposes Workload API; attests workloads; runs as DaemonSet |
| **Registration Entries** | Maps selectors (e.g., K8s namespace, service account) → SPIFFE ID |

---

## Core Concepts

### SPIFFE ID

A URI that uniquely identifies a workload within a trust domain:

```
spiffe://<trust-domain>/<path>
```

Examples:
- `spiffe://example.org/ns/default/sa/my-service` - Kubernetes workload
- `spiffe://example.org/host/my-server` - Bare metal host

### Trust Domain

A trust domain is a logical grouping (e.g., your organization, a cluster). All workloads in the same trust domain trust each other's SVIDs when properly validated.

### SVID (SPIFFE Verifiable Identity Document)

Two formats:
- **X.509-SVID** - Certificate + private key; used for mTLS
- **JWT-SVID** - JWT token; used for API auth, OIDC-style flows

SVIDs are short-lived (configurable TTL) and automatically rotated.

### Workload API

A gRPC/HTTP API exposed by the SPIRE Agent via Unix domain socket. Workloads call it to:
- Fetch their X.509-SVID
- Fetch their JWT-SVID
- Get the trust bundle (CA certs for validating other workloads)

---

## Why Use SPIFFE/SPIRE in Kubernetes?

1. **Workload Identity** - Every pod gets a unique, verifiable identity (not just service account tokens)
2. **mTLS Without Complexity** - Automatic certificate issuance and rotation
3. **Zero Trust** - Identity-based auth instead of network perimeter
4. **Multi-Cluster** - Federation enables cross-cluster trust
5. **Platform Agnostic** - Same identity model across K8s, VMs, serverless

---

## How Does This Compare to Other Options?

Kubernetes has alternatives: AWS IRSA, GCP Workload Identity, Istio, Linkerd, cert-manager. They address different use cases (cloud API access vs. service-to-service mTLS). See [08 - Alternatives & Comparison](./08-alternatives-and-comparison.md) for a decision guide.

---

## Next Steps

- **Understand security model** → [02 - Security Concepts](./02-security-concepts.md)
- **Compare with alternatives** → [08 - Alternatives & Comparison](./08-alternatives-and-comparison.md)
- **Set up a cluster** → [03 - KIND Cluster Setup](./03-setup-kind.md)
