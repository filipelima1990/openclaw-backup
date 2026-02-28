# Mission Control - Current Status

**Last Updated:** 2026-02-27 17:35 UTC

## Configuration

**Access Mode:** Localhost only
**Frontend Mode:** Development (reads .env directly)
**Backend Mode:** Production (uvicorn)

## Access URLs

- **Frontend:** http://localhost:3001
- **Backend:** http://localhost:8001
- **Health Check:** http://localhost:8001/healthz

## Environment Variables

### Frontend (.env)
```
NEXT_PUBLIC_API_URL=http://localhost:8001
NEXT_PUBLIC_AUTH_MODE=local
```

### Backend (.env)
```
CORS_ORIGINS=http://167.235.68.81:3001,http://localhost:3001,http://127.0.0.1:3001
BASE_URL=http://localhost:8001
AUTH_MODE=local
LOCAL_AUTH_TOKEN=c277144553b1c089efe380b48fc52d9a61ce07c18a2d5f1bb4714c2e5455c143
```

## Services Running

| Service | Port | Process | Status |
|---------|------|---------|--------|
| Frontend | 3001 | Next.js dev (Turbopack) | ✅ Running |
| Backend | 8001 | uvicorn | ✅ Running |
| Database | 5432 | PostgreSQL | ✅ Healthy |

## Authentication Token

```
c277144553b1c089efe380b48fc52d9a61ce07c18a2d5f1bb4714c2e5455c143
```

## How to Use

1. Open browser to: http://localhost:3001
2. Paste the auth token above
3. Click "Sign In"

## Troubleshooting

If you still get "Unable to reach backend to validate token":

1. Open browser Developer Console (F12)
2. Go to the "Console" tab
3. Paste the exact error message here

The most likely causes:
- Network connectivity issue between browser and backend
- CORS configuration issue
- Frontend not reading updated environment variables

## Logs

- Backend: `/var/log/mission-control-backend.log`
- Frontend: `/var/log/mission-control-frontend.log`
