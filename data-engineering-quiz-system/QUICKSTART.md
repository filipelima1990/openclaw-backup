# Quick Start Guide

Get the Data Engineering Quiz System running in 10 minutes!

## Prerequisites Check

```bash
# Verify Docker is installed
docker --version
docker-compose --version

# You should see versions like:
# Docker version 24.0.x
# Docker Compose version v2.x.x
```

## Step 1: Get a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Copy your bot token (looks like `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)

## Step 2: Get an OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up/log in
3. Navigate to API Keys section
4. Create a new secret key
5. Copy it (starts with `sk-`)

## Step 3: Configure Environment

```bash
cd /root/.openclaw/workspace/data-engineering-quiz-system

# Copy the example env file
cp .env.example .env

# Edit it with your credentials
nano .env
```

Update these three **required** variables:

```bash
TELEGRAM_BOT_TOKEN=your_bot_token_from_step_1
OPENAI_API_KEY=your_api_key_from_step_2
WEBHOOK_URL=https://your-domain.com  # Or use ngrok (see Step 4)
```

## Step 4: Set Up Webhook URL

### Option A: Using ngrok (Recommended for testing)

```bash
# Install ngrok (if not already)
# On Ubuntu: apt install ngrok
# Or download from https://ngrok.com/download

# In one terminal, run ngrok
ngrok http 8080

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
# Update .env with: WEBHOOK_URL=https://abc123.ngrok.io
```

### Option B: Using a real domain

```bash
# Update .env with your domain
WEBHOOK_URL=https://quiz.yourdomain.com
```

## Step 5: Start the System

```bash
# Start all services
docker-compose up -d

# Wait for services to be healthy (about 30 seconds)
docker-compose ps

# You should see all services as "Up (healthy)"
```

## Step 6: Verify Everything Works

```bash
# Check the bot is running
docker-compose logs quiz-bot | tail -20

# You should see something like:
# INFO:quiz-bot:✅ Database initialized
# INFO:quiz-bot:🚀 Starting quiz system...
# INFO:quiz-bot:Telegram webhook started on port 8080
```

## Step 7: Test the Bot

1. Open Telegram and search for your bot (the username you created with BotFather)
2. Send `/start` to the bot
3. You should receive a welcome message

### Optional: Manually Trigger a Quiz

```bash
# Enter the bot container
docker-compose exec quiz-bot bash

# Run a test flow
python -c "
from main import test_quiz_flow
import asyncio
asyncio.run(test_quiz_flow('your_telegram_user_id'))
"
```

To find your Telegram user ID:
1. Open https://t.me/userinfobot
2. Send any message
3. It will reply with your user ID

## Access the Web Interfaces

- **Prefect UI**: http://localhost:4200
  - Monitor flow runs
  - Check task logs
  - View metrics and artifacts

- **PgAdmin** (optional): http://localhost:5050
  - Database management interface
  - Email: `admin@example.com`
  - Password: `admin`

- **Health Check**: http://localhost:8080/health
  - Returns `{"status": "healthy"}` if running

## Common Commands

```bash
# View logs in real-time
docker-compose logs -f quiz-bot

# Restart the bot
docker-compose restart quiz-bot

# Stop everything
docker-compose down

# Stop and remove volumes (deletes all data!)
docker-compose down -v

# Update the bot code and restart
docker-compose up -d --build quiz-bot

# Check database
docker-compose exec postgres psql -U quiz_user -d quiz_db -c "\dt"
```

## Troubleshooting

### Bot doesn't respond

```bash
# Check if webhook is set correctly
curl https://api.telegram.org/bot<YOUR_TOKEN>/getWebhookInfo

# It should show your webhook URL
# If not, the bot will auto-set it on startup
```

### Database errors

```bash
# Check if postgres is healthy
docker-compose ps postgres

# Check postgres logs
docker-compose logs postgres

# Try connecting manually
docker-compose exec postgres psql -U quiz_user -d quiz_db
```

### Questions not being generated

```bash
# Check if there are questions in the database
docker-compose exec postgres psql -U quiz_user -d quiz_db -c "
SELECT difficulty_level, COUNT(*) FROM questions GROUP BY difficulty_level;
"

# Check OpenAI API key is valid
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

## Next Steps

1. **Deploy the daily quiz flow** in Prefect UI
2. **Add more users** - they just need to `/start` the bot
3. **Monitor progress** via Prefect UI and analytics views
4. **Customize question bank** - add your own questions to `schema.sql`

For full deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Questions?

- Check the logs: `docker-compose logs -f quiz-bot`
- Review the main README: [README.md](./README.md)
- Check Prefect flow status in the UI: http://localhost:4200

---

**Estimated time**: 10 minutes (after getting API keys)

**System components running**:
- ✅ PostgreSQL (quiz database)
- ✅ Redis (caching)
- ✅ Prefect Server (orchestration)
- ✅ Prefect Agent (flow execution)
- ✅ Quiz Bot (Telegram integration)
