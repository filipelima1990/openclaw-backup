# Mission Control - AI Agent Orchestration Dashboard

**Location:** `/opt/mission-control/`  
**Access:** http://167.235.68.81:4000 (local) or via SSH tunnel  
**Status:** Running (production mode, 24/7) - Systemd service enabled

---

## What Is This?

Mission Control is a **dashboard for orchestrating OpenClaw agents**. It provides:

- **Kanban Board** - 7 columns: Planning → Inbox → Assigned → In Progress → Testing → Review → Done
- **AI Planning** - Interactive Q&A where AI asks clarifying questions before starting work
- **Agent Discovery** - Import existing OpenClaw agents with one click
- **Real-time Live Feed** - Watch agent activity as it happens
- **Task Management** - Create, assign, track, and complete tasks
- **Workspace Management** - Organize projects in `/root/.openclaw/workspace/projects/`

---

## Architecture

```
Mission Control (Next.js, port 4000)
    ↓ WebSocket
OpenClaw Gateway (port 127.0.0.1:18789)
    ↓ Spawns
AI Agents (main, music-curator, + specialized agents)
```

---

## Configuration

**Environment File:** `/opt/mission-control/.env.local`

```bash
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18789
OPENCLAW_GATEWAY_TOKEN=5eeb197dd8304f22b780ebf5d43d581ad86165e2f3b28e4b
DATABASE_PATH=./mission-control.db
WORKSPACE_BASE_PATH=/root/.openclaw/workspace
PROJECTS_PATH=/root/.openclaw/workspace/projects
```

---

## Accessing the Dashboard

### From Local Machine
```bash
# Option 1: SSH tunnel (recommended)
ssh -L 4000:localhost:4000 root@167.235.68.81
# Then open http://localhost:4000

# Option 2: Direct access (if you're on the server)
open http://localhost:4000
```

### From Browser
After setting up SSH tunnel, visit: **http://localhost:4000**

---

## Quick Start

### 1. Check Connection
- Open the dashboard at http://localhost:4000
- Click **"Connect to Gateway"** if not already connected
- Verify your existing agents are discovered (main, music-curator)

### 2. Import Existing Agents
- Go to **Agents** panel
- Click **"Discover Agents"**
- Your OpenClaw agents should appear automatically

### 3. Create Your First Task
1. Click **"New Task"** button
2. Enter title and description
3. Click **"Start Planning"**
4. Answer the AI's clarifying questions
5. Confirm when ready
6. Watch the agent work in real-time

---

## Workflow

### Planning Phase
- AI asks clarifying questions to understand your needs
- You provide answers in natural language
- AI creates a detailed plan before starting work

### Execution Phase
- A specialized agent is auto-created based on your answers
- Agent executes tasks: writes code, browses web, creates files
- Real-time feed shows all agent activity

### Delivery Phase
- Completed work appears in Mission Control
- Deliverables (files, logs, summaries) are attached to tasks
- Tasks move from "In Progress" → "Testing" → "Review" → "Done"

---

## Task Status Flow

```
Planning → Inbox → Assigned → In Progress → Testing → Review → Done
```

- **Planning** - AI asking questions
- **Inbox** - Ready to assign
- **Assigned** - Agent picked up
- **In Progress** - Agent working
- **Testing** - Results delivered, testing phase
- **Review** - Final review needed
- **Done** - Completed

---

## Database

- **Type:** SQLite
- **Location:** `/opt/mission-control/mission-control.db`
- **Schema:** Auto-created on first run

### Reset Database (start fresh)
```bash
cd /opt/mission-control
rm mission-control.db
```

### Inspect Database
```bash
cd /opt/mission-control
sqlite3 mission-control.db ".tables"
```

---

## Development vs Production

### Current Status: Production Mode ✅
- Running: `systemd service` (production build)
- Auto-restart: Enabled
- Port: 4000
- Optimized for 24/7 operation

### Systemd Service
```bash
# Service file: /etc/systemd/system/mission-control.service
# Start: systemctl start mission-control
# Stop: systemctl stop mission-control
# Restart: systemctl restart mission-control
# Status: systemctl status mission-control
# Logs: journalctl -u mission-control -f
```

### Nginx Reverse Proxy (Optional)
- Not configured yet
- Can be added for HTTPS and domain mapping

---

## Troubleshooting

### Can't connect to OpenClaw Gateway
```bash
# Check if Gateway is running
openclaw gateway status

# Restart Gateway
openclaw gateway restart

# Check logs
openclaw gateway logs
```

### Mission Control not responding
```bash
# Check if process is running
lsof -i :4000

# Check logs
cd /opt/mission-control
npm run dev  # Look for errors in console
```

### Port 4000 already in use
```bash
# Find process
lsof -i :4000

# Kill process
kill -9 <PID>
```

---

## Usage Ideas

### Ad-hoc Tasks
- Quick investigations
- One-off coding tasks
- Research requests
- File organization

### Project Management
- Track ongoing development work
- Coordinate multiple agents
- Review deliverables
- Maintain task history

### Integration with Existing Systems
- **LipeTips:** Create tasks for new features, scraping improvements
- **Housing Market:** Track scraper maintenance, data analysis tasks
- **PredictZ:** Create tasks for new betting markets, analysis tools
- **Last.fm:** Task music curator improvements, recommendation tweaks

---

## Tech Stack

- **Frontend:** Next.js 14.2.21, React, Tailwind CSS
- **Database:** SQLite
- **Backend:** Next.js API routes
- **WebSocket:** OpenClaw Gateway integration
- **Runtime:** Node.js 22.22.0

---

## Next Steps

- [ ] Set up systemd service for auto-restart
- [ ] Configure nginx reverse proxy for HTTPS
- [ ] Test with existing agents (main, music-curator)
- [ ] Create first real task to test workflow
- [ ] Document best practices for task creation
- [ ] Set up backup for SQLite database

---

## Resources

- **GitHub:** https://github.com/crshdn/mission-control
- **Live Demo:** https://missioncontrol.ghray.com
- **Documentation:** https://github.com/crshdn/mission-control/blob/main/README.md
- **OpenClaw:** https://github.com/openclaw/openclaw

---

**Last Updated:** 2026-02-28
