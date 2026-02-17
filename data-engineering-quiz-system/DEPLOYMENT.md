# Deployment Guide

## Prerequisites

- Docker and Docker Compose installed
- Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- OpenAI API Key (for LLM question generation)
- Domain name (for webhook) or use ngrok for local development

## Quick Start (Local Development)

### 1. Clone and Setup

```bash
# Clone repository (or navigate to the workspace)
cd /root/.openclaw/workspace/data-engineering-quiz-system

# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

### 2. Configure Environment Variables

Required variables in `.env`:

```bash
# Telegram Bot Token (required)
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

# OpenAI API Key (required for LLM questions)
OPENAI_API_KEY=sk-...

# For local development, you can use ngrok:
# 1. Run: ngrok http 8080
# 2. Use the ngrok URL for WEBHOOK_URL
WEBHOOK_URL=https://abc123.ngrok.io

# Mode
QUIZ_MODE=development
```

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f quiz-bot

# Check all services
docker-compose ps
```

### 4. Set Up Telegram Webhook

The bot will automatically set up the webhook when it starts. Verify:

```bash
# Check webhook status (replace BOT_TOKEN)
curl https://api.telegram.org/bot<BOT_TOKEN>/getWebhookInfo
```

### 5. Access Services

- **Prefect UI**: http://localhost:4200
- **PgAdmin**: http://localhost:5050 (if using admin profile)
- **Health Check**: http://localhost:8080/health

### 6. Deploy Prefect Flows

```bash
# Enter the quiz-bot container
docker-compose exec quiz-bot bash

# Deploy the daily quiz distribution flow
python -c "
from prefect import flow
from main import distribute_daily_quizzes
from prefect.deployments import DeploymentSpec
from prefect.orion.schemas.schedules import CronSchedule
from datetime import timezone, timedelta

deployment = distribute_daily_quizzes.deploy(
    name='daily-quiz-production',
    work_queue_name='quiz-work-queue',
    schedule=CronSchedule(cron='0 10 * * *', timezone='UTC'),
    tags=['production', 'daily']
)
"
```

## Production Deployment

### Option 1: Self-Hosted with Docker Compose

```bash
# 1. Prepare production .env
cp .env.example .env.production
nano .env.production

# Update critical variables:
QUIZ_MODE=production
WEBHOOK_URL=https://quiz.yourdomain.com
POSTGRES_PASSWORD=<strong_password>
TELEGRAM_BOT_TOKEN=<your_bot_token>
OPENAI_API_KEY=<your_key>

# 2. Start with production compose file
docker-compose -f docker-compose.yml --env-file .env.production up -d

# 3. Set up reverse proxy (nginx example below)
```

### Option 2: Cloud Deployment (AWS/GCP/Azure)

#### AWS Architecture

```
┌─────────────────────────────────────────────┐
│            Application Load Balancer        │
│              (SSL Termination)              │
└───────────────────┬─────────────────────────┘
                    │
        ┌───────────┼───────────┐
        ▼                       ▼
┌──────────────┐      ┌────────────────┐
│   ECS Fargate │      │  EC2 Instance  │
│  (Quiz Bot)  │      │ (Prefect)      │
└──────┬───────┘      └────────────────┘
       │                      │
       └──────────┬───────────┘
                  ▼
         ┌────────────────┐
         │   RDS Aurora  │
         │   PostgreSQL   │
         └────────────────┘
```

#### AWS Deployment Steps

1. **Create VPC and Security Groups**
```bash
# Create VPC with private/public subnets
# Security groups allow:
# - ALB → ECS (port 8080)
# - ECS → RDS (port 5432)
# - ECS → Redis (port 6379)
```

2. **Create RDS PostgreSQL**
```bash
aws rds create-db-instance \
  --db-instance-identifier quiz-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --allocated-storage 20
```

3. **Create ECS Task Definition**

```json
{
  "family": "quiz-bot",
  "containerDefinitions": [
    {
      "name": "quiz-bot",
      "image": "your-ecr-repo/quiz-bot:latest",
      "memory": 512,
      "cpu": 256,
      "environment": [
        {
          "name": "DATABASE_URL",
          "value": "postgresql://user:pass@quiz-db.xxxx.us-east-1.rds.amazonaws.com:5432/quiz_db"
        },
        {
          "name": "WEBHOOK_URL",
          "value": "https://quiz.yourdomain.com"
        }
      ],
      "secrets": [
        {
          "name": "TELEGRAM_BOT_TOKEN",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:quiz-bot-token"
        }
      ],
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
```

4. **Create ECS Service with Load Balancer**
```bash
aws ecs create-service \
  --cluster quiz-cluster \
  --service-name quiz-service \
  --task-definition quiz-bot \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "..."
```

### Option 3: Kubernetes (Helm Chart)

```yaml
# values.yaml
replicaCount: 2

image:
  repository: your-registry/quiz-bot
  tag: latest

env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: quiz-secrets
        key: database-url
  - name: TELEGRAM_BOT_TOKEN
    valueFrom:
      secretKeyRef:
        name: quiz-secrets
        key: telegram-bot-token

service:
  type: LoadBalancer
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  hosts:
    - host: quiz.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: quiz-tls
      hosts:
        - quiz.yourdomain.com

postgresql:
  enabled: true
  auth:
    password: <strong-password>

redis:
  enabled: true
  architecture: standalone
```

```bash
# Deploy with Helm
helm repo add your-repo https://charts.yourdomain.com
helm install quiz-system your-repo/quiz-bot -f values.yaml
```

## Nginx Reverse Proxy Configuration

```nginx
# /etc/nginx/sites-available/quiz-system
upstream quiz_bot {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name quiz.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name quiz.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/quiz.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/quiz.yourdomain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Quiz bot webhook endpoint
    location /webhook {
        proxy_pass http://quiz_bot;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://quiz_bot;
        access_log off;
    }

    # Prefect webhook for answer processing
    location /api/webhooks/quiz-answer {
        proxy_pass http://quiz_bot;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Monitoring and Alerting

### Prometheus Metrics

```python
# Add to main.py
from prometheus_client import Counter, Histogram, start_http_server

quiz_questions_sent = Counter('quiz_questions_sent', 'Total questions sent')
quiz_answers_received = Counter('quiz_answers_received', 'Total answers received')
quiz_duration = Histogram('quiz_duration_seconds', 'Time to answer question')

@app.on_event('startup')
async def start_metrics():
    start_http_server(9090)
```

### CloudWatch Alarms (AWS)

```bash
# Create alarm for failed question deliveries
aws cloudwatch put-metric-alarm \
  --alarm-name quiz-failed-deliveries \
  --alarm-description "Alert on failed quiz deliveries" \
  --metric-name FailedDeliveries \
  --namespace QuizSystem \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### Grafana Dashboard

Import a dashboard showing:
- Questions sent per day
- Response rate
- Accuracy by topic
- Difficulty distribution
- Streak statistics

## Backup Strategy

### PostgreSQL Backup

```bash
# Daily backup script (cron)
#!/bin/bash
BACKUP_DIR="/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)

pg_dump -h localhost -U quiz_user quiz_db | gzip > $BACKUP_DIR/quiz_db_$DATE.sql.gz

# Retain last 7 days
find $BACKUP_DIR -name "quiz_db_*.sql.gz" -mtime +7 -delete
```

### Point-in-Time Recovery

```bash
# Enable WAL archiving in postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'
```

## Troubleshooting

### Issue: Telegram Webhook Not Working

```bash
# Check webhook info
curl https://api.telegram.org/bot<BOT_TOKEN>/getWebhookInfo

# Delete webhook
curl https://api.telegram.org/bot<BOT_TOKEN>/deleteWebhook

# Set webhook manually
curl -X POST "https://api.telegram.org/bot<BOT_TOKEN>/setWebhook" \
  -d "url=https://your-domain.com/webhook"
```

### Issue: Prefect Flows Not Running

```bash
# Check agent is connected
docker-compose logs prefect-agent

# Check work queue
docker-compose exec prefect-agent prefect work-queue inspect quiz-work-queue

# Manually trigger a flow
curl -X POST "http://localhost:4200/api/flows/flow-id/run" \
  -H "Content-Type: application/json"
```

### Issue: Database Connection Errors

```bash
# Check postgres health
docker-compose exec postgres pg_isready

# Check connection from bot
docker-compose exec quiz-bot python -c "
import asyncpg
import asyncio

async def test():
    conn = await asyncpg.connect('postgresql://quiz_user:quiz_password@postgres:5432/quiz_db')
    print('Connected!')
    await conn.close()

asyncio.run(test())
"
```

### Issue: Questions Not Being Generated

```bash
# Check static question bank
docker-compose exec postgres psql -U quiz_user -d quiz_db -c "
SELECT difficulty_level, topic, COUNT(*) 
FROM questions 
GROUP BY difficulty_level, topic;
"

# Check OpenAI API key is valid
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Store secrets in environment variables or secret manager (not in code)
- [ ] Enable SSL/TLS for all external connections
- [ ] Restrict database access to application containers only
- [ ] Use separate database user with minimal privileges
- [ ] Enable rate limiting on webhook endpoints
- [ ] Set up API key rotation schedule
- [ ] Enable audit logging for all sensitive operations
- [ ] Regular security updates for all containers
- [ ] Network segmentation (database in private subnet)
