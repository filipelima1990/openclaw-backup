# Sessions Breakdown: Visual Summary

**Date:** 2026-03-01

---

## Storage by Category

```
Total: 51 MB
┌─────────────────────────────────────────────────┐
│                                         │
│  Active Sessions (1.2 MB)                │
│  ■■■■■■■  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│                                         │
│  Stale Sessions (1 MB)                   │
│  ■■■■  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│                                         │
│  Deleted Files (30 MB)                    │
│  ■■■■■■■■■■■■■■■■■■■■■■■■■■  ▓  │
│                                         │
│  Reset Files (19 MB)                      │
│  ■■■■■■■■■■■■■■■■■■■■■  ▓▓▓   │
│                                         │
└─────────────────────────────────────────────────┘

Legend:
■ = Files currently in directory
▓ = Space that can be reclaimed
```

---

## Sessions by Age

```
│ Today (Mar 1)       │
│ ■■■■■■■■■■■ (1.8 MB)     │  Active & recent
│                               │
│ Yesterday (Feb 28)     │
│ ■■■■■ (212 KB)             │  Recent, keep
│                               │
│ Feb 24-27              │
│ ■■■■■ (1 MB)                │  Stale, can delete
│                               │
│ Feb 20-22              │
│ ■■■■■■■ (many small files)  │  Old, can delete
│                               │
│ Before Feb 20           │
│ ■■■■■■ (many old files)     │  Very old, delete
│                               │
└──────────────────────────────────┘
```

---

## Top 10 Largest Files

| # | File | Size | Type | Action |
|---|-------|------|--------|
| 1 | `a67f7472-2fd1-4e86-abee-63777d000a3e.jsonl.reset.*` | 1.7 MB | Reset | 🔴 Delete |
| 2 | `6803da99-a05b-4bca-99e9-69786750526f.jsonl.deleted.*` | 1.7 MB | Deleted | 🔴 Delete |
| 3 | `d49c561f-cc83-4943-aff1-fb1814d30aca.jsonl.deleted.*` | 1.4 MB | Deleted | 🔴 Delete |
| 4 | `283c4f21-0cf2-46ea-bec2-914e04fa080d.jsonl.reset.*` | 1.4 MB | Reset | 🔴 Delete |
| 5 | `5194362a-f38d-4120-8a9d-6c228e057b32.jsonl.reset.*` | 1.3 MB | Reset | 🔴 Delete |
| 6 | `1c12a46f-6e28-4eb5-8259-41fffd2b1e8c.jsonl.reset.*` | 1.3 MB | Reset | 🔴 Delete |
| 7 | `8f05138e-e545-4b9d-bb90-65a32c331f6f.jsonl.deleted.*` | 1.2 MB | Deleted | 🔴 Delete |
| 8 | `ee242086-126b-4e91-b3eb-79047e6080ce.jsonl.deleted.*` | 1.1 MB | Deleted | 🔴 Delete |
| 9 | `77bba73c-d3ef-4a05-aa7d-46ffc03593db.jsonl.reset.*` | 1.1 MB | Reset | 🔴 Delete |
| 10 | `4b6b5c06-7b17-4bf4-abc7-4a334a10d1ab.jsonl.reset.*` | 1.1 MB | Reset | 🔴 Delete |

**Top 10 files total:** 14.4 MB (can reclaim)

---

## Files by Status

```
Keep (Safe)
├─ Active sessions: 9 files, 1.2 MB
├─ Recent sessions: 5 files, 540 KB
└─ Music curator: 1 file, 4 KB
   Total: 15 files, 1.7 MB

Delete (Safe)
├─ Stale sessions: 2 files, 1 MB
├─ Deleted files: ~50 files, 30 MB
└─ Reset files: ~45 files, 19 MB
   Total: 97 files, 50 MB

Grand Total: 112 files, 51.7 MB
```

---

## Cleanup Impact Comparison

```
Before Cleanup: 51 MB  ■■■■■■■■■■■■■■■■■■■■■■■■■

Conservative: 49 MB   ■■■■■■■■■■■■■■■■■■■■■■■■  (reclaim 2 MB)

Aggressive:   36 MB   ■■■■■■■■■■■■■■■■■■■           (reclaim 15 MB)

Full:         7 MB   ■■■■■■■                         (reclaim 44 MB)
```

---

## Agent Breakdown

```
Main Agent
├─ Sessions: 9 files, 1.2 MB
├─ Deleted: 52 files, 30 MB
└─ Reset:   41 files, 19 MB
   Total: 102 files, 50 MB

Music Curator
├─ Sessions: 1 file, 4 KB
├─ Deleted: 1 file, 41 KB
└─ Reset:   0 files, 0 KB
   Total: 2 files, 45 KB

Quiz Master
└─ Sessions: 0 files (empty)
   Total: 0 files
```

---

## Timeline of Sessions

```
Feb  1  Feb  8  Feb 15  Feb 22  Mar  1
  │         │         │         │         │
  ├─────────────────────────────────┤
  │  Old deleted/reset files      │
  │  (20-30 files, 25 MB)      │
  │                            │
  ├─────────────────────┤        │
  │  Recent sessions (Feb 20-27) │
  │  (2 files, 1 MB)            │
  │                            │
  ├─────────────┤               │
  │  Yesterday (Feb 28)         │
  │  (5 files, 212 KB)          │
  │                            │
  └──────────┤                 │
  │  Today (Mar 1)            │
  │  (3 files, 1.8 MB)       │
  │                            │
```

---

## Action Summary

| Category | Count | Size | Action |
|----------|--------|-------|--------|
| **Keep** | 15 | 1.7 MB | ✅ No action |
| **Delete Now** | 50 | 15 MB | 🔴 Conservative cleanup |
| **Delete Later** | 47 | 35 MB | ⚠️ Aggressive cleanup |
| **Total** | 112 | 51.7 MB | - |

---

**Visual Summary Generated:** 2026-03-01 01:15 UTC
**Based on:** OpenClaw sessions analysis
