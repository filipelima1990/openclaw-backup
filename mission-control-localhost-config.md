# Mission Control - Localhost Configuration

**Date:** 2026-02-27
**Access Mode:** Localhost only (no public IP)

## Access URLs

- **Frontend:** http://localhost:3001
- **Backend:** http://localhost:8001
- **Health Check:** http://localhost:8001/healthz

## Authentication Token

```
c277144553b1c089efe380b48fc52d9a61ce07c18a2d5f1bb4714c2e5455c143
```

## Configuration Changes

All URLs changed from public IP (167.235.68.81) to localhost:

### Frontend (.env)
```env
NEXT_PUBLIC_API_URL=http://localhost:8001
```

### Backend (.env)
```env
CORS_ORIGINS=http://localhost:3001,http://127.0.0.1:3001
BASE_URL=http://localhost:8001
```

### Root (.env)
```env
FRONTEND_PORT=3001
BACKEND_PORT=8001
NEXT_PUBLIC_API_URL=http://localhost:8001
```

## Services Running

- Backend: uvicorn on port 8001
- Frontend: Next.js on port 3001
- Database: PostgreSQL on port 5432 (existing)

## How to Use

1. Open browser to: http://localhost:3001
2. Paste auth token: `c277144553b1c089efe380b48fc52d9a61ce07c18a2d5f1bb4714c2e5455c143`
3. Click "Sign In"

## Logs

- Backend: `/var/log/mission-control-backend.log`
- Frontend: `/var/log/mission-control-frontend.log`
