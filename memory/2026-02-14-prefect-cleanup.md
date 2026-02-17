# 2026-02-14 - Prefect Deployment Cleanup & Schedule Update

**Time:** 2026-02-14 15:50 UTC

## Actions Completed

### 1. ✅ Deleted Old Deployment
- **Deployment:** "Daily Scrape and Load Housing Data/daily-scrape-housing-nationwide"
- **ID:** `359bfc47-66c2-44f7-ab02-569247e8ac85`
- **Reason:** Outdated deployment from 2026-02-13, before database separation
- **Status:** Successfully deleted

### 2. ✅ Created New Prod Deployment (1 AM UTC)
- **Flow:** "Scrape and Load Housing Market Data"
- **Deployment:** "daily-scrape-porto-housing"
- **ID:** `fcb7874f-96d3-46c3-a3a4-0b0cd62ca00b`
- **Schedule:** Daily at 1:00 AM UTC (cron: `0 1 * * *`)
- **Database:** `portugal_houses_prod` (from /opt/portugal-house-market/.env)
- **View:** http://localhost:4200/deployments/deployment/fcb7874f-96d3-46c3-a3a4-0b0cd62ca00b

### 3. ✅ Created New Dev Deployment (1 AM UTC)
- **Flow:** "Scrape and Load Housing Market Data"
- **Deployment:** "daily-scrape-porto-housing-dev"
- **ID:** `fa8e8929-ea5c-481e-96fa-200a8b2aefa2`
- **Schedule:** Daily at 1:00 AM UTC (cron: `0 1 * * *`)
- **Database:** `portugal_houses_dev` (from /opt/portugal-house-market-dev/.env)
- **View:** http://localhost:4200/deployments/deployment/fa8e8929-ea5c-481e-96fa-200a8b2aefa2

## Final Deployment State

| Project | Deployment Name | Environment | Schedule | Database |
|---------|----------------|--------------|-----------|-----------|
| **Housing** | `daily-scrape-porto-housing-dev` | Dev | 1:00 AM UTC | `portugal_houses_dev` |
| **Housing** | `daily-scrape-porto-housing` | Prod | 1:00 AM UTC | `portugal_houses_prod` |
| **Football** | `weekly-load-premier-league` | Shared | Sundays 10:00 AM UTC | `football_data_prod` |

## Utility Flow (No Deployment)

**"Quick Scrape (No Database)"** - Kept for testing
- **Purpose:** Manual testing without database load
- **Usage:** `python3 -m src.flows.scrape_flow --quick`
- **No Deployment:** Runs only when manually triggered

## Deployment Commands

**Prod:**
```bash
cd /opt/portugal-house-market
source /opt/prefect/venv/bin/activate
prefect deploy src/flows/scrape_flow.py:scrape_and_load_flow \
  --name daily-scrape-porto-housing \
  --pool default-pool \
  --cron "0 1 * * *" \
  --timezone UTC
```

**Dev:**
```bash
cd /opt/portugal-house-market-dev
source /opt/prefect/venv/bin/activate
prefect deploy src/flows/scrape_flow.py:scrape_and_load_flow \
  --name daily-scrape-porto-housing-dev \
  --pool default-pool \
  --cron "0 1 * * *" \
  --timezone UTC
```

## Testing Flow

```bash
# Quick scrape (no database)
python3 -m src.flows.scrape_flow --quick

# Full scrape with database load
python3 -m src.flows.scrape_flow

# With filters
python3 -m src.flows.scrape_flow --price-max 500000 --typologies TWO THREE
```

---

**Status:** ✅ All deployments cleaned and updated
