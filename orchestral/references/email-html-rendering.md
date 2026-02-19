# HTML Email Rendering (Apple Mail)

## Problem

`codex-email-cli.py` previously sent the body as plain text (`content: bodyText`), so raw HTML tags could appear in received emails.

## Fix

We now send rich email content through this path:

1. Codex returns `body` as HTML.
2. Python converts HTML -> RTF using `textutil`.
3. AppleScript reads RTF (`as «class RTF »`) and sets `content` to that rich value.
4. Mail sends multipart output (text/plain + text/html), so clients render correctly.

## Safety Rule

To avoid triggering local mail automation during tests, sending is blocked to:

- `lachlan.mia.chan@gmail.com`

Use:

- `lachchen@qq.com`

for all test sends.

## Files Updated

- `orchestral/prompt_tools/codex-email-cli.py`
- `orchestral/prompt_tools/email_send_prompt.md`

## Quick Test

```bash
python3 /Users/lachlan/Local/Clawbot/orchestral/prompt_tools/codex-email-cli.py \
  --instruction "Send a compact HTML status update with heading, bullets, and table." \
  --to lachchen@qq.com \
  --from lachlan.miao.chen@gmail.com \
  --model gpt-5.3-codex-spark \
  --reasoning high \
  --send
```

If rendering is correct, the email should display styled title/list/table (not raw HTML tags).
