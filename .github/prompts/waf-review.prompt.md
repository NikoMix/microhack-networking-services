---
mode: agent
description: >-
  Reusable skill for Challenge 02 / control B.2.2. Runs an Azure Well-Architected
  Review of the CFS design against at least two pillars (always Security and
  Reliability), scoring findings and separating must-fix from hardening.
---

# Skill: Well-Architected review (B.2.2)

Use with the **`waf-reviewer`** agent.

## Goal

Produce `B2.2_WAFReview_CFS_v1.md` — a scored WAF review covering **≥2 pillars**
(**Security + Reliability** mandatory; **Performance Efficiency** if latency is a
stated goal), with actionable, traceable findings.

## Steps

1. **Read** `B2.1_SolutionDesign_CFS_v1.md` and the approved B.1.1 requirements.
2. **Score each pillar** (1–5 or R/A/G) with explicit justification.
3. **Security checks** — Zero Trust segmentation, Firewall Premium IDPS/TLS,
   DDoS tier, Private Link coverage, private DNS + exfiltration controls,
   Bastion-only admin, Key Vault purge protection, key auth disabled, WAF, OIDC.
4. **Reliability checks** — availability zones, gateway redundancy, ER+VPN
   failover, health probes, SLA stacking, BGP convergence, IaC reproducibility,
   network-config backup/DR.
5. **Classify** each finding **Must-fix-before-deploy** vs **Post-deploy
   hardening**, with the exact AVM parameter / Azure control that closes it.

## Output format

```markdown
# B.2.2 Well-Architected Review — CFS
## Scope & pillars reviewed
## Pillar scores
| Pillar | Score | Summary |
## Findings
| ID | Pillar | Finding | Risk | Recommendation | AVM/Azure control | Priority |
## Must-fix before deploy
## Post-deploy hardening
## Overall posture statement
```

## Definition of done

- [ ] ≥2 pillars reviewed (Security + Reliability mandatory)
- [ ] Each pillar scored with justification
- [ ] Every finding has a specific AVM/Azure remediation
- [ ] Must-fix vs hardening separated
- [ ] Must-fix items routed to `solution-designer` / `iac-engineer`
