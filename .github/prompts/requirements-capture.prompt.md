---
mode: agent
description: >-
  Reusable skill for Challenge 01 / control B.1.1. Interviews the pupil (acting
  as the CFS customer) and produces a complete, testable Cloud Networking
  Requirements Assessment covering all eight audit bullets, three traffic flows,
  and a non-overlapping IP/DNS plan.
---

# Skill: Requirements capture (B.1.1)

Use with the **`requirements-analyst`** agent.

## Goal

Produce `B1.1_Requirements_CFS_v1.md` — a structured requirements set that is
**complete** (all eight bullets), **testable** (each requirement has an
acceptance criterion), and **traceable** (each maps to a likely Azure service).

## Steps

1. **Read first.** Load the CFS scenario brief from
   `src/content/docs/reference/` and any prior notes. Do not re-ask what the brief
   already answers.
2. **Walk the eight bullets** and capture each:
   1. Business & technical drivers (incl. DORA / GDPR / PCI residency).
   2. Connectivity (hybrid, inter-spoke, ingress/egress, branch/remote).
   3. Security & compliance (Zero Trust, inspection, DDoS, private-only PaaS).
   4. Performance & latency targets.
   5. Scalability & growth (spoke count, IP runway, multi-region).
   6. IP addressing & DNS (non-overlapping plan, private zones, hybrid DNS).
   7. Operations & governance (monitoring, RBAC, policy, handover owner).
   8. Constraints & assumptions (budget, timeline, skills, out-of-scope).
3. **Capture ≥3 traffic flows** (user→app→db, on-prem admin→spoke VM,
   workload→Private Link PaaS). These seed B.4.1 tests.
4. **Draft a non-overlapping IP/DNS plan** (hub + spokes + reserved growth).
5. **Label every assumption** where the brief is silent and flag it for sign-off.

## Output format

```markdown
# B.1.1 Cloud Networking Requirements Assessment — CFS

## Scope & method
## 1. Business & technical drivers
... (bullets 2–8) ...
## Traffic flows (≥3)
## IP addressing & DNS plan
## Requirements
| ID | Requirement | Priority | Acceptance criterion | Likely Azure service |
## Assumptions & open questions
```

## Definition of done

- [ ] All eight bullets addressed
- [ ] ≥3 traffic flows captured
- [ ] Non-overlapping IP/DNS plan present
- [ ] Every requirement has a testable acceptance criterion
- [ ] Assumptions explicitly labelled
- [ ] Ready for `challenger` review and the human approval gate
