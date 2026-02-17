# Prefect Deployment Cleanup Summary

**Date:** 2026-02-14 15:45 UTC

## Current Situation

You have **3 flows** registered in Prefect for the housing project:

1. **"Daily Scrape and Load Housing Data"** (from 2026-02-13) - OLD - Should be DELETED
2. **"Quick Scrape (No Database)"** (from 2026-02-14) - UTILITY - Should be KEPT
3. **"Scrape and Load Housing Market Data"** (from 2026-02-14) - MAIN - Now DEPLOYED

## Flow Explanations

### 1. "Daily Scrape and Load Housing Data" (OLD - DELETE)
- **Created:** 2026-02-13
- **Status:** Old deployment with outdated code
- **Action:** Needs to be deleted
- **Reason:** This was created before database separation and may not use the correct `.env` configuration

### 2. "Quick Scrape (No Database)" (UTILITY - KEEP)
- **Created:** 2026-02-14
- **Status:** Utility flow for testing
- **Action:** Keep for manual testing
- **Use Cases:**
  - Testing scraper without affecting production data
  - Quick exploration during development
  - Debugging issues before running full load
- **Note:** This flow does NOT have a deployment - it's run only when manually triggered
- **CLI Usage:** `python3 -m src.flows.scrape_flow --quick`

### 3. "Scrape and Load Housing Market Data" (MAIN - DEPLOYED)
- **Created:** 2026-02-14
- **Status:** New deployment created ✅
- **Action:** This is the deployment you should use
- **Schedule:** Daily at 9:00 AM UTC
- **Deployment ID:** `ade722ce-e9b5-4743-91e8-36217704470a`
- **Database:** Uses `.env` file (dev or prod depending on directory)
- **View in UI:** http://167.235.68.81:4200/deployments/deployment/ade722ce-e9b5-4743-91e8-36217704470a

## Deployment Status

**Current Deployments:**
- ✅ "Scrape and Load Housing Market Data/daily-scrape-porto-housing" (NEW - ACTIVE)
- ⚠️  "Daily Scrape and Load Housing Data/[old-deployment-name]" (OLD - DELETE)
- ✅ "Load Premier League Data/weekly-load-premier-league" (Football - ACTIVE)

## Action Required

**Delete the old deployment:**

Option 1: Via Prefect UI (Recommended - Easier)
1. Go to http://167.235.68.81:4200/deployments
2. Look for the deployment with flow name starting with "Daily Scrape and Load Housing Data"
3. It should be the one with an older creation date (2026-02-13)
4. Click on it and select "Delete" or "Pause"
5. Confirm deletion

Option 2: Via CLI (Advanced)
To find the exact deployment name:
```bash
source /opt/prefect/venv/bin/activate
prefect deployment ls
```

Look for the deployment that has "Daily Scrape and Load Housing" in the name (not the new "Scrape and Load Housing Market Data").

Then delete it:
```bash
prefect deployment delete "EXACT/FLOW/NAME/DEPLOYMENT/NAME"
```

**Why keep "Quick Scrape (No Database)":**
- Useful for testing without affecting production data
- Run manually: `cd /opt/portugal-house-market && python3 -m src.flows.scrape_flow --quick`
- No deployment needed (runs only when manually triggered)

## Final Setup

After cleanup, you should have:
- **1 Housing Deployment:** "Scrape and Load Housing Market Data/daily-scrape-porto-housing"
- **1 Housing Utility Flow:** "Quick Scrape (No Database)" (no deployment, manual only)
- **1 Football Deployment:** "Load Premier League Data/weekly-load-premier-league"

---

**Status:** ✅ New deployment created, old deployment needs manual deletion
