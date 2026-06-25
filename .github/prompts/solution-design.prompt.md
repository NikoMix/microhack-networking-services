---
mode: agent
description: >-
  Reusable skill for Challenge 02 / control B.2.1. Turns approved B.1.1
  requirements into the CFS hub & spoke High-Level Design — chosen scenario, ALZ
  design-area mapping, AVM module selection, topology diagram, and decisions log.
---

# Skill: Solution design (B.2.1)

Use with the **`solution-designer`** agent.

## Goal

Produce `B2.1_SolutionDesign_CFS_v1.md` — a deployable HLD that the
`iac-engineer` can implement verbatim, satisfies **B.3.2's ≥5 services**, and
maps every ALZ design area.

## Steps

1. **Adopt** the approved B.1.1 IP plan and traffic flows — do not invent new
   ones.
2. **Pick one of the five scenarios** and justify it (CFS default: *Secure
   network infrastructure*, with *Secure global app delivery* for the web tier).
3. **Map every ALZ / CAF design area** (identity, network topology, resource
   org, governance, security, management, platform automation, cost).
4. **Select components + AVM modules** with SKU/tier and a one-line reason each.
5. **Name ≥5 B.3.2 services** explicitly and mark deployed vs covered-by-design.
6. **Draw the topology** (`mermaid`) and record a **decisions log** with weighted
   trade-offs (e.g. Firewall Premium vs Standard, hub & spoke vs vWAN).

## Output format

```markdown
# B.2.1 Solution Design (HLD) — CFS
## Executive summary
## Chosen scenario & justification
## ALZ design-area mapping
| Design area | CFS decision | Notes |
## Topology (mermaid)
## Components & AVM modules
| Component | AVM module | SKU/tier | Why |
## IP/DNS plan
## Traffic flows
## Azure networking services for B.3.2
| Service | Deployed? | Role |
## Decisions log
| Decision | Options | Chosen | Score/why |
## Assumptions
```

## Definition of done

- [ ] One scenario chosen + justified
- [ ] All ALZ design areas mapped
- [ ] ≥5 B.3.2 services named (deployed vs by-design)
- [ ] Every component cites an AVM module + tier
- [ ] Topology diagram + decisions log present
- [ ] Ready for `waf-reviewer`, `challenger`, and the human approval gate
