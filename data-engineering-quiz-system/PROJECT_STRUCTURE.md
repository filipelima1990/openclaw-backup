# Project Structure

```
data-engineering-quiz-system/
├── README.md                    # Complete design document (main reference)
├── QUICKSTART.md                # 10-minute setup guide
├── DEPLOYMENT.md                # Production deployment guide
├── PROJECT_STRUCTURE.md         # This file
├── requirements.txt            # Python dependencies
├── Dockerfile                   # Container image build
├── docker-compose.yml           # Local development compose file
├── .env.example                 # Environment variables template
├── schema.sql                   # Database schema + seed data
│
├── main.py                      # Application entry point (to be created)
├── repository.py                # Database repository layer (to be created)
├── quiz_generator.py            # Question generation logic (to be created)
├── telegram_bot.py              # Telegram bot integration (to be created)
├── difficulty_adapter.py        # Adaptive algorithm (to be created)
├── prefect_flows.py             # Prefect flow definitions (to be created)
│
└── tests/                       # Test suite (to be created)
    ├── test_difficulty.py       # Unit tests for adaptive algorithm
    ├── test_generator.py       # Unit tests for question generation
    └── test_integration.py      # End-to-end integration tests
```

## File Descriptions

### Documentation Files

| File | Purpose | Target Audience |
|------|---------|-----------------|
| `README.md` | Complete system design, architecture, and implementation details | Data Engineers, System Architects |
| `QUICKSTART.md` | Get the system running in 10 minutes | Developers, Anyone testing the system |
| `DEPLOYMENT.md` | Production deployment on various platforms | DevOps Engineers, SREs |
| `PROJECT_STRUCTURE.md` | Project organization and file descriptions | Anyone navigating the codebase |

### Configuration Files

| File | Purpose | Notes |
|------|---------|-------|
| `requirements.txt` | Python package dependencies | Pin versions for reproducibility |
| `Dockerfile` | Container image build | Multi-stage build for optimization |
| `docker-compose.yml` | Local development environment | Includes all required services |
| `.env.example` | Environment variables template | Copy to `.env` and configure |
| `schema.sql` | Database schema + seed data | Runs automatically on first start |

### Source Files (To Be Created)

| File | Purpose | Key Functions |
|------|---------|----------------|
| `main.py` | Application entry point | `main()`, health endpoint |
| `repository.py` | Database access layer | `get_user_state()`, `persist_answer()`, etc. |
| `quiz_generator.py` | Question generation | `generate_question()`, `_get_static_question()`, `_generate_llm_question()` |
| `telegram_bot.py` | Telegram integration | `send_question()`, `handle_answer()`, `send_feedback()` |
| `difficulty_adapter.py` | Adaptive algorithm | `calculate_adaptation()` |
| `prefect_flows.py` | Prefect orchestration | `distribute_daily_quizzes()`, `execute_user_quiz_flow()` |

## Key Design Patterns Used

### 1. Repository Pattern (`repository.py`)
- Abstract database operations behind a clean interface
- Easy to mock for testing
- Centralizes SQL queries

### 2. Factory Pattern (`quiz_generator.py`)
- QuestionGenerator creates questions based on difficulty
- Supports multiple sources (static, LLM)
- Fallback mechanism for reliability

### 3. State Machine (`difficulty_adapter.py`)
- Clear state transitions for difficulty levels
- Explicit rules for streak changes
- Predictable behavior

### 4. Task/Flow Pattern (`prefect_flows.py`)
- Decomposed into reusable tasks
- Each task can retry independently
- Clear dependency graph

### 5. Strategy Pattern (Question Generation)
- Switch between static and LLM generation
- Easy to add new question sources
- Fallback strategy built in

## Data Flow

```
User (Telegram)
    ↓
[Webhook] → Telegram Bot → Database (store answer)
    ↓
[Prefect Flow Trigger] → retrieve user state
    ↓
[Generate Question] → Question Generator (static or LLM)
    ↓
[Send Question] → Telegram Bot → User
    ↓
User answers → [Webhook] → Database (store answer)
    ↓
[Prefect Flow] → validate answer → adapt difficulty → update state
    ↓
[Send Feedback] → Telegram Bot → User
```

## Scaling Considerations

### Horizontal Scaling

- **Bot**: Multiple instances behind load balancer
- **Prefect Agents**: Multiple agents processing flows
- **Database**: Read replicas for analytics queries
- **Redis**: Redis Cluster for high availability

### Vertical Scaling

- Increase Docker container resources (CPU, memory)
- Scale PostgreSQL instance size
- Upgrade Prefect server resources

### Bottlenecks

| Component | Potential Bottleneck | Mitigation |
|-----------|---------------------|------------|
| PostgreSQL | Connection pool exhaustion | Use pgBouncer |
| Redis | Memory pressure for large caches | Configure eviction policy |
| Telegram Bot | Rate limiting (30 msg/sec) | Distribute users across bots |
| OpenAI API | Rate limits (RPM) | Cache questions, use static bank |
| Prefect | Flow queue backlog | Scale agents horizontally |

## Security Considerations

### Secrets Management

| Secret | Storage Method |
|--------|----------------|
| Telegram Bot Token | Environment variable / AWS Secrets Manager |
| OpenAI API Key | Environment variable / AWS Secrets Manager |
| Database Password | Environment variable / AWS Secrets Manager |
| Prefect API Key | Environment variable |

### Network Security

- PostgreSQL in private subnet (production)
- Redis with AUTH enabled
- Webhook endpoints behind reverse proxy
- TLS/SSL for all external connections

### Data Privacy

- No PII stored (only Telegram user ID)
- Answers stored for analytics only
- Option to opt out of daily quizzes

## Testing Strategy

### Unit Tests
- `test_difficulty.py`: Test all difficulty adaptation logic
- `test_generator.py`: Test question generation algorithms
- `test_repository.py`: Test database operations

### Integration Tests
- `test_integration.py`: Full flow test (question → answer → feedback)
- Test database transactions
- Test webhook handling

### Load Tests
- Simulate 1000 concurrent users
- Test webhook response time
- Verify database performance under load

## Monitoring Stack

### Metrics
- Prefect: Flow success/failure rates, task duration
- Application: Questions sent, answers received, accuracy
- Database: Connection pool, query latency
- System: CPU, memory, disk usage

### Logging
- Structured JSON logs
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Centralized logging (ELK stack, CloudWatch)

### Tracing
- Distributed tracing (optional)
- Trace question delivery through all components
- Identify performance bottlenecks

## Development Workflow

```bash
# 1. Make changes
vim main.py

# 2. Run tests
pytest tests/

# 3. Build and run locally
docker-compose up --build

# 4. Test manually
# Send /start to your bot

# 5. Check logs
docker-compose logs -f quiz-bot

# 6. Deploy to staging
git push staging
# CI/CD builds and deploys

# 7. Test staging
# Prefect UI: http://staging.example.com:4200
# Bot: @quiz_test_bot

# 8. Deploy to production
git push production
```

## CI/CD Pipeline (Suggested)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest tests/
      - name: Build Docker image
        run: docker build -t quiz-bot:latest .
```

```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: |
          # Your deployment logic
          # e.g., AWS ECS update, Kubernetes rollout
```

## Getting Help

- **Documentation**: Check `README.md` for detailed design
- **Quick Issues**: Check `QUICKSTART.md` troubleshooting section
- **Deployment**: Check `DEPLOYMENT.md` for production issues
- **Logs**: `docker-compose logs -f quiz-bot`
- **Prefect UI**: Monitor flow runs and task logs

## Contributing

1. Create feature branch
2. Make changes and add tests
3. Ensure all tests pass
4. Update documentation if needed
5. Submit pull request

## License

[Specify your license here]
