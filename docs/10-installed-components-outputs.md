# Installed Components and Outputs Reference

This document captures the actual outputs from a working SPIRE demo cluster. Use it to understand what gets installed without running the setup yourself. All data below is from a real `spire-demo` KIND cluster created by `scripts/setup-demo.sh`.

---

## 1. KIND Clusters

After setup, you may have multiple KIND clusters. The demo uses `spire-demo`:

```bash
$ kind get clusters
cluster1
cluster2
spire-demo
```

**Note:** Switch context with `kubectl config use-context kind-spire-demo` before running commands.

---

## 2. Namespaces

```bash
$ kubectl get ns
NAME                 STATUS   AGE
default              Active   9m9s
kube-node-lease      Active   9m9s
kube-public          Active   9m9s
kube-system          Active   9m9s
local-path-storage   Active   9m4s
spire                Active   8m53s
```

| Namespace | Purpose |
|-----------|---------|
| `default` | Sample workload (client) runs here |
| `spire` | All SPIRE components (server, agent, CSI driver, OIDC provider) |
| `local-path-storage` | KIND's default storage provisioner |
| `kube-system` | Core Kubernetes components |

---

## 3. Nodes

```bash
$ kubectl get nodes -o wide
NAME                       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION     CONTAINER-RUNTIME
spire-demo-control-plane   Ready    control-plane   10m   v1.31.0   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.12.54-linuxkit   containerd://1.7.18
```

A single-node KIND cluster; the SPIRE agent runs as a DaemonSet (one per node).

---

## 4. Pods (All Namespaces)

```bash
$ kubectl get pods -A
NAMESPACE            NAME                                                    READY   STATUS    RESTARTS   AGE
default              client-5494b9dc5c-gchrt                                 1/1     Running   0          5m51s
kube-system          coredns-6f6b679f8f-9jfzb                                1/1     Running   0          9m3s
kube-system          coredns-6f6b679f8f-dpjpj                                1/1     Running   0          9m3s
kube-system          etcd-spire-demo-control-plane                           1/1     Running   0          9m11s
kube-system          kindnet-z4597                                           1/1     Running   0          9m3s
kube-system          kube-apiserver-spire-demo-control-plane                 1/1     Running   0          9m11s
kube-system          kube-controller-manager-spire-demo-control-plane        1/1     Running   0          9m11s
kube-system          kube-proxy-4gdvh                                        1/1     Running   0          9m3s
kube-system          kube-scheduler-spire-demo-control-plane                 1/1     Running   0          9m10s
local-path-storage   local-path-provisioner-57c5987fd4-hgd9k                 1/1     Running   0          9m3s
spire                spire-agent-l9wht                                       1/1     Running   0          8m50s
spire                spire-server-0                                          2/2     Running   0          8m55s
spire                spire-spiffe-csi-driver-tpswb                           2/2     Running   0          8m50s
spire                spire-spiffe-oidc-discovery-provider-65fc7d58dd-2clms   2/2     Running   0          8m55s
```

### SPIRE-Specific Pods

| Pod | Purpose |
|-----|---------|
| `spire-server-0` | SPIRE Server (StatefulSet) – issues SVIDs, manages trust |
| `spire-agent-l9wht` | SPIRE Agent (DaemonSet) – Workload API on each node |
| `spire-spiffe-csi-driver-tpswb` | CSI driver – mounts agent socket into pods via CSI volumes |
| `spire-spiffe-oidc-discovery-provider-*` | OIDC discovery – JWT/OIDC federation |
| `client-*` | Sample workload – fetches SVID via agent socket |

---

## 5. Services

```bash
$ kubectl get svc -A
NAMESPACE     NAME                                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
default       client                                 ClusterIP   10.96.50.188   <none>        80/TCP                   9m31s
default       kubernetes                             ClusterIP   10.96.0.1      <none>        443/TCP                  10m
kube-system   kube-dns                               ClusterIP   10.96.0.10     <none>        53/UDP,53/TCP,9153/TCP   10m
spire         spire-controller-manager-webhook       ClusterIP   10.96.26.142   <none>        443/TCP                  10m
spire         spire-server                           ClusterIP   10.96.88.249   <none>        443/TCP                  10m
spire         spire-spiffe-oidc-discovery-provider   ClusterIP   10.96.153.83   <none>        443/TCP                  10m
```

| Service | Purpose |
|---------|---------|
| `spire-server` | Agent connects here for attestation and SVID issuance |
| `spire-controller-manager-webhook` | Webhook for automatic workload registration |
| `spire-spiffe-oidc-discovery-provider` | OIDC discovery endpoint |
| `client` | Sample workload (from `manifests/client-deployment.yaml`) |

---

## 6. Workloads (DaemonSets, StatefulSets, Deployments)

```bash
$ kubectl get daemonsets,statefulsets,deployments -A
NAMESPACE     NAME                                     DESIRED   CURRENT   READY   AGE
kube-system   daemonset.apps/kindnet                   1         1        1       10m
kube-system   daemonset.apps/kube-proxy                1         1        1       10m
spire         daemonset.apps/spire-agent               1         1        1       10m
spire         daemonset.apps/spire-spiffe-csi-driver   1         1        1       10m

NAMESPACE   NAME                            READY   AGE
spire       statefulset.apps/spire-server   1/1     10m

NAMESPACE            NAME                                                   READY   UP-TO-DATE   AVAILABLE   AGE
default              deployment.apps/client                                 1/1     1            1           9m31s
kube-system          deployment.apps/coredns                               2/2     2            2           10m
local-path-storage   deployment.apps/local-path-provisioner                1/1     1            1           10m
spire                deployment.apps/spire-spiffe-oidc-discovery-provider   1/1     1            1           10m
```

### Images Used

| Component | Image |
|-----------|-------|
| spire-server | `ghcr.io/spiffe/spire-server:1.14.2` |
| spire-agent | `ghcr.io/spiffe/spire-agent:1.14.2` |
| spire-controller-manager | `ghcr.io/spiffe/spire-controller-manager:0.6.3` |
| spire-spiffe-csi-driver | `ghcr.io/spiffe/spiffe-csi-driver:0.2.7` |
| spire-spiffe-oidc-discovery-provider | `ghcr.io/spiffe/oidc-discovery-provider:1.14.2` |
| client (sample workload) | `ghcr.io/spiffe/spire-agent:1.5.1` |

---

## 7. Helm Releases

```bash
$ helm list -n spire
NAME       NAMESPACE   REVISION   UPDATED                              STATUS   CHART            APP VERSION
spire      spire       1          2026-03-19 13:31:08.745843 +0530 IST deployed spire-0.28.3    1.14.2
spire-crds spire       1          2026-03-19 13:31:07.295507 +0530 IST deployed spire-crds-0.5.0 0.0.1
```

| Release | Chart | Purpose |
|---------|-------|---------|
| `spire-crds` | spire-crds-0.5.0 | Custom Resource Definitions for SPIRE |
| `spire` | spire-0.28.3 | Server, Agent, CSI driver, OIDC provider |

---

## 8. ConfigMaps

```bash
$ kubectl get configmaps -A
NAMESPACE            NAME                                                   DATA   AGE
default              kube-root-ca.crt                                       1      10m
kube-node-lease      kube-root-ca.crt                                       1      10m
kube-public          cluster-info                                           2      10m
kube-public          kube-root-ca.crt                                       1      10m
kube-system          coredns                                                1      10m
...
spire                spire-agent                                            1      10m
spire                spire-bundle                                           1      9m4s
spire                spire-controller-manager                               1      10m
spire                spire-server                                           1      10m
spire                spire-spiffe-oidc-discovery-provider                   2      10m
```

SPIRE ConfigMaps hold agent config, server config, trust bundle, and OIDC provider settings.

---

## 9. RBAC (ClusterRoles / ClusterRoleBindings)

```bash
$ kubectl get clusterroles,clusterrolebindings | grep spire
NAME                                                                 CREATED AT
clusterrole.rbac.authorization.k8s.io/spire-agent                    2026-03-19T08:01:09Z
clusterrole.rbac.authorization.k8s.io/spire-spire-controller-manager 2026-03-19T08:01:09Z
clusterrole.rbac.authorization.k8s.io/spire-spire-server             2026-03-19T08:01:09Z

NAME                                                                 ROLE                           AGE
clusterrolebinding.rbac.authorization.k8s.io/spire-agent             ClusterRole/spire-agent        10m
clusterrolebinding.rbac.authorization.k8s.io/spire-spire-controller-manager ClusterRole/spire-spire-controller-manager 10m
clusterrolebinding.rbac.authorization.k8s.io/spire-spire-server       ClusterRole/spire-spire-server 10m
```

These roles allow the agent to attest workloads, the server to validate tokens, and the controller manager to manage registration entries.

---

## 10. SPIRE Registration Entries

```bash
$ kubectl exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show
Found 2 entries
Entry ID         : spire-demo.07116242-b572-4b6f-82e4-039fa34853d9
SPIFFE ID        : spiffe://example.org/ns/default/sa/default
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/spire-demo/8b6bf1f4-084b-43d4-a4cb-847188530afe
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:86a61501-8880-47bc-8237-da988ebdbbe4
Hint             : default

Entry ID         : spire-demo.1e0de4f0-4e11-4df7-8a34-83184f743fad
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-spiffe-oidc-discovery-provider
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/spire-demo/8b6bf1f4-084b-43d4-a4cb-847188530afe
Revision         : 1
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:42cc5f55-3205-4bc3-8947-1c4fad916565
DNS name         : oidc-discovery.example.org
DNS name         : spire-spiffe-oidc-discovery-provider
...
Hint             : oidc-discovery-provider
```

**Note:** With the controller manager, entries are created automatically. The `spire-server entry create` commands in `setup-demo.sh` may be redundant; the controller manager registers workloads based on ClusterSPIFFEID resources.

---

## 11. SVID Fetch (Verification)

From the sample workload pod:

```bash
$ kubectl exec -it $(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}') -- \
  /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock
```

**Output:**

```
Received 1 svid after 23.078125ms

SPIFFE ID:		spiffe://example.org/ns/default/sa/default
SVID Valid After:	2026-03-19 08:04:05 +0000 UTC
SVID Valid Until:	2026-03-19 12:04:15 +0000 UTC
CA #1 Valid After:	2026-03-19 08:01:58 +0000 UTC
CA #1 Valid Until:	2026-03-20 08:02:08 +0000 UTC
```

This confirms the workload in `default` namespace with `default` service account receives an SVID with `spiffe://example.org/ns/default/sa/default`.

---

## 12. SPIRE Agent Logs (Snippet)

```bash
$ kubectl logs -n spire spire-agent-l9wht -c spire-agent --tail=15
```

**Output:**

```
time="2026-03-19T08:02:54.669710671Z" level=info msg="Plugin loaded" plugin_name=k8s_psat plugin_type=NodeAttestor
time="2026-03-19T08:02:54.669957046Z" level=info msg="Plugin loaded" plugin_name=k8s plugin_type=WorkloadAttestor
time="2026-03-19T08:02:54.671367129Z" level=info msg="SVID is not found. Starting node attestation"
time="2026-03-19T08:02:54.840416338Z" level=info msg="Node attestation was successful" spiffe_id="spiffe://example.org/spire/agent/k8s_psat/spire-demo/8b6bf1f4-084b-43d4-a4cb-847188530afe"
time="2026-03-19T08:02:54.857772921Z" level=info msg="Starting Workload and SDS APIs" address=/tmp/spire-agent/public/spire-agent.sock network=unix
time="2026-03-19T08:02:54.857842296Z" level=info msg="Serving health checks" address="0.0.0.0:9982"
time="2026-03-19T08:04:15.267455583Z" level=info msg="Creating X509-SVID" spiffe_id="spiffe://example.org/ns/default/sa/default"
```

Key events: node attestation success, Workload API listening on Unix socket, and X509-SVID creation for the default workload.

---

## 13. Agent Socket Path (Helm Chart)

The Helm chart (`helm-charts-hardened`) uses:

- **Host path:** `/run/spire/agent-sockets`
- **Socket file:** `spire-agent.sock` (with symlinks `socket` and `api.sock`)

The sample client mounts this via `hostPath` and uses:

```
-socketPath /run/spire/agent-sockets/spire-agent.sock
```

---

## Quick Reference: Key Commands

| Purpose | Command |
|---------|---------|
| List clusters | `kind get clusters` |
| Use demo cluster | `kubectl config use-context kind-spire-demo` |
| All pods | `kubectl get pods -A` |
| SPIRE pods | `kubectl get pods -n spire` |
| Registration entries | `kubectl exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show` |
| Verify SVID | `kubectl exec $(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}') -- /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock` |
| Agent logs | `kubectl logs -n spire -l app.kubernetes.io/name=spire-agent -c spire-agent --tail=50` |
