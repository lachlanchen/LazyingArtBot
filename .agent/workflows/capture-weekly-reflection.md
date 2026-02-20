# capture-weekly-reflection

- Purpose: summarize capture quality and produce weekly tuning notes.
- Schedule: Sunday batch.
- Inputs:
  - `assistant_hub/05_meta/feedback_signals.jsonl`
  - `assistant_hub/05_meta/reasoning_queue.jsonl`
- Output:
  - `assistant_hub/05_meta/capture_agent_weekly_review.md`
- Runner:
  - `pnpm moltbot:capture:weekly-reflection`
  - fallback: `npx -y -p tsx tsx scripts/capture/weekly-reflection.ts`
- Status: executable runner available (manual run; not wired to daemon/systemd in this step).
