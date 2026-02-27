#!/usr/bin/env -S node --import tsx
import path from "node:path";
import {
  appendJsonlUnique,
  dayDiff,
  initHub,
  readText,
  tokyoYmd,
  type FeedbackSignal,
  writeText,
} from "./_utils.js";

function parseIdFromLine(line: string): string | null {
  const hit = line.match(/\(id:(\d{4}-\d{2}-\d{2}-\d{3,4})\)/);
  return hit?.[1] ?? null;
}

function parseTitleFromLine(line: string): string {
  // Extract human-readable title from tasks_master line
  // Format: - [ ] (P1) 任務標題 (id:...) type:... due:...
  const hit = line.match(/^-\s*\[.?\]\s*(?:\([^)]*\)\s*)?(.+?)\s*\(id:/);
  return hit?.[1]?.trim() ?? line.replace(/^-\s*\[.?\]\s*/, "").slice(0, 60);
}

async function main() {
  const horizon = Number.parseInt(process.env.CAPTURE_STALE_DAYS ?? "7", 10);
  const today = tokyoYmd();
  const paths = await initHub();
  const tasksMasterPath = path.join(paths.work, "tasks_master.md");
  const raw = await readText(tasksMasterPath);

  const rows = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.startsWith("- [ ]"));

  const stale = rows
    .map((line) => {
      const id = parseIdFromLine(line);
      if (!id) {
        return null;
      }
      const ymd = id.slice(0, 10);
      const ageDays = dayDiff(ymd, today);
      if (ageDays < horizon) {
        return null;
      }
      return { id, ageDays, line };
    })
    .filter((item): item is { id: string; ageDays: number; line: string } => Boolean(item))
    .toSorted((a, b) => b.ageDays - a.ageDays);

  const reportPath = path.join(paths.meta, "stale_actions.md");
  const reportLines = [
    "# stale_actions",
    "",
    `date: ${today}`,
    `horizon_days: ${horizon}`,
    `count: ${stale.length}`,
    "",
  ];
  if (stale.length === 0) {
    reportLines.push("- (none)");
  } else {
    for (const item of stale) {
      const title = parseTitleFromLine(item.line);
      reportLines.push(`- ${title} (id:${item.id}) age_days:${item.ageDays}`);
    }
  }
  reportLines.push("");
  await writeText(reportPath, reportLines.join("\n"));

  const feedbackRows: FeedbackSignal[] = stale.map((item) => ({
    token: `stale_action:${today}:${item.id}`,
    type: "stale_action",
    id: item.id,
    date: today,
    age_days: item.ageDays,
    created_at: new Date().toISOString(),
  }));

  const added = await appendJsonlUnique({
    filePath: path.join(paths.meta, "feedback_signals.jsonl"),
    rows: feedbackRows,
  });

  console.log(
    `capture:stale-checker stale=${stale.length} signals_added=${added} -> ${reportPath}`,
  );
}

await main();
