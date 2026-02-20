# MEMORY.md - Long-term Memory for Billie

_Refer to `.secrets.md` for sensitive information (tokens, IPs, keys)._

---

## Active Systems

All systems use cron jobs or systemd services. Documentation lives in `/opt/<system>/README.md`.

| System | Location | Schedule | Destination |
|--------|----------|----------|-------------|
| Daily Quiz | `/opt/quiz/` | 9 AM UTC (cron) | Personal chat | **PostgreSQL-backed** - Learning paths, topic mastery, weak area detection |
| Health Report | `/opt/healthcheck/` | Sundays 10 AM UTC (cron) | Personal chat |
| Last.fm Albums | `/opt/lastfm-albums/` | 2 PM UTC (OpenClaw cron) | Channel -1003823481796 | **AUTOMATIC:** Dedicated music-curator agent runs daily. When user replies "listened", Billie runs `/opt/lastfm-albums/process_ack.py 1` |
| Housing Market | `/opt/portugal-house-market/` | Daily 1 AM UTC (cron) | PostgreSQL: portugal_houses |
| Gambling Bot | `/opt/gambling-bot/` | 24/7 (systemd) | Telegram bot | **Standalone bot** - JSON-based storage |
| Gambling Web | `/opt/gambling-web/` | 24/7 (systemd) | API: http://167.235.68.81:8000 | **React+FastAPI** - PostgreSQL backend |
| Mission Control | `/opt/mission-control/` | 00:00-07:00 UTC (timer) | Dashboard: http://167.235.68.81:3101 | **Autonomous agent** - Next.js 16, Server Components, Server Actions - Morning brief at 07:00 UTC | **Futuristic UI** - Sidebar navigation, gradient effects, glassmorphism (2026-02-20) |
| PostgreSQL | `/opt/postgresql/` | Running 24/7 (Docker) | Port 5432 |
| Backup System | `/opt/openclaw-backup/` | Daily 2 AM UTC (cron) | GitHub: filipelima1990/openclaw-backup |

---

## Key Technical Decisions

### Architecture Philosophy
- **Cron over orchestration:** Using system crontab for simple scheduled jobs
- **Prefect for data pipelines:** Single Prefect server orchestrates data projects
- **Database-backed:** PostgreSQL for data systems, JSON for simple bots
- **Telegram-first:** All notifications go through Telegram via OpenClaw CLI
- **Modular design:** Each system is self-contained in `/opt/<system>/`

### Collaboration Workflow
- **Team approach:** Billie generates initial project files → Filipe refines with Claude Code
- **Claude Code:** Used to sharpen, refactor, and improve code quality
- **Commit convention:** Both Billie and Claude Code contributions use "Billie:" prefix (partner vs bot persona)

### Prefect Architecture (Feb 2026 - Simplified)
- **Single server:** One Prefect instance on port 4200 (http://167.235.68.81:4200)
- **Single deployment:** `Scrape and Load Housing Market Data/daily-scrape-porto-housing` (1:00 AM UTC)
- **Shared work pool:** `default-pool` (process type) handles deployments
- **PostgreSQL databases:**
  - `football_data` - Premier League match history
  - `portugal_houses` - Porto housing listings (185K+ records)
  - `quiz` / `quiz_prod` - Quiz system
- **Worker:** systemd service (prefect-worker.service) runs 24/7

### Git Workflow (Feb 2026)
- **Commit prefix:** Use "Billie:" instead of "Bot:" (Filipe prefers partner over bot persona)
- **Simplified structure:** No DEV/PROD separation - single production setup
- **Breaking changes:** Automatically create PR instead of asking
  - Breaking = schema changes, API contract changes, flow schedule changes, large refactorings

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

### 2026-02-09 - Telegram Routing Fix
- Fixed personal chat routing (peer structure issue)

### 2026-02-10 - Infrastructure
- System healthcheck weekly report
- Installed PostgreSQL 16 via Docker
- Re-installed Prefect 3.5.0 with PostgreSQL backend

### 2026-02-11 - Gambling Bot (Standalone)
- Built standalone gambling bot (python-telegram-bot) with deposits, withdrawals, bet tracking with odds
- Features: ROI, EV, win rate vs break-even, odds range analysis, stop loss alerts (70%, 90%, 100%), streak tracking
- Commands: /start, /help, /summary, /export, /goal, /progress, /deposit, /withdrawal, /bet <amount> [odds] [market] <result>, /stats, /stoploss, /reset_month
- Void bets: Track voided/cancelled/refunded bets
- JSON-based storage (no PostgreSQL needed)
- Zero token usage - standalone bot
- Service: systemd (gambling-bot.service) - runs 24/7

### 2026-02-11 to 2026-02-14 - Gambling Bot Enhancements
- Added market tracking (ML, Over/Under, Handicap, etc.)
- Advanced analytics: streak by market, day of week analysis, market × odds heatmap, market EV
- Custom market management system with categories
- Streamlit Dashboard (now superseded by gambling-web)
- `/uncategorized` command to find unclassified markets
- `/last` command to show recent transactions
- Bank stat added (actual money available to bet)
- Transaction type filter
- Stats calculation bug fix

### 2026-02-12 - Free API Research
- Researched free APIs for developers (LLM, data, scraping, automation)
- Personalized recommendations: n8n, Groq, OpenRouter, CoinGecko, Hugging Face, GitHub API, Scrape Creators, Supabase, OpenWeatherMap

### 2026-02-12 to 2026-02-19 - Last.fm Albums
- Built Last.fm album recommendation system
- Message-checking cron for acknowledgment detection
- Dedicated music-curator agent created
- OpenClaw cron job: Daily at 2 PM UTC
- Workflow: User replies "listened" → Billie detects → Runs process_ack.py

### 2026-02-13 to 2026-02-16 - Prefect & Git Workflow
- Implemented professional git workflow (later simplified)
- Multi-project Prefect setup with single server
- Created GitHub repos for football-data and portugal-house-market
- PostgreSQL database separation (later removed)
- Data migration & testing
- Prefect deployment cleanup & polars bug fix

### 2026-02-14 - Gambling Web (React+FastAPI)
- Started new gambling tracker with React frontend and FastAPI backend
- PostgreSQL-backed (gambling database)
- API on port 8000
- **Note:** Not actively used yet, but kept for future rework

### 2026-02-17 - OpenClaw Backup System
- Created GitHub repository: https://github.com/filipelima1990/openclaw-backup
- Backup system setup with cron job (Daily 2:00 AM UTC)
- Backs up: MEMORY.md, memory/, AGENTS.md, USER.md, SOUL.md, IDENTITY.md, markdown docs
- Excludes: .secrets.md, gmail-tools/, .env files, logs, Python cache

### 2026-02-18 - OddsPortal Predictions (Removed)
- Tech News system archived
- OddsPortal predictions system created (later removed Feb 20)

### 2026-02-19 - Guitar Practice System (Removed)
- Archived `/opt/guitar/`
- System crontab entry removed

### 2026-02-19 - Mission Control
- Created autonomous overnight agent with Next.js dashboard
- Execution window: 00:00 - 07:00 UTC
- Morning brief at 07:00 UTC
- Task tracking with logs, artefacts, blockers
- Self-improvement system
- Dashboard on port 3101

### 2026-02-19 - Quiz System PostgreSQL Migration
- Migrated Quiz system from JSON to PostgreSQL
- Database: `quiz_prod` / `quiz` (both exist)
- Tables: topics, difficulties, questions, user_progress, answer_history, topic_mastery
- New features: Learning path suggestions, topic mastery tracking, weak area detection
- 101 questions migrated, 17 answer history preserved

### 2026-02-20 - System Cleanup
- **Removed:** /opt/OddsHarvester (third-party odds scraper)
- **Removed:** /opt/engtips (English tips - 5 daily)
- **Removed:** /opt/travel (Travel tips)
- **Removed:** /opt/oddsportal-hot-matches (Hot matches analysis)
- **Removed:** /opt/_archived/ (dev versions archived)
- **Removed:** Cron jobs for engtips and travel
- **Removed:** OpenClaw cron job for oddsportal-hot-matches
- **Simplified:** Prefect - only one deployment (housing market), no DEV/PROD separation
- **Kept:** Gambling Bot (standalone) and Gambling Web (React+FastAPI) - serve different purposes, to be reworked later
- **Kept:** Mission Control - will be revamped
- **Kept:** Google/Chrome - browser automation

### 2026-02-22 - OddsPortal Skills Removed
- **Removed:** OpenClaw skills - oddsportal-hot-matches and oddsportal-predictions
- **Removed:** Workspace directory - `/root/.openclaw/workspace/oddsportal-hot-matches/` (1.5M)
- No longer using OddsPortal-related features

### 2026-02-22 - Web Development Skills Added
- **Installed:** nextjs-developer - Senior Next.js 14+ App Router specialist (server components, server actions, performance optimization)
- **Installed:** frontend-design - Web Interface Guidelines for UI reviews (Vercel)
- **Installed:** react-best-practices - Vercel React/Next.js performance optimization (57 rules across 8 categories)
- Skills installed via clawdhub from LobeHub marketplace
- Ready to build production-grade web apps with Next.js

### 2026-02-22 - Testing, API & DevOps Skills Added
- **Installed:** web-qa-bot - AI-powered web QA automation (accessibility-tree based testing)
- **Installed:** playwright-cli - Browser automation for end-to-end tests
- **Installed:** fastapi-expert - Senior-level FastAPI skill (async Python, Pydantic V2, JWT/OAuth2)
- **Installed:** read-github - Semantic search across GitHub repos (README, /docs, code)
- **Installed:** dokploy - Deploy Docker/git/compose apps via CLI
- **Installed MCP Servers:**
  - Postgres MCP Pro - Database health, index tuning, query plans, safe SQL execution (installed via pipx)
  - Web Scraper MCP - General-purpose scraping (Playwright, Apify, requests/BeautifulSoup)
- MCP servers configured at `/opt/mcp-servers/README.md`
- MCP servers integrate with Claude Desktop or MCP-compatible clients (not OpenClaw skills)

### 2026-02-22 - Prefect Decommissioned
- **Decision:** Prefect was overkill for current needs (only 2 simple daily pipelines)
- **Removed:**
  - Prefect services: systemd (prefect.service, prefect-worker.service) disabled and stopped
  - Prefect venv: ~240MB RAM reclaimed
  - Football Data project: `/opt/football-data/` deleted
- **Simplified:** Housing market moved from Prefect to cron (daily 1 AM UTC)
- **Resources Reclaimed:** ~240MB RAM + ~42% CPU usage
- **Rationale:** Prefect was good for learning, but cron is better for simple "run script at X time" workflows

### 2026-02-20 - Mission Control Dashboard Revamped (Final)
- **Complete refactor** using Next.js 16, Server Components, Server Actions, and modern React patterns
- **New Sections:**
  - **System Health**: CPU, Memory, Uptime widgets
  - **Team Section**: All 5 registered agents (Mission Control, Music Curator, Quiz Agent, Health Check, Gambling Bot)
  - **Skills Section**: All 15 installed OpenClaw skills with categories and filters
- **Enhanced Logs**: Session grouping, detailed log viewer with stack traces and context
- **Enhanced Tasks**: Edit backlog tasks, high priority tasks, blocked tasks, recent tasks
- **Documents Hub**: Scans all /opt/ projects for markdown files, comprehensive filtering
- **Architecture changes:**
  - Migrated from client-only to Server Components by default
  - Created centralized data layer (lib/data.ts, lib/agents.ts, lib/documents.ts) with React.cache()
  - Implemented Server Actions for mutations (create/delete tasks)
  - Full TypeScript coverage with strict mode
  - Added proper error boundaries and loading states
- **Skills applied:** nextjs-developer, react-best-practices, frontend-design
- **Documentation:** Created REFACTOR.md, REFACTOR_CHECKLIST.md, IMPROVEMENTS_SUMMARY.md
- **API endpoints:** All updated to use new data layer (backward compatible)
- **Service:** Systemd service restarted and running on port 3101
- **Build time:** ~5 seconds with Turbopack
- **Bundle size:** ~100KB (gzip) for initial load
- **Understanding hub**: Dashboard now serves as central knowledge base to understand what we're building together

### 2026-02-20 - Mission Control Dashboard Revamped
- **Complete refactor** using Next.js 16, Server Components, Server Actions, and modern React patterns
- **Architecture changes:**
  - Migrated from client-only pages to Server Components by default
  - Created centralized data layer (`lib/data.ts`) with React.cache() for deduplication
  - Implemented Server Actions for mutations (create/delete/update tasks)
  - Full TypeScript coverage with strict mode
  - Added proper error boundaries and loading states for each route
- **New components created:**
  - UI components: Card, Badge, Button, Loading spinners
  - Feature components: TaskForm, TaskList, LogList, DocumentList
  - Utility functions: cn(), formatDate(), formatTime(), formatRelativeTime()
- **Performance improvements:**
  - Parallel data fetching with Promise.all()
  - Eliminated fetch waterfalls
  - Added revalidation support (30-second cache)
  - Proper loading states and error handling
- **Accessibility enhancements:**
  - ARIA labels on all interactive elements
  - Semantic HTML structure
  - Keyboard navigation support
  - Screen reader friendly
- **Skills applied:** nextjs-developer, react-best-practices, frontend-design
- **Documentation:** Created `dashboard/REFACTOR.md` and `dashboard/REFACTOR_CHECKLIST.md`
- **API endpoints:** All updated to use new data layer (backward compatible)
- **Service:** Systemd service restarted and running on port 3101
- **Build time:** ~5 seconds with Turbopack
- **Bundle size:** ~100KB (gzip) for initial load

---

## Telegram Channel IDs

| Purpose | Chat ID |
|---------|---------|
| Last.fm Albums | -1003823481796 | **AUTOMATIC:** When user replies "listened", Billie runs `/opt/lastfm-albums/process_ack.py 1` |
| Personal Chat | 8251137081 |

---

## Quick Reference

- **OpenClaw CLI:** `openclaw <command>`
- **Server access:** SSH tunnel via `~/openclaw-ui.sh` (local) or direct to `.secrets.md`
- **System status:** Check each `/opt/<system>/README.md`
- **Cron jobs:** System crontab (`crontab -l`)
- **Docker:** `docker ps` for running containers (PostgreSQL)
- **Prefect:** http://167.235.68.81:4200
- **Mission Control Dashboard:** http://167.235.68.81:3101
- **Gambling API:** http://167.235.68.81:8000

---

## Running Systemd Services

| Service | Status | Purpose |
|---------|--------|---------|
| prefect.service | active | Prefect server (port 4200) |
| prefect-worker.service | active | Executes Prefect deployments |
| gambling-bot.service | active | Standalone Telegram gambling bot |
| gambling-api.service | active | FastAPI backend for gambling-web (port 8000) |
| gambling-dashboard.service | disabled | Streamlit dashboard (superseded by gambling-web) |
| mission-control-dashboard.service | active | Next.js dashboard (port 3101) |
| mission-control-tick.timer | active | Wakes mission-control agent every 30 min |

---

## PostgreSQL Databases

- **football_data** - Premier League match history
- **portugal_houses** - Porto housing listings (185K+ records)
- **quiz** / **quiz_prod** - Quiz system (both exist, likely use quiz_prod)
- **postgres** - System DB

---

## File Structure Summary

```
/opt/
├── containerd/          (12K) - Docker runtime
├── postgresql/          (16K) - PostgreSQL config
├── openclaw-backup/     (20K) - Backup scripts
├── healthcheck/         (36K) - Weekly system report
├── lastfm-albums/       (100K) - Last.fm recommendations
├── gambling-bot/        (372K) - Standalone Telegram bot (JSON)
├── quiz/                (876K) - Data Engineering Quiz (PostgreSQL)
├── football-data/       (896K) - Premier League scraper (Prefect)
├── gambling-web/        (239M) - React+FastAPI gambling tracker (PostgreSQL)
├── google/              (388M) - Chrome browser (automation)
├── mission-control/     (453M) - Autonomous agent + Next.js dashboard
├── prefect/             (577M) - Prefect server (port 4200)
└── portugal-house-market/ (710M) - Housing scraper (Prefect)
```

---

## Future Work / To Rework

1. **Gambling Systems:** Both gambling-bot (standalone) and gambling-web (React+FastAPI) need to be reworked - they serve different purposes but aren't actively used yet
2. **Prefect Deployments:** Only one deployment (housing market) - football data deployment was removed

### 2026-02-20 - Mission Control UI Enhancements
- **Futuristic UI Redesign:** Applied modern, futuristic design to Mission Control dashboard
- **Sidebar Navigation:**
  - Fixed sidebar with gradient design (blue/purple theme)
  - Navigation items: Dashboard, Team, Skills, Tasks, Logs, Documents
  - Active page indicator with glowing dot
  - Smooth transitions and hover effects
  - Moon emoji (🌙) as branding element
- **Team Section Fixes:**
  - Now shows only 2 actual OpenClaw agents (main, music-curator)
  - Enhanced with glassmorphism cards, animated gradients, and status indicators
- **Agent Cards:**
  - Glassmorphism design with hover effects
  - Animated status dots (green for active, yellow for paused, gray for idle)
  - Gradient borders and backdrop blur
  - Smooth transitions on hover
- **Layout Changes:**
  - All pages now use DashboardLayout wrapper with sidebar
  - Removed top header (navigation moved to sidebar)
  - Added section IDs (#team, #skills) for hash navigation
- **Performance:** ~5-second build time with Turbopack, ~100KB bundle size
- **Tech Stack:** Next.js 16, React 19, Tailwind CSS v4

---

**Last Updated:** 2026-02-20
