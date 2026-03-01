#!/bin/bash
#
# OpenClaw Sessions Cleanup Script
# Safely removes old/deleted/reset session files
#
# Usage:
#   cleanup_sessions.sh --dry-run     # Preview deletions (safe)
#   cleanup_sessions.sh                # Conservative cleanup (recommended)
#   cleanup_sessions.sh --aggressive   # Delete more old files
#   cleanup_sessions.sh --full         # Maximum cleanup (keep only active)
#
# Author: Billie (OpenClaw AI Assistant)
# Date: 2026-03-01
#

set -e

# Configuration
MAIN_SESSIONS_DIR="/root/.openclaw/agents/main/sessions"
ACTIVE_SESSION="969973b9-afb6-43e6-a3e6-273e9b440a08.jsonl"
DRY_RUN=false
AGGRESSIVE=false
FULL_CLEANUP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      ;;
    --aggressive)
      AGGRESSIVE=true
      ;;
    --full)
      FULL_CLEANUP=true
      ;;
    --help)
      echo "Usage: $0 [--dry-run] [--aggressive] [--full]"
      echo ""
      echo "Options:"
      echo "  --dry-run    Preview deletions without executing"
      echo "  --aggressive Delete more old files (10-15 MB reclaimed)"
      echo "  --full        Delete everything except active session (40-45 MB reclaimed)"
      echo ""
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=== OpenClaw Sessions Cleanup ===${NC}"
echo ""

# Verify we're in the right directory
if [ ! -d "$MAIN_SESSIONS_DIR" ]; then
  echo -e "${RED}Error: Sessions directory not found: $MAIN_SESSIONS_DIR${NC}"
  exit 1
fi

cd "$MAIN_SESSIONS_DIR"

# Function to calculate size of files matching pattern
calculate_size() {
  find . -maxdepth 1 -name "$1" -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1
}

# Function to delete files
delete_files() {
  local pattern="$1"
  local description="$2"
  local size=$(calculate_size "$pattern")

  if [ -z "$size" ] || [ "$size" = "0" ]; then
    echo -e "${YELLOW}No files matching: $pattern${NC}"
    return
  fi

  echo -e "${BLUE}Deleting: $description${NC}"
  echo "  Pattern: $pattern"
  echo "  Size: $size"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete files matching: $pattern${NC}"
    echo ""
  else
    find . -maxdepth 1 -name "$pattern" -delete
    echo -e "${GREEN}✓ Deleted${NC}"
    echo ""
  fi
}

# Active session check
echo -e "${BLUE}Active session:${NC} $ACTIVE_SESSION"
echo ""

if [ "$FULL_CLEANUP" = true ]; then
  echo -e "${YELLOW}=== FULL CLEANUP MODE ===${NC}"
  echo -e "${RED}WARNING: This will delete everything except the active session!${NC}"
  echo ""

  # Delete all JSONL files except active session
  size=$(find . -maxdepth 1 -name "*.jsonl" ! -name "$ACTIVE_SESSION" -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
  echo -e "${BLUE}Deleting all sessions except active${NC}"
  echo "  Size: $size"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete all *.jsonl files except $ACTIVE_SESSION${NC}"
  else
    find . -maxdepth 1 -name "*.jsonl" ! -name "$ACTIVE_SESSION" -delete
    echo -e "${GREEN}✓ Deleted${NC}"
  fi

  echo ""

elif [ "$AGGRESSIVE" = true ]; then
  echo -e "${YELLOW}=== AGGRESSIVE CLEANUP MODE ===${NC}"
  echo ""

  # Delete all deleted/reset files
  delete_files "*.deleted.*" "Deleted session files"
  delete_files "*.reset.*" "Reset session files"

  # Delete old sessions (> 2 days)
  echo -e "${BLUE}Deleting old sessions (> 2 days)${NC}"
  size=$(find . -maxdepth 1 -name "*.jsonl" -mtime +2 ! -name "$ACTIVE_SESSION" -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
  echo "  Size: $size"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete sessions older than 2 days${NC}"
  else
    find . -maxdepth 1 -name "*.jsonl" -mtime +2 ! -name "$ACTIVE_SESSION" -delete
    echo -e "${GREEN}✓ Deleted${NC}"
  fi

  echo ""

else
  echo -e "${GREEN}=== CONSERVATIVE CLEANUP MODE (Recommended) ===${NC}"
  echo ""

  # Delete large deleted/reset files (> 1MB)
  echo -e "${BLUE}Deleting large deleted/reset files (> 1MB)${NC}"
  deleted_size=$(find . -maxdepth 1 -name "*.deleted.*" -size +1M -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1 || echo "0B")
  reset_size=$(find . -maxdepth 1 -name "*.reset.*" -size +1M -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1 || echo "0B")
  echo "  Deleted files: $deleted_size"
  echo "  Reset files: $reset_size"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete large deleted/reset files${NC}"
  else
    find . -maxdepth 1 -name "*.deleted.*" -size +1M -delete
    find . -maxdepth 1 -name "*.reset.*" -size +1M -delete
    echo -e "${GREEN}✓ Deleted${NC}"
  fi

  echo ""

  # Delete old deleted/reset files (> 30 days)
  echo -e "${BLUE}Deleting old deleted/reset files (> 30 days)${NC}"
  old_deleted=$(find . -maxdepth 1 -name "*.deleted.*" -mtime +30 -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1 || echo "0B")
  old_reset=$(find . -maxdepth 1 -name "*.reset.*" -mtime +30 -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1 || echo "0B")
  echo "  Deleted files: $old_deleted"
  echo "  Reset files: $old_reset"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete old deleted/reset files${NC}"
  else
    find . -maxdepth 1 -name "*.deleted.*" -mtime +30 -delete
    find . -maxdepth 1 -name "*.reset.*" -mtime +30 -delete
    echo -e "${GREEN}✓ Deleted${NC}"
  fi

  echo ""

  # Delete old sessions (> 5 days)
  echo -e "${BLUE}Deleting old sessions (> 5 days)${NC}"
  size=$(find . -maxdepth 1 -name "*.jsonl" -mtime +5 ! -name "$ACTIVE_SESSION" -exec du -ch {} + 2>/dev/null | tail -n 1 | cut -f1)
  echo "  Size: $size"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would delete sessions older than 5 days${NC}"
  else
    find . -maxdepth 1 -name "*.jsonl" -mtime +5 ! -name "$ACTIVE_SESSION" -delete
    echo -e "${GREEN}✓ Deleted${NC}"
  fi

  echo ""
fi

# Show summary
echo -e "${BLUE}=== Summary ===${NC}"
total_before=$(du -sh . 2>/dev/null | cut -f1)
echo "Current directory size: $total_before"

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a DRY RUN. No files were deleted.${NC}"
  echo ""
  echo -e "${GREEN}To execute cleanup, run:${NC}"
  echo "  $0"
else
  echo -e "${GREEN}Cleanup complete!${NC}"
  echo ""
  echo -e "${YELLOW}Verify Mission Control is working correctly before continuing.${NC}"
fi

echo ""
echo -e "${BLUE}Active session files:${NC}"
find . -maxdepth 1 -name "*.jsonl" -exec ls -lh {} \; 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo -e "${BLUE}Deleted/Reset files remaining:${NC}"
remaining_deleted=$(find . -maxdepth 1 -name "*.deleted.*" | wc -l)
remaining_reset=$(find . -maxdepth 1 -name "*.reset.*" | wc -l)
echo "  Deleted files: $remaining_deleted"
echo "  Reset files: $remaining_reset"

exit 0
