# Kubernetes Workload Identity: Alternatives & Comparison

This document helps you understand the different options for workload identity in Kubernetes and when to choose SPIFFE/SPIRE over alternatives—or when to combine them.

---

## Two Different Problems

Workload identity in Kubernetes often addresses **two distinct use cases**:

| Use Case | What You Need | Example |
|----------|---------------|---------|
| **Cloud API access** | Pod needs to call AWS S3, GCP BigQuery, Azure Blob | Backend fetches data from S3 using IAM credentials |
| **Service-to-service auth** | Pod A calls Pod B; both need to verify each other | Frontend calls backend over mTLS; both prove identity |

**Important:** These are complementary. You may need both. The solutions below map to one or both.

---

## Option 1: Cloud-Native Workload Identity

*For: Pods accessing cloud provider APIs (S3, GCS, Azure Storage, etc.)*

### AWS IRSA (IAM Roles for Service Accounts)

- **What:** Annotate a Kubernetes ServiceAccount with an IAM role ARN. Pods get short-lived AWS credentials via OIDC.
- **Scope:** EKS only. AWS APIs only.
- **Pros:** Native, no extra components, well-documented.
- **Cons:** AWS-only. No service-to-service mTLS.

### GCP Workload Identity

- **What:** Bind a Kubernetes ServiceAccount to a GCP Service Account. Pods exchange K8s JWT for GCP tokens.
- **Scope:** GKE only. GCP APIs only.
- **Pros:** Native, no keys to manage, supports Workload Identity Federation for cross-cloud.
- **Cons:** GCP-only. No service-to-service mTLS.

### Azure Workload Identity

- **What:** Federated credentials + Managed Identity. Pods get Azure tokens via OIDC.
- **Scope:** AKS only. Azure APIs only.
- **Pros:** Native, no secrets in pods.
- **Cons:** Azure-only. No service-to-service mTLS.

### When to Use

| Scenario | Use Cloud-Native |
|----------|------------------|
| Single cloud (AWS/GCP/Azure) | ✅ Yes—simplest for cloud API access |
| Multi-cloud | ⚠️ GCP Workload Identity Federation can help; still cloud-specific |
| Service-to-service mTLS | ❌ No—these don't provide workload identity for mTLS |

---

## Option 2: Service Meshes (Built-in Identity)

*For: Service-to-service mTLS, traffic management, observability*

### Istio

- **What:** Envoy-based service mesh. Issues its own certificates to workloads. Supports SPIFFE IDs and can integrate with SPIRE.
- **Identity:** Built-in CA (istiod) or external (e.g., SPIRE, cert-manager).
- **Pros:** Feature-rich (mTLS, authz, traffic splitting, observability). Large ecosystem.
- **Cons:** Complex, heavier (Envoy sidecar ~50MB). Learning curve.

### Linkerd

- **What:** Lightweight service mesh. Rust-based proxy. Automatic mTLS.
- **Identity:** Built-in identity (Linkerd's own CA). No SPIFFE/SPIRE by default.
- **Pros:** Simple, low resource (~10MB/sidecar). Easy to adopt.
- **Cons:** Less flexible than Istio. Identity is mesh-internal, not SPIFFE-standard.

### Consul Connect

- **What:** HashiCorp service mesh. Envoy-based. Integrates with Consul service discovery.
- **Identity:** Can issue SPIFFE-compatible certs. Consul implements SPIFFE Workload API.
- **Pros:** Good for HashiCorp ecosystem. SPIFFE support. Service discovery + mesh.
- **Cons:** Tied to Consul. Medium complexity.

### When to Use

| Scenario | Use Service Mesh |
|----------|------------------|
| Need mTLS + traffic management + observability | ✅ Yes—mesh gives you all three |
| Only need workload identity / mTLS | ⚠️ Mesh may be overkill; consider SPIRE alone |
| Multi-cluster / federation | ✅ Istio + SPIRE federation; Consul has federation |
| Minimal footprint | ✅ Linkerd—lightest option |

---

## Option 3: cert-manager (with SPIFFE)

*For: Certificate lifecycle management; can issue SPIFFE-compatible certs*

### cert-manager + csi-driver-spiffe

- **What:** cert-manager issues certificates. CSI driver delivers them to pods. Supports SPIFFE identity.
- **Identity:** SPIFFE IDs via CertificateRequest; attestation via pod Service Account.
- **Pros:** Familiar if you already use cert-manager. Kubernetes-native (CRDs). No DaemonSet agent.
- **Cons:** Different model than SPIRE (no node attestation). Less mature for full SPIFFE workflow.

### When to Use

| Scenario | Use cert-manager |
|----------|------------------|
| Already using cert-manager for other certs | ✅ Good fit—extend with SPIFFE |
| Want K8s-native, CRD-based workflow | ✅ cert-manager is CRD-centric |
| Need node attestation, join tokens, non-K8s workloads | ❌ SPIRE is better |

---

## Option 4: SPIFFE/SPIRE (Standalone)

*For: Standards-based workload identity; attestation; multi-platform; federation*

### SPIRE

- **What:** Production implementation of SPIFFE. Node + workload attestation. Issues X.509-SVID and JWT-SVID.
- **Identity:** SPIFFE IDs. Workload API. Attestation-based (no bootstrap secrets).
- **Pros:** Standards-based, platform-agnostic, attestation, federation, works with Istio/Envoy/Consul.
- **Cons:** Extra components (server, agent). Operational overhead. Steeper learning curve.

### When to Use

| Scenario | Use SPIFFE/SPIRE |
|----------|------------------|
| Multi-cloud / hybrid (K8s + VMs + bare metal) | ✅ One identity model everywhere |
| Need strong attestation (node + workload) | ✅ SPIRE's differentiator |
| Federation across clusters/orgs | ✅ SPIFFE Federation |
| Integrate with Istio, Envoy, Vault, etc. | ✅ Broad ecosystem support |
| Single K8s cluster, single cloud, only cloud API access | ⚠️ Cloud-native (IRSA, etc.) may be simpler |

---

## Option 5: Kubernetes Service Account Tokens

*For: Basic pod identity (limited)*

### Bound Service Account Tokens (K8s 1.24+)

- **What:** Short-lived, audience-bound JWTs for pods. Mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`.
- **Identity:** JWT with `sub` = `system:serviceaccount:<ns>:<sa>`.
- **Pros:** Built-in. No extra components.
- **Cons:** Not for mTLS. Limited to K8s API and OIDC-style auth. Not SPIFFE-standard. Not for general service-to-service crypto auth.

### When to Use

| Scenario | Use K8s SA Tokens |
|----------|-------------------|
| Authenticate to K8s API | ✅ Yes |
| OIDC federation (e.g., GCP Workload Identity) | ✅ Yes—they consume these tokens |
| Service-to-service mTLS | ❌ No—use mesh or SPIRE |

---

## Comparison Matrix

| Capability | Cloud (IRSA/GCP/Azure) | Istio | Linkerd | Consul | cert-manager+SPIFFE | SPIRE |
|------------|------------------------|-------|---------|-------|--------------------|-------|
| **Cloud API access** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌* |
| **Service-to-service mTLS** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SPIFFE-standard identity** | ❌ | Partial | ❌ | ✅ | ✅ | ✅ |
| **Node attestation** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Multi-cloud / hybrid** | Per-cloud | ✅ | ✅ | ✅ | K8s only | ✅ |
| **Federation** | ❌ | ✅ | Limited | ✅ | ❌ | ✅ |
| **Extra components** | None | Many | Few | Consul | cert-mgr + CSI | Server + Agent |
| **Complexity** | Low | High | Low | Medium | Medium | Medium-High |

*SPIRE can authenticate *to* cloud (e.g., Vault, AWS via OIDC federation) but is not a replacement for IRSA/GCP WI for direct cloud API calls.

---

## Decision Guide

```
Do you need pods to call cloud APIs (S3, GCS, etc.)?
├── Yes, single cloud (AWS/GCP/Azure)
│   └── Use IRSA / GCP Workload Identity / Azure Workload Identity
└── No (or you need more)

Do you need service-to-service mTLS?
├── No
│   └── Cloud-native identity may be enough
└── Yes
    ├── Do you need traffic management, observability, etc.?
    │   ├── Yes → Use a service mesh (Istio / Linkerd / Consul)
    │   │         Consider SPIRE as identity backend for Istio if you need federation/attestation
    │   └── No → Do you need multi-cloud, VMs, attestation, or federation?
    │       ├── Yes → Use SPIRE (or cert-manager+SPIFFE for K8s-only)
    │       └── No → Linkerd or Istio (simplest mTLS with mesh)
    └── ...
```

---

## Combining Options (Common Patterns)

| Pattern | When | How |
|---------|------|-----|
| **Cloud + Mesh** | Pods need cloud APIs + mTLS | IRSA/GCP WI for cloud; Istio/Linkerd for mTLS |
| **SPIRE + Istio** | Strong identity + mesh features | SPIRE issues SVIDs; Istio uses them for mTLS |
| **SPIRE + Vault** | Identity + secrets | SPIRE SVID authenticates to Vault; Vault returns secrets |
| **cert-manager + SPIRE** | Unified PKI | cert-manager as root CA; SPIRE for workload identity |

---

## Summary: When SPIFFE/SPIRE Is the Right Choice

**Choose SPIFFE/SPIRE when:**

- You need **one identity model** across Kubernetes, VMs, bare metal, or multi-cloud
- You want **attestation-based** identity (no bootstrap secrets)
- You need **federation** across clusters or organizations
- You're building **zero trust** and want standards-based, cryptographic workload identity
- You integrate with **Envoy, Istio, Vault, Kafka**, etc., and want SPIFFE-native support

**Consider alternatives when:**

- You only need **cloud API access** → Use IRSA, GCP Workload Identity, or Azure Workload Identity
- You only need **mTLS in a single K8s cluster** → Linkerd or Istio may be simpler
- You're **K8s-only** and already use cert-manager → cert-manager + SPIFFE CSI may fit

---

## References

- [SPIRE Comparisons (Official)](https://spiffe.io/docs/latest/spire-about/comparisons/)
- [AWS IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [GCP Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
- [cert-manager CSI Driver for SPIFFE](https://cert-manager.io/docs/usage/csi-driver-spiffe/)
- [Istio Security](https://istio.io/latest/docs/concepts/security/)
