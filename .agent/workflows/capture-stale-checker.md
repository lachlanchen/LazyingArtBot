# capture-stale-checker

- Purpose: detect stale action items (default horizon: 7 days).
- Schedule: daily batch.
- Inputs:
  - `assistant_hub/02_work/tasks_master.md`
- Output:
  - stale markers
  - feedback event candidates (`stale_action`)
- Runner:
  - `pnpm moltbot:capture:stale-checker`
  - fallback: `npx -y -p tsx tsx scripts/capture/stale-checker.ts`
- Status: executable runner available (manual run; not wired to daemon/systemd in this step).
