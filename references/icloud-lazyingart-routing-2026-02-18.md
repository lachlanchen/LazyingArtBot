# iCloud LazyingArt Routing (2026-02-18)

## Goal

Move auto-mail outputs to iCloud containers named `LazyingArt`:

- Reminders -> `iCloud/LazyingArt`
- Calendar events -> `iCloud/LazyingArt`
- Keep `AutoLife` untouched

## What Was Done

1. **Reminders moved**
   - Moved reminders from `iCloud/Reminders` to `iCloud/LazyingArt`.
   - `AutoLife` was not moved.

2. **Calendar destination corrected to iCloud**
   - Created/confirmed iCloud calendar `LazyingArt`.
   - Removed local-only `Default` calendar collision and ensured target is iCloud.
   - Mail rule now uses calendar **name** (`LazyingArt`) instead of hardcoded id.

3. **Pipeline defaults updated (live workspace automation)**
   - Default reminder list changed to `LazyingArt`.
   - Default calendar changed to `LazyingArt`.
   - Legacy placeholders (`Lachlan`, `Calendar`) still map to configured default.

4. **Automail2note bundle synchronized**
   - Synced runtime scripts into `automail2note/` via `scripts/install_automail2note.sh`.

## Files Touched

### Live runtime files

- `~/.openclaw/workspace/automation/create_reminder.applescript`
- `~/.openclaw/workspace/automation/lazyingart_apply_action.py`
- `~/.openclaw/workspace/automation/lazyingart_simple.py`
- `~/.openclaw/workspace/automation/lazyingart_simple_rule.applescript`
- `/Users/lachlan/Library/Application Scripts/com.apple.mail/Lazyingart Simple Rule.scpt` (recompiled)

### Repo bundle files

- `automail2note/create_reminder.applescript`
- `automail2note/lazyingart_apply_action.py`
- `automail2note/lazyingart_simple.py`
- `automail2note/lazyingart_simple_rule.applescript`
- `automail2note/Lazyingart Simple Rule.scpt`
- `automail2note/README.txt`

## Verification Snapshot

Checked after migration:

- Reminders:
  - `iCloud/Reminders = 0`
  - `iCloud/LazyingArt = 5`
  - `iCloud/AutoLife = 3`
- Calendar (AppleScript view):
  - `LazyingArt count = 13`
- Calendar source (EventKit):
  - `LazyingArt source = iCloud`
  - calendar id = `F0D9CE96-AA0E-4D74-89A7-3CF56784BB43`

## Notes

- Name-based routing works as long as `LazyingArt` is unique in Calendar (current state: unique).
- If duplicate calendars with the same name appear again, either clean duplicates or switch back to id-based routing.
- Notes pipeline already writes under `Lazyingart/...`; no change needed there.
