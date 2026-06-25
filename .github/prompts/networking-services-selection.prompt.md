---
mode: agent
description: >-
  Reusable skill for Challenge 02/03. Selects and documents at least five Azure
  networking services from the audit's 11-service list so control B.3.2 is
  provably satisfied, marking deployed vs covered-by-design.
---

# Skill: Networking services selection (B.3.2)

Use with the **`solution-designer`** and **`iac-engineer`** agents.

## Goal

Pick **≥5** services from the audit's 11-service list, justify each against CFS
requirements, and map each to the resource that implements it — so B.3.2 is
unambiguous to an auditor.

## The 11-service list

VNet + **VNet Peering**, **ExpressRoute**, **VPN Gateway**, **Virtual WAN**,
**CDN**, **Front Door**, **Load Balancer**, **Private Link**, **Traffic
Manager**, **Application Gateway**, **Azure Firewall**.

## CFS recommended set (≥5 deployed)

| Service | Deployed? | CFS role |
| --- | --- | --- |
| VNet + VNet Peering | ✅ | Hub & spoke topology |
| Azure Firewall (Premium) | ✅ | Central egress + IDPS/TLS inspection |
| Azure Bastion | ✅ | Private admin access (no public IP) |
| Private Link / private endpoints | ✅ | Private-only PaaS + private DNS |
| Application Gateway + WAF | ✅ | Secure ingress to the web tier |
| Load Balancer | ✅/➖ | Spoke workload distribution |
| Front Door | ➖ (by design) | Secure global delivery overlay |
| ExpressRoute / VPN Gateway | ➖ (by design) | Hybrid connectivity (design) |

> Bastion is not on the 11-service list — count it as hardening, not toward the
> five. Ensure **at least five list services** are explicitly named.

## Steps

1. Map CFS requirements → candidate services from the list.
2. Choose ≥5 to **deploy**; mark others **covered-by-design** with rationale.
3. For each deployed service, name the **AVM module** and the resource name
   (CFS naming).
4. Emit the table into the HLD (B.2.1) and an implementation checklist for B.3.2.

## Definition of done

- [ ] ≥5 list services named and justified
- [ ] Deployed vs covered-by-design marked
- [ ] Each deployed service mapped to an AVM module + resource name
- [ ] Table embedded in B.2.1 and B.3.2 evidence
