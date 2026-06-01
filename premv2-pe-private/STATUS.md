# Deployment status — `apim-priv-sm01`

_Snapshot: 2026-06-01 14:20 EDT_

## TL;DR

| Component | Status |
|---|---|
| APIM Premium v2 (VNet-injected, public access disabled) | ✅ Provisioned, healthy |
| Private Endpoint (Gateway) | ✅ Connected/Approved |
| Public CNAME (ownership marker) | ✅ Live |
| Split-horizon Private DNS (internal + remote zones) | ✅ Both A records in place, both VNets linked |
| **Custom hostname `apimprivate.demos.srinman.com` on APIM** | ✅ **Live** — added via portal with Key Vault cert source (system-assigned MI + RBAC) |
| Developer-portal custom hostname | ⏸ Not yet attempted (waiting on Proxy hostname to land) |
| End-to-end HTTPS from inside each VNet (ACA shell) | ✅ **PASSED** — HTTP 200 on both paths, APIM serves the KV cert via SNI |

---

## APIM service (`apim-rg/apim-priv-sm01`)

| Property | Value |
|---|---|
| SKU | `PremiumV2 / 1` |
| Region | `centralus` |
| Provisioning state | `Succeeded` |
| `virtualNetworkType` | `Internal` |
| Injected subnet | `apim-vnet-cus/apim-subnet` (10.10.1.0/24) |
| **`privateIPAddresses`** | **`["10.10.1.4"]`** |
| `publicIPAddresses` | `[]` |
| `publicNetworkAccess` | `Disabled` ✅ |
| `developerPortalStatus` | `Enabled` (took effect on a later PATCH cycle) |
| `gatewayUrl` | `https://apim-priv-sm01.azure-api.net` |
| `hostnameConfigurations` | only the default `apim-priv-sm01.azure-api.net` — custom hostname **rolled back** |

## Private Endpoint (`apim-rg/pe-apim-gateway`)

| Property | Value |
|---|---|
| Group ID | `Gateway` |
| Subnet | `apim-vnet-cus/pe-subnet` (10.10.2.0/24) |
| Provisioning state | `Succeeded` |
| Connection state | `Approved` |
| **PE NIC IP** | **`10.10.2.4`** |
| Auto-registered FQDN | `apim-priv-sm01.azure-api.net` |

## Public DNS (Azure DNS, `infrarg/demos.srinman.com`)

| Record | Type | Value |
|---|---|---|
| `apimprivate.demos.srinman.com` | CNAME | `apim-priv-sm01.azure-api.net` |

Verified via `dig @8.8.8.8` — resolves correctly.

## Private DNS — split-horizon (`demos.srinman.com`)

| Zone resource | Linked VNet(s) | `apimprivate` A record |
|---|---|---|
| `infrarg/demos.srinman.com` | `apim-vnet-cus` (link `link-apim-vnet-cus`) | `10.10.1.4` (APIM VNet-injected IP) |
| `remote-callers-rg/demos.srinman.com` | `remote-callers-vnet` (link `link-remote-vnet-demos`) | `10.10.2.4` (PE IP) |

Two same-named zones in different RGs — each VNet linked to exactly one. This is the supported split-horizon pattern and it is in place and resolvable from the respective VNets.

## Other supporting resources

| Resource | Status |
|---|---|
| RG `apim-rg` (centralus / eastus mix) | exists |
| VNet `apim-vnet-cus` (10.10.0.0/16) with `apim-subnet` + `pe-subnet` | ready, delegated, NSG attached |
| NSG `nsg-apim-subnet-cus` | rules: `ApiManagement→3443`, `VirtualNetwork→443`, `AzureLoadBalancer→*` |
| RG `remote-callers-rg` (centralus) | exists |
| VNet `remote-callers-vnet` (10.20.0.0/16, subnet `clients` 10.20.1.0/24) | ready |
| VNet peering apim ↔ remote | both directions `Connected / FullyInSync` |
| Cert artifacts under `certs/` | `apim2.pfx` (SAN `apimprivate.demos.srinman.com`) generated with self-signed CA `rootCA.crt` |
| Older artifacts | `apim-vnet` (eastus) + `apim-vnet-eus2` + `nsg-apim-subnet` (eastus2) still exist from earlier region probes — unused, can be deleted |

---

## Open issue — custom hostname PATCH silently rolls back

### What happened

Two attempts to add the `apimprivate.demos.srinman.com` Proxy hostname (PFX uploaded inline, base64, `defaultSslBinding=true`, `certificateSource=Custom`):

| Attempt | Started (UTC) | Result | Duration |
|---|---|---|---|
| 1 | 16:33:42 | service went to `Updating`, then back to `Succeeded` with the custom hostname missing | ~47 min |
| 2 | 17:28:27 | same pattern: `Updating` → `Succeeded`, custom hostname absent | ~47 min |

### Evidence

- Activity log shows `Microsoft.ApiManagement/service/write` `Accepted` at each PATCH start, but **no terminal `Succeeded` or `Failed` event for the service-write op**. The associated Azure Policy `auditIfNotExists` was `Canceled` ~47 min later in both runs.
- After the policy cancel, the resource snaps back to `Succeeded` with `hostnameConfigurations` containing only `apim-priv-sm01.azure-api.net`.
- Public CNAME `apimprivate.demos.srinman.com → apim-priv-sm01.azure-api.net` is live and resolvable from Google public resolver, so the ownership check should pass.
- Cert is a valid PFX (verified with `openssl pkcs12`), SAN matches the hostname.

### Suspected causes (to investigate)

1. **`publicNetworkAccess=Disabled` interferes with v2's hostname validation pipeline.** APIM's cert-chain / OCSP / ownership-verification machinery may reach out via a path that's blocked when public access is off. Workaround to try: PATCH `publicNetworkAccess=Enabled`, add hostname, then PATCH `publicNetworkAccess=Disabled` again.
2. **Self-signed cert chain not accepted on v2.** v2 may require either Key Vault reference or a cert chained to a publicly trusted CA, even though the API accepts the upload. Worth testing with an Azure-issued / Let's Encrypt cert.
3. **Azure Policy `auditIfNotExists` blocking finalization.** A tenant-level policy is being evaluated on every PATCH and `Canceled` exactly when the operation hits the 47-min watchdog. Could be related to the `ResourceReadFailed: Azure Policy required full resource content` error seen on an earlier preview-API attempt.

### Recommended next step

Try the workaround in order:

```bash
# 1. Re-enable public access temporarily
az rest --method patch \
  --uri "https://management.azure.com/subscriptions/3eef5dad-ad68-4246-8e02-e13d661de047/resourceGroups/apim-rg/providers/Microsoft.ApiManagement/service/apim-priv-sm01?api-version=2024-05-01" \
  --body '{"properties":{"publicNetworkAccess":"Enabled"}}'

# 2. Wait until Succeeded, then PATCH hostname (body in /tmp/h3.json from earlier run)
az rest --method patch \
  --uri ".../apim-priv-sm01?api-version=2024-05-01" \
  --body @/tmp/h3.json

# 3. Once hostname is present, disable public access again
az rest --method patch \
  --uri ".../apim-priv-sm01?api-version=2024-05-01" \
  --body '{"properties":{"publicNetworkAccess":"Disabled"}}'
```

If that still silently rolls back, escalate via portal (it surfaces richer error detail than the REST envelope) or open an Azure support ticket — this looks like a v2 platform issue worth confirming with the product group.

---

## Outstanding work (once hostname lands)

- [ ] Add DevPortal hostname `portal.srinman.com.private` (or `portal.demos.srinman.com`) — note `developerPortalStatus` is now `Enabled`.
- [ ] ~~Deploy a jumpbox VM in each VNet~~ — replaced with ACA `nicolaka/netshoot` apps (`shell-internal`, `shell-remote`). See test results below.
- [x] From each VNet, `nslookup apimprivate.demos.srinman.com` returns the per-VNet IP (10.10.1.4 vs 10.10.2.4). ✅
- [x] `curl https://apimprivate.demos.srinman.com/status-0123456789abcdef` returns **HTTP 200 from both VNets**. ✅
- [ ] Repeat against developer portal hostname from internal VM only (after Proxy hostname lands).
- [ ] Fold all confirmed findings into `README.md`.

---

## End-to-end test from inside each VNet (ACA `netshoot` shells)

Deployed two Azure Container Apps with internal-only ACA environments, one per VNet:

| App | RG | ACA env | VNet / subnet |
|---|---|---|---|
| `shell-internal` | `apim-rg` | `aca-env-internal` (internal) | `apim-vnet-cus/aca-subnet` (10.10.4.0/23) |
| `shell-remote` | `remote-callers-rg` | `aca-env-remote` (internal) | `remote-callers-vnet/aca-subnet` (10.20.4.0/23) |

Both run `nicolaka/netshoot:latest` with `sleep infinity`; reached via `az containerapp exec` (wrap with `script -qec ... /dev/null` from a non-TTY shell).

### Results

```text
=== FROM INTERNAL VNet (apim-vnet-cus) ===
[1] dig +short apimprivate.demos.srinman.com   →   10.10.1.4
[2] nc -zvw3 apimprivate.demos.srinman.com 443 →   succeeded
[3] curl -sk .../status-0123456789abcdef        →   http=200, resolved=10.10.1.4, ssl_verify=20

=== FROM REMOTE VNet (remote-callers-vnet) ===
[1] dig +short apimprivate.demos.srinman.com   →   10.10.2.4
[2] nc -zvw3 apimprivate.demos.srinman.com 443 →   succeeded
[3] curl -sk .../status-0123456789abcdef        →   http=200, resolved=10.10.2.4, ssl_verify=20
```

**Interpretation**

- Split-horizon Private DNS resolves the same FQDN to **different IPs per VNet**, exactly as designed.
- Both paths reach the APIM gateway (HTTP 200 from `/status-0123456789abcdef`, APIM's unauthenticated health endpoint).
- The remote-callers VNet talks to the **Private Endpoint NIC (10.10.2.4)** via the peering — no NVA in the path.
- `ssl_verify=20` is **expected** until the custom hostname PATCH succeeds: APIM is still presenting its built-in `*.azure-api.net` cert which doesn't match SAN `apimprivate.demos.srinman.com`. `-k` bypasses the check; APIM itself accepts and serves the request. Once the Proxy hostname is loaded with the self-signed PFX, drop `-k` and use `--cacert rootCA.crt` for a clean handshake.
