---
marp: true
theme: default
paginate: true
header: "Module B · Networking Services in Microsoft Azure — Train-the-Trainer"
footer: "Contoso Financial Services microhack · GitHub Copilot agents + Azure"
---

# Networking Services in Microsoft Azure

## Module B — a 1-day, agent-driven Train-the-Trainer microhack

Deliver a Microsoft best-practice **hub & spoke** secure network — with private
networking, isolation, and private compute — to **your own Azure subscription**,
driven by **GitHub Copilot agents, skills, and MCP servers**.

This deck is the trainer's spine. The pupil instructions live in the docs site;
the answer keys live in the trainer-only solution pages.

---

## Who this is for

- Partner **network architects** preparing to deliver the microhack to pupils
- You will **re-deliver** this content, so every slide has a talk-track note in
  the [Facilitator guide](../trainer/facilitator-guide/)
- Assumed background: Azure networking fundamentals, Git, and basic Bicep
- No prior GitHub Copilot agent experience required — we teach it live

---

## What the pupils deliver in one day

- A real, deployed **Azure Landing Zone** hub & spoke topology
- **Nine** native Azure networking services (the audit needs five)
- A complete **Module B evidence pack** (7 audit artifacts)
- Every step produced **with** Copilot agents — not by hand
- A clean **teardown** so no resource is left running

The microhack is the proof that an architect can run the specialization
end to end with an AI pair.

---

## Module B controls — the whole map

| Control | Name | Challenge |
| --- | --- | --- |
| B.1.1 | Requirements Assessment | 01 |
| B.2.1 | Solution Design | 02 |
| B.2.2 | Well-Architected Review | 02 |
| B.3.1 | Scenario Implementation | 03 |
| B.3.2 | Five+ networking services | 03 + 04 |
| B.4.1 | Validation and Testing | 05 |
| B.4.2 | Post-Deployment Documentation | 06 |

---

## The customer — Contoso Financial Services

- Regulated EU fintech migrating off on-prem and a third-party network
- Hard requirements: **zero public PaaS exposure**, isolated spokes, **no public
  IPs** on compute, central egress inspection, secure global delivery
- Data residency: **Sweden Central**
- One narrative spine runs through all seven challenges — the pupils play the
  partner architect, the trainer plays the CFS sponsor

---

## Target architecture

- **Hub**: Azure Firewall Premium (IDPS + TLS inspection), VPN Gateway, Bastion,
  Log Analytics
- **Spoke**: private workload subnets, internal Load Balancer, private compute
  with no public IP
- **Private Link**: Key Vault and Storage reachable only over private endpoints
- **Edge**: Application Gateway + WAF and Front Door + WAF for global delivery
- **Governance**: budgets, alerts, Network Watcher, NSG flow logs

See `diagrams/hub-spoke-architecture` for the full topology.

---

## The agentic toolchain — eight agents

- `network-architect` — orchestrator, owns gates and approvals
- `requirements-analyst` — B.1.1 discovery
- `solution-designer` — B.2.1 high-level design
- `waf-reviewer` — B.2.2 Security + Reliability review
- `iac-engineer` — B.3.1 / B.3.2 deployment
- `validation-engineer` — B.4.1 testing
- `evidence-author` — B.4.2 documentation
- `challenger` — cross-cutting red-team and QA

---

## Skills — reusable prompts

Each skill in `.github/prompts/` is a packaged, repeatable prompt:

- `requirements-capture`, `solution-design`, `waf-review`
- `what-if-review`, `networking-services-selection`
- `evidence-generation`, `teardown-checklist`
- `orchestration-kickoff` — the trainer's "start the day" prompt

Demonstrate invoking a skill live in Challenge 01 so pupils see the pattern.

---

## MCP servers — keyless

- **Azure MCP** — lets agents query and reason over live Azure resources
- **GitHub MCP** — issues, PRs, and workflow runs from chat
- Wired in `.vscode/mcp.json`, environment-variable inputs, **no keys in files**
- In Codespaces the GitHub remote MCP needs no extra setup

The MCP servers are what make the agents *act* on the real environment.

---

## Modular inference — three backends

| Backend | Cost | Auth | When |
| --- | --- | --- | --- |
| GitHub Models | Free, rate-limited | `GITHUB_TOKEN` | Classroom default |
| Azure OpenAI | Pay-per-token | Keyless (Entra ID) | Enterprise data residency |
| Azure AI Foundry | Pay-per-token | Keyless (Entra ID) | Catalog + evaluations |

Same agent files, **only environment variables change**. No image generation is
needed, so any text model works. Details: [Inference backends](../trainer/inference-backends/).

---

## How deployments happen

- Pupils never run `az deploy` from a laptop — they run **GitHub Actions**
- **OIDC** federation: no secrets, no keys, short-lived tokens
- Staged deploy via `deploy.yml`, input `component`:
  `gateway` then `hub` then `spoke` then `edge` (or `all`)
- Teardown via `teardown.yml` with the literal confirm token `DELETE`
- Hub foundation deploys with every stage, so each stage is self-consistent

---

## Challenge 00 — Setup and the CFS brief

- Open the Codespace, establish **OIDC** trust to Azure
- Bring the agents and **MCP** online in Copilot Chat
- Set a **budget alert** before anything is deployed
- Read in the CFS brief — the scenario every later challenge builds on

Trainer goal: everyone green before the first break. Pair up stragglers.

---

## Challenge 01 — Requirements Assessment (B.1.1)

- Drive discovery with `@requirements-analyst` and the `requirements-capture` skill
- Capture all eight topic areas into `B1.1_RequirementsAssessment_CFS_v1.xlsx`
- The trainer answers as the CFS sponsor — keep responses consistent with the brief
- `@challenger` checks for gaps before sign-off

This is the first live agent demo — go slow and narrate.

---

## Challenge 02 — Design and Well-Architected Review

- `@solution-designer` produces the HLD across the six ALZ design areas (B.2.1)
- `@waf-reviewer` runs the Well-Architected Review — **Security and Reliability
  are mandatory** pillars (B.2.2)
- Artifacts: `B2.1_SolutionDesign_CFS_v1.docx`, `B2.2_WellArchitectedReview_CFS_v1.xlsx`
- Gate: the architecture must be approved before any deploy

---

## Challenge 03 — Deploy the hub and spoke

- **Start the gateway first** — `deploy.yml -f component=gateway` is the 30–45 min
  long pole; kick it off, then keep working
- Then `component=hub`, `component=spoke`
- Preview any stage safely with `whatIfOnly=true`
- Covers B.3.1 and begins B.3.2; evidence: `B3.x_AsBuilt_CFS_v1.docx`

The single most important pacing rule of the day lives on this slide.

---

## Challenge 04 — Private networking and global delivery

- Verify the **spoke** stage: Private Link to Key Vault and Storage, private DNS,
  no public IPs on compute, internal Load Balancer
- Deploy the **edge** stage: Application Gateway + WAF and Front Door + WAF
- Completes B.3.2 — nine services total, well past the five required
- `@iac-engineer` explains each service's role; `@challenger` probes for public exposure

---

## Challenge 05 — Validation and Testing (B.4.1)

- `@validation-engineer` builds the test plan in `B4.1_ValidationTestPlan_CFS_v1.xlsx`
- Prove private-only access, central egress, and WAF enforcement
- Enable **Network Watcher** and **NSG flow logs**
- **Mandatory customer sign-off** — the trainer signs the Customer Sign-Off sheet
- Virtual delivery: a named acknowledgement in chat or email is acceptable

---

## Challenge 06 — As-built, operations, and teardown

- `@evidence-author` finalizes the as-built, the decision log, and the SOPs
- Assemble the complete seven-artifact evidence pack
- Run `teardown.yml` with confirm `DELETE` — verify nothing is left running
- Close with the **retrospective**: what would you change for a real engagement

Teardown is graded. Cost left running is a fail condition.

---

## The evidence pack — seven artifacts

- `B1.1_RequirementsAssessment_CFS_v1.xlsx`
- `B2.1_SolutionDesign_CFS_v1.docx`
- `B2.2_WellArchitectedReview_CFS_v1.xlsx`
- `B3.x_AsBuilt_CFS_v1.docx` (B.3.1 + B.3.2)
- `B4.1_ValidationTestPlan_CFS_v1.xlsx` (tests + sign-off)
- `B4.2_DecisionLog_CFS_v1.xlsx`
- `B4.2_SOPs_CFS_v1.docx`

Templates ship pre-seeded with CFS context in `evidence-templates/`.

---

## Facilitation — demo the agents live

- Always run at least one agent prompt **on the projector** per challenge
- Show the **MCP** server answering a live Azure question (for example, list the
  deployed firewall policy) so pupils see the agent acting on reality
- Narrate *why* you chose the agent and the skill, not just *what* you typed
- When an agent is wrong, **keep it** on screen and correct it — that is the lesson

---

## Pacing — the gateway is the clock

- Kick off `component=gateway` the moment Challenge 03 opens
- Use the 30–45 min wait to run the Challenge 03 design talk-track and start the
  spoke planning — never sit idle watching a deployment
- If you are behind by lunch, demo 03–06 from the solution keys (half-day cut)
- Full timing sheet: [Timing and pacing](../trainer/timing-and-pacing/)

---

## Common pitfalls

- **OIDC not trusted** — the federated credential subject must match the repo and
  environment exactly
- **Quota** — VPN Gateway and public IP quotas in Sweden Central; pre-check
- **Gateway "stuck"** — it is not stuck, it takes 30–45 min; verify state, do not redeploy
- **Name collisions** — the `cfs` prefix plus region token must be unique per pupil
- **Public exposure** — the classic mistake is a public backend; `@challenger` catches it

---

## Teardown and cost hygiene

- Every pupil runs `teardown.yml` with confirm `DELETE` at the end of the day
- Verify the resource groups are gone — do not trust the workflow blindly
- The **budget alert** from Challenge 00 is the safety net if anyone forgets
- Trainer closes the room only after every subscription is confirmed clean

A microhack that leaves resources running has failed its own teardown lesson.

---

## Half-day "design-only" variant

- Run Challenges 00, 01, and 02 hands-on
- **Demo** Challenges 03 through 06 from the solution keys
- No real deploy means no OIDC, quota, or teardown overhead
- Ideal for executive or pre-sales audiences who need the shape, not the keys

The cut points are called out in the Facilitator guide.

---

## Build and present this deck

- Build to HTML: `npm run slides` (output in `dist-slides/`)
- Present directly in VS Code with the **Marp for VS Code** extension
- Licence-free: Marp CLI is open source and ships in the dev container
- Edit this file (`slides/module-b-microhack.md`) — one H1, H2 per slide

---

## Resources

- Docs site: the challenge and reference pages
- Trainer section: facilitator guide, timing, inference backends, reset runbook
- Solution keys: trainer-only expected agent outputs and grading rubrics
- Repo: agents in `.github/agents/`, skills in `.github/prompts/`, IaC in `infra/`

---

## Go run it

You now have the spine, the agents, the infrastructure, and the evidence
templates. Open the [Facilitator guide](../trainer/facilitator-guide/), dry-run
Challenge 03 once before class, and deliver.

Bring the agents to life — that is the whole point.
