# Evidence Templates — Module B Networking Microhack

Pre-seeded evidence templates for the **Contoso Financial Services (CFS)** Azure Networking Microhack.
Each template satisfies one or more **Module B control** evidence requirements for the
_Networking Services in Microsoft Azure Advanced Specialization_ audit.

> **How to use:** Open the relevant template, complete all cells/sections marked `<< >>` or highlighted
> in yellow, then save your completed copy to `evidence-output/<filename>` (gitignored — never commit
> evidence output with participant data).

---

## Template Inventory

| File | Control(s) Satisfied | Format | Purpose | Key Sections |
|------|---------------------|--------|---------|--------------|
| [B1.1_RequirementsAssessment_CFS_v1.xlsx](./B1.1_RequirementsAssessment_CFS_v1.xlsx) | **B.1.1** | Excel | Requirements register | Functional reqs, NFRs, Constraints, Compliance mapping |
| [B2.1_SolutionDesign_CFS_v1.docx](./B2.1_SolutionDesign_CFS_v1.docx) | **B.2.1** | Word | Solution design document | Architecture, service selection, IP plan, security, compliance |
| [B2.2_WellArchitectedReview_CFS_v1.xlsx](./B2.2_WellArchitectedReview_CFS_v1.xlsx) | **B.2.2** | Excel | WAF review workbook | Security + Reliability (required); OE + Perf + Cost (optional) |
| [B3.x_AsBuilt_CFS_v1.docx](./B3.x_AsBuilt_CFS_v1.docx) | **B.3.1 + B.3.2** | Word | As-built record | Resource inventory, service-to-control map (≥5 services), IP plan |
| [B4.1_ValidationTestPlan_CFS_v1.xlsx](./B4.1_ValidationTestPlan_CFS_v1.xlsx) | **B.4.1** | Excel | Test plan + results | 16 pre-seeded test cases, expected vs actual, customer sign-off |
| [B4.2_DecisionLog_CFS_v1.xlsx](./B4.2_DecisionLog_CFS_v1.xlsx) | **B.4.2** | Excel | Architecture decision log | 10 pre-seeded decisions (topology, IaC, services, DR) |
| [B4.2_SOPs_CFS_v1.docx](./B4.2_SOPs_CFS_v1.docx) | **B.4.2** | Word | Standard operating procedures | 5 SOPs: Firewall changes, PE management, NSG audit, VPN recovery, teardown |

---

## Control → Template Mapping

| Module B Control | Control Name | Evidence Template(s) |
|-----------------|--------------|----------------------|
| B.1.1 | Requirements Assessment | `B1.1_RequirementsAssessment_CFS_v1.xlsx` |
| B.2.1 | Solution Design | `B2.1_SolutionDesign_CFS_v1.docx` |
| B.2.2 | Well-Architected Review | `B2.2_WellArchitectedReview_CFS_v1.xlsx` |
| B.3.1 | Implementation (network) | `B3.x_AsBuilt_CFS_v1.docx` |
| B.3.2 | Implementation (services) | `B3.x_AsBuilt_CFS_v1.docx` |
| B.4.1 | Validation & Testing | `B4.1_ValidationTestPlan_CFS_v1.xlsx` |
| B.4.2 | Post-Deployment Docs | `B4.2_DecisionLog_CFS_v1.xlsx` + `B4.2_SOPs_CFS_v1.docx` |

---

## Filling In the Templates

### B1.1 — Requirements Assessment (`xlsx`)

1. Open the **Requirements Register** sheet.
2. Review the 10 functional requirements and 7 NFRs — they are pre-seeded for CFS. Add any project-specific requirements.
3. Set **Status** to `Closed` as each requirement is deployed and verified.
4. Add notes in the **Notes / Assumptions** column for any deviations.
5. Check the **Compliance Mapping** sheet — verify DORA/GDPR/PCI-DSS mappings match your deployment.

### B2.1 — Solution Design (`docx`)

1. Complete all `<< >>` placeholders (Prepared By, Date, Reviewer, etc.).
2. Review Section 5 (IP Addressing Plan) against your actual deployment.
3. Update Section 7 (Compliance Mapping) if you used different services.
4. Get signatures in Section 9 (Document Approval).

### B2.2 — Well-Architected Review (`xlsx`)

1. **Security** sheet is **REQUIRED** — complete all pre-seeded findings. Set Owner + Status.
2. **Reliability** sheet is **REQUIRED** — complete all pre-seeded findings.
3. Optionally complete Operational Excellence, Performance, Cost sheets.
4. Set Status = `Closed` only when remediation is applied and evidence exists.
5. The Dashboard auto-calculates finding counts per pillar.

> ⚠️ The auditor **requires both Security and Reliability** — do not skip either pillar.

### B3.x — As-Built Record (`docx`)

1. Complete Section 1 (Deployment Summary) — subscription ID, deployment date, GitHub Actions run.
2. Complete the Resource Inventory (Section 2) — copy from `az resource list --tag environment=lab`.
3. Mark each service in Section 3 (Service-to-Control Map) as `Yes` once deployed.
4. Verify IP addressing in Section 4 matches actual deployment.
5. Document any deviations in Section 5.
6. Get sign-off in Section 6.

### B4.1 — Validation Test Plan (`xlsx`)

1. Open the **Test Plan** sheet — 16 pre-seeded test cases covering all B.3.2 services.
2. Run each test and fill in **Actual Result** and **Pass / Fail**.
3. Add evidence screenshot references in the **Evidence** column.
4. Fill in **Tester** name and **Date Tested**.
5. Go to the **Customer Sign-Off** sheet — complete the summary counts and get all 4 signatures.

> ⚠️ The auditor checks for a **customer sign-off block** — do not skip the Sign-Off sheet.

### B4.2 — Decision Log (`xlsx`)

1. Review the 10 pre-seeded architecture decisions (topology, IaC, Firewall SKU, etc.).
2. Add any project-specific decisions as `DL-011` onwards.
3. Set Status = `Approved` / `Under Review` / `Superseded` as appropriate.
4. Note the Review Date for each decision.

### B4.2 — SOPs (`docx`)

1. Complete all `<< >>` placeholders in each SOP's contact table.
2. Review the 5 SOPs for accuracy against your deployed environment.
3. Add any organization-specific procedures in the blank rows.
4. Get review signatures on each SOP.

---

## Naming Convention

All evidence files follow: `B<x.y>_<DocType>_CFS_v1.<ext>`

- `B<x.y>` — Module B control number (e.g. `B2.1`, `B4.2`)
- `<DocType>` — Document type in CamelCase
- `CFS` — Customer (Contoso Financial Services)
- `v1` — Version number
- `.<ext>` — File extension (`xlsx` for spreadsheets, `docx` for documents)

> Completed evidence output goes to `evidence-output/` (gitignored). **Never commit** evidence
> output files containing participant subscription IDs or personal data.

---

## Related Diagrams

Architecture diagrams referenced in the evidence templates are in [`../diagrams/`](../diagrams/):

- `hub-spoke-architecture.drawio` / `.svg` — Main topology (referenced in B2.1, B3.x)
- `private-link-compute-detail.drawio` / `.svg` — PE detail (referenced in B3.x, B4.1)
- `global-delivery.drawio` / `.svg` — Front Door flow (referenced in B2.1, B4.1)
- `traffic-flow-egress-firewall.drawio` / `.svg` — Firewall egress (referenced in B2.2, B4.1)
