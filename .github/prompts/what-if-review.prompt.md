---
mode: agent
description: >-
  Reusable skill for Challenge 03–04 / controls B.3.x. Runs a safe what-if
  (Bicep) or terraform plan (Terraform) preview, summarises the delta, and gates
  the deployment behind explicit human approval. Never deploy without this.
---

# Skill: What-if / plan review (B.3.x)

Use with the **`iac-engineer`** agent. **No deployment happens without a clean,
human-approved preview.**

## Goal

Produce a concise preview summary of exactly what will change, so the pupil can
approve with confidence before the OIDC pipeline applies it.

## Steps

1. **Build & lint** first: `az bicep build` / `terraform validate && terraform
   fmt -check`. Resolve all warnings.
2. **Preview**:
   - **Bicep:** `az deployment sub create --location swedencentral
     --template-file infra/bicep/main.bicep --parameters @infra/bicep/main.bicepparam
     --what-if`
   - **Terraform:** `terraform plan -out tfplan` then `terraform show tfplan`.
3. **Summarise the delta** — group by Create / Modify / Delete / NoChange; call
   out anything destructive, any public exposure, and resource counts.
4. **Standards gate** — confirm: no public IPs on compute, no public PaaS
   endpoints, OIDC (no secrets), Key Vault purge protection on, key auth
   disabled, CFS naming + `lab` tag, `swedencentral`, latest API versions, AVM
   modules used.
5. **Cost note** — rough monthly estimate (`azure-pricing`) and confirm the
   teardown path exists in `infra/scripts/`.
6. **Stop at the gate** — present the summary; wait for explicit pupil approval
   before the workflow applies.

## Output format

```markdown
## What-if summary — <deployment>
- Create: N | Modify: N | Delete: N | NoChange: N
### Notable changes
- ...
### Destructive / exposure flags
- ...
### Standards check
- [ ] OIDC, no secrets   - [ ] Private-by-default   - [ ] KV purge protection
- [ ] CFS naming/tag     - [ ] AVM-first            - [ ] Latest API versions
### Est. monthly cost & teardown
- ...
**Decision required:** approve to deploy via GitHub Actions (OIDC)?
```

## Definition of done

- [ ] Build/validate clean
- [ ] What-if/plan run and summarised
- [ ] Destructive/exposure changes flagged
- [ ] Standards checklist passed
- [ ] Teardown path confirmed
- [ ] Awaiting explicit human approval
