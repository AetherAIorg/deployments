# Margin Deployments

Production deploy orchestration for the Margin stack. This repo owns platform config (DigitalOcean, Vercel, GitHub Pages) and tracks application source via the `app/` git submodule (`aether_org`).

## Architecture

```
aether_org push ──► trigger-deploy.yml ──► repository_dispatch ──► deploy-all.yml
                                                                      ├── bump app/
                                                                      ├── DO SSH deploy
                                                                      ├── Vercel CLI
                                                                      └── GitHub Pages
```

| Component | Platform | Config |
|-----------|----------|--------|
| MetricGraph API + worker | DigitalOcean Droplet | [`do/docker-compose.prod.yml`](do/docker-compose.prod.yml) |
| Postgres + Redis | Same droplet (Docker) | pgvector + Redis in compose |
| MetricGraph UI | Vercel | `app/metricgraph/frontend` |
| Catalog UI | Vercel | `app/registry_governance/frontend` |
| Marketing site | GitHub Pages | `app/margin_github_pages` |
| Neo4j KG | Neo4j Aura | `do/.env` |
| Object storage | Cloudflare R2 / S3 | `do/.env` |

Hub, ingest, and catalog-api are deferred for MVP. Full Render stack preserved in [`render.full.yaml`](render.full.yaml) (deprecated).

## Quick start

### 1. Clone and init submodule

```bash
git clone https://github.com/AetherAIorg/deployments.git
cd deployments
./scripts/init.sh
```

### 2. DigitalOcean Droplet (MVP backend)

1. Create an **Ubuntu 24.04** droplet (**1 GB RAM / ~$6/mo** recommended).
2. Add your SSH key.
3. Point `api.yourdomain.com` A-record to the droplet IP.
4. On the droplet:

```bash
curl -fsSL https://raw.githubusercontent.com/AetherAIorg/deployments/main/scripts/setup-droplet.sh | bash
```

5. Edit `do/.env` on the droplet:

   - `API_DOMAIN` — your API subdomain
   - `AUTH_SECRET` — same value as Vercel (`openssl rand -base64 32`)
   - `CORS_ORIGINS` — include your Vercel frontend URL
   - `NEO4J_*`, `S3_*` — optional for MVP; required for KG and file uploads

6. Redeploy after editing env:

```bash
cd /root/deployments
docker compose --env-file do/.env -f do/docker-compose.prod.yml up -d --build
```

7. Verify: `curl -fsS https://api.yourdomain.com/api/health`

### 3. Connect Vercel

Deploy `app/metricgraph/frontend` (or link `aether_org` directly). Set:

- `NEXT_PUBLIC_API_URL=https://api.yourdomain.com`
- `AUTH_SECRET` — match backend

Add `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_*` to GitHub secrets.

### 4. GitHub Actions auto-deploy

**In `deployments` repo secrets:**

| Secret | Purpose |
|--------|---------|
| `SUBMODULE_PAT` | Read/write submodule bump |
| `DO_HOST` | Droplet IP or hostname |
| `DO_SSH_USER` | SSH user (e.g. `root`) |
| `DO_SSH_KEY` | Private key for Actions |
| `VERCEL_TOKEN` | Vercel deploy |
| `VERCEL_ORG_ID` | Vercel scope |
| `VERCEL_PROJECT_ID_APP` | MetricGraph frontend |

**In `aether_org` repo secrets:**

| Secret | Purpose |
|--------|---------|
| `DEPLOYMENTS_DISPATCH_TOKEN` | PAT with `actions:write` on deployments repo |

**In `deployments` repo variables (health checks):**

`API_URL`, `MARGIN_APP_URL` (hub/catalog optional for MVP)

### 5. First deploy

Merge to `aether_org` `main` → auto-triggers deployments pipeline, or run **Deploy All** manually in GitHub Actions.

## Day-2 flow

Merge to `aether_org` `main` → deployments bumps `app/` submodule → SSH redeploy on droplet + Vercel.

Infra changes: push to `deployments` `main` (`do/`, workflows) → redeploy without submodule bump.

## Scripts

| Script | Purpose |
|--------|---------|
| [`scripts/init.sh`](scripts/init.sh) | Init submodule |
| [`scripts/setup-droplet.sh`](scripts/setup-droplet.sh) | First-time droplet bootstrap |
| [`scripts/deploy-do.sh`](scripts/deploy-do.sh) | Redeploy on droplet |
| [`scripts/deploy-vercel.sh`](scripts/deploy-vercel.sh) | Vercel CLI prod deploy |
| [`scripts/verify-health.sh`](scripts/verify-health.sh) | Curl health endpoints |
| [`scripts/verify-s3.sh`](scripts/verify-s3.sh) | Test S3/R2 bucket access |

## Local development

Use Docker in `aether_org` (`docker compose up`). This repo is production-only.

## Backups

Postgres data lives in the `pgdata` Docker volume. Schedule periodic `pg_dump` on the droplet for production use.
