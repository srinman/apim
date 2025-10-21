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

### Overview

The Premium V2 tier introduces the ability to attach **workspace gateways**, enabling isolated API management for different teams, business units, or projects within a single APIM instance. Workspaces provide logical isolation with dedicated gateway resources while sharing the underlying APIM infrastructure.

### Workspace Gateway Association

Workspace gateways are created and associated with workspaces through the following mechanisms:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    WORKSPACE GATEWAY ASSOCIATION OPTIONS                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

Option 1: Azure Portal
├─► Navigate to APIM instance → Workspaces
├─► Create new workspace
├─► Select "Create workspace gateway"
└─► Configure:
    • Workspace name
    • Gateway scaling units
    • Custom domain (optional)
    • Access policies

Option 2: Azure CLI
$ az apim workspace create \
    --resource-group <rg-name> \
    --service-name <apim-name> \
    --workspace-id <workspace-id>

$ az apim workspace gateway create \
    --resource-group <rg-name> \
    --service-name <apim-name> \
    --workspace-id <workspace-id> \
    --gateway-id <gateway-id>

Option 3: ARM/Bicep Template
resource workspace 'Microsoft.ApiManagement/service/workspaces@2023-05-01-preview' = {
  parent: apimService
  name: 'team-a-workspace'
  properties: {
    displayName: 'Team A Workspace'
    description: 'Workspace for Product Team A'
  }
}

resource workspaceGateway 'Microsoft.ApiManagement/service/workspaces/gateways@2023-05-01' = {
  parent: workspace
  name: 'team-a-gateway'
  properties: {
    locationData: {
      name: 'Azure Region'
    }
  }
}

Option 4: Terraform
resource "azurerm_api_management_workspace" "team_a" {
  api_management_id = azurerm_api_management.main.id
  name              = "team-a-workspace"
  display_name      = "Team A Workspace"
}

resource "azurerm_api_management_workspace_gateway" "team_a_gateway" {
  workspace_id = azurerm_api_management_workspace.team_a.id
  name         = "team-a-gateway"
  # Additional configuration
}

Option 5: REST API
POST https://management.azure.com/subscriptions/{subscriptionId}/
     resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/
     service/{serviceName}/workspaces/{workspaceId}?api-version=2023-05-01-preview

POST https://management.azure.com/subscriptions/{subscriptionId}/
     resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/
     service/{serviceName}/workspaces/{workspaceId}/gateways/{gatewayId}
     ?api-version=2023-05-01-preview
```

### Architecture: Management Plane Operations

This diagram shows how different actors configure and manage the APIM instance, workspaces, and gateways:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│              MANAGEMENT PLANE - Configuration & Administration                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Platform Admin  │  │ Workspace Admin │  │ API Developer   │  │ DevOps Pipeline │
│                 │  │ (Team A)        │  │                 │  │ (CI/CD)         │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │                    │
         │                    │                    │                    │
    [1]  │ Azure Portal       │                    │                    │
         │ Azure CLI          │                    │                    │
         │ ARM/Terraform      │                    │                    │
         │                    │                    │                    │
         ▼                    │                    │                    │
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       AZURE MANAGEMENT APIs                                         │
│         (Azure Resource Manager - management.azure.com)                             │
└─────────────────────────────────────────────────────────────────────────────────────┘
         │                    │                    │                    │
         │ [2] Creates/       │ [3] Manages        │ [4] Creates/       │ [5] Deploys
         │     Configures     │     Workspace      │     Updates        │     APIs via
         │     APIM Instance  │     Resources      │     APIs           │     IaC
         │                    │                    │                    │
         ▼                    ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          APIM PREMIUM V2 INSTANCE                                   │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                           MANAGEMENT PLANE                                    │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  INSTANCE-LEVEL CONFIGURATION                                           │ │ │
│  │  │                                                                         │ │ │
│  │  │  Platform Admin manages:                                                │ │ │
│  │  │  • APIM instance settings                                               │ │ │
│  │  │  • Workspace creation/deletion                                          │ │ │
│  │  │  • Gateway provisioning                                                 │ │ │
│  │  │  • Global policies                                                      │ │ │
│  │  │  • RBAC assignments                                                     │ │ │
│  │  │  • Network configuration                                                │ │ │
│  │  │  • Multi-region settings                                                │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  WORKSPACE 1: "Product Team A"                                          │ │ │
│  │  │  ├─ Workspace Admin manages:                                            │ │ │
│  │  │  │  • Workspace-scoped APIs                                             │ │ │
│  │  │  │  • Workspace gateway scaling                                         │ │ │
│  │  │  │  • Workspace policies                                                │ │ │
│  │  │  │  • Workspace RBAC                                                    │ │ │
│  │  │  │  • Backend configurations                                            │ │ │
│  │  │  │                                                                      │ │ │
│  │  │  └─ API Developer manages:                                              │ │ │
│  │  │     • API definitions (OpenAPI)                                         │ │ │
│  │  │     • API operations                                                    │ │ │
│  │  │     • API policies                                                      │ │ │
│  │  │     • Products & subscriptions                                          │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  WORKSPACE 2: "Product Team B"                                          │ │ │
│  │  │  ├─ Workspace Admin manages:                                            │ │ │
│  │  │  │  • Workspace-scoped APIs                                             │ │ │
│  │  │  │  • Workspace gateway scaling                                         │ │ │
│  │  │  │  • Workspace policies                                                │ │ │
│  │  │  │  • Workspace RBAC                                                    │ │ │
│  │  │  │                                                                      │ │ │
│  │  │  └─ API Developer manages:                                              │ │ │
│  │  │     • API definitions                                                   │ │ │
│  │  │     • API operations & policies                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  WORKSPACE N: "Partner APIs"                                            │ │ │
│  │  │  ├─ Workspace Admin manages:                                            │ │ │
│  │  │  │  • Partner-facing APIs                                               │ │ │
│  │  │  │  • Workspace gateway scaling                                         │ │ │
│  │  │  │  • Partner access policies                                           │ │ │
│  │  │  │                                                                      │ │ │
│  │  │  └─ API Developer manages:                                              │ │ │
│  │  │     • Partner API contracts                                             │ │ │
│  │  │     • Integration configurations                                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                      DEVELOPER PORTAL (CENTRALIZED)                           │ │
│  │                                                                               │ │
│  │  Platform Admin configures:                                                  │ │
│  │  • Portal branding & customization                                           │ │
│  │  • Cross-workspace API visibility                                            │ │
│  │  • Authentication providers                                                  │ │
│  │                                                                               │ │
│  │  Workspace Admins configure:                                                 │ │
│  │  • Workspace API documentation                                               │ │
│  │  • Products & subscription tiers                                             │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

[6] Configuration pushed to Data Plane
         │
         │ Automatic synchronization
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         DATA PLANE / RUNTIME GATEWAYS                               │
│                         (Configuration is READ-ONLY here)                           │
│                                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ Primary Gateway  │  │ Workspace 1      │  │ Workspace N      │                 │
│  │                  │  │ Gateway          │  │ Gateway          │                 │
│  │ Receives config  │  │ Receives config  │  │ Receives config  │                 │
│  │ for instance-    │  │ for workspace 1  │  │ for workspace N  │                 │
│  │ level APIs       │  │ APIs only        │  │ APIs only        │                 │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘                 │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Architecture: Data Plane - API Traffic Flow

This diagram shows how API calls flow through the gateways to backend services:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                  DATA PLANE - API Request/Response Flow                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Consumer A   │  │ Consumer B   │  │ Consumer C   │  │ Partner      │
│ (External)   │  │ (Internal)   │  │ (Internal)   │  │ (External)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │
       │ HTTPS           │ HTTPS           │ HTTPS           │ HTTPS
       │ API call        │ API call        │ API call        │ API call
       │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          APIM PREMIUM V2 INSTANCE                                   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         DATA PLANE / RUNTIME                                │   │
│  │                                                                             │   │
│  │  ┌───────────────────────────────────────────────────────────────────────┐ │   │
│  │  │  PRIMARY GATEWAY (Instance-level)                                     │ │   │
│  │  │  Endpoint: https://{service}.azure-api.net                            │ │   │
│  │  │                                                                        │ │   │
│  │  │  Handles: Instance-wide & shared APIs                                 │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Inbound]  ───────────────────────────────►  [Processing]            │ │   │
│  │  │  • Authentication/Authorization                • Policy execution     │ │   │
│  │  │  • API key validation                          • Request transform    │ │   │
│  │  │  • JWT validation                              • Rate limiting        │ │   │
│  │  │  • IP filtering                                • Caching              │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Outbound]  ◄───────────────────────────────  [Backend]              │ │   │
│  │  │  • Response transform                          • Route to backend     │ │   │
│  │  │  • Response caching                            • Load balancing       │ │   │
│  │  │  • Logging/metrics                             • Circuit breaker      │ │   │
│  │  └────────────────────────────────────┬───────────────────────────────────┘ │   │
│  │                                       │                                     │   │
│  │                                       │ Routes to shared backends           │   │
│  │                                       ▼                                     │   │
│  │                        ┌──────────────────────────┐                        │   │
│  │                        │  Shared Backend Services │                        │   │
│  │                        └──────────────────────────┘                        │   │
│  │                                                                             │   │
│  │  ┌───────────────────────────────────────────────────────────────────────┐ │   │
│  │  │  WORKSPACE 1 GATEWAY                                                  │ │   │
│  │  │  Workspace: "Product Team A"                                          │ │   │
│  │  │  Endpoint: https://{service}-workspace1.azure-api.net                 │ │   │
│  │  │                                                                        │ │   │
│  │  │  Handles: ONLY Team A APIs                                            │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Inbound]  ───────────────────────────────►  [Processing]            │ │   │
│  │  │  • Workspace-level auth                        • Workspace policies   │ │   │
│  │  │  • Subscription validation                     • Team A transforms    │ │   │
│  │  │  • Quota enforcement                            • Team A rate limits  │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Outbound]  ◄───────────────────────────────  [Backend]              │ │   │
│  │  │  • Team A response policies                    • Team A backends      │ │   │
│  │  │  • Workspace metrics                            • AKS cluster         │ │   │
│  │  └────────────────────────────────────┬───────────────────────────────────┘ │   │
│  │                                       │                                     │   │
│  │                                       │ Routes to Team A backends           │   │
│  │                                       ▼                                     │   │
│  │                        ┌──────────────────────────┐                        │   │
│  │                        │  Team A Backend Services │                        │   │
│  │                        │  • Microservices (AKS)   │                        │   │
│  │                        │  • App Services          │                        │   │
│  │                        │  • Azure Functions       │                        │   │
│  │                        └──────────────────────────┘                        │   │
│  │                                                                             │   │
│  │  ┌───────────────────────────────────────────────────────────────────────┐ │   │
│  │  │  WORKSPACE 2 GATEWAY                                                  │ │   │
│  │  │  Workspace: "Product Team B"                                          │ │   │
│  │  │  Endpoint: https://{service}-workspace2.azure-api.net                 │ │   │
│  │  │                                                                        │ │   │
│  │  │  Handles: ONLY Team B APIs                                            │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Inbound]  ───────────────────────────────►  [Processing]            │ │   │
│  │  │  • Workspace-level auth                        • Workspace policies   │ │   │
│  │  │  • Subscription validation                     • Team B transforms    │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Outbound]  ◄───────────────────────────────  [Backend]              │ │   │
│  │  │  • Team B response policies                    • Team B backends      │ │   │
│  │  └────────────────────────────────────┬───────────────────────────────────┘ │   │
│  │                                       │                                     │   │
│  │                                       │ Routes to Team B backends           │   │
│  │                                       ▼                                     │   │
│  │                        ┌──────────────────────────┐                        │   │
│  │                        │  Team B Backend Services │                        │   │
│  │                        │  • Container Apps        │                        │   │
│  │                        │  • Azure Functions       │                        │   │
│  │                        │  • Logic Apps            │                        │   │
│  │                        └──────────────────────────┘                        │   │
│  │                                                                             │   │
│  │  ┌───────────────────────────────────────────────────────────────────────┐ │   │
│  │  │  WORKSPACE N GATEWAY                                                  │ │   │
│  │  │  Workspace: "Partner APIs"                                            │ │   │
│  │  │  Endpoint: https://{service}-workspaceN.azure-api.net                 │ │   │
│  │  │                                                                        │ │   │
│  │  │  Handles: ONLY Partner APIs                                           │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Inbound]  ───────────────────────────────►  [Processing]            │ │   │
│  │  │  • Partner authentication                      • Partner policies     │ │   │
│  │  │  • OAuth/API key validation                    • SLA enforcement      │ │   │
│  │  │  • Throttling                                  • Contract validation  │ │   │
│  │  │                                                                        │ │   │
│  │  │  [Outbound]  ◄───────────────────────────────  [Backend]              │ │   │
│  │  │  • Partner response format                     • Integration services │ │   │
│  │  └────────────────────────────────────┬───────────────────────────────────┘ │   │
│  │                                       │                                     │   │
│  │                                       │ Routes to integration backends      │   │
│  │                                       ▼                                     │   │
│  │                        ┌──────────────────────────┐                        │   │
│  │                        │  Partner Integration     │                        │   │
│  │                        │  Backend Services        │                        │   │
│  │                        │  • Integration APIs      │                        │   │
│  │                        │  • Third-party connectors│                        │   │
│  │                        └──────────────────────────┘                        │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘

KEY CHARACTERISTICS:

1. ISOLATION: Each workspace gateway handles ONLY its workspace APIs
   • No cross-workspace traffic
   • Independent request processing
   • Separate endpoint URLs

2. INDEPENDENT SCALING: Each gateway scales independently
   • Workspace 1: Can have 2 units
   • Workspace 2: Can have 5 units
   • Workspace N: Can have 1 unit

3. POLICY ISOLATION: Policies are workspace-scoped
   • Global policies apply to all
   • Workspace policies apply only to that workspace
   • API-level policies within workspace

4. BACKEND ROUTING: Each workspace routes to its own backends
   • No shared backend access across workspaces (unless explicitly configured)
   • Workspace-specific network paths
   • Independent circuit breakers and retry policies

5. MONITORING: Separate telemetry per workspace
   • Workspace-level metrics
   • Independent Application Insights (optional)
   • Per-workspace cost tracking
```

### Workspace Gateway Benefits

**Isolation:**
- Each workspace has dedicated gateway resources
- Complete API and configuration isolation
- No cross-contamination of traffic or policies

**Independent Scaling:**
- Scale each workspace gateway based on its specific load
- Different teams can have different capacity requirements
- Cost optimization per team/business unit

**Governance:**
- Workspace-level RBAC and access control
- Team-specific policy management
- Delegated administration model

**Multi-tenancy:**
- Support for multiple teams, business units, or customers
- Isolated environments within single APIM instance
- Clear boundaries and ownership

**Financial Management:**
- Chargeback/showback capabilities per workspace
- Track consumption and costs per team
- Budget allocation and monitoring

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
