#!/usr/bin/env -S node --import tsx
import path from "node:path";
import { initHub, readJsonl, shiftYmd, tokyoYmd, type FeedbackSignal, type QueueEntry, writeText } from "./_utils.js";

type TypeCount = { type: string; count: number };

function toYmd(ts: string | undefined): string | null {
  if (!ts) {
    return null;
  }
  const parsed = Date.parse(ts);
  if (!Number.isFinite(parsed)) {
    return null;
  }
  const d = new Date(parsed);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

async function main() {
  const today = tokyoYmd();
  const start = shiftYmd(today, -6);
  const paths = await initHub();
  const queue = await readJsonl<QueueEntry>(path.join(paths.meta, "reasoning_queue.jsonl"));
  const feedback = await readJsonl<FeedbackSignal>(path.join(paths.meta, "feedback_signals.jsonl"));

  const queueWeek = queue.filter((entry) => {
    const ymd = toYmd(entry.ts) ?? today;
    return ymd >= start && ymd <= today;
  });
  const feedbackWeek = feedback.filter((entry) => {
    const ymd = typeof entry.date === "string" ? entry.date : toYmd(typeof entry.created_at === "string" ? entry.created_at : undefined);
    if (!ymd) {
      return false;
    }
    return ymd >= start && ymd <= today;
  });

  const typeMap = new Map<string, number>();
  let confidenceTotal = 0;
  let confidenceCount = 0;
  for (const row of queueWeek) {
    const type = String(row.type ?? "unknown");
    typeMap.set(type, (typeMap.get(type) ?? 0) + 1);
    if (typeof row.confidence === "number" && Number.isFinite(row.confidence)) {
      confidenceTotal += row.confidence;
      confidenceCount += 1;
    }
  }

  const types: TypeCount[] = [...typeMap.entries()]
    .map(([type, count]) => ({ type, count }))
    .sort((a, b) => b.count - a.count);

  const feedbackTypeMap = new Map<string, number>();
  for (const row of feedbackWeek) {
    const type = String(row.type ?? "unknown");
    feedbackTypeMap.set(type, (feedbackTypeMap.get(type) ?? 0) + 1);
  }

  const avgConfidence = confidenceCount > 0 ? confidenceTotal / confidenceCount : 0;
  const topType = types[0]?.type ?? "none";
  const topFeedback = [...feedbackTypeMap.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? "none";

  const lines: string[] = [];
  lines.push("# Capture Agent Weekly Review");
  lines.push("");
  lines.push(`period: ${start} ~ ${today}`);
  lines.push(`queue_items: ${queueWeek.length}`);
  lines.push(`feedback_events: ${feedbackWeek.length}`);
  lines.push(`avg_confidence: ${avgConfidence.toFixed(2)}`);
  lines.push("");
  lines.push("## Type Distribution");
  if (types.length === 0) {
    lines.push("- (none)");
  } else {
    for (const item of types) {
      lines.push(`- ${item.type}: ${item.count}`);
    }
  }
  lines.push("");
  lines.push("## Feedback Distribution");
  if (feedbackTypeMap.size === 0) {
    lines.push("- (none)");
  } else {
    for (const [type, count] of [...feedbackTypeMap.entries()].sort((a, b) => b[1] - a[1])) {
      lines.push(`- ${type}: ${count}`);
    }
  }
  lines.push("");
  lines.push("## Notes");
  lines.push(`- 主要捕捉類型：${topType}`);
  lines.push(`- 主要回饋信號：${topFeedback}`);
  lines.push(
    avgConfidence < 0.75
      ? "- 信心均值偏低，建議下週優先優化分類提示與附件語義描述。"
      : "- 信心均值穩定，建議維持目前流程並持續監測 stale/watch 比例。",
  );
  lines.push("");

  const outPath = path.join(paths.meta, "capture_agent_weekly_review.md");
  await writeText(outPath, `${lines.join("\n")}\n`);
  console.log(`capture:weekly-reflection rows=${queueWeek.length}/${feedbackWeek.length} -> ${outPath}`);
}

await main();
