# MEMORY.md - Long-term Memory for Billie

_Refer to `.secrets.md` for sensitive information (tokens, IPs, keys)._

---

## Active Systems

All systems use cron jobs and send to Telegram channels/chats. Documentation lives in `/opt/<system>/README.md`.

| System | Location | Schedule | Destination |
|--------|----------|----------|-------------|
| Daily Quiz | `/opt/quiz/` | 9 AM UTC | Personal chat |
| English Tips | `/opt/engtips/` | 5x daily (8, 11, 14, 17, 20 UTC) | Channel -1003875454703 |
| Tech News | `/opt/newsletter/` | 3x daily (8, 12, 18 UTC) | Channel -1003369440176 |
| Guitar Practice | `/opt/guitar/` | 8 AM UTC | Group -5287670840 |
| Travel Tips | `/opt/travel/` | 8 AM UTC | Channel -1003401888787 |
| Health Report | `/opt/healthcheck/` | Sundays 10 AM UTC | Personal chat |
| Last.fm Albums | `/opt/lastfm-albums/` | 2 PM UTC | Channel -1003823481796 |
| Prefect | `/opt/prefect/` | Running 24/7 | Dashboard: http://167.235.68.81:4200 |
| Football Data | `/opt/football-data/` | Sundays 10 AM UTC | PostgreSQL: football_data_prod (dev: football_data_dev) |
| Housing Market | `/opt/portugal-house-market/` | Daily 1 AM UTC | PostgreSQL: portugal_houses_prod (dev: portugal_houses_dev) |
| Gambling Tracker | `/opt/gambling-tracker/` | On-demand | Group -5125156105 |
| PostgreSQL | `/opt/postgresql/` | Running 24/7 | Port 5432 |

---

## Key Technical Decisions

### Architecture Philosophy
- **Cron over orchestration:** Using system crontab instead of Prefect for simple scheduled jobs (Dec 2025)
- **Prefect multi-project:** Single Prefect server orchestrating multiple GitHub repos (Feb 2026)
- **File-based storage:** JSON for state, no external databases needed for most systems
- **Telegram-first:** All notifications go through Telegram via OpenClaw CLI
- **Modular design:** Each system is self-contained in `/opt/<system>/`

### Prefect Multi-Project Architecture (Feb 2026)
- **Single server:** One Prefect instance on port 4200 (http://167.235.68.81:4200)
- **Multiple projects:** Each project has its own GitHub repo and flows
- **Shared work pool:** `default-pool` (process type) handles all deployments
- **GitHub repos:**
  - filipelima1990/football-data - Premier League historical data
  - filipelima1990/portugal-house-market - Porto housing market scraper
- **Deployments:**
  - `weekly-load-premier-league` - Sundays 10:00 AM UTC
  - `daily-scrape-porto-housing` - Daily 9:00 AM UTC
- **Configuration:** Each project has `prefect.yaml` with deployment settings
- **Worker:** systemd service (prefect-worker.service) runs 24/7

### Git Workflow & Deployment (Feb 2026)
- **Commit prefix:** Use "Billie:" instead of "Bot:" (Filipe prefers partner over bot persona)
- **Default branch:** Always work on `dev` branch, auto-deploy via GitHub Actions
- **Production deployments:** Ask before pushing to `main` branch (unless explicitly requested)
- **Breaking changes:** Automatically create PR instead of asking
  - Breaking = schema changes, API contract changes, flow schedule changes, large refactorings
- **Project structure:**
  - `/opt/<project>/` → Production (main branch)
  - `/opt/<project>-dev/` → Development (dev branch)
- **GitHub Actions:**
  - `deploy-staging.yml` → Push to dev → deploy to /opt/<project>-dev
  - `deploy-prod.yml` → Push to main → deploy to /opt/<project>
- **Shared Prefect server:** All projects use `/opt/prefect` (port 4200) - no project-specific servers
- **Portugal House Market:** Dev on 4200, Prod on 4201 (separate servers for testing, will migrate to shared)
- **Football Data:** Uses shared Prefect server only

### OpenClaw Configuration (Feb 2026)
- Telegram bindings use `peer.kind` and `peer.id` structure (not `accountId`)
- Personal chat: `peer.kind: "dm", peer.id: "8251137081"`
- Supergroup IDs start with `-100...` (Telegram upgrade changed group IDs)
- Gateway runs on port 18789 behind nginx (HTTPS)

### Security Notes
- All Telegram channel IDs are in respective system directories
- Auth tokens stored in `.secrets.md` (not loaded into context)
- PostgreSQL and Prefect ports exposed - need firewall rules for production

---

## Timeline

### 2026-02-04 - Initial Setup
- Created Billie persona, configured OpenClaw gateway, set up nginx reverse proxy
- Installed Docker 29.2.1

### 2026-02-04 to 2026-02-06 - Learning Systems
- Built Data Engineering Quiz (adaptive difficulty, streak tracking)
- Built English Tips (5 daily, Portuguese-speaker focused)
- Built Tech News Newsletter (3 daily, RSS feeds)
- Built Guitar Practice Reminder (5 categories, rotation)
- Wiped Prefect housing project (moved to cron-based approach)

### 2026-02-09 - Telegram Routing Fix
- Fixed personal chat routing (peer structure issue)
- Quiz group upgraded to supergroup format

### 2026-02-09b/c - Travel Planning
- Created manual trip recommendations workflow
- Built automated daily travel tips system

### 2026-02-10 - Infrastructure
- System healthcheck weekly report
- Installed PostgreSQL 16 via Docker
- Re-installed Prefect 3.5.0 with PostgreSQL backend
- Built Last.fm album recommendation system

### 2026-02-11 - Gambling Tracker → Standalone Bot (Modular)
- Built standalone gambling bot (python-telegram-bot) with deposits, withdrawals, bet tracking with odds
- Features: ROI, EV, win rate vs break-even, odds range analysis, stop loss alerts (70%, 90%, 100%), streak tracking
- Commands: /start, /help, /summary, /export, /goal, /progress, /deposit, /withdrawal, /bet <amount> <result> [odds], /stats, /stoploss, /reset_month
- Void bets: Track voided/cancelled/refunded bets
- Charts: Profit trend line chart, win/loss/void pie chart
- Goals: Monthly profit or bet count targets with progress tracking
- Location: /opt/gambling-bot/
- Modular design: State, stats, charts, exporters in separate modules
- Service: systemd (gambling-bot.service) - runs 24/7
- JSON-based storage (no PostgreSQL needed)
- Zero token usage - standalone bot

### 2026-02-11 - Streamlit Dashboard Fixes
- Fixed critical bug: `st.confirm()` doesn't exist, replaced with two-step button pattern
- Fixed "This Week" filter - was showing last 7 days instead of calendar week
- Fixed KeyError on transactions page - added profit calculation for each transaction
- Initialized all statistics variables before conditional blocks to prevent undefined variable errors
- Added safe `.get()` calls for dictionary access with default values
- Improved error handling for charts and best/worst days
- Removed Export section (user request)
- Fixed goals persistence by removing redundant `load_goals()` calls
- Changed success messages to `st.toast()` for better UX
- Removed unused imports (json, time_utils, exporter)

### 2026-02-11 - Gambling Bot & Dashboard Updates
- Removed bet target - now only profit goal is tracked
- Added market field to bets: ML (moneyline), oX.X (over goals), uX.X (under goals), h±X.X (handicap)
- Telegram: `/bet 10 win 2.0 ml` (market codes are optional)
- Streamlit: Added "📝 Add Transaction" page with deposit, withdrawal, bet forms
- Bet form includes market dropdown with live preview of market code
- Market displayed in transactions as `[ML]`, `[O2.5]`, etc.
- Navigation: Dashboard, Add Transaction, Transactions, Settings

### 2026-02-11 - Market Analysis Added
- Added market type tracking to stats (Money Line, Over/Under Goals, Handicap)
- `/stats` command now shows performance breakdown by market type (all-time only)
- Streamlit Dashboard displays "Performance by Market Type" section
- Shows profit, total bets, and win rate for each market

### 2026-02-11 - Advanced Analytics Features
- Streak by market: Track win/loss streaks separately for each market type
- Day of week analysis: Performance by day (Mon-Sun) with profit, bets, WR
- Market × Odds heatmap: 2D matrix showing profit by market AND odds range
- Market EV: Expected value per market to identify most profitable markets
- Confidence intervals: 95% Wilson score for win rates (e.g., "58% [45%-70%]")

### 2026-02-11 - Extended Market Types
- Added 18 total market types (up from 4)
- New: Double Chance, BTTS, DNB, Accumulators (double, treble, acca)
- New: Corners, Cards, HT/FT, First/Last Goalscorer
- New: Result at X goals (R3, R5, R7, R9)
- Streamlit dropdown updated with all market types
- Bot help updated with market code examples

### 2026-02-11 - Custom Market Management System
- Simplified betting flow: 4 core markets + Custom option
- Custom: Free text input for any market code
- Market Management page: Organize custom markets into categories
- State supports market_categories for grouping
- Example categories pre-loaded: Outcomes, Accumulators, Props, Time Markets, Goalscorers, Result Markets

### 2026-02-11 - Streamlit Dashboard Bug Fixes (Evening)
- Fixed missing `save_goals` import (would crash on goal updates)
- Added input UI for all market types: Corners, Cards, HT/FT, Double Chance, Both Teams Score, DNB
- Added categorized market selector in bet form
- Fixed Stop Loss Settings: Changed `max_value=10000` to `max_value=10000.0` (float)
- Fixed Market Management: Updated all references from `state["market_categories"]` to `state["stats"]["market_categories"]`
- Fixed type conversion: Convert all market codes to strings to prevent sorting errors
- Fixed timestamp parsing: Use `format='mixed'` and `utc=True` for robust ISO8601 handling (in both load_data and Transactions page)
- Consolidated duplicate code with helper functions: `is_categorized_market()`, `get_market_code()`
- Fixed "Clear All Data": Now resets `market_categories`, `market_stats`, `market_streaks`, `market_odds_matrix`
- Fixed nginx proxy: Updated from port 8502 to 8501 with proper configuration
- **Removed Add Transaction page** from Streamlit dashboard (246 lines removed) - use Telegram bot instead

### 2026-02-11 - Dynamic Market Management
- Added helper functions to state_manager.py:
  - `get_available_markets()`: Returns list of all available markets (core + categorized)
  - `get_market_display_name()`: Gets display name for market code from categories
- Updated stats.py to use market categories for better naming:
  - `get_market_type()` now accepts state parameter and uses categorized market names
  - Updated `update_markets()`, `update_market_streaks()`, `update_market_odds_matrix()` to pass state
  - Added `recalculate_market_stats()` to refresh market names after category changes
- Telegram bot updates:
  - New `/recalc` command to refresh market stats with updated category names
  - Updated help text to include `/recalc` command
- **Result**: Custom markets now display as category name only (e.g., "Outcomes", "Accumulators") for cleaner stats

### 2026-02-14 - Gambling Bot: /uncategorized Command
- Added `/uncategorized` command to show all markets displaying as "Other"
- Command scans all bet transactions and identifies uncategorized markets
- Shows market code, bet count, win/loss record, and win rate for each uncategorized market
- Provides guidance on how to categorize markets via Streamlit Dashboard
- Updated help text in both `/start` and `/help` commands
- Updated README.md with new command documentation
- Bot restarted successfully (gambling-bot.service)
- **Use case**: User can quickly see what markets need categorization and fix them via dashboard

### 2026-02-14 - Gambling Bot: /last Command
- Added `/last` command to show last N transactions (default: 10)
- Command supports filtering by transaction type: `/last bet`, `/last deposit`, `/last withdrawal`
- `/last N` - Show last N transactions
- `/last N exclude_type` - Show last N excluding specific type
- Each transaction shows type, amount, details (result, odds, market for bets), and timestamp
- Updated help text in both `/start` and `/help` commands
- Updated README.md with command documentation and examples
- Bot restarted successfully (gambling-bot.service)
- **Use cases**: Quick review of recent activity, error checking, filtering by transaction type

### 2026-02-14 - Gambling Bot: Rollback /delete Command
- Rolled back `/delete` command functionality per user request
- User prefers to delete transactions using Streamlit Dashboard instead of Telegram commands
- Removed three async functions: `delete_tx()`, `confirm_delete()`, `cancel_delete()`
- Removed command handlers: `delete`, `confirm_delete`, `cancel`
- Removed `/delete`, `/confirm_delete`, `/cancel` from `/start` and `/help` command lists
- Updated README.md to remove delete-related commands and examples
- Bot restarted successfully (gambling-bot.service)

### 2026-02-11 - Bank Stat Added
- Added "Bank (Available)" metric to show money available to bet
- **Formula**: `deposits - withdrawals - losses + winnings`
  - Represents actual money available to bet (not P&L)
- Added `bank` to `calculate_stats()` function in stats.py
- Updated bot.py to save and display bank in `/stats` output
- Updated Streamlit dashboard to show bank as prominent metric with emoji indicator
- Updated default state and reset_month to include bank calculation
- **Display**: Bank shown first in both Telegram stats and Dashboard metrics

### 2026-02-11 - Transaction Type Filter
- Added transaction type filter to Transactions page in Streamlit dashboard
- **Filter options**: All, Bet, Deposit, Withdrawal
- Dropdown selector allows viewing specific transaction types
- Default is "All" to show everything
- **Use case**: Quickly view only bets, only deposits, or only withdrawals without scrolling through all transactions

### 2026-02-11 - Stats Calculation Bug Fix
- Fixed critical bug: `total_won` and `total_lost` not being saved after recalculation
- **Root cause**: When recalculating stats, only `net_profit` and `bank` were saved, not the intermediate values
- **Impact**: These fields showed €0 even when actual values were €17.28 (won) and €240.00 (lost)
- **Fix**: Updated `add_transaction()` and `reset_month()` in bot.py to save ALL calculated stats:
  - `deposits`, `withdrawals`, `total_bets`, `total_wagered`
  - `total_won`, `total_lost`, `wins`, `losses`
  - `net_profit`, `bank`, `roi`, `ev`, `win_rate`, `average_odds`
- **Verification**: Ran manual recalculation script to fix existing state
- **Result**: All stats now accurate and consistent

### 2026-02-11 - Delete Transactions Feature
- Added ability to delete individual transactions from Transactions page in Streamlit dashboard
- **New UI elements**:
  - Added "#" column to transaction table for identification
  - Added "Delete Transaction" section with selectbox
  - Shows transaction details before deletion
  - Delete button with confirmation
  - Cancel button to go back
- **Automatic recalculation**: All stats are recalculated immediately after deletion:
  - Deposits, withdrawals, total bets, total wagered
  - Total won, total lost, wins, losses
  - Net profit, bank, ROI, EV, win rate, average odds
  - Monthly stop loss
- **Use case**: Delete mistaken transactions registered via Telegram bot
- **Implementation**: Uses transaction index to identify and remove from state

### 2026-02-14 - Gambling Bot: /delete Command
- Added `/delete` command to remove incorrectly recorded transactions
- Two-step confirmation process for safety: `/delete <number>` → `/confirm_delete <number>`
- `/cancel` command to cancel a pending deletion
- Shows full transaction details before confirmation (number, type, amount, details, timestamp)
- Stats automatically recalculated after deletion (no manual `/recalc` needed)
- Updated help text in both `/start` and `/help` commands
- Updated README.md with delete workflow documentation and examples
- Bot restarted successfully (gambling-bot.service)

### 2026-02-12 - Bet Command Argument Order Updated
- Changed `/bet` command argument order for better workflow
- **Old format**: `/bet <amount> <result> [odds] [market]`
- **New format**: `/bet <amount> [odds] [market] <result>`
- **Benefits**:
  - Result is now the last argument (required)
  - Odds and market are optional, in the middle
  - More intuitive betting workflow
- **Updated files**:
  - `bot.py`: Modified `bet()` command handler to parse new argument order
  - Updated `/start` welcome message with new examples
  - Updated `/help` command documentation
  - Updated `README.md` with new syntax
- **Examples**:
  - `/bet 10 2.0 ml win` - Full bet with market
  - `/bet 10 1.8 o2.5 loss` - Standard bet
  - `/bet 15 push o2.5` - Push bet (no odds needed in market)
  - `/bet 10 win` - Simple bet (odds defaults to 1.0)

### 2026-02-12 - Free API Research
- Conducted comprehensive research on free APIs recommended by developers and data engineers (2025-2026)
- Searched Twitter/X, Reddit, and developer blogs for current sentiment
- **Key findings**:
  - **Top LLM APIs**: Google Gemini (1,500 req/day), Groq (ultra-fast), OpenRouter (100+ models), Hugging Face (500K+ models)
  - **Data APIs**: CoinGecko (crypto, no auth), OpenWeatherMap (weather), REST Countries (unlimited), GitHub API (5,000 req/hr auth)
  - **Scraping APIs**: Scrape Creators (social media), ScrapingBee (general), Firecrawl (AI-powered), Apify (10K+ tools)
  - **Automation**: n8n (free self-hosted workflow automation), Zapier (100 tasks/month free)
  - **Monitoring**: Sentry (error tracking free), Grafana (open-source)
  - **Email**: SendGrid **discontinued free tier July 2025**, Resend emerging as alternative
- **Personalized recommendations for Filipe** (Data Engineering focus):
  - n8n (workflow orchestration), Groq (fast LLM inference), OpenRouter (multi-model experimentation)
  - CoinGecko (crypto data for gambling insights), Hugging Face (ML experiments), GitHub API (repo automation)
  - Scrape Creators (social data), Supabase (PostgreSQL + auto APIs), OpenWeatherMap (weather pipeline source)
- **Note**: Detailed findings stored in `memory/2026-02-12.md`

### 2026-02-12 - Last.fm Albums Acknowledgment Automation
- Implemented Option 2: Message-Checking Cron (automated acknowledgment detection)
- **Workflow:** User replies "listened" → Billie detects → Runs `process_ack.py 1` → Next day new album
- **Files updated:**
  - `check_messages.py` - Attempts to check Telegram for "listened" messages (has API limitations)
  - `send_album.py` - Calls check_messages.py before sending new album
  - `ACKNOWLEDGMENT.md` - Updated documentation for new workflow
  - `README.md` - Updated to reflect automated acknowledgment
- **Known limitation:** Telegram Bot API can't read channel messages easily; relies on Billie (AI agent) to detect "listened" in channel
- **Manual fallback:** `/opt/lastfm-albums/process_ack.py 1` if automated detection fails
- **Current state:** 3 albums listened (Hayley Williams, Interpol, Kings of Leon)

### 2026-02-13 - Git Workflow Implementation
- Implemented professional git workflow with dev/prod environments for both projects
- **Portugal House Market:**
  - Created dev branch, set up `/opt/portugal-house-market-dev` and `/opt/portugal-house-market`
  - Created separate Prefect servers for testing (dev: 4200, prod: 4201) - plan to migrate to shared
  - GitHub Actions: `deploy-staging.yml` (dev branch) and `deploy-prod.yml` (main branch)
  - Automated deployments tested successfully
  - Documentation: `DEPLOYMENT.md` created
- **Football Data:**
  - Created dev branch, set up `/opt/football-data-dev` and `/opt/football-data`
  - Uses shared Prefect server at `/opt/prefect` (port 4200)
  - GitHub Actions: `deploy-staging.yml` (dev branch) and `deploy-prod.yml` (main branch)
  - Automated deployments tested successfully
  - Documentation: `DEPLOYMENT.md` created
- **Shared Infrastructure:**
  - RSA 4096-bit SSH key for GitHub Actions: `/root/.ssh/github_actions_rsa`
  - GitHub secrets configured for both projects: `SERVER_HOST`, `SERVER_USER`, `SSH_PRIVATE_KEY`
  - Shared Prefect server at `/opt/prefect` (port 4200) orchestrates all projects
- **Commit Convention:** Use "Billie:" prefix (partner vs bot persona), work on dev branch by default
- **Breaking Changes:** Automatically create PR (schema changes, API changes, schedule changes, refactorings)

### 2026-02-13 - Prefect Multi-Project Architecture
- Implemented multi-project Prefect setup with single server, multiple GitHub repos
- Created `filipelima1990/football-data` (private) repo from `/opt/football-data`
  - Premier League data from football-data.co.uk
  - Deployment: `weekly-load-premier-league` (Sundays 10:00 AM UTC)
- Cloned `filipelima1990/portugal-house-market` to `/opt/portugal-house-market`
  - Porto housing market scraper (Imovirtual)
  - Deployment: `daily-scrape-porto-housing` (Daily 9:00 AM UTC)
- Both deployments use shared `default-pool` work pool
- Created `prefect.yaml` for both projects with pull step for working directory
- Updated both projects to use Prefect v3 API (`flow.deploy()` vs deprecated `Deployment.build_from_flow()`)
- Deployed via CLI: `prefect deploy <flow_file> --name <name> --pool <pool> --cron <schedule>`
- All deployments visible at http://167.235.68.81:4200

### 2026-02-14 - PostgreSQL Database Separation (Dev/Prod)
- Created separate PostgreSQL databases for each project's dev and prod environments
  - Football Data: `football_data_dev`, `football_data_prod`
  - Housing Market: `portugal_houses_dev`, `portugal_houses_prod`
- Created schemas for all databases:
  - Football: `raw_pl_matches` table with indexes (match_date, home_team, away_team, league_division)
  - Housing: Three schemas (raw, staging, marts) with listings tables and price tracking
- Updated all `.env` files to use environment-specific databases:
  - `/opt/football-data/.env` → `football_data_prod`
  - `/opt/football-data-dev/.env` → `football_data_dev`
  - `/opt/portugal-house-market/.env` → `portugal_houses_prod`
  - `/opt/portugal-house-market-dev/.env` → `portugal_houses_dev`
- Created documentation:
  - `/opt/football-data/DEPLOYMENT.md` - Updated with database configuration
  - `/opt/portugal-house-market/DEPLOYMENT.md` - Created full deployment guide
  - `/root/.openclaw/workspace/DATABASE_SETUP.md` - Complete setup summary
  - `/root/.openclaw/workspace/create_schemas.py` - Schema recreation script
- Old database `football_data` (deprecated) still exists but unused
- User `dataeng` created for housing project access (password: `changeme`)
- Architecture benefit: Clean separation prevents cross-contamination between dev and prod

### 2026-02-14 - Data Migration & Testing
- Migrated 185,562 housing listings from `postgres.raw.listings` to both dev and prod databases
- Migration method: CSV export → temp tables → insert with conflict resolution
- Verification: All tests passed (configuration, data integrity, insert operations)
- Housing data: 185,562 total listings, 63,139 unique properties
- Football data: Schema ready (`raw_pl_matches` table with indexes)
- Both deployments ready for production (PRs created for review)
- Status: ✅ All tests passed, ready to merge PRs to main

### 2026-02-14 - Prefect Deployment Cleanup & Schedule Update
- Deleted old deployment "Daily Scrape and Load Housing Data/daily-scrape-housing-nationwide" (outdated)
- Created new deployments with 1:00 AM UTC schedule:
  - `daily-scrape-porto-housing-dev` (dev environment, uses `portugal_houses_dev` DB)
  - `daily-scrape-porto-housing` (prod environment, uses `portugal_houses_prod` DB)
- Kept utility flow "Quick Scrape (No Database)" for manual testing (no deployment)
- Both deployments use same flow but different `.env` files based on directory
- Schedule changed from 9:00 AM UTC to 1:00 AM UTC (user request)
- Status: ✅ Deployments cleaned and schedule updated

### 2026-02-16 - Prefect Deployment Cleanup & Bug Fix
- **Removed deployments:**
  - `Load Premier League Data/weekly-load-premier-league` (football flow)
  - `Scrape and Load Housing Market Data/daily-scrape-porto-housing-dev` (dev flow from prod Prefect server)
- **Fixed critical polars filter bug:**
  - Issue: `ValueError: invalid predicate for filter` in scrape_flow.py
  - Root cause: Using lambda function with polars filter (incorrect syntax)
  - Fix: Changed from `df.filter(lambda r: r["price_eur"] is not None)` to `df.filter(pl.col("price_eur").is_not_null())`
  - Added `import polars as pl` to scrape_flow.py
  - Fixed in both `/opt/portugal-house-market` (prod) and `/opt/portugal-house-market-dev` (dev)
  - Committed changes to both repos
  - Restarted Prefect worker service
- **Current deployments:** Only `Scrape and Load Housing Market Data/daily-scrape-porto-housing` remains
- **Status:** ✅ All errors resolved, worker running smoothly

### 2026-02-17 - OpenClaw Backup System
- **Created GitHub repository:** https://github.com/filipelima1990/openclaw-backup
- **Backup system setup:**
  - Added remote "backup" to workspace git repo
  - Created `/opt/openclaw-backup/backup.sh` - Main backup script
  - Created `/opt/openclaw-backup/setup-cron.sh` - Cron installer
  - Created `/opt/openclaw-backup/README.md` - Documentation
  - Set up cron job: Daily at 2:00 AM UTC
- **What gets backed up:**
  - `MEMORY.md` - Long-term memory
  - `memory/` - Daily notes
  - `AGENTS.md`, `USER.md`, `SOUL.md`, `IDENTITY.md` - Configuration
  - All markdown documentation
  - `openclaw.json` - Main config (temporarily included)
  - `cron/` - Cron definitions (temporarily included)
- **Excluded from backup:**
  - `.secrets.md` - Sensitive information
  - `gmail-tools/` - Contains Google OAuth credentials
  - `.env` files, log files, Python cache, virtual environments
  - `openclaw-config.json`, `cron-backup/` - Temporary backup files
- **Status:** ✅ Backup system operational, first backup successful

---

## Telegram Channel IDs

## Telegram Channel IDs

| Purpose | Chat ID |
|---------|---------|
| English Tips | -1003875454703 |
| Tech News | -1003369440176 |
| Travel Tips | -1003401888787 |
| Last.fm Albums | -1003823481796 | **IMPORTANT:** When user replies "listened" in this channel, I should automatically run `/opt/lastfm-albums/process_ack.py 1` |
| Guitar Practice | -5287670840 |
| Personal Chat | 8251137081 |

---

## Quick Reference

- **OpenClaw CLI:** `openclaw <command>`
- **Server access:** SSH tunnel via `~/openclaw-ui.sh` (local) or direct to `.secrets.md`
- **System status:** Check each `/opt/<system>/README.md`
- **Cron jobs:** System crontab (`crontab -l`)
- **Docker:** `docker ps` for running containers (PostgreSQL, Prefect)
