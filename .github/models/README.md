# Modular inference — point the agents at any model backend

The Module B microhack agents in [`.github/agents/`](../agents/) are **model-
agnostic**. The same agent definitions run unchanged against three license-free
inference backends — you only change **environment variables**. No AI application
is deployed, and **no image generation** is required by any agent, so a plain
text/chat-completion model is all you need.

| Backend | Best for | Cost | Auth |
| --- | --- | --- | --- |
| **GitHub Models** *(default)* | Codespaces, getting started, zero Azure setup | Free tier, rate-limited | `GITHUB_TOKEN` / PAT |
| **Azure OpenAI** | Enterprise SLA, data stays in your tenant | Pay-per-token | **Keyless** (`DefaultAzureCredential`) |
| **Azure AI Foundry** | Model catalog, evaluations, governance | Pay-per-token | **Keyless** (`DefaultAzureCredential`) |

> **Keyless first.** For both Azure backends, authenticate with Entra ID via
> `DefaultAzureCredential` (Managed Identity, `az login`, or GitHub Actions
> OIDC). **Never** paste API keys into files, env vars committed to git, or agent
> definitions. Secrets — if ever unavoidable — live only in Key Vault.

---

## 1. GitHub Models (default)

Zero Azure dependency — ideal in Codespaces where `GITHUB_TOKEN` already exists.

```bash
export GITHUB_MODELS_ENDPOINT="https://models.github.ai/inference"
export GITHUB_TOKEN="<your GitHub token>"   # Codespaces injects this automatically
export MODEL_ID="openai/gpt-4o"             # any text model from the catalog
```

- Endpoint is OpenAI-compatible (`/chat/completions`).
- Token needs the `models: read` permission (the default Codespaces token works).
- Rate-limited free tier — perfect for the lab, not for production load.

See [`github-models.env.example`](./github-models.env.example).

## 2. Azure OpenAI (keyless)

```bash
export AZURE_OPENAI_ENDPOINT="https://<your-aoai>.openai.azure.com/"
export AZURE_OPENAI_DEPLOYMENT="gpt-4o"      # your deployment name
export OPENAI_API_VERSION="2024-10-21"       # use the latest GA version
# No key — DefaultAzureCredential handles auth:
az login   # or rely on Managed Identity / GitHub OIDC
```

Grant the identity the **Cognitive Services OpenAI User** role on the resource.
In GitHub Actions, use OIDC (`azure/login@v2`, `id-token: write`) — no stored
secret. See [`azure-openai.env.example`](./azure-openai.env.example).

## 3. Azure AI Foundry (keyless)

```bash
export AZURE_AI_FOUNDRY_PROJECT_ENDPOINT="https://<project>.services.ai.azure.com/api/projects/<project>"
export AZURE_AI_FOUNDRY_DEPLOYMENT="gpt-4o"  # model deployed in your Foundry project
export OPENAI_API_VERSION="2024-10-21"
az login   # DefaultAzureCredential — keyless
```

Grant the identity **Azure AI Developer** (or **Cognitive Services OpenAI User**)
on the Foundry project. Same OpenAI-compatible code path as Azure OpenAI, plus the
Foundry model catalog and evaluation tooling. See
[`azure-ai-foundry.env.example`](./azure-ai-foundry.env.example).

---

## Switching backends

1. Pick a backend and export its variables (above) — or copy the matching
   `*.env.example` to `.env` and fill it in (**never commit `.env`**).
2. Leave the agent files unchanged; they reference these variables only.
3. Verify access:
   - GitHub Models: `curl -sS $GITHUB_MODELS_ENDPOINT/chat/completions -H "Authorization: Bearer $GITHUB_TOKEN" -H "Content-Type: application/json" -d '{"model":"'$MODEL_ID'","messages":[{"role":"user","content":"ping"}]}'`
   - Azure backends: `az account show` succeeds and the identity has the role above.

## Trade-offs at a glance

- **Latency / quota** — GitHub Models free tier throttles under load; Azure
  backends scale with your provisioned/standard quota.
- **Data residency** — Azure OpenAI / Foundry keep data in your tenant and region
  (align to `swedencentral` for CFS); GitHub Models is a shared service.
- **Governance** — Foundry adds the model catalog, content safety, and
  evaluations; Azure OpenAI is the leanest enterprise path; GitHub Models is the
  fastest start.
- **Auth** — Azure backends are **keyless** (Entra ID / OIDC); GitHub Models uses
  the existing GitHub token. None of them require a purchased third-party license.

See the rendered [Modular inference](../../src/content/docs/reference/modular-inference.mdx)
and [Agents & MCP](../../src/content/docs/reference/agents-and-mcp.mdx) reference
pages for the participant-facing version.
