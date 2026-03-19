# Verification Guide

This document provides step-by-step verification procedures to ensure SPIFFE/SPIRE is working correctly.

---

## Verification Checklist

| Step | Command / Action | Expected Result |
|------|------------------|-----------------|
| 1 | Cluster connectivity | `kubectl get nodes` shows Ready nodes |
| 2 | SPIRE Server running | `kubectl get pods -n spire` shows spire-server-0 Running |
| 3 | SPIRE Agent running | DaemonSet has Ready pods on each node |
| 4 | Registration entries | `spire-server entry show` lists agent + workload entries |
| 5 | Workload SVID fetch | `spire-agent api fetch` returns SVID with correct SPIFFE ID |
| 6 | JWT-SVID (optional) | `spire-agent api fetch jwt` returns JWT |

---

## 1. Cluster and SPIRE Components

```bash
# Cluster
kubectl get nodes
kubectl cluster-info

# SPIRE namespace
kubectl get all -n spire

# Server (StatefulSet)
kubectl get statefulset -n spire
kubectl get pods -n spire -l app.kubernetes.io/name=spire-server

# Agent (DaemonSet)
kubectl get daemonset -n spire
kubectl get pods -n spire -l app.kubernetes.io/name=spire-agent
```

**Expected:** All pods in `Running` and `Ready` state.

---

## 2. SPIRE Server Logs

```bash
kubectl logs -n spire spire-server-0 --tail=50
```

Look for:
- Server started successfully
- No repeated attestation errors

---

## 3. SPIRE Agent Logs

```bash
kubectl logs -n spire -l app.kubernetes.io/name=spire-agent --tail=50
```

Look for:
- Successful node attestation
- Connection to server established
- No "failed to attest" or "connection refused"

---

## 4. Registration Entries

```bash
kubectl exec -n spire spire-server-0 -- \
  /opt/spire/bin/spire-server entry show
```

**Expected output (example):**
```
Entry ID         : xxx
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Selectors        : k8s_psat:agent_ns:spire, k8s_psat:agent_sa:spire-agent, k8s_psat:cluster:spire-demo

Entry ID         : yyy
SPIFFE ID        : spiffe://example.org/ns/default/sa/default
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Selectors        : k8s:ns:default, k8s:sa:default
```

---

## 5. Workload SVID Fetch (X.509)

From a workload pod that has the agent socket mounted:

```bash
POD=$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock
```

**Success:** Output shows SPIFFE ID, validity dates, and certificate details.

**Failure:** See [Troubleshooting](#troubleshooting) below.

---

## 6. Workload JWT-SVID Fetch (Optional)

```bash
POD=$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /opt/spire/bin/spire-agent api fetch jwt \
  -audience my-audience \
  -socketPath /run/spire/agent-sockets/spire-agent.sock
```

**Success:** A JWT string is printed. You can decode it at [jwt.io](https://jwt.io) to see the `sub` claim (SPIFFE ID).

---

## 7. Trust Bundle

```bash
POD=$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /opt/spire/bin/spire-agent api fetch x509 -socketPath /run/spire/agent-sockets/spire-agent.sock -write /tmp/
# Or use 'spire-agent api fetch' and inspect output for trust bundle
```

The trust bundle contains the CA certificate(s) used to verify other workloads' SVIDs in the same trust domain.

---

## Troubleshooting

### "connection refused" or "no such file or directory" when fetching SVID

- **Cause:** Agent socket not available to the workload pod.
- **Fix:** Verify agent socket path. Ensure workload pod mounts the same host path where the agent creates the socket. For Helm, check agent ConfigMap for `socket_path`.

### "no identity issued" or "no SVID"

- **Cause:** No registration entry matches the workload's selectors.
- **Fix:** Create a registration entry with selectors matching the workload's namespace and service account. Verify with `spire-server entry show`.

### Agent attestation failure

- **Cause:** Node registration entry missing or cluster name mismatch.
- **Fix:** Create node entry with correct `k8s_psat:cluster:` value. Check agent logs for the cluster name it reports.

### Agent cannot reach server

- **Cause:** Network policy, wrong server address, or server not ready.
- **Fix:** Check server service name and port. Ensure no firewall/network policy blocks agent→server traffic.

---

## Verification Script (Optional)

Save as `scripts/verify.sh` and run after deployment:

```bash
#!/bin/bash
set -e
echo "=== Verifying SPIRE ==="
kubectl get pods -n spire
echo ""
echo "=== Registration entries ==="
kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server entry show
echo ""
echo "=== SVID fetch from workload ==="
POD=$(kubectl get pods -l app=client -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/agent-sockets/spire-agent.sock
echo ""
echo "=== Verification complete ==="
```

---

## Next Steps

- **Advanced topics** → [07 - Advanced Topics](./07-advanced-topics.md)
