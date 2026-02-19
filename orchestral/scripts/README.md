# Orchestral Scripts

Calendar + reminder migration helpers used by LazyingArt operations.

- `check_calendar_events.sh`
  - Dump events from named calendars and ambiguous same-name calendars for manual verification.
- `search_account_calendar_reminder_summary.sh`
  - Print source/target counts for reminder lists and calendars before/after migration.
- `search_account_calendar_events.sh`
  - Resolve a calendar by `source account + calendar name` and print source/target snapshots.
- `move_account_calendar_reminders_to_lazyingart.sh`
  - Move reminders/events into LazyingArt targets.
  - Supports `--dry-run`.
  - Calendar move path has duplicate guards to avoid re-adding the same event on retries.
- `move_events_from_account_calendar_to_lazyingart.sh`
  - Move one specific account calendar into LazyingArt using EventKit source resolution.
  - Handles stores where calendar names are ambiguous (multiple `Calendar` calendars).
  - Recurrence-aware: upgrades non-recurring duplicates in target to recurring events when source has recurrence.
  - Emits `ACCOUNT_MOVE_SUMMARY` with `sourceAfterCount` so you can detect server-managed source events that remain after delete attempts.
- `run_resource_analysis.sh`
  - Generic resource analysis entrypoint for any company.
  - Supports repeatable `--resource-root` and writes markdown outputs for downstream prompt tools.
  - By default writes markdown to:
    - `~/Documents/LazyingArtBotIO/<company>/Output/ResourceAnalysis/<RUN_ID>`
  - Recommended for pre-processing local resource packs before pipeline prompts.

Recommended sequence:

````bash
orchestral/scripts/search_account_calendar_reminder_summary.sh
orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh --dry-run
orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh
orchestral/scripts/search_account_calendar_reminder_summary.sh

### Example: Lightmind resource pass

```bash
orchestral/scripts/run_resource_analysis.sh \
  --company Lightmind \
  --resource-root \"/Users/lachlan/Library/Containers/com.tencent.WeWorkMac/Data/WeDrive/LightMind Tech Ltd./LightMind Tech Ltd./LightMind_Confidential\" \
  --resource-root \"/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input\" \
  --resource-root \"/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output\" \
  --model gpt-5.1-codex-mini \
  --reasoning medium
````
