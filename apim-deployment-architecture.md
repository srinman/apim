# APIM Deployment Architecture

> **Reference Document**: [API Gateway in Azure API Management](https://learn.microsoft.com/en-us/azure/api-management/api-management-gateways-overview)

## Overview

This document provides comprehensive deployment architecture patterns for Azure API Management (APIM) with a focus on V2 tiers (Basic v2, Standard v2, and Premium v2) and their integration with modern Azure API infrastructure components.

---

## Table of Contents

1. [APIM Architecture Components](#apim-architecture-components)
2. [V2 Tier Deployment Patterns](#v2-tier-deployment-patterns)
3. [Premium V2 with Workspace Gateway](#premium-v2-with-workspace-gateway)
4. [Integration with API Center](#integration-with-api-center)
5. [Comparison Matrix](#comparison-matrix)

---

## APIM Architecture Components

### Core Planes and Components

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AZURE API MANAGEMENT SERVICE                        │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                        MANAGEMENT PLANE                               │ │
│  │                                                                       │ │
│  │  • Service Configuration                                             │ │
│  │  • API Definitions                                                   │ │
│  │  • Policy Management                                                 │ │
│  │  • User & Subscription Management                                    │ │
│  │  • Analytics & Monitoring Configuration                              │ │
│  │                                                                       │ │
│  │  Management APIs:                                                    │ │
│  │  ├─ Azure Portal                                                     │ │
│  │  ├─ Azure Resource Manager (ARM)                                    │ │
│  │  ├─ PowerShell/CLI                                                   │ │
│  │  └─ REST Management API                                              │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                        DEVELOPER PORTAL                               │ │
│  │                                                                       │ │
│  │  • API Discovery & Documentation                                     │ │
│  │  • Interactive API Console                                           │ │
│  │  • Developer Onboarding                                              │ │
│  │  • Subscription Key Management                                       │ │
│  │  • Self-Service Registration                                         │ │
│  │                                                                       │ │
│  │  Access: https://{service-name}.developer.azure-api.net              │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## V2 Tier Deployment Patterns

### Basic V2 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BASIC V2 DEPLOYMENT                                │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │   API Consumers      │
                    │  (External/Internal) │
                    └──────────┬───────────┘
                               │
                               │ HTTPS
                               ▼
              ┌────────────────────────────────┐
              │   APIM Basic V2 Gateway        │
              │   (Managed - Data Plane)       │
              │                                │
              │  • Public Endpoint             │
              │  • Request Routing             │
              │  • Policy Enforcement          │
              │  • Authentication/Authz        │
              │  • Rate Limiting               │
              │  • Response Caching            │
              └────────────┬───────────────────┘
                           │
                           │ Policy-based routing
                           ▼
           ┌───────────────────────────────────────┐
           │        Backend Services               │
           │                                       │
           │  ┌──────────┐  ┌──────────┐         │
           │  │ App      │  │ Function │         │
           │  │ Service  │  │ App      │         │
           │  └──────────┘  └──────────┘         │
           │                                       │
           │  ┌──────────┐  ┌──────────┐         │
           │  │ Logic    │  │ Container│         │
           │  │ App      │  │ App      │         │
           │  └──────────┘  └──────────┘         │
           └───────────────────────────────────────┘

Key Features:
• Public endpoint only
• Basic scaling with units
• Standard v2 monitoring via Azure Monitor
• No VNet integration
```

### Standard V2 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STANDARD V2 DEPLOYMENT                              │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │   API Consumers      │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
         ┌──────────┐   ┌──────────┐   ┌──────────┐
         │ Public   │   │ Private  │   │ Private  │
         │ Endpoint │   │ Endpoint │   │ Endpoint │
         │          │   │  (PE-1)  │   │  (PE-2)  │
         └────┬─────┘   └────┬─────┘   └────┬─────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
              ┌──────────────────────────────────┐
              │  APIM Standard V2 Gateway        │
              │  (Managed - Data Plane)          │
              │                                  │
              │  • Inbound Private Endpoints     │
              │  • Outbound VNet Integration ─┐  │
              │  • Enhanced Scaling            │  │
              │  • Azure Monitor Analytics     │  │
              └────────────┬───────────────────┘  │
                           │                      │
                           │                      │
                  Backend  │              ┌───────▼─────────┐
                  Routing  │              │  Azure VNet     │
                           ▼              │                 │
           ┌──────────────────────────┐   │  ┌───────────┐ │
           │   Backend Services       │   │  │ Private   │ │
           │                          │   │  │ Backend   │ │
           │  • Public Backends       │   │  │ Services  │ │
           │  • VNet-integrated       │   │  └───────────┘ │
           │    backends via          │   └─────────────────┘
           │    outbound integration  │
           └──────────────────────────┘

Key Features:
• Inbound private endpoints for secure access
• Outbound VNet integration for private backend connectivity
• Enhanced scaling capabilities
• Azure Monitor-based analytics
```

### Premium V2 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PREMIUM V2 DEPLOYMENT                               │
└─────────────────────────────────────────────────────────────────────────────┘

                       ┌──────────────────────┐
                       │   API Consumers      │
                       │  (Global)            │
                       └──────────┬───────────┘
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
        ┌───────▼─────┐  ┌────────▼──────┐  ┌──────▼───────┐
        │   Region 1   │  │   Region 2    │  │   Region 3   │
        │  (Primary)   │  │  (Secondary)  │  │  (Secondary) │
        └───────┬──────┘  └────────┬──────┘  └──────┬───────┘
                │                  │                 │
    ┌───────────────────────────────────────────────────────────────┐
    │            APIM Premium V2 Multi-Region Gateway               │
    │                                                               │
    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
    │  │ Gateway     │    │ Gateway     │    │ Gateway     │     │
    │  │ Instance    │    │ Instance    │    │ Instance    │     │
    │  │ Region 1    │    │ Region 2    │    │ Region 3    │     │
    │  │             │    │             │    │             │     │
    │  │ • Scale     │    │ • Scale     │    │ • Scale     │     │
    │  │   Units: N  │    │   Units: M  │    │   Units: P  │     │
    │  │ • Avail     │    │ • Avail     │    │ • Avail     │     │
    │  │   Zones     │    │   Zones     │    │   Zones     │     │
    │  └─────────────┘    └─────────────┘    └─────────────┘     │
    │                                                               │
    │  Features:                                                   │
    │  • Multi-region deployment                                   │
    │  • Inbound private endpoints per region                      │
    │  • Outbound VNet integration per region                      │
    │  • Cross-region traffic management                           │
    │  • Regional backend routing                                  │
    └───────────────────────────────────────────────────────────────┘
                                  │
                                  │ Policy-based routing
                                  ▼
               ┌──────────────────────────────────────┐
               │      Regional Backend Services       │
               │                                      │
               │  Region 1     Region 2     Region 3 │
               │  Backends     Backends     Backends │
               └──────────────────────────────────────┘

Key Features:
• Multi-region deployment with independent scaling per region
• Inbound private endpoints in each region
• Outbound VNet integration in each region
• Availability zone support
• Cross-region load balancing and failover
• Enhanced observability and analytics
```

---

## Premium V2 with Workspace Gateway

### Workspace Gateway Architecture

The Premium V2 tier introduces the ability to attach **workspace gateways**, enabling isolated API management for different teams, business units, or projects within a single APIM instance.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    PREMIUM V2 with WORKSPACE GATEWAY                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         APIM PREMIUM V2 INSTANCE                                    │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                           MANAGEMENT PLANE                                    │ │
│  │                                                                               │ │
│  │  • Centralized Configuration                                                 │ │
│  │  • Global Policies                                                           │ │
│  │  • Identity & Access Management                                              │ │
│  │  • Workspace Provisioning & Management                                       │ │
│  │  • Cross-workspace Monitoring                                                │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                      DEVELOPER PORTAL (CENTRALIZED)                           │ │
│  │                                                                               │ │
│  │  • Unified API Catalog                                                       │ │
│  │  • Cross-workspace API Discovery                                             │ │
│  │  • Developer Self-service                                                    │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         DATA PLANE / RUNTIME                                │   │
│  │                                                                             │   │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │   │
│  │  │              PRIMARY GATEWAY (Instance-level)                        │  │   │
│  │  │                                                                      │  │   │
│  │  │  • Instance-wide APIs                                                │  │   │
│  │  │  • Shared/Common APIs                                                │  │   │
│  │  │  • Global endpoint: https://{service}.azure-api.net                 │  │   │
│  │  └──────────────────────────────────────────────────────────────────────┘  │   │
│  │                                                                             │   │
│  │  ┌──────────────────────────────────────────────────────────────────────┐  │   │
│  │  │  WORKSPACE 1 GATEWAY                                                 │  │   │
│  │  │                                                                      │  │   │
│  │  │  Workspace: "Product Team A"                                        │  │   │
│  │  │  • Isolated API definitions                                         │  │   │
│  │  │  • Workspace-specific policies                                      │  │   │
│  │  │  • Dedicated endpoint: https://{service}-workspace1.azure-api.net   │  │   │
│  │  │  • Independent scaling units                                        │  │   │
│  │  │  • Workspace-level RBAC                                             │  │   │
│  │  │                                                                      │  │   │
│  │  │  Connected Backends:                                                │  │   │
│  │  │  └─ Team A microservices (AKS, App Service)                        │  │   │
│  │  └──────────────────────┬───────────────────────────────────────────────┘  │   │
│  │                         │                                                   │   │
│  │  ┌──────────────────────▼───────────────────────────────────────────────┐  │   │
│  │  │  WORKSPACE 2 GATEWAY                                                 │  │   │
│  │  │                                                                      │  │   │
│  │  │  Workspace: "Product Team B"                                        │  │   │
│  │  │  • Isolated API definitions                                         │  │   │
│  │  │  • Workspace-specific policies                                      │  │   │
│  │  │  • Dedicated endpoint: https://{service}-workspace2.azure-api.net   │  │   │
│  │  │  • Independent scaling units                                        │  │   │
│  │  │  • Workspace-level RBAC                                             │  │   │
│  │  │                                                                      │  │   │
│  │  │  Connected Backends:                                                │  │   │
│  │  │  └─ Team B services (Functions, Container Apps)                    │  │   │
│  │  └──────────────────────┬───────────────────────────────────────────────┘  │   │
│  │                         │                                                   │   │
│  │  ┌──────────────────────▼───────────────────────────────────────────────┐  │   │
│  │  │  WORKSPACE N GATEWAY                                                 │  │   │
│  │  │                                                                      │  │   │
│  │  │  Workspace: "Partner APIs"                                          │  │   │
│  │  │  • Isolated API definitions                                         │  │   │
│  │  │  • Workspace-specific policies                                      │  │   │
│  │  │  • Dedicated endpoint: https://{service}-workspaceN.azure-api.net   │  │   │
│  │  │  • Independent scaling units                                        │  │   │
│  │  │  • Workspace-level RBAC                                             │  │   │
│  │  │                                                                      │  │   │
│  │  │  Connected Backends:                                                │  │   │
│  │  │  └─ Partner integration services                                   │  │   │
│  │  └──────────────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘

Workspace Gateway Benefits:
• Isolation: Each workspace has dedicated gateway resources
• Scaling: Independent scaling per workspace based on demand
• Governance: Workspace-level RBAC and policy management
• Multi-tenancy: Support for multiple teams/business units
• Billing: Potential for chargeback/showback per workspace
```

---

## Integration with API Center

Azure API Center provides centralized API governance and discovery across your organization. Here's how APIM integrates with API Center:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      APIM + API CENTER INTEGRATION                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                             AZURE API CENTER                                        │
│                      (Centralized API Governance & Discovery)                       │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                        API INVENTORY & CATALOG                                │ │
│  │                                                                               │ │
│  │  • Complete API inventory across organization                                │ │
│  │  • API metadata & documentation                                              │ │
│  │  • API versioning information                                                │ │
│  │  • API lifecycle stages (Design, Development, Production, Deprecated)        │ │
│  │  • Cross-environment API tracking                                            │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                        GOVERNANCE & COMPLIANCE                                │ │
│  │                                                                               │ │
│  │  • API design standards                                                      │ │
│  │  • Security & compliance policies                                            │ │
│  │  • API quality gates                                                         │ │
│  │  • Breaking change detection                                                 │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────────────────────────────┘
                               │
                               │ API Registration & Sync
                               │ Metadata Exchange
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      APIM PREMIUM V2 INSTANCE                                       │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                          MANAGEMENT PLANE                                     │ │
│  │                                                                               │ │
│  │  API Center Integration:                                                     │ │
│  │  • Automatic API registration to API Center                                  │ │
│  │  • Bidirectional metadata sync                                               │ │
│  │  • API compliance checking                                                   │ │
│  │  • Deployment status updates                                                 │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                         DEVELOPER PORTAL                                      │ │
│  │                                                                               │ │
│  │  Enhanced with API Center:                                                   │ │
│  │  • Discovery of APIs from API Center catalog                                 │ │
│  │  • API governance information display                                        │ │
│  │  • Cross-APIM instance API discovery                                         │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                    DATA PLANE / RUNTIME GATEWAYS                            │   │
│  │                                                                             │   │
│  │  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐  │   │
│  │  │  Primary Gateway     │  │ Workspace Gateway 1  │  │ Workspace       │  │   │
│  │  │                      │  │                      │  │ Gateway N       │  │   │
│  │  │  Runtime APIs ───────┼──┼──────────────────────┼──┼─────────┐       │  │   │
│  │  └──────────────────────┘  └──────────────────────┘  └─────────┼───────┘  │   │
│  │                                                                  │          │   │
│  └──────────────────────────────────────────────────────────────────┼──────────┘   │
└─────────────────────────────────────────────────────────────────────┼──────────────┘
                                                                      │
                                                 Telemetry &          │
                                                 Usage Metrics        │
                                                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           AZURE MONITOR / APP INSIGHTS                              │
│                                                                                     │
│  • Gateway performance metrics                                                     │
│  • API usage analytics                                                             │
│  • Error rates and diagnostics                                                     │
│  • SLA tracking                                                                    │
│  • Custom dashboards                                                               │
└─────────────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           BACKEND SERVICES                                          │
│                                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐             │
│  │ Azure       │  │ Function    │  │ Container   │  │ External     │             │
│  │ App Service │  │ Apps        │  │ Apps        │  │ APIs         │             │
│  └─────────────┘  └─────────────┘  └─────────────┘  └──────────────┘             │
│                                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐             │
│  │ AKS         │  │ Logic Apps  │  │ On-premises │  │ Third-party  │             │
│  │ Services    │  │             │  │ Services    │  │ Services     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### API Center Integration Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     API Lifecycle with API Center                       │
└─────────────────────────────────────────────────────────────────────────┘

1. API DESIGN
   │
   │  Designer creates OpenAPI spec
   │  ▼
   ├─► Register in API Center
   │   • API metadata
   │   • Design stage
   │   • Owner information
   │
2. API DEVELOPMENT
   │
   │  Deploy to APIM (Dev/Test)
   │  ▼
   ├─► Auto-sync to API Center
   │   • Update deployment status
   │   • Link to APIM instance
   │   • Development stage
   │
3. API TESTING & VALIDATION
   │
   │  Governance checks
   │  ▼
   ├─► API Center validates
   │   • Security compliance
   │   • Design standards
   │   • Breaking changes
   │
4. API PRODUCTION DEPLOYMENT
   │
   │  Deploy to APIM Production
   │  ▼
   ├─► Update API Center
   │   • Production stage
   │   • Live endpoint information
   │   • SLA commitments
   │
5. API CONSUMPTION
   │
   │  Developers discover APIs
   │  ▼
   ├─► Via API Center + Dev Portal
   │   • Search API catalog
   │   • View governance info
   │   • Access documentation
   │   • Test in Dev Portal
   │
6. API MONITORING & GOVERNANCE
   │
   │  Runtime metrics & compliance
   │  ▼
   └─► API Center tracks
       • Usage metrics from APIM
       • Compliance violations
       • API health scores
```

---

## Comparison Matrix

### V2 Tiers Feature Comparison

| Feature | Basic V2 | Standard V2 | Premium V2 |
|---------|----------|-------------|------------|
| **Networking** |
| Public endpoints | ✅ | ✅ | ✅ |
| Inbound private endpoints | ❌ | ✅ | ✅ |
| Outbound VNet integration | ❌ | ✅ | ✅ |
| VNet injection | ❌ | ❌ | ❌ |
| **Scaling & Availability** |
| Manual scaling (units) | ✅ | ✅ | ✅ |
| Multi-region deployment | ❌ | ❌ | ✅ |
| Availability zones | ❌ | ❌ | ✅ |
| **Workspace Support** |
| Workspace gateways | ❌ | ❌ | ✅ |
| Multi-tenant isolation | ❌ | ❌ | ✅ |
| **Observability** |
| Azure Monitor analytics | ✅ | ✅ | ✅ |
| Application Insights | ✅ | ✅ | ✅ |
| Advanced analytics | ❌ | ✅ | ✅ |
| **Backend Integration** |
| HTTP/2 gateway-to-backend | ✅ | ✅ | ✅ |
| External cache (Redis) | ✅ | ✅ | ✅ |
| **API Center Integration** |
| API registration | ✅ | ✅ | ✅ |
| Metadata sync | ✅ | ✅ | ✅ |
| Governance compliance | ✅ | ✅ | ✅ |

### Gateway Types Comparison

| Aspect | Managed Gateway (V2) | Workspace Gateway | Self-hosted Gateway |
|--------|---------------------|-------------------|---------------------|
| **Deployment Location** | Azure (managed) | Azure (managed, in workspace) | Customer environment (K8s, etc.) |
| **Management** | Fully managed by Azure | Managed by Azure | Customer managed |
| **Scaling** | Azure-managed units | Independent workspace units | Customer-controlled replicas |
| **Use Case** | Standard API management | Multi-tenant/team isolation | Hybrid/multi-cloud scenarios |
| **Availability** | All tiers | Premium V2 only | Premium, Standard, Developer |
| **Network Isolation** | VNet integration (Std v2+) | Workspace-level isolation | Customer network |
| **Cost Model** | Per unit/tier | Per workspace + units | Compute + Premium tier |

---

## Deployment Considerations

### When to Use Basic V2
- Simple API management needs
- Public-facing APIs only
- Single team/project
- Cost-sensitive scenarios
- No VNet requirements

### When to Use Standard V2
- Private endpoint requirements
- Need for outbound VNet integration
- Medium-scale deployments
- Enhanced monitoring needs
- Single region deployment

### When to Use Premium V2
- Multi-region requirements
- High availability with availability zones
- Multi-team/workspace isolation needed
- Large-scale enterprise deployments
- Complex networking requirements
- Chargeback/showback requirements per team

### When to Use Workspace Gateways
- Multiple business units or teams sharing APIM
- Need for isolated API management per team
- Independent scaling requirements per workspace
- Separate governance policies per workspace
- Multi-tenant SaaS scenarios

### When to Use API Center
- Organization-wide API governance
- Multiple APIM instances
- API standardization across teams
- Compliance and audit requirements
- Centralized API discovery
- API lifecycle management across environments

---

## Best Practices

1. **Architecture Planning**
   - Start with Standard v2 for most production workloads
   - Upgrade to Premium v2 when multi-region or workspace isolation is needed
   - Integrate with API Center from the beginning for better governance

2. **Workspace Strategy (Premium V2)**
   - Design workspaces around organizational boundaries (teams, products, business units)
   - Define clear RBAC policies per workspace
   - Plan scaling strategy per workspace based on expected load

3. **API Center Integration**
   - Register all APIs in API Center, regardless of deployment environment
   - Maintain consistent metadata across API lifecycle
   - Use API Center for cross-cutting governance policies

4. **Developer Portal**
   - Customize portal for your organization's branding
   - Enable self-service API subscription
   - Integrate API Center catalog for comprehensive API discovery

5. **Monitoring & Observability**
   - Enable Application Insights for all gateways
   - Set up Azure Monitor dashboards per workspace
   - Use API Center for cross-instance API health tracking

6. **Security**
   - Use private endpoints for internal APIs (Standard v2+)
   - Implement outbound VNet integration for secure backend communication
   - Apply workspace-level RBAC in Premium v2
   - Enforce API governance policies via API Center

---

## Related Documentation

- [API Management Overview](https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts)
- [Workspaces in API Management](https://learn.microsoft.com/en-us/azure/api-management/workspaces-overview)
- [Azure API Center](https://learn.microsoft.com/en-us/azure/api-center/)
- [Self-hosted Gateway](https://learn.microsoft.com/en-us/azure/api-management/self-hosted-gateway-overview)
- [V2 Tiers](https://learn.microsoft.com/en-us/azure/api-management/v2-service-tiers-overview)
- [Multi-region Deployment](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-deploy-multi-region)

---

**Document Version**: 1.0  
**Last Updated**: October 21, 2025  
**Author**: API Management Architecture Team
