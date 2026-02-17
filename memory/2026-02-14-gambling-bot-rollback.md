# 2026-02-14 - Gambling Bot: Rollback /delete Command

**Time:** 2026-02-14 17:06 UTC

## Request

User asked: "You can rollback this functionality. I'd rather delete it on the streamlit UI later."

## Actions Taken

Rolled back the `/delete` command functionality that was just added.

### Removed from bot.py:
1. **Three async functions:**
   - `delete_tx()` - Show transaction and ask for confirmation
   - `confirm_delete()` - Confirm and delete transaction
   - `cancel_delete()` - Cancel pending deletion

2. **Command handlers:**
   - `CommandHandler("delete", delete_tx)`
   - `CommandHandler("confirm_delete", confirm_delete)`
   - `CommandHandler("cancel", cancel_delete)`

### Updated in bot.py:
1. **Removed command handlers** from application registration

### Updated in bot.py:
1. **Welcome message** - Removed `/delete`, `/confirm_delete`, `/cancel` from command list
2. **Help message** - Removed `/delete`, `/confirm_delete`, `/cancel` from command list

### Updated in README.md:
1. **Command table** - Removed delete-related commands
2. **Examples** - Removed delete-related examples

## Reason for Rollback

User prefers to delete transactions using the Streamlit Dashboard instead of Telegram commands. This keeps the Telegram bot focused on:
- Recording transactions (/deposit, /withdrawal, /bet)
- Viewing stats (/stats, /summary)
- Managing markets (/uncategorized, /recalc)
- Viewing history (/last)

## Current Commands (After Rollback)

| Command | Description |
|---------|-------------|
| `/start` | Start bot and see welcome message |
| `/help` | Show all available commands |
| `/summary` | Quick one-line overview |
| `/export [period]` | Export data to CSV |
| `/goal <profit>` | Set monthly profit goal |
| `/progress` | Show goal progress |
| `/deposit <amount>` | Record a deposit |
| `/withdrawal <amount>` | Record a withdrawal |
| `/bet <amount> [odds] [market] <result>` | Record a bet |
| `/last [N] [exclude]` | Show last N transactions (default: 10) |
| `/stats [period]` | Show statistics |
| `/stoploss <amount>` | Set monthly stop loss limit |
| `/reset_month` | Reset monthly tracking |
| `/uncategorized` | Show all uncategorized markets (need categorization) |
| `/recalc` | Recalculate market stats after updating categories |

---

**Status:** ✅ Rollback completed, bot restarted successfully
