---
mode: agent
description: >-
  Reusable skill for Challenge 06. Tears down the CFS deployment cleanly to stop
  cost, verifies nothing is left running, and records the teardown as evidence.
  Pair every deployment with this.
---

# Skill: Teardown checklist (cost hygiene)

Use with the **`iac-engineer`** and **`evidence-author`** agents. Every
deployment must be paired with a working teardown.

## Goal

Return the pupil's subscription to a clean, zero-cost state and prove it.

## Steps

1. **Pre-checks** — confirm validation evidence (B.4.1) and as-built (B.4.2) are
   captured *before* destroying anything.
2. **Preview the teardown** where possible (`what-if` on an empty template, or
   `terraform plan -destroy`).
3. **Tear down** in dependency order using `infra/scripts/` (e.g.
   `infra/scripts/teardown.sh` / `.ps1`), or delete the CFS resource groups:
   `rg-cfs-hub-swc`, `rg-cfs-spoke-*-swc`, and any shared RG.
4. **Verify empty** — `az group list` shows no `rg-cfs-*`; `az resource list`
   shows no `cfs-*`; soft-deleted Key Vaults purged (purge protection respected —
   note any retention).
5. **Cost confirm** — check the Challenge 00 budget/alert; note any residual
   (e.g. soft-delete retention, diagnostic storage) and its decay.
6. **Record** — append a teardown entry to the runbook / evidence index with date
   and verification output.

## Output format

```markdown
## Teardown — CFS — <date>
- [ ] B.4.1 + B.4.2 evidence captured first
- [ ] Teardown previewed
- [ ] Resource groups deleted: rg-cfs-hub-swc, rg-cfs-spoke-*-swc
- [ ] Verified: no rg-cfs-* / cfs-* resources remain
- [ ] Key Vault soft-delete handled
- [ ] Budget/alert checked; residual cost noted
Verification output:
```

## Definition of done

- [ ] Evidence captured before destroy
- [ ] All CFS resources removed and verified
- [ ] Residual cost understood and recorded
- [ ] Teardown logged in the runbook / evidence index
