# 2026-02-14 - Gambling Bot: Add /last Command

**Time:** 2026-02-14 16:42 UTC

## Request

User asked: "Can I also run a command to view the list of last 10 transactions? Add a functionality to exclude as well"

## Implementation

Added `/last` command to gambling bot to view recent transaction history with filtering capabilities.

### Command Features

**Show last N transactions:**
```bash
/last              # Shows last 10 (default)
/last 20            # Shows last 20
/last 5              # Shows last 5
```

**Exclude transaction types:**
```bash
/last bet           # Shows last 10, excluding bets (shows deposits + withdrawals only)
/last deposit        # Shows last 10, excluding deposits
/last withdrawal     # Shows last 10, excluding withdrawals
/last 20 bet       # Shows last 20, excluding bets
```

### Output Format

Each transaction shows:
- **Type:** DEPOSIT, WITHDRAWAL, BET (with emoji)
- **Amount:** Euro value (€XX.XX)
- **Details:**
  - **Deposits/Withdrawals:** Just amount
  - **Bets:** Result (WIN/LOSS/PUSH/VOID), odds, market code
- **Time:** Transaction time in HH:MM format

**Example output:**
```
📋 Last 10:

1. 🎲 €10.00 BET 🟢 WIN @ 2.00 (ML) [16:30]
2. 🎲 €20.00 BET 🔴 LOSS @ 1.80 (O2.5) [16:15]
3. 💵 €100.00 DEPOSIT [15:45]
4. 🎲 €15.00 BET 🟡 PUSH @ 2.50 (O2.5) [14:30]
5. 🎲 €25.00 BET 🟢 WIN @ 2.20 (H+1) [13:45]
...
```

### Use Cases

**Track recent activity:**
- See what you bet on today
- Check if last bet was recorded correctly
- Verify deposits were processed

**Filter by type:**
- `/last bet` - Review only deposits and withdrawals
- `/last deposit` - Review only bets and withdrawals
- `/last withdrawal` - Review only bets and deposits
- `/last 5 bet` - See last 5 non-bet transactions

### Files Modified

1. **bot.py**
   - Added `last()` async function
   - Registered CommandHandler for "last"
   - Updated help text in `start()` and `help_command()`
   - Added transaction filtering logic

2. **README.md**
   - Added `/last` command to command table
   - Added examples for filtering functionality

### Technical Details

**Filtering logic:**
```python
# Parse arguments
count = 10  # Default 10
exclude_type = None

if context.args:
    try:
        count = int(context.args[0])
        if len(context.args) > 1:
            exclude_type = context.args[1].lower()
    except ValueError:
        exclude_type = context.args[0].lower()

# Filter transactions
if exclude_type:
    recent_transactions = [t for t in recent_transactions if t.get("type").lower() != exclude_type]
else:
    recent_transactions = recent_transactions[:count]
```

**Transaction ordering:**
- Transactions are reversed (newest first)
- Shows most recent activity at the top
- Includes timestamps for easy identification

### Benefits

- **Quick review:** See recent activity without full stats
- **Error checking:** Verify transactions were recorded correctly
- **Flexible filtering:** Focus on specific transaction types
- **Time-aware:** Shows transaction times (HH:MM format)

---

**Status:** ✅ Command implemented and bot restarted successfully
