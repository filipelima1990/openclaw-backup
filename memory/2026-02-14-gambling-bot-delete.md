# 2026-02-14 - Gambling Bot: Add /delete Command

**Time:** 2026-02-14 16:51 UTC

## Request

User asked: "When I meant 'exclude' I was talking about a functionality to remove a transaction that was recorded incorrectly"

## Implementation

Added `/delete` command with confirmation workflow to safely remove incorrectly recorded transactions.

### Command Flow

**Two-step process for safety:**
1. `/delete <number>` - Shows transaction details and asks for confirmation
2. `/confirm_delete <number>` - Confirms and deletes the transaction
3. `/cancel` - Cancels a pending deletion

### Usage

```bash
/last              # See transaction numbers
/delete 5            # Delete transaction #5
/confirm_delete 5     # Confirm deletion of #5
/cancel               # Cancel pending deletion
```

### Features

**Safety confirmation:**
- `/delete` shows the full transaction before asking for confirmation
- Transaction shows number, type, amount, details (result/odds/market), and timestamp
- Must confirm with `/confirm_delete` to actually delete
- `/cancel` aborts a pending deletion

**Automatic stats recalculation:**
- After deletion, all statistics are recalculated from scratch
- No manual `/recalc` needed
- Profit, win rate, streaks, market stats all updated automatically

**Examples:**
```
/last
[shows transactions with # numbers]

/delete 3
❓ Delete this transaction?

#3. 🎲 €10.00 BET 🔴 LOSS @ 1.80 (O2.5) [16:15]

Reply with:
  /confirm_delete 3 to confirm
  /cancel to cancel

/confirm_delete 3
✅ Deleted #3. 🎲 €10.00 BET [16:15]

Stats recalculated automatically.
```

### Files Modified

1. **bot.py**
   - Added `delete_tx()` async function - Shows transaction and asks for confirmation
   - Added `confirm_delete()` async function - Actually deletes the transaction
   - Added `cancel_delete()` async function - Cancels pending deletion
   - Registered CommandHandlers for "delete", "confirm_delete", "cancel"
   - Updated help text in `start()` and `help_command()`

2. **README.md**
   - Added `/delete`, `/confirm_delete`, `/cancel` to command table
   - Added examples for delete workflow

### Technical Details

**Pending deletion storage:**
```python
# Stores pending transaction number in file
pending_file = Path("/opt/gambling-bot/pending_delete.txt")
with open(pending_file, "w") as f:
    f.write(str(tx_number))
```

**Stats refresh:**
```python
# After deletion, refresh all stats
refresh_all_stats(
    state,
    calculate_stats,
    update_streak,
    update_odds_ranges,
    update_markets,
    update_market_streaks,
    update_market_odds_matrix,
    filter_transactions,
    get_month_start
)
```

### Benefits

- **Safe deletion**: Two-step confirmation prevents accidents
- **Full details**: Shows all transaction info before deletion
- **Auto-recalc**: Stats automatically updated after deletion
- **Easy cancellation**: Can cancel pending deletion with `/cancel`

---

**Status:** ✅ Command implemented and bot restarted successfully
