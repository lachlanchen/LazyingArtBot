# HKU Calendar -> LazyingArt Playbook

This runbook handles the `lachen@connect.hku.hk` calendar migration when multiple calendars share the same name (`Calendar`).

## Why this exists

Name-only AppleScript lookups are ambiguous in this setup. We first resolve by:

- source account/store title (`lachen@connect.hku.hk`)
- source calendar name (`Calendar`)

Then we migrate using that exact resolved calendar id.

## Scripts

- Search:
  - `orchestral/scripts/search_account_calendar_events.sh`
- Move:
  - `orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh`

## Standard sequence

1. Inspect source + target

```bash
orchestral/scripts/search_account_calendar_events.sh \
  --source-account "lachen@connect.hku.hk" \
  --source-calendar "Calendar" \
  --target-calendar "LazyingArt" \
  --keywords "anniversary"
```

2. Dry-run move

```bash
orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh \
  --source-account "lachen@connect.hku.hk" \
  --source-calendar "Calendar" \
  --target-calendar "LazyingArt" \
  --dry-run
```

3. Apply move

```bash
orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh \
  --source-account "lachen@connect.hku.hk" \
  --source-calendar "Calendar" \
  --target-calendar "LazyingArt"
```

## Notes

- Target dedupe is based on `summary + start + end`.
- Recurring source events are upgraded into recurring target events (if target only had a non-recurring duplicate before).
- Read `ACCOUNT_MOVE_SUMMARY` last two fields:
  - `sourceAfterCount`
  - `dryRunFlag`
- If `sourceAfterCount` remains non-zero after apply, source data is likely server-managed and resisted deletion.
- Observed case: `lachen@connect.hku.hk / Calendar` recurring `Anniversary` can remain in source even after delete attempts.
- In that case, migration is still complete once target has the recurring event and dedupe prevents re-copy.
- Final cleanup must be done at the source provider (HKU calendar UI/account policy) if hard-delete is required.

## Prompt tools

- `orchestral/prompt_tools/prompt_account_calendar_search.sh`
- `orchestral/prompt_tools/prompt_account_calendar_move.sh`

These wrappers run the scripts above, then ask Codex to audit/plan using structured JSON output.
