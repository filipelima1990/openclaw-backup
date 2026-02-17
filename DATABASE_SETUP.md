# PostgreSQL Database Setup Summary

**Date:** 2026-02-14
**Purpose:** Configure separate PostgreSQL databases for dev and prod environments

---

## Overview

Created separate PostgreSQL databases for each project's development and production environments to ensure clean separation and prevent data contamination.

---

## Databases Created

### PostgreSQL Container
- **Container Name:** `postgres`
- **Port:** 5432
- **User:** `postgres` (with password `prefect123`)
- **Additional User:** `dataeng` (with password `changeme`)

### Database List

| Database | Purpose | Environment |
|----------|---------|-------------|
| `postgres` | Prefect backend (unchanged) | Infrastructure |
| `football_data_dev` | Football data dev environment | Development |
| `football_data_prod` | Football data production | Production |
| `portugal_houses_dev` | Housing data dev environment | Development |
| `portugal_houses_prod` | Housing data production | Production |

---

## Project Configurations

### Football Data Project

**Dev Environment:** `/opt/football-data-dev/.env`
```bash
DB_NAME=football_data_dev
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=prefect123
```

**Prod Environment:** `/opt/football-data/.env`
```bash
DB_NAME=football_data_prod
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=prefect123
```

**Schema:** `raw_pl_matches` table with indexes
- Table: `public.raw_pl_matches`
- Indexes: date, home_team, away_team, league_division

### Portugal House Market Project

**Dev Environment:** `/opt/portugal-house-market-dev/.env`
```bash
POSTGRES_DB=portugal_houses_dev
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=prefect123
```

**Prod Environment:** `/opt/portugal-house-market/.env`
```bash
POSTGRES_DB=portugal_houses_prod
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=prefect123
```

**Schema:** Three schemas (raw, staging, marts)
- `raw.listings` - Raw scraped data
- `raw.listings_latest` - Latest snapshot view
- `staging.price_history` - Price change tracking
- `marts` - Final analytics tables (ready for dbt)

---

## Verification

### List All Databases
```bash
docker exec postgres psql -U postgres -c "\l"
```

### Check Football Data Schema
```bash
# Dev
docker exec postgres psql -U postgres -d football_data_dev -c "\dt"

# Prod
docker exec postgres psql -U postgres -d football_data_prod -c "\dt"
```

### Check Housing Schema
```bash
# Dev
docker exec postgres psql -U postgres -d portugal_houses_dev -c "\dt raw.*"

# Prod
docker exec postgres psql -U postgres -d portugal_houses_prod -c "\dt raw.*"
```

---

## Prefect Integration

Both projects use the **shared Prefect server** at `/opt/prefect` (port 4200).

### Football Data Deployment
- **Flow Name:** `weekly-load-premier-league`
- **Schedule:** Sundays at 10:00 AM UTC
- **Database:** Reads from `.env` (dev/prod based on directory)

### Housing Data Deployment
- **Flow Name:** `daily-scrape-porto-housing`
- **Schedule:** Daily at 9:00 AM UTC
- **Database:** Reads from `.env` (dev/prod based on directory)

---

## Migration Notes

### Old Database (Deprecated)
- `football_data` - Old single database (still exists but unused)
  - Data can be migrated to `football_data_prod` if needed
  - After migration, can be dropped

### New Database Strategy
- Each project has dedicated dev/prod databases
- No shared databases between projects
- Prefect backend remains on `postgres` database

---

## Future Considerations

1. **Backups:** Set up automated backups for production databases
2. **Monitoring:** Add database monitoring (connection pool, query performance)
3. **Access Control:** Fine-tune user permissions (postgres vs dataeng)
4. **Migration:** Consider migrating old `football_data` to `football_data_prod`
5. **Drop Old Database:** After confirming data migration, drop `football_data`

---

## Quick Reference

| Project | Dev DB | Prod DB | Prefect Flow |
|---------|--------|---------|--------------|
| Football Data | `football_data_dev` | `football_data_prod` | `weekly-load-premier-league` |
| Housing Market | `portugal_houses_dev` | `portugal_houses_prod` | `daily-scrape-porto-housing` |

---

## Files Updated

- `/opt/football-data/.env` - Updated DB_NAME to `football_data_prod`
- `/opt/football-data-dev/.env` - Created with DB_NAME `football_data_dev`
- `/opt/portugal-house-market/.env` - Updated POSTGRES_DB to `portugal_houses_prod`
- `/opt/portugal-house-market-dev/.env` - Created with POSTGRES_DB `portugal_houses_dev`
- `/opt/football-data/DEPLOYMENT.md` - Added database configuration section
- `/opt/portugal-house-market/DEPLOYMENT.md` - Created with database configuration

---

## Setup Script

The schema creation script is available at:
```
/root/.openclaw/workspace/create_schemas.py
```

This script can be re-run to recreate schemas if needed.

---

**Status:** ✅ All databases and schemas configured successfully
