# AutoLife Capture & Planning Philosophy

This document summarizes how we operate AutoLife across notes, calendars, reminders, and Codex prompt tools. Treat it as the canonical reference when writing new automation or prompts.

## Core mindset

6. **Delegate via prompt tools**
   - Every instruction should become a small, composable prompt tool (JSON schema + runner).
   - I act as the orchestrator: chain tools, pass context between them, and only keep lightweight memory pointers.
   - Prompt tools read existing notes before writing, follow the emoji/bilingual style, and emit structured JSON for downstream steps.

1. **Capture-first workflow**
   - Anything the human sends (purchases, todos, research ideas, split bills, company work for lazying.art or lightmind.art, PhD items, passive-income plans, app ideas, random epiphanies) gets recorded immediately.
   - Act first, report afterward. If details are missing, note that in the follow-up but do not wait for confirmation before capturing.

1. **AutoLife notes as the primary brain**
   - Notes live in iCloud > AutoLife, organized with emoji-rich folders:
     - `🌱 Life` (personal notes: 📥 Inbox, ♾️ Agent Platform, 🌀 Echomind Lab, 🧾 Meta Notes, 🛠️ AutoAppDev, ✍️ AutoNovelWriter, 🏡 Home & Errands, 🔁 Daily Rituals, 🛒 Purchases & Gear)
     - `🏢 Companies`
       - `🐼 Lazying.art` → 🎨 Milestones, 🎯 Strategy & Plan, 🌀 Echomind Lab if applicable
       - `👓 Lightmind.art` → 🧪 Milestones, 👓 Strategy & Plan
       - Shared: 🚀 Action Funnel, 🧠 Market Intel Digest
     - `🔬 Research Hub` → 🔬 Research Board (PhD & R&D milestones)
     - `🪵 Log` → daily log notes (HTML + markdown mirror)
   - Emoji + bilingual headings (EN/中文/日本語) are required for every note update.

1. **Local mirrors**
   - `AutoLife/MetaNotes/…` mirrors key notes by folder (Life, Companies/🐼, Companies/👓, Research). Any automation that writes to Notes should also update the corresponding markdown file.

1. **Calendars & reminders**
   - Two canonical iCloud calendars/lists:
     - `LazyingArt` – tied to the mail-processing pipeline.
     - `AutoLife` – general planning blocks.
   - Refer to calendars/lists **by name**, never by ID. Ensure no local duplicates exist (use the EventKit scripts documented in `references/icloud-autolife-calendar-setup.md`).

1. **Prompt tools orchestrate everything**
   - Every recurring workflow must be encapsulated in a Codex prompt tool (`prompt_notes`, `prompt_calendar_and_reminder`, `prompt_market_research`, `prompt_company_management`, `prompt_passive_income`, `prompt_making_plan`, `prompt_log`, etc.).
   - `run_auto_ops.sh` standardizes JSON-in/JSON-out using `auto_ops_schema.json`.
   - Prompts explicitly instruct Codex to read existing structure before writing, to use emoji/bilingual headings, and to target the correct folders (e.g., `🐼 Lazying.art`).

## Operational loop

1. **Capture** – Ingest message into the relevant AutoLife note(s), add reminders or calendar events if timing is explicit.
2. **Structure** – Decide whether it belongs in 🌱 Life, 🏢 Companies (🐼/👓), 🔬 Research, or 🧠 Market Intel.
3. **Mirror** – Update the markdown counterpart under `AutoLife/MetaNotes/...`.
4. **Log** – Run `prompt_log.sh` for meaningful batches; Entries append to 🪵 Log (Apple Notes + `/AutoLife/Log/YYYY-MM-DD.md`).
5. **Report** – Reply to the human summarizing what got captured and any follow-up needs.

## Styling checklist

- Every note/folder name starts with an emoji.
- Headings mix EN/中文/日本語 when useful.
- Bullets include owner + due window when applicable.
- Inline status icons (✅, ⏳, 🟡) highlight progress.
- For company work, specify which org: `🐼 Lazying.art` vs. `👓 Lightmind.art` vs. `🔬 Research`.

## Automation defaults

- Calendar events: default to `AutoLife` unless the task explicitly belongs to `LazyingArt` timeline.
- Reminders: default to `AutoLife` list for personal tasks, `LazyingArt` for mail-derived tasks.
- Email sending: `codex-email-cli.py` with sender `lachlan.miao.chen@gmail.com`, recipient `lachchen@qq.com` when pushing important updates.

## References

- `references/icloud-autolife-calendar-setup.md` – EventKit runbook to create/migrate AutoLife calendars in iCloud.
- `references/icloud-lazyingart-routing-2026-02-18.md` – Mail pipeline routing notes.
- `AutoLife/MetaNotes/...` – Markdown mirrors for each note.

Keep this document updated whenever the philosophy or folder layout changes.

## Conversation Source

Key agreement (2026-02-18):

> AutoLife is the default brain dump for everything the human throws at me, with zero pre-confirmation.
>
> - Capture-first workflow: purchases, todos, research/entrepreneurship/novel ideas, split bills, company work (lazying.art, lightmind.art), HK PhD items with Prof. Lam, passive-income plans, app-dev thoughts, random epiphanies — all get recorded immediately. I act first, then update on what I did.
> - Structure inside Notes: AutoLife iCloud folder holds inbox + sub-notes; I choose where each item lives.
> - Local Meta archive: mirror key notes in `AutoLife/MetaNotes`.
> - Next steps: parse every new item, drop it into the right note/reminder/calendar slot, choose sensible times if missing, then report back with any follow-ups needed.

Any future change to this philosophy should update this document and cite the conversation/date.
