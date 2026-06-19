# Margin Deployments

Production deploy orchestration for the Margin stack. This repo owns platform config (Render, Vercel, GitHub Pages) and tracks application source via the `app/` git submodule (`aether_org`).

## Architecture

```
aether_org push ──► trigger-deploy.yml ──► repository_dispatch ──► deploy-all.yml
                                                                      ├── bump app/
                                                                      ├── Render hooks
                                                                      ├── Vercel CLI
                                                                      └── GitHub Pages
```

| Component | Platform | Config |
|-----------|----------|--------|
| MetricGraph API + worker | Render | `render.yaml` → `margin-api`, `margin-worker` |
| Integration Hub | Render | `margin-hub` |
| Ingest engine | Render | `margin-ingest` |
| Catalog API | Render | `catalog-api` |
| Postgres + Redis | Render | `margin-postgres`, `catalog-postgres`, `margin-redis` |
| MetricGraph UI | Vercel | `app/metricgraph/frontend` |
| Catalog UI | Vercel | `app/registry_governance/frontend` |
| Marketing site | GitHub Pages | `app/margin_github_pages` |
| Neo4j KG | Neo4j Aura | manual env on Render |
| Object storage | S3 / R2 | manual env on Render |

## Quick start

### 1. Clone and init submodule

Update [`.gitmodules`](.gitmodules) with your `aether_org` remote, then:

```bash
git clone git@github.com:YOUR_ORG/deployments.git
cd deployments
git submodule add git@github.com:YOUR_ORG/aether_org.git app   # first time only
./scripts/init.sh
```

### 2. Connect Render

1. [Render Dashboard](https://dashboard.render.com) → **New Blueprint**
2. Connect this repo
3. Sync [`render.yaml`](render.yaml)
4. Set `sync: false` secrets from [`.env.example`](.env.example) (Neo4j, S3, auth, webhooks, API keys)

After first deploy, set webhook URLs using each service's Render external URL:

- `INTEGRATION_WEBHOOK_URL` → `https://<margin-hub>/webhooks/metricgraph`
- `GOVERNANCE_WEBHOOK_URL` → `https://<catalog-api>/webhooks/metricgraph`
- `HUB_WEBHOOK_URL` (ingest) → `https://<margin-hub>/webhooks/ingest`

Create **Deploy Hooks** for each Render service and add URLs to GitHub secrets (`RENDER_DEPLOY_HOOK_*`).

### 3. Connect Vercel

Create two projects with root directories (in this repo):

- `app/metricgraph/frontend`
- `app/registry_governance/frontend`

Set env vars from `.env.example`. Add `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_*` to GitHub secrets.

### 4. GitHub Pages

In this repo: **Settings → Pages → Build and deployment → GitHub Actions**.

### 5. Cross-repo CI secrets

**In `deployments` repo secrets:**

| Secret | Purpose |
|--------|---------|
| `SUBMODULE_PAT` | Read/write submodule bump |
| `VERCEL_TOKEN` | Vercel deploy |
| `VERCEL_ORG_ID` | Vercel scope |
| `VERCEL_PROJECT_ID_APP` | MetricGraph frontend |
| `VERCEL_PROJECT_ID_CATALOG` | Catalog frontend |
| `RENDER_DEPLOY_HOOK_*` | Trigger Render rebuilds |

**In `aether_org` repo secrets:**

| Secret | Purpose |
|--------|---------|
| `DEPLOYMENTS_DISPATCH_TOKEN` | PAT with `actions:write` on deployments repo |

**In `margin_github_pages` repo secrets (separate remote):**

Same `DEPLOYMENTS_DISPATCH_TOKEN` and `DEPLOYMENTS_REPO` variable. Pushes dispatch `pages-updated` (Pages-only deploy).

**In `aether_org` repo variables:**

| Variable | Example |
|----------|---------|
| `DEPLOYMENTS_REPO` | `YOUR_ORG/deployments` |

**In `deployments` repo variables (health checks):**

`API_URL`, `HUB_URL`, `CATALOG_API_URL`, `MARGIN_APP_URL`, `CATALOG_APP_URL`

### 6. First deploy

```bash
# Manual trigger from GitHub Actions → Deploy All
# Or merge to aether_org main (auto-triggers via trigger-deploy.yml)
```

Mint API keys against live API:

```bash
# After margin-api is up
curl -X POST ...  # or use CLI from app repo
```

Set `MARGIN_API_KEY`, `INGEST_API_KEY`, `METRICGRAPH_API_KEY` in Render.

## Day-2 flow

Merge to `aether_org` `main` → `trigger-deploy.yml` → deployments bumps `app/` submodule → full stack redeploy.

Push to `margin_github_pages` `main` → `pages-updated` dispatch → Pages-only deploy (checks out that repo directly).

Infra-only changes: push to `deployments` `main` (`render.yaml`, workflows) → redeploy without submodule bump.

## Scripts

| Script | Purpose |
|--------|---------|
| [`scripts/init.sh`](scripts/init.sh) | Init submodule |
| [`scripts/deploy-render.sh`](scripts/deploy-render.sh) | POST Render deploy hooks |
| [`scripts/deploy-vercel.sh`](scripts/deploy-vercel.sh) | Vercel CLI prod deploy |
| [`scripts/run-migrations.sh`](scripts/run-migrations.sh) | Optional Render one-off migrations |
| [`scripts/verify-health.sh`](scripts/verify-health.sh) | Curl health endpoints |
| [`scripts/verify-s3.sh`](scripts/verify-s3.sh) | Test S3/R2 bucket access |

## PyPI

The `margin` SDK publishes from `aether_org` on `margin-v*` tags — not from this repo.

## Local development

Use Docker in `aether_org` (`docker compose up`). This repo is production-only.
