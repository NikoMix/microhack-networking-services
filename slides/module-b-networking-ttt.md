---
marp: true
theme: default
paginate: true
header: "Module B — Networking Services · Train-the-Trainer"
footer: "Contoso Financial Services · Microsoft Azure Advanced Specialization"
---

# Module B — Networking Services

## Train-the-Trainer Microhack

1-day classroom lab · GitHub Copilot agents + MCP + Azure IaC

Contoso Financial Services — regulated EU fintech · swedencentral

---

## Who This Deck Is For

This deck equips trainers to **re-deliver** the Module B Networking Services microhack —
a 1-day classroom lab proving all seven Module B controls using GitHub Copilot agents,
MCP servers, and real Azure IaC deployments.

**Use this deck to:**

- Open and close each challenge block with context and timing
- Walk pupils through the agentic demo flow before they attempt independently
- Manage timing and trigger the gateway deployment at the right moment
- Address common questions and failure points during the day

**Audience:** Partner solution architects and trainers re-delivering this microhack to a
cohort of network engineers or cloud architects.

---

## Agentic Pattern — Every Challenge Follows This Loop

Every challenge uses the same five-step agentic workflow:

1. **Trainer opens** the challenge — context slide, timing, expected output
2. **Pupils invoke** the specialist Copilot agent in Copilot Chat
3. **Agent produces** a draft — requirements doc, HLD, Bicep, test plan, or evidence pack
4. **Challenger red-teams** the output — gaps, risks, compliance issues
5. **Human approval gate** — pupil reviews, corrects, approves — the approval IS the evidence

The trainer **demonstrates** steps 1–3 live before pupils attempt independently.

---

<!-- _class: lead -->

## How the Day Works

---

## The Day at a Glance

| Time | Block | Module B | Duration |
| --- | --- | --- | --- |
| 08:45 | Welcome, intros, objectives | — | 15 min |
| 09:00 | **Challenge 00** — Setup and CFS brief | Foundation | 45 min |
| 09:45 | **Challenge 01** — Requirements Assessment | B.1.1 | 45 min |
| 10:30 | Break | — | 15 min |
| 10:45 | **Challenge 02** — Solution Design and WAR | B.2.1 + B.2.2 | 75 min |
| 12:00 | Lunch | — | 45 min |
| 12:45 | **Challenge 03** — Deploy Hub and Spoke | B.3.1 + B.3.2 | 90 min |
| 14:15 | Break | — | 15 min |
| 14:30 | **Challenge 04** — Private Networking and Delivery | B.3.2 | 75 min |
| 15:45 | **Challenge 05** — Validation and Testing | B.4.1 | 60 min |
| 16:45 | Break | — | 10 min |
| 16:55 | **Challenge 06** — As-Built and Teardown | B.4.2 | 50 min |
| 17:45 | Retrospective and close | — | 15 min |

---

## Golden Rule — Start Gateways at 12:45

VPN / Virtual WAN gateway provisioning takes **30–45 minutes** — the day's only hard
blocking dependency.

At the moment lunch ends (12:45), before reading anything else, every pupil runs:

```bash
gh workflow run deploy.yml -f component=gateway
```

- Provisions the hub VNet + Azure Firewall Premium + VPN Gateway
- Continue with Bicep review via `@iac-engineer` while it builds
- Do **not** wait idle — the full agenda depends on this parallelism
- Write the command on the board before releasing the cohort from lunch

---

<!-- _class: lead -->

## Module B Overview

---

## The Seven Module B Controls

| Challenge | Control | What the auditor checks |
| --- | --- | --- |
| 00 — Setup | Foundation | Working environment, OIDC trust, agents live |
| 01 — Requirements | **B.1.1** | Structured assessment covering 8 topic areas |
| 02 — Solution Design | **B.2.1** | HLD with all ALZ design areas mapped to CFS |
| 02 — WAF Review | **B.2.2** | WAF Security + Reliability pillars reviewed |
| 03–04 — Deploy | **B.3.1** | At least one Module B scenario implemented |
| 03–04 — Deploy | **B.3.2** | 5 or more native Azure networking services |
| 05 — Validation | **B.4.1** | Test plan executed and customer sign-off captured |
| 06 — As-Built | **B.4.2** | As-built doc, decision log, and runbook produced |

---

## Azure Networking Services — 9 of 9 Deployed

CFS deploys **9 native Azure networking services** — well above the 5 required for B.3.2:

| Service | Challenge | Purpose |
| --- | --- | --- |
| Virtual Network + VNet Peering | 03 | Hub and spoke isolation |
| Azure Firewall Premium | 03 | Central egress and IDPS |
| Azure Bastion Standard | 03 | Private admin, no public IPs on compute |
| VPN Gateway | 03 | Hybrid connectivity to branches |
| Private Link + Private Endpoints | 04 | Zero public PaaS endpoints |
| Azure Load Balancer (internal) | 04 | Spoke workload high availability |
| NSG + NSG flow logs | 04 | Segmentation and audit trail |
| Application Gateway + WAF v2 | 04 | L7 SSL offload and OWASP WAF |
| Azure Front Door + WAF Premium | 04 | Global CDN and DDoS protection |

---

<!-- _class: lead -->

## The CFS Scenario

---

## Contoso Financial Services — The Brief

**Contoso Financial Services (CFS)** is a regulated EU fintech migrating from an
on-premises network to Azure. One narrative spine runs through all seven challenges.

**Requirements (PSD2 and GDPR constraints):**

- Zero public PaaS endpoints — Private Link everywhere
- Private compute only — admin access via Bastion, no public IPs on workload VMs
- Central egress via Azure Firewall Premium with IDPS enabled
- Hybrid connectivity to 3 branch offices via VPN (ExpressRoute by design only)
- Secure global delivery via Front Door + WAF + Application Gateway + WAF
- Primary region swedencentral, westeurope as documented DR target

---

## CFS Hub and Spoke Target Architecture

**Hub VNet** (`cfs-hub-vnet-swc`): Firewall Premium + Bastion Standard + VPN Gateway

**Spoke VNet** (`cfs-spoke-vnet-swc`): private VM + internal LB + Private Endpoints

| Resource | Name | SKU |
| --- | --- | --- |
| Hub VNet | cfs-hub-vnet-swc | /20 |
| Spoke VNet | cfs-spoke-vnet-swc | /24 |
| Azure Firewall | cfs-hub-afw-swc | Premium |
| Azure Bastion | cfs-hub-bas-swc | Standard |
| VPN Gateway | cfs-hub-gw-swc | VpnGw1AZ |
| App Gateway | cfs-edge-agw-swc | WAF_v2 |
| Front Door | cfs-edge-afd-swc | Premium |

Naming: `cfs-<role>-<type>-swc` · RGs: `rg-cfs-<tier>-swc` · tag: `env=lab`

---

## Deploy and Teardown Interface (Canonical)

**Deploy via GitHub Actions workflow_dispatch with OIDC (environment: `lab`):**

```bash
gh workflow run deploy.yml -f component=gateway  # hub VNet + gateway — RUN FIRST (30–45 min)
gh workflow run deploy.yml -f component=hub      # adds Azure Bastion
gh workflow run deploy.yml -f component=spoke    # spoke + peering + Private Endpoints + VM + LB
gh workflow run deploy.yml -f component=edge     # App Gateway + WAF + Front Door + WAF
gh workflow run deploy.yml -f component=all      # all components in a single workflow run
```

**Optional flags:** `-f whatIfOnly=true` (preview) · `-f location=swedencentral`

**Valid components: `all` · `gateway` · `hub` · `spoke` · `edge` — no others exist.**

**Teardown (literal string `DELETE` required):**

```bash
gh workflow run teardown.yml -f confirm=DELETE
```

---

<!-- _class: lead -->

## Challenge 00

### Setup, Tooling and the CFS Brief

*Foundation · 45 minutes · 09:00–09:45*

---

## Challenge 00 — What Pupils Do

**Goal:** Every pupil has a running Codespace with agents, MCP, OIDC, and budget alert active.

**Steps:**

1. Fork the repo and open in GitHub Codespaces (dev container starts automatically)
2. Set up OIDC federated credential linking the GitHub repo to the Azure subscription
3. Verify agents respond: `@network-architect` and `@requirements-analyst` in Copilot Chat
4. Confirm the Azure MCP server is live (check `.vscode/mcp.json`)
5. Set a budget alert on the Azure subscription (referenced in Challenge 06 evidence)
6. Read the CFS brief in `reference/cfs-scenario/`

**Trainer talk track:**

- Demonstrate OIDC setup live — it is the most common failure point for new cohorts
- Show `@network-architect` responding before releasing pupils to attempt
- Confirm `az account show` runs clean from the Codespace terminal
- Checkpoint at 09:40: every pupil has agents live and OIDC verified

---

## Challenge 00 — OIDC Setup at a Glance

OIDC federated credentials let GitHub Actions authenticate to Azure without stored secrets.

**Required Azure RBAC:**

- `Contributor` on the subscription or resource group
- `User Access Administrator` (for role assignments during IaC deployment)

**GitHub Actions secrets required:**

| Secret | Where to find it |
| --- | --- |
| `AZURE_CLIENT_ID` | App registration or Managed Identity client ID |
| `AZURE_TENANT_ID` | Azure Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |

GitHub Actions environment `lab` gates secrets with required reviewer approval.

Full setup guide: `prerequisites/`

---

<!-- _class: lead -->

## Challenge 01

### Requirements Assessment

*B.1.1 · 45 minutes · 09:45–10:30*

---

## Challenge 01 — What Pupils Do

**Goal:** Produce a requirements assessment covering all 8 Module B topic areas (B.1.1).

**Steps:**

1. In Copilot Chat: invoke `@requirements-analyst`
2. Use the `requirements-capture` skill to drive the structured 8-topic interview
3. Agent drafts `B1.1_RequirementsAssessment_CFS_v1.docx`
4. Invoke `@challenger` to red-team the draft and identify gaps
5. Pupil approves and signs the final document — this is the B.1.1 evidence artifact

**The 8 topic areas** (auditor checks all of these):

- Business requirements · Current state assessment · Target architecture
- Networking services · Security and compliance · Hybrid connectivity
- Identity and access management · Operational requirements

**Checkpoint at 10:25:** every pupil has an approved and signed B.1.1 draft.

---

<!-- _class: lead -->

## Challenge 02

### Solution Design + Well-Architected Review

*B.2.1 + B.2.2 · 75 minutes · 10:45–12:00*

---

## Challenge 02 — Solution Design (B.2.1)

**Goal:** Produce an HLD with all ALZ design areas mapped to the CFS engagement.

**Invoke:** `@solution-designer` with the `solution-design` skill

**ALZ design areas the agent covers for CFS:**

- Enterprise enrolment and Entra ID
- Identity and access management
- **Network topology and connectivity** (hub and spoke — primary focus)
- Resource organisation, tagging, and governance
- Security, compliance, and monitoring

**Talk track:** Show how the agent selects hub and spoke (Scenario 1) over vWAN and records
the rationale in the decision log. The auditor checks that design choices are justified —
a good HLD explains *why*, not just *what*.

**Evidence artifact:** `B2.1_SolutionDesign_CFS_v1.docx`

---

## Challenge 02 — Well-Architected Review (B.2.2)

**Goal:** WAF review against at least 2 pillars — Security (mandatory) and Reliability (mandatory).

**Invoke:** `@waf-reviewer` with the `waf-review` skill

| Pillar | Key CFS findings |
| --- | --- |
| Security | No public PaaS · Firewall Premium + IDPS · Private Link everywhere · NSG flow logs |
| Reliability | AZ-redundant Firewall · AZ-redundant Gateway · ZRS storage · Bastion Standard |

**B.2.2 requirements:**

- At least 2 pillars reviewed — Security and Reliability are mandatory for CFS
- Each finding must include a recommendation, not just a risk flag
- `@challenger` must review the WAF output before the pupil signs off

**Evidence artifact:** `B2.2_WAFReview_CFS_v1.docx`

---

<!-- _class: lead -->

## Challenge 03

### Deploy the Secure Hub and Spoke

*B.3.1 + B.3.2 (start) · 90 minutes · 12:45–14:15*

---

## Challenge 03 — Trigger the Gateway First

Remind pupils at 12:00 (start of lunch): *"When you return at 12:45, your first command is the gateway."*

Immediately at 12:45, before reading the challenge page:

```bash
gh workflow run deploy.yml -f component=gateway
```

This provisions: hub VNet + Log Analytics + Azure Firewall Premium + VPN Gateway.

**Duration: 30–45 minutes — the day's only hard long pole.**

- Continue with Bicep review via `@iac-engineer` while it builds
- Write the command on the board or paste it in Teams chat before releasing from lunch
- Confirm in GitHub Actions that all pupils have a running workflow job

---

## Challenge 03 — Hub Deployment Sequence

**After triggering gateway, continue in parallel:**

```bash
# Hub component — no dependency on gateway, runs in parallel:
gh workflow run deploy.yml -f component=hub    # adds Azure Bastion (~5 min)

# Spoke component — wait for gateway workflow to complete first:
gh workflow run deploy.yml -f component=spoke  # spoke VNet + peering + Private Endpoints + VM + LB
```

**B.3.2 services confirmed after this challenge:**

- Virtual Network + VNet Peering
- Azure Firewall Premium
- Azure Bastion Standard
- VPN Gateway

**Talk track:** Use `@iac-engineer` to walk through `infra/bicep/`. Show the
`-f whatIfOnly=true` flag before the real deploy. Point out Azure Verified Module references.

---

<!-- _class: lead -->

## Challenge 04

### Private Networking, Isolation and Global Delivery

*B.3.2 (complete) · 75 minutes · 14:30–15:45*

---

## Challenge 04 — What Gets Deployed

```bash
gh workflow run deploy.yml -f component=edge
```

**Services added in this challenge (completing 9 of 9 for B.3.2):**

| Service | Purpose |
| --- | --- |
| Private Endpoints (Key Vault + Storage) | Zero public PaaS endpoints |
| Internal Load Balancer | Spoke workload high availability |
| NSG + NSG flow logs | Segmentation and audit trail |
| Application Gateway + WAF v2 | L7 SSL offload and OWASP WAF |
| Azure Front Door + WAF Premium | Global CDN and DDoS protection |

**Key demo points:**

- DNS from inside the spoke VM returns a private IP, not a public IP
- WAF policy in the Azure portal: custom rules vs managed OWASP ruleset
- End-to-end private path: Front Door to App Gateway to private spoke VM

---

<!-- _class: lead -->

## Challenge 05

### Validation and Testing

*B.4.1 · 60 minutes · 15:45–16:45*

---

## Challenge 05 — What Pupils Do

**Goal:** Execute the B.4.1 test plan and capture customer sign-off.

**Invoke:** `@validation-engineer`

**Mandatory test cases the agent scripts:**

1. Hub to spoke connectivity via Firewall (Azure Connection Monitor)
2. Private endpoint DNS resolution returns a private IP
3. Firewall blocks direct Internet egress from spoke subnet
4. WAF blocks an OWASP test payload at Application Gateway
5. Front Door health probe reaches private origin via App Gateway
6. Bastion SSH or RDP to private VM — no public IP required

**Evidence artifacts:**

- `B4.1_TestPlan_CFS_v1.docx` — test cases, scope, and pass/fail criteria
- `B4.1_SignOff_CFS_v1.docx` — **trainer must sign as "customer" for the audit**

**Checkpoint at 16:40:** all 6 test cases green and sign-off document signed.

---

<!-- _class: lead -->

## Challenge 06

### As-Built Documentation, Operations and Teardown

*B.4.2 · 50 minutes · 16:55–17:45*

---

## Challenge 06 — As-Built Evidence Pack

**Goal:** Document the deployed state and produce the complete B.4.2 evidence pack.

**Invoke:** `@evidence-author`

**Three required documents:**

| Artifact | What the auditor checks |
| --- | --- |
| `B4.2_AsBuilt_CFS_v1.docx` | Actual deployed state — real IPs, SKUs, deviations from HLD |
| `B4.2_DecisionLog_CFS_v1.docx` | Key design decisions with recorded rationale |
| `B4.2_OperationsRunbook_CFS_v1.docx` | Day-2 SOPs for Firewall policy, cert renewal, GW failover |

The as-built must reflect **actual deployed state**, not design intent.
`@evidence-author` queries the live Azure environment to generate accurate resource details.

---

## Challenge 06 — Teardown

**After every pupil has captured and signed their evidence pack:**

```bash
gh workflow run teardown.yml -f confirm=DELETE
```

**Critical details:**

- The token must be the **literal string `DELETE`** — nothing else will be accepted
- Deletes all resources in `rg-cfs-hub-swc` and `rg-cfs-spoke-swc`
- Optional: add `-f noWait=true` to return control immediately
- Verify deletion in the Azure portal before ending the session

**Trainer checklist before triggering teardown:**

- Every pupil has all three B.4.2 documents saved locally
- B.4.1 sign-off document is signed by the trainer
- All evidence artifacts from B.1.1 through B.4.2 are saved

---

<!-- _class: lead -->

## Copilot Agents, Skills and MCP

### Live Demonstration Guide

---

## The Copilot Agent Ecosystem

Eight specialist agents — invoke by `@name` in Copilot Chat:

| Agent | Role | Primary challenge |
| --- | --- | --- |
| `@network-architect` | Orchestrator — routes work to specialists | All |
| `@requirements-analyst` | Requirements capture for B.1.1 | 01 |
| `@solution-designer` | HLD with ALZ design areas for B.2.1 | 02 |
| `@waf-reviewer` | WAF Security and Reliability review for B.2.2 | 02 |
| `@iac-engineer` | Bicep and Terraform IaC deploy via OIDC | 03–04 |
| `@validation-engineer` | Test plan execution and sign-off for B.4.1 | 05 |
| `@evidence-author` | As-built, decision log, runbook for B.4.2 | 06 |
| `@challenger` | Red-team and QA at every human approval gate | All |

Agent definitions: `.github/agents/*.agent.md`

---

## Skills — Reusable Prompt Files

Skills live in `.github/prompts/*.prompt.md` — invoked inside agent sessions:

| Skill | Purpose |
| --- | --- |
| `requirements-capture` | Structured 8-topic interview for B.1.1 |
| `solution-design` | HLD scaffold with ALZ design areas |
| `waf-review` | WAF review template for Security and Reliability |
| `networking-services-selection` | Maps CFS requirements to Azure services |
| `what-if-review` | Explains Azure what-if and Terraform plan output |
| `evidence-generation` | Compiles evidence artifacts from agent output |
| `teardown-checklist` | Confirms all resources are deleted before sign-off |
| `orchestration-kickoff` | Bootstraps the full CFS engagement from scratch |

---

## MCP Servers — Wiring Agents to Azure and GitHub

Two MCP servers are pre-configured in `.vscode/mcp.json`:

**Azure MCP** (keyless — `DefaultAzureCredential`):

- Lists resources, resource groups, and subscriptions
- Queries Azure Resource Graph and Log Analytics
- Reads Key Vault secrets (RBAC-protected, no API keys stored)

**GitHub MCP** (Codespaces `GITHUB_TOKEN`):

- Creates and updates GitHub Issues for per-challenge control tracking
- Reads and creates pull requests and workflow runs
- Reads repository files for agent context and grounding

**Live demo:** Show `@network-architect` querying the subscription via Azure MCP to
confirm the hub VNet is deployed before starting Challenge 05.

---

## Modular Inference — Switching Backends

Agents are **model-agnostic** — switch inference provider without modifying any agent file.

| Backend | How to activate | Notes |
| --- | --- | --- |
| GitHub Models (default) | `GITHUB_TOKEN` auto-set in Codespaces | Zero setup required |
| Azure OpenAI | Set `AZURE_OPENAI_ENDPOINT` + RBAC | gpt-4o, gpt-4.1-turbo |
| Azure AI Foundry | Set `AZURE_AI_PROJECT_ENDPOINT` | Any Foundry deployment |

Full switching guide: `reference/modular-inference`

**No Azure AI application is deployed** — inference only drives Copilot agents in chat.

**All three backends are keyless** — no API keys stored in GitHub secrets.

---

<!-- _class: lead -->

## Facilitation Tips

---

## Room Setup and Cohort Management

**Before the class:**

- Verify every pupil has **Owner rights** on an Azure subscription
- Confirm GitHub Copilot is enabled for all participants
- Check GitHub Codespaces quota (60 core-hours per month on the free tier)
- Verify swedencentral quota for Firewall Premium, Public IPs, and VPN Gateway
- Decide inference backend — GitHub Models is zero-setup default
- Dry-run Challenge 03 once on your own subscription first

**During the class:**

- Cohort size of 8–16 is ideal; pair participants per subscription beyond that
- After lunch (Challenge 03) is the most critical timing moment — keep the gateway announcement crisp
- Challenge 04 commonly overruns by 10–15 minutes on first delivery; plan for it

---

## Common Failure Points

| Symptom | Likely cause | Quick fix |
| --- | --- | --- |
| OIDC auth fails | Federated credential subject format wrong | Re-check `repo:owner/repo:environment:lab` format |
| Agent not responding | Copilot extension disabled in Codespace | Re-enable in the Extensions panel |
| Quota error on Firewall | Premium SKU not pre-approved | Add `-f location=westeurope` flag |
| Gateway takes over 45 min | Region capacity pressure | Check Actions log; cancel and retry |
| DNS returns public IP | Private DNS zone not linked to spoke VNet | Add VNet link in Azure portal |
| Teardown workflow fails | Resource lock on resource group | Remove locks before re-triggering |
| `@challenger` returns empty | Context window overloaded | Summarise agent output before invoking |

Full runbook: `trainer/troubleshooting-and-reset`

---

<!-- _class: lead -->

## Wrap and Retrospective

---

## Retrospective Prompts (10 minutes at 17:45)

**What worked well?**

- Which agent output surprised you with its quality?
- Which challenge felt most authentic to a real partner engagement?
- What would you highlight as a differentiator when talking to a customer?

**What to improve?**

- Where did you lose time? (Common: OIDC setup, gateway wait, WAF review depth)
- Which talk track needed more depth or a stronger live demo moment?
- Any evidence items that needed more polish for audit readiness?

**Confidence check:** Ask each participant: *"Are you ready to deliver this to a partner cohort?"*

---

## Re-delivery Checklist

Before delivering to a partner cohort, confirm:

- [ ] Dry-run Challenge 03 on your own subscription (warms quota and registrations)
- [ ] Verified swedencentral quota for Firewall Premium and Public IPs
- [ ] Every pupil has Owner rights on an Azure subscription
- [ ] Inference backend selected and tested (GitHub Models is zero-setup default)
- [ ] Cohort briefed on cost estimate (approximately €40–80 for a full day)
- [ ] GitHub Copilot enabled for all participants
- [ ] Reviewed the Delivery Logistics guide in `trainer/delivery-logistics`
- [ ] Trainer subscription ready for live demonstrations

**Thank you for delivering this microhack.**

Module B — Networking Services in Microsoft Azure Advanced Specialization
