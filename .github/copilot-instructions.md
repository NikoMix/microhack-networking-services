# GitHub Copilot instructions — Module B Networking Microhack

You are assisting inside the **Module B Networking Services Train-the-Trainer microhack**
repository. The repo teaches partner network architects to deliver all seven Module B
controls of the *Networking Services in Microsoft Azure Advanced Specialization* by
deploying a secure Azure hub & spoke landing zone for a fictional fintech, **Contoso
Financial Services (CFS)**, using Copilot agents, skills, and MCP.

## How this repo is organised

- `.github/agents/` — custom agents (one `*.agent.md` per role). Prefer delegating work to
  the most specific agent (requirements, solution-design, WAF review, IaC, validation,
  evidence, challenger) over doing it inline.
- `.github/prompts/` — reusable skills / prompt files invoked during challenges.
- `.github/models/` — **modular inference** config. Agents are model-agnostic and run on
  **GitHub Models** (default), **Azure OpenAI**, or **Azure AI Foundry**. No AI app is deployed.
- `infra/bicep/` (primary) and `infra/terraform/` (alternate) — the Azure Landing Zone
  Accelerator-based hub & spoke. `infra/scripts/` holds deploy/teardown/cost helpers.
- `src/content/docs/` — Astro Starlight lab guides (`challenges/`, `trainer/`, `solutions/`,
  `reference/`).
- `evidence-templates/`, `diagrams/`, `slides/`, `tools/` — supporting assets.

## Azure & IaC standards (always apply)

- **Microsoft best practices**: CAF / ALZ topology, Well-Architected Framework, **Azure
  Verified Modules (AVM) first** for both Bicep and Terraform.
- **Identity**: Managed Identity for Azure-hosted; **OIDC federated credentials** for GitHub
  Actions. **Never** hardcode credentials or use key-based auth. Secrets via Key Vault only.
- **Key Vault**: keep purge protection **on**. Storage/Cosmos: disable key access; use RBAC.
- **API versions**: use the latest available. Bicep files live under `infra/`.
- **Private by default**: no public PaaS endpoints — use Private Link / private endpoints and
  private DNS zones. Compute has no public IP; admin access via Bastion. Central egress via
  Azure Firewall.
- **Region**: `swedencentral` (param `location`, fallback `westeurope`).
- **Naming**: `cfs-<role>-<type>-<region>` (e.g. `cfs-hub-vnet-swc`); resource groups
  `rg-cfs-<tier>-swc`; environment tag `lab`.
- **Validation before deploy**: always `az deployment ... what-if` (Bicep) or `terraform plan`
  (Terraform) first.
- **Cost hygiene**: every deployment must be paired with a working teardown path; deploy a
  budget + alert in Challenge 00.

## Documentation standards

- Astro Starlight MDX. Each page has frontmatter `title`, `description`, and `sidebar.order`.
- Use Starlight `Aside`, `Steps`, `Card` components. Map control IDs (e.g. **B.2.1**) explicitly.
- Keep participant lab guides task-oriented; keep solution keys in `solutions/` (trainer-only).

## Evidence standards

- Module B evidence files: `B<x.y>_<DocType>_CFS_v1.<ext>` (e.g. `B2.1_SolutionDesign_CFS_v1.docx`).
- Each artifact must address every bullet the auditor checks for that control (see the
  control pages on the docs site and the `reference/` mapping).

## Commits & quality

- Conventional Commits. Append the trailer
  `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
- Run `npm run validate` (astro check + markdownlint) before opening a docs PR.
- Keep dependencies current and free of known vulnerabilities; only license-free libraries.
- Comment code only where it clarifies a non-obvious decision.
