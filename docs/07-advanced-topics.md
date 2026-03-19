# Advanced Topics

This document covers advanced SPIFFE/SPIRE concepts and deployment patterns.

---

## 1. SPIRE Controller Manager & ClusterSPIFFEID

When using the **Helm Charts Hardened**, the chart deploys **SPIRE Controller Manager**, which automatically manages registration entries via Kubernetes Custom Resources.

### ClusterSPIFFEID

A `ClusterSPIFFEID` CRD defines which pods get which SPIFFE ID:

```yaml
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: default
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels: {}  # Match all pods
```

**Default behavior:** All pods receive `spiffe://{trustDomain}/ns/{namespace}/sa/{serviceAccount}`.

### Custom Identifiers

Restrict or extend identifiers via Helm values:

```yaml
spire-server:
  controllerManager:
    identities:
      clusterSPIFFEIDs:
        default:
          namespaceSelector:
            matchExpressions:
              - key: kubernetes.io/metadata.name
                operator: NotIn
                values: [kube-system, spire]
        frontend:
          namespaceSelector:
            matchExpressions:
              - key: kubernetes.io/metadata.name
                operator: In
                values: [production]
          podSelector:
            matchLabels:
              app: frontend
          dnsNameTemplates:
            - frontend.example.com
```

---

## 2. SPIFFE CSI Driver

The [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi) mounts the Workload API socket into pods via CSI volumes instead of hostPath.

**Benefits:**
- No hostPath (better isolation)
- Per-pod socket binding
- Works with restricted Pod Security Standards

**Usage:** Add a volume using the CSI driver in your pod spec. Requires the CSI driver to be installed in the cluster (some Helm charts include it).

---

## 3. mTLS with Envoy and SPIRE

For **service-to-service mTLS**, use Envoy as a sidecar or proxy with SPIRE:

1. **Envoy** terminates TLS and validates client certificates using the SPIFFE trust bundle
2. **SPIRE** provides X.509-SVIDs to Envoy via the Workload API (or SDS)
3. Envoy uses the SVID as the server certificate and validates client SVIDs

**Resources:**
- [SPIRE with Envoy and X.509-SVIDs](https://spiffe.io/docs/latest/microservices/envoy-x509/readme/)
- [SPIRE with Envoy and JWT-SVIDs](https://spiffe.io/docs/latest/microservices/envoy-jwt/readme/)

---

## 4. Federation (Multi-Trust-Domain)

Federation allows workloads in **different trust domains** to authenticate each other.

**Use case:** Cluster A (`cluster1.com`) and Cluster B (`cluster2.com`) need to communicate with mTLS.

**How it works:**
- Each SPIRE Server has its own trust domain and CA
- Servers exchange **trust bundles** (each other's CA certs)
- Workloads in A can validate SVIDs from B and vice versa

**Setup:** Configure federation in SPIRE Server and Agent. See [SPIRE Federation](https://spiffe.io/docs/latest/spire-helm-charts-hardened-advanced/federation/).

**Demo:** [SPIFFE/SPIRE Federation on KIND clusters](https://github.com/nishantapatil3/spire-federation-kind)

---

## 5. Nested SPIRE

For large or multi-tenant deployments, you can run a **nested** SPIRE topology:

- **Root SPIRE** – Issues identities to **downstream** SPIRE servers
- **Downstream SPIRE** – Issues identities to workloads in its scope

Useful for:
- Hierarchical trust
- Delegating identity management to teams/tenants
- Scaling across many clusters

See [Nested SPIRE](https://spiffe.io/docs/latest/spire-helm-charts-hardened-advanced/nested-spire/).

---

## 6. Production Recommendations

| Area | Recommendation |
|------|----------------|
| **Datastore** | Use PostgreSQL or MySQL instead of SQLite for HA |
| **Bootstrap** | Replace default bootstrap bundle with your PKI |
| **SVID TTL** | Keep short (e.g., 1 hour); balance security vs. load |
| **Node attestation** | Prefer platform attestation (K8s SA, cloud IID) over join tokens |
| **Telemetry** | Enable Prometheus metrics and structured logging |
| **RBAC** | Restrict who can create registration entries / ClusterSPIFFEIDs |
| **Network** | Use NetworkPolicies to limit SPIRE Server/Agent exposure |

---

## 7. Scaling SPIRE

- **Server:** Run multiple replicas with a shared datastore (PostgreSQL/MySQL)
- **Agent:** DaemonSet ensures one agent per node; scale with cluster
- **Join tokens:** Avoid for production; use platform attestation

See [Scaling SPIRE](https://spiffe.io/docs/latest/planning/scaling_spire/).

---

## 8. Integration Ecosystem

| Tool | SPIFFE Support |
|------|----------------|
| **Envoy** | X.509 + JWT SVID auth |
| **Istio** | Native SPIFFE/SPIRE integration |
| **cert-manager** | CSI driver, SPIFFE issuer |
| **Consul** | SPIFFE implementation |
| **Vault** | SVID authentication for secrets |
| **OPA** | Policy based on SPIFFE ID |

---

## Further Reading

- [SPIFFE Specifications](https://spiffe.io/docs/latest/spiffe-specs/)
- [SPIRE Configuration Reference](https://spiffe.io/docs/latest/deploying/spire_server/)
- [SPIRE Use Cases](https://spiffe.io/docs/latest/spire-about/use-cases/)
