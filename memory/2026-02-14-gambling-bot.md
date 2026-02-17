# 2026-02-14 - Gambling Bot: Add /uncategorized Command

**Time:** 2026-02-14 16:40 UTC

## Request

User asked: "Can I add a command to see all uncategorized markets on gambling bot on telegram?"

## Implementation

Added `/uncategorized` command to gambling bot to show all markets that are displaying as "Other" (uncategorized).

### Command Functionality

**What it does:**
- Scans all bet transactions
- Identifies markets that are neither:
  1. Core built-in markets (ml, over, under, handicap)
  2. Custom markets that have been categorized into categories
- Shows count, wins, losses, and win rate for each uncategorized market

**Example output:**
```
📋 Uncategorized Markets (15 bets total):

• custom_market1
  8 bets | 5W-3L | 63% WR

• custom_market2
  7 bets | 2W-5L | 29% WR

💡 To categorize these markets:
1. Use the Streamlit Dashboard → Market Management page
2. Add them to categories like 'Outcomes', 'Props', etc.
3. Run /recalc to update stats with new names
```

### Files Modified

1. **bot.py**
   - Added `uncategorized()` async function
   - Registered CommandHandler for "uncategorized"
   - Updated help text in `start()` and `help_command()`

2. **README.md**
   - Added `/uncategorized` to command table
   - Added `/uncategorized` to examples section

### How It Works

**Market categorization:**
1. Core markets: ml, over, under, handicap (always categorized)
2. Custom markets: Can be organized into categories via Streamlit Dashboard
3. Uncategorized: Any market not in the above two groups

**Detection logic:**
```python
# Get market type (returns "Other" for uncategorized)
market_type = get_market_type(market_code, state)

# If it's "Other", track it
if market_type == "Other":
    # Add to uncategorized list
```

### Use Case

**Workflow for user:**
1. Run `/uncategorized` to see what needs categorization
2. Go to Streamlit Dashboard → Market Management page
3. Add uncategorized markets to categories (e.g., "Props", "Specials")
4. Run `/recalc` to update statistics with new category names
5. Stats will now show categorized names instead of "Other"

### Benefits

- **Clear visualization:** See exactly which markets aren't categorized
- **Better stats:** After categorizing, stats show meaningful names
- **Actionable:** Direct guidance on how to fix it

---

**Status:** ✅ Command implemented and bot restarted successfully
