# APIM Premium v2 Workspace Gateway Deep Dive

> Companion to `apim-deployment-architecture.md`. Focused on workspace configuration patterns for a federated API management operating model with a central APIM platform team and distributed API development teams.

---

## Goals & Audience

- Enable a **central platform team** to operate the APIM instance while delegating workspace ownership to individual API product teams.
- Provide prescriptive guidance on how to configure workspaces, gateways, RBAC, and networking in **Premium v2** with workspace gateways.
- Clarify management-plane responsibilities versus data-plane request flows.
- Document cost drivers for Premium v2 workspaces and gateways.

---

## Roles & Responsibilities

| Role | Scope | Primary Tools | Responsibilities |
|------|-------|---------------|------------------|
| **Platform Team** | APIM instance-wide | Azure Portal, ARM/Bicep, Terraform, Azure CLI | Provision APIM Premium v2, enable workspaces, create workspace gateways, enforce guardrails, manage global policies, monitor capacity and cost |
| **Workspace Admin** | Single workspace | Azure Portal (workspace scope), ARM/Terraform scoped to workspace, REST | Manage workspace RBAC, configure workspace gateway scaling, onboard APIs, author workspace policies, coordinate network integration |
| **API Developer** | Workspace APIs | DevOps pipelines, DevOps Git repos, REST, IDE toolchains | Publish OpenAPI definitions, configure API-level policies, manage products & subscriptions, test via dev portal |
| **Security & Networking** | Cross-cutting | Azure Firewall/VNet tooling, Private DNS | Approve network isolation (VNets, Private Endpoints), manage certificates and custom domains |

Workspace RBAC includes `Workspace Reader`, `Workspace Contributor`, `Workspace Gateway Administrator`, and custom roles mapped to the API dev teams for least-privilege operations.

---

## Architecture: Management Plane Operations

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                  MANAGEMENT PLANE (Federated Operating Model)                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐    ┌─────────────────────┐
│ Platform Team       │   │ Workspace Admin (A) │   │ Workspace Admin (B) │    │ DevOps Pipelines    │
│ (Instance Owner)    │   │ RBAC: Workspace     │   │ RBAC: Workspace     │    │ (IaC + CI/CD)        │
│ RBAC: Owner         │   │ Contributor,        │   │ Contributor,        │    │ Managed Identity     │
│                     │   │ Gateway Admin       │   │ Gateway Admin       │    │ Scoped RBAC          │
└──────────┬──────────┘   └──────────┬──────────┘   └──────────┬──────────┘    └──────────┬──────────┘
			  │                         │                         │                           │
	 [1] Azure Portal / ARM / CLI     │                         │                    [2] ARM/Bicep/Terraform
			  │                         │                         │                           │
			  ▼                         ▼                         ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                           AZURE RESOURCE MANAGER (management.azure.com)                      │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
			  │                         │                         │                           │
			  │                         │                         │                           │
			  ▼                         ▼                         ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                               APIM PREMIUM V2 INSTANCE                                       │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Instance Scope (Platform Team)                                      │ │
│  │                                                                                        │ │
│  │  • Enable workspaces feature                                                           │ │
│  │  • Create workspace resources                                                           │ │
│  │  • Associate workspace gateways + hostnames                                             │ │
│  │  • Configure global policies, custom domains, logging                                   │ │
│  │  • Govern network isolation (VNets, private endpoints)                                   │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Workspace: `product-team-a`                                         │ │
│  │                                                                                        │ │
│  │  Workspace RBAC:                                                                       │ │
│  │    • Workspace Owner / Contributor (Team A leads)                                      │ │
│  │    • Workspace Gateway Administrator                                                   │ │
│  │    • Workspace Reader                                                                  │ │
│  │                                                                                        │ │
│  │  Workspace Gateway Association:                                                        │ │
│  │    • Gateway Name: `team-a-gateway`                                                    │ │
│  │    • Hostname: `https://apim-contoso-team-a.azure-api.net`                             │ │
│  │    • Network Isolation: Private endpoint `team-a-pe` into spoke VNet                   │ │
│  │    • Capacity Scaling: 3 units (Premium v2 workspace gateway units)                    │ │
│  │                                                                                        │ │
│  │  Workspace Admin actions:                                                              │ │
│  │    • Publish APIs via CI/CD                                                            │ │
│  │    • Configure workspace-level policies                                                │ │
│  │    • Manage workspace gateway scaling (scale-out / scale-in)                           │ │
│  │    • Assign workspace RBAC to dev team members                                         │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Workspace: `product-team-b`                                         │ │
│  │  (Similar structure with dedicated hostname, private endpoint, scaling)                 │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Workspace: `partner-apis`                                          │ │
│  │  (Partner-facing gateway, dedicated RBAC, network segregation)                          │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Configuration Sync to Data Plane                                   │ │
│  │  (System-managed propagation of policies, APIs, products to correct gateway scope)      │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

Legend:
[1] Instance-level operations (Platform team)
[2] Workspace-scoped deployments (DevOps pipelines & workspace admins)

Key Takeaways:
- Workspaces inherit guardrails but manage their own APIs and gateway capacity.
- Workspace gateway administrators can scale their dedicated gateway without affecting other teams.
- Hostnames, network isolation (VNet/Private Endpoint), and RBAC are defined per workspace.

---

## Architecture: Data Plane API Calls

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                        DATA PLANE (API Request Flow)                                         │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────┐    ┌────────────────────┐    ┌────────────────────┐    ┌────────────────────┐
│ External Consumer  │    │ Internal Consumer   │    │ Partner Consumer   │    │ Automation Client  │
│ (Internet)         │    │ (Corporate Network) │    │ (Partner VNet)     │    │ (Service Principal)│
└─────────┬──────────┘    └─────────┬──────────┘    └─────────┬──────────┘    └─────────┬──────────┘
			 │ HTTPS (public)          │ HTTPS (Private DNS)      │ HTTPS (B2B)            │ mTLS / OAuth
			 │ Host: `apim-contoso`    │ Host: `apim-contoso`      │ Host: `apim-contoso`   │ Host: workspace
			 │ or workspace FQDN       │ or workspace FQDN        │ or workspace FQDN      │ FQDN
			 ▼                         ▼                          ▼                        ▼

┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                               APIM PREMIUM V2 ENDPOINTS                                      │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Primary Gateway (Instance Level)                                                      │ │
│  │  Hostname: `https://apim-contoso.azure-api.net`                                        │ │
│  │  Network: Public IP + optional private endpoint                                        │ │
│  │  Scope: Shared APIs (centralized)                                                      │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Workspace Gateway: `team-a-gateway`                                                   │ │
│  │  Hostname: `https://apim-contoso-team-a.azure-api.net`                                 │ │
│  │  Network Isolation:                                                                    │ │
│  │    • Private Endpoint → Spoke VNet `spoke-team-a`                                      │ │
│  │    • Optional Application Gateway / Firewall                                           │ │
│  │  Capacity Scaling: 3 units (scale per demand)                                          │ │
│  │  Association: Bound to workspace `product-team-a`                                      │ │
│  │  Policy Scope: Workspace policies + API-level policies                                 │ │
│  │                                                                                         │ │
│  │  Request Flow steps:                                                                   │ │
│  │    1. Inbound call authenticated (OAuth, subscription key)                             │ │
│  │    2. Workspace policies executed (rate limit, headers, transformations)               │ │
│  │    3. Routing to Team A backends via VNet integration                                  │ │
│  │    4. Response policies applied (masking, caching)                                     │ │
│  │    5. Telemetry emitted to Azure Monitor / App Insights                                │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Workspace Gateway: `team-b-gateway`                                                   │ │
│  │  Hostname: `https://apim-contoso-team-b.azure-api.net`                                 │ │
│  │  Network Isolation: Private Endpoint → Spoke VNet `spoke-team-b`                       │ │
│  │  Capacity Scaling: 1 unit (burst via autoscale policy)                                  │ │
│  │  Association: Bound to workspace `product-team-b`                                      │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Workspace Gateway: `partner-gateway`                                                  │ │
│  │  Hostname: `https://partners-contoso.azure-api.net`                                    │ │
│  │  Network Isolation: Public + IP restrictions for partner ranges                        │ │
│  │  Capacity Scaling: 2 units                                                             │ │
│  │  Association: Workspace `partner-apis`                                                 │ │
│  └────────────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

										│
										│ Routed via workspace-specific policies & backends
										▼

┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             BACKEND DEV/API SERVICES                                        │
│                                                                                              │
│  Workspace `product-team-a` Backends:                                                       │
│   • AKS namespace `team-a` (Private IP)                                                     │
│   • Azure Function Apps (Private endpoint)                                                  │
│   • Azure SQL / Cosmos DB via VNet integration                                              │
│                                                                                              │
│  Workspace `product-team-b` Backends:                                                       │
│   • Container Apps Environment (Internal ingress)                                           │
│   • Logic Apps Standard (Private endpoint)                                                  │
│                                                                                              │
│  Workspace `partner-apis` Backends:                                                         │
│   • Integration services exposed via Application Gateway                                   │
│                                                                                              │
│  Telemetry Flow: Workspace gateway → Azure Monitor / App Insights (workspace-specific)       │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

Highlights:
- Inbound API calls terminate on **workspace-specific hostnames** enforcing isolation.
- Network isolation is achieved through private endpoints, VNets, or IP restrictions per workspace gateway.
- Gateway capacity (units) is managed independently; scaling events do not affect other workspaces.
- Workspace gateways only call APIs registered within their associated workspace.
- Telemetry and diagnostics can be filtered by workspace for cost and performance governance.

---

## Workspace Configuration Checklist

1. **Workspace Creation**
	- Platform team enables workspaces and creates `product-team-*` workspaces.
	- Assign workspace admins via Azure RBAC (`Microsoft.ApiManagement/service/workspaces/*`).

2. **Gateway Association**
	- Create workspace gateway per workspace.
	- Define hostname (managed domain or custom), TLS certificates, and SNI bindings.
	- Decide on public vs private exposure; configure Private Endpoint if required.

3. **Network Isolation**
	- Integrate workspace gateway with hub-spoke VNet model using Private Link.
	- Configure outbound VNet integration for gateway-to-backend connectivity.
	- Maintain Private DNS zones per workspace for backend resolution.

4. **Capacity & Scaling**
	- Allocate initial gateway units (minimum 1 per workspace gateway).
	- Enable autoscale rules driven by custom metrics (requests per second, latency).
	- Monitor utilization via Azure Monitor metrics (`GatewayCapacity`).

5. **RBAC & Governance**
	- Platform team sets guardrails via global policies and Azure Policy.
	- Workspace admins manage internal RBAC: Reader, Data Contributor, Policy Author.
	- Ensure least-privilege access for CI/CD identities.

6. **API Deployment**
	- API dev teams push OpenAPI specs via pipelines scoped to workspace.
	- Workspace policies enforce team-specific security (JWT validation, quota).
	- Products/subscriptions managed per workspace to separate consumers.

7. **Monitoring & Telemetry**
	- Route logs to workspace-specific Application Insights or Log Analytics tables.
	- Create Cost Management views filtered by workspace gateway resource.
	- Implement alerts on latency, error rate, and capacity thresholds.

---

## Cost Model Considerations

Premium v2 pricing combines base units for the APIM instance with additional workspace gateway units. Key cost components:

- **APIM Premium v2 Base Units**: Required to enable workspaces and advanced networking. Billed per unit-hour. Minimum 1 unit per region.
- **Workspace Gateway Units**: Each workspace gateway scales independently; billed per unit-hour at Premium v2 workspace gateway rates. Scaling up a workspace gateway does not require scaling the base APIM unit count, but total throughput must remain within overall service limits.
- **Multi-region Deployments**: Additional regional deployments multiply both base and workspace gateway unit costs per region.
- **Networking**: Private endpoints, VNet data transfer, Azure Firewall/Application Gateway add to operating expenses.
- **Monitoring & Logs**: Application Insights and Log Analytics ingestion/retention costs accrue per workspace if telemetry is segregated.
- **Certificates & Domains**: Managed certificates included; custom domains may require Azure DNS or key vault costs.

Cost Optimization Tips:
- Right-size workspace gateway units per team based on observed throughput metrics.
- Use autoscale with conservative upper bounds to avoid runaway costs.
- Aggregate logs using sampling for low-volume workspaces.
- Apply Azure Cost Management tags to workspace resources for chargeback/showback to API teams.
- Periodically review idle workspaces/gateways and scale-in or disable as needed.

---

## References

- `apim-deployment-architecture.md` – High-level deployment patterns and diagrams.
- [API Management Premium v2 pricing](https://azure.microsoft.com/pricing/details/api-management/).
- [Workspaces overview](https://learn.microsoft.com/azure/api-management/workspaces-overview).
- [Workspace gateway documentation](https://learn.microsoft.com/azure/api-management/workspace-gateways-overview).
- [Azure RBAC for API Management](https://learn.microsoft.com/azure/api-management/api-management-role-based-access-control).
