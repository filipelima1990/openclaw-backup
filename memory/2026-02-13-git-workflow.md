# Git Workflow Setup - 2026-02-13

## Projects Configured

Both projects now have professional git workflow with dev/prod environments and automated deployments.

### Portugal House Market
- **GitHub:** https://github.com/filipelima1990/portugal-house-market
- **Dev:** `/opt/portugal-house-market-dev` → dev branch
- **Prod:** `/opt/portugal-house-market` → main branch
- **Prefect:** Dev on port 4200, Prod on port 4201 (separate servers for testing)
- **GitHub Actions:** Automated deployments on push to dev/main
- **Status:** ✅ Complete

### Football Data
- **GitHub:** https://github.com/filipelima1990/football-data
- **Dev:** `/opt/football-data-dev` → dev branch
- **Prod:** `/opt/football-data` → main branch
- **Prefect:** Uses shared server at `/opt/prefect` (port 4200)
- **GitHub Actions:** Automated deployments on push to dev/main
- **Status:** ✅ Complete

## Shared Infrastructure

### SSH Key for GitHub Actions
- **Private:** `/root/.ssh/github_actions_rsa` (RSA 4096-bit)
- **Public:** `/root/.ssh/github_actions_rsa.pub` (added to authorized_keys)
- **Purpose:** GitHub Actions authentication for automated deployments

### GitHub Secrets
Both projects use same secrets (configured in each repo):
- `SERVER_HOST`: 167.235.68.81
- `SERVER_USER`: root
- `SSH_PRIVATE_KEY`: RSA key from above

### Shared Prefect Server
- **Location:** `/opt/prefect`
- **Port:** 4200
- **Dashboard:** http://167.235.68.81:4200
- **Purpose:** Orchestrates all projects (football-data, portugal-house-market, etc.)

## Workflow Rules (for Billie)

### Commit Prefix
- Use "Billie:" instead of "Bot:" (Filipe prefers partner persona)

### Default Behavior
- Always work on `dev` branch
- Commit with "Billie:" prefix
- Push to dev → GitHub Action auto-deploys
- Ask before pushing to `main` (unless explicitly requested)

### Breaking Changes
Automatically create PR instead of asking:
- Database schema changes
- API contract changes
- Flow schedule changes
- Environment variable changes
- Large refactorings

### When to Ask
- Before pushing to `main`
- Before deleting files
- Before making API calls or external changes
- If unsure which environment to target

## GitHub Actions Workflows

### Staging Deployment (dev branch)
- **Trigger:** Push to `dev` branch
- **Action:** SSH to server → `git pull origin dev` → (optional: restart service)
- **Housing Market:** Restarts Prefect dev server
- **Football Data:** Just git pull (uses shared Prefect)

### Production Deployment (main branch)
- **Trigger:** Push to `main` branch
- **Action:** SSH to server → `git pull origin main` → (optional: restart service)
- **Housing Market:** Restarts Prefect prod server
- **Football Data:** Just git pull (uses shared Prefect)

## Quick Reference

| Environment | Directory | Branch | Prefect |
|-------------|-----------|--------|----------|
| **Housing Dev** | /opt/portugal-house-market-dev | dev | Port 4200 |
| **Housing Prod** | /opt/portugal-house-market | main | Port 4201 |
| **Football Dev** | /opt/football-data-dev | dev | Shared (4200) |
| **Football Prod** | /opt/football-data | main | Shared (4200) |

## Documentation

Both projects have comprehensive deployment guides:
- Portugal House Market: `DEPLOYMENT.md` in repo
- Football Data: `DEPLOYMENT.md` in repo

Both include:
- Git workflow (feature → dev → main)
- Directory structure
- GitHub Actions configuration
- Prefect flow management
- Troubleshooting guide
