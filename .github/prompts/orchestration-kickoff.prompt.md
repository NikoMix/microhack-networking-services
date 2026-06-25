---
mode: agent
description: >-
  Reusable kickoff skill. Bootstraps the CFS engagement with the network-architect
  orchestrator — establishes context, finds the lowest open control, and routes
  to the right sub-agent while enforcing human approval gates.
---

# Skill: Orchestration kickoff

Use with the **`network-architect`** agent to start or resume the engagement.

## Goal

Get the pupil to the single correct next action, with the right sub-agent and the
right approval gate.

## Steps

1. **Establish context** — confirm the CFS scenario, the target subscription, and
   that OIDC + the Challenge 00 budget are in place.
2. **Find the lowest open control** from the GitHub Issues and produced evidence
   files (`B<x.y>_<DocType>_CFS_v1`). Work it next.
3. **Route** to exactly one sub-agent:

   | Open control | Run |
| --- | --- |
   | B.1.1 | `requirements-analyst` |
   | B.2.1 | `solution-designer` |
   | B.2.2 | `waf-reviewer` |
   | B.3.1 / B.3.2 | `iac-engineer` |
   | B.4.1 | `validation-engineer` |
   | B.4.2 | `evidence-author` |

4. **Always** invoke `challenger` on the produced deliverable.
5. **Stop at the human approval gate** — summarise (bullets/tables), surface
   `challenger` findings and residual risk, and ask for explicit approval before
   proceeding.

## Guardrails

- Never cross a gate on the pupil's behalf.
- Never deploy without an approved what-if (use `what-if-review`).
- Never skip the teardown pairing (use `teardown-checklist`).
- Keep AVM-first, OIDC, private-by-default, `swedencentral`, CFS naming.

## Definition of done

- [ ] Context confirmed
- [ ] Lowest open control identified
- [ ] Correct sub-agent invoked + `challenger` run
- [ ] Tight summary presented
- [ ] Pupil prompted at the approval gate
