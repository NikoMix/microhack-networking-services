# Architecture Diagrams — Module B Networking Microhack

Reference architecture diagrams for the **Contoso Financial Services (CFS)** Azure Hub & Spoke
secure network deployed during the Module B Networking Microhack.

---

## Diagram Inventory

| File | Format | Challenge / Control | Description |
|------|--------|--------------------|-|
| [hub-spoke-architecture.drawio](./hub-spoke-architecture.drawio) | draw.io XML | Ch 00–06 / **B.3.1 + B.3.2** | Full hub & spoke topology — hub VNet, spoke VNet, Firewall, Bastion, VPN GW, App Gateway, Front Door, Private Endpoints, Log Analytics |
| [hub-spoke-architecture.svg](./hub-spoke-architecture.svg) | SVG | Ch 00–06 / **B.3.1 + B.3.2** | Exported SVG (open `.drawio` for editable version) |
| [private-link-compute-detail.drawio](./private-link-compute-detail.drawio) | draw.io XML | Ch 04 / **B.3.2** | Private Endpoint + Private Compute detail — PE NICs, private DNS zones, public endpoint disabled, Managed Identity auth flow |
| [private-link-compute-detail.svg](./private-link-compute-detail.svg) | SVG | Ch 04 / **B.3.2** | Exported SVG |
| [global-delivery.drawio](./global-delivery.drawio) | draw.io XML | Ch 03/04 / **B.3.2 (Scenario #4)** | Global delivery: AFD → App Gateway + WAF → ILB → private compute; WAF attack-blocking callouts; TLS termination points |
| [global-delivery.svg](./global-delivery.svg) | SVG | Ch 03/04 / **B.3.2 (Scenario #4)** | Exported SVG |
| [traffic-flow-egress-firewall.drawio](./traffic-flow-egress-firewall.drawio) | draw.io XML | Ch 03 / **B.3.2** | Traffic flow detail — spoke UDR → Firewall inspection → SNAT to internet; on-prem via VPN; AGW subnet UDR exemption; Firewall policy rule order |
| [traffic-flow-egress-firewall.svg](./traffic-flow-egress-firewall.svg) | SVG | Ch 03 / **B.3.2** | Exported SVG |

### Mermaid Sources (for embedding in docs)

| File | Used In Docs |
|------|-------------|
| [mermaid/hub-spoke-architecture.mmd](./mermaid/hub-spoke-architecture.mmd) | Overview, Solution Design |
| [mermaid/private-link-compute-detail.mmd](./mermaid/private-link-compute-detail.mmd) | Challenge 04 |
| [mermaid/global-delivery.mmd](./mermaid/global-delivery.mmd) | Challenge 03/04 |
| [mermaid/traffic-flow-egress-firewall.mmd](./mermaid/traffic-flow-egress-firewall.mmd) | Challenge 03 |

---

## Diagram → Control Mapping

| Diagram | Module B Controls | Auditor Checkpoint |
|---------|------------------|--------------------|
| `hub-spoke-architecture` | B.3.1, B.3.2 | Hub & Spoke topology; ≥5 native Azure networking services visible |
| `private-link-compute-detail` | B.3.2 | Private Endpoints deployed; public endpoints disabled; no public IPs on compute |
| `global-delivery` | B.3.2 | Azure Front Door + WAF + App Gateway end-to-end; WAF in Prevention mode |
| `traffic-flow-egress-firewall` | B.3.2 | All spoke traffic inspected by Azure Firewall; UDR applied; Firewall policy documented |

---

## How to Open / Edit

### draw.io Desktop / Browser

1. Install [draw.io Desktop](https://github.com/jgraph/drawio-desktop/releases) (free, open source) or open [diagrams.net](https://app.diagrams.net/).
2. Open the `.drawio` file from this directory.
3. Export to SVG: **File → Export → SVG** → overwrite the matching `.svg` file.

### VS Code draw.io Extension

1. Install the [draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) extension (free).
2. Open any `.drawio` file directly in VS Code.

### Mermaid (`.mmd` files)

Mermaid diagrams render natively in:

- GitHub Markdown (fenced ` ```mermaid ` blocks)
- Astro Starlight (via `<Code>` or mermaid plugin)
- VS Code Markdown Preview with [Markdown Preview Mermaid Support](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)

To embed in docs:

````markdown
```mermaid
<!-- paste contents of .mmd file here -->
```
````

---

## Deployed Architecture Summary

```
Internet Users (Global)
    │
    ▼ HTTPS:443
Azure Front Door Standard (Global Anycast)
    │ + WAF (Prevention, OWASP 3.2)
    ▼ HTTPS
App Gateway v2 + WAF (swedencentral, Zones 1-2-3)
    │ + WAF (Prevention, OWASP 3.2)
    ▼ HTTP (internal)
Internal Load Balancer (Standard, Zone-redundant)
    │
    ▼ TCP balanced
Private Compute VMs (No Public IPs, Managed Identity)
    │                    │                   │
    ▼ UDR               ▼ Private            ▼ Bastion
Azure Firewall ←── All egress
(Hub, Zones 1-2-3)     Private Endpoints    Azure Bastion
    │                  (KV, Storage, SQL)   (browser RDP/SSH)
    ▼
Internet (SNAT)

On-Premises ←──── IKEv2 VPN ──────► VPN Gateway ──► Hub ──► Spoke
(172.16.0.0/12)                     (BGP ASN 65515)
```

---

## Naming Conventions

All diagram files follow: `<topic>.<ext>`

- `hub-spoke-architecture` — Main topology overview
- `private-link-compute-detail` — Private networking zoom-in
- `global-delivery` — AFD → AGW → backend path
- `traffic-flow-egress-firewall` — Firewall inspection deep-dive

SVG exports are co-located with their `.drawio` source files.
Mermaid sources are in `mermaid/` subdirectory.

---

## Related Evidence Templates

| Diagram | Referenced In |
|---------|--------------|
| `hub-spoke-architecture` | `B2.1_SolutionDesign_CFS_v1.docx` (Section 3.1), `B3.x_AsBuilt_CFS_v1.docx` |
| `private-link-compute-detail` | `B3.x_AsBuilt_CFS_v1.docx` (Section 3), `B4.1_ValidationTestPlan_CFS_v1.xlsx` (TC-005/TC-006) |
| `global-delivery` | `B2.1_SolutionDesign_CFS_v1.docx` (Section 2.3), `B4.1_ValidationTestPlan_CFS_v1.xlsx` (TC-011/TC-012) |
| `traffic-flow-egress-firewall` | `B2.2_WellArchitectedReview_CFS_v1.xlsx` (SEC-002, SEC-003), `B4.1_ValidationTestPlan_CFS_v1.xlsx` (TC-003/TC-004) |
