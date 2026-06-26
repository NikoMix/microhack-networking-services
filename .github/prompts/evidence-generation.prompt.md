---
mode: agent
description: >-
  Reusable skill for Challenges 01–06. Generates and maintains Module B evidence
  artifacts with the correct file naming, audit-bullet coverage, and the
  evidence index that maps every control to its artifact.
---

# Skill: Evidence generation (B.1.1 → B.4.2)

Use with the producing agent for each control (and especially
**`evidence-author`** for the index).

## Goal

Every control produces an artifact that (a) is named to standard, (b) addresses
**every** auditor bullet for that control, and (c) appears in the evidence index.

## File-naming standard

`B<x.y>_<DocType>_CFS_v1.<ext>` — e.g. `B2.1_SolutionDesign_CFS_v1.docx`,
`B4.1_SignOff_CFS_v1.pdf`. Markdown sources live in the lab; the
`evidence-templates/` render the final `.docx`/`.pdf`.

## Control → artifact map

| Control | DocType | File |
| --- | --- | --- |
| B.1.1 | Requirements | `B1.1_Requirements_CFS_v1` |
| B.2.1 | SolutionDesign | `B2.1_SolutionDesign_CFS_v1` |
| B.2.2 | WAFReview | `B2.2_WAFReview_CFS_v1` |
| B.3.1 / B.3.2 | Implementation | `B3.1_Implementation_CFS_v1` |
| B.4.1 | TestPlan + SignOff | `B4.1_TestPlan_CFS_v1`, `B4.1_SignOff_CFS_v1` |
| B.4.2 | AsBuilt + Runbook | `B4.2_AsBuilt_CFS_v1`, `B4.2_Runbook_CFS_v1` |

## Steps

1. Confirm the control's required bullets (see the control pages and
   `reference/` mapping) and check the draft addresses **each** one.
2. Apply the file-naming standard exactly; version is `v1` for the lab.
3. Ensure traceability: requirements → design → deployment → validation → docs.
4. Update the **evidence index**:

   ```markdown
   | Control | Artifact | Version | Date | Status |
   |---|---|---|---|---|
   | B.1.1 | B1.1_Requirements_CFS_v1 | v1 | 2026-… | Complete |
   ```

## Definition of done

- [ ] Artifact named to standard
- [ ] Every auditor bullet for the control addressed
- [ ] Traceable to upstream/downstream artifacts
- [ ] Evidence index updated
