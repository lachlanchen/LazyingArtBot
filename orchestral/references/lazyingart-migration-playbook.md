# LazyingArt Migration Playbook (Calendars + Reminders)

This playbook moves data from selected account surfaces into `LazyingArt`.

## Scripts

- Search/inspect:
  - `orchestral/scripts/search_account_calendar_reminder_summary.sh`
- Move:
  - `orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh`
- Account-specific search/move (when calendar names are ambiguous):
  - `orchestral/scripts/search_account_calendar_events.sh`
  - `orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh`

## Default source scope

- `lachlan.miao.chen@gmail.com`
- `lachen@connect.hku.hk`

## Standard run sequence

1. Inspect current state

```bash
orchestral/scripts/search_account_calendar_reminder_summary.sh
```

2. Dry-run planned migration

```bash
orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh --dry-run
```

3. Apply migration

```bash
orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh
```

4. Post-check

```bash
orchestral/scripts/search_account_calendar_reminder_summary.sh
```

## Important behavior notes

- Reminders are moved by account/list into `iCloud/LazyingArt`.
- Calendar events are moved from:
  - exact named source calendars (`--source-named-calendars`), and
  - non-empty ambiguous calendars by name (default `Calendar`) unless `--no-ambiguous` is used.
- Calendar copy includes a duplicate guard (`summary + start + end`) in target `LazyingArt` so re-runs stay idempotent.
- Some server-backed events can persist in source calendars after move attempts due upstream sync behavior.

## Prompt tools

- Search tool: `orchestral/prompt_tools/prompt_lazyingart_migration_search.sh`
- Move tool: `orchestral/prompt_tools/prompt_lazyingart_migration_move.sh`

These tools call Codex with prompts that explicitly reference the scripts above.
