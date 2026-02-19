# Calendar Check Method (LazyingArt / ambiguous account calendars)

This method is for cases where Calendar has duplicate generic names (for example multiple `Calendar` entries) and AppleScript does not clearly expose source account names per calendar in a reliable way.

## Why this method

- Direct source-account mapping can be ambiguous in AppleScript.
- Calendar names like `Calendar`, `Birthdays`, `United States holidays` can exist multiple times.
- A practical check is:
  1. dump exact-name calendars you care about,
  2. dump all candidates under a generic ambiguous name,
  3. run a keyword scan across all calendars.

## Script

- `orchestral/scripts/check_calendar_events.sh`

## Usage

Default (current quick-check profile):

```bash
orchestral/scripts/check_calendar_events.sh
```

Custom names and keyword set:

```bash
orchestral/scripts/check_calendar_events.sh \
  --named-calendars "lachlan.miao.chen@gmail.com,lachen@connect.hku.hk" \
  --ambiguous-name "Calendar" \
  --keywords "agentic,microscopy,anniversary"
```

## Output sections

- `named: <calendar name> #<n>`
  - exact-name matches and full event list for each match
- `ambiguous group: <name>`
  - all calendars with the same generic name, each dumped separately
- `[keyword-scan]`
  - matches across all calendars by title keywords

## Notes

- This is an audit/read method only; it does not mutate calendar data.
- If you want stable account routing, avoid duplicate calendar names for important calendars.
