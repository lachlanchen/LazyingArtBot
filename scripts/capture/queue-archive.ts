/**
 * queue-archive.ts
 * Archives consumed entries older than ARCHIVE_AGE_DAYS from reasoning_queue.jsonl
 * and feedback_signals.jsonl into monthly archive files.
 *
 * Run via cron (monthly, 2nd of month at 04:00).
 */
import fs from "node:fs/promises";
import path from "node:path";
import { resolveHubPaths } from "../../src/capture-agent/hub.js";
import { readJsonl, writeJsonl } from "./_utils.js";

const ARCHIVE_AGE_DAYS = 90;

async function archiveJsonl(
  srcPath: string,
  archiveDir: string,
  prefix: string,
  cutoffMs: number,
): Promise<{ archived: number; kept: number }> {
  const rows = await readJsonl<Record<string, unknown>>(srcPath);

  const active: Record<string, unknown>[] = [];
  const toArchive: Record<string, unknown>[] = [];

  for (const row of rows) {
    const ts = new Date(
      (row["ts"] as string | undefined) ?? (row["created_at"] as string | undefined) ?? 0,
    ).getTime();
    if (row["consumed"] && ts < cutoffMs) {
      toArchive.push(row);
    } else {
      active.push(row);
    }
  }

  if (toArchive.length === 0) {
    return { archived: 0, kept: active.length };
  }

  await fs.mkdir(archiveDir, { recursive: true });
  const month = new Date().toISOString().slice(0, 7); // YYYY-MM
  const archivePath = path.join(archiveDir, `${prefix}_${month}.jsonl`);
  const archiveLines = toArchive.map((r) => JSON.stringify(r)).join("\n") + "\n";
  await fs.appendFile(archivePath, archiveLines, "utf8");

  await writeJsonl({ filePath: srcPath, rows: active });

  return { archived: toArchive.length, kept: active.length };
}

async function main(): Promise<void> {
  const paths = resolveHubPaths();
  const archiveDir = path.join(paths.meta, "archive");
  const cutoffMs = Date.now() - ARCHIVE_AGE_DAYS * 86_400_000;

  const queueResult = await archiveJsonl(
    path.join(paths.meta, "reasoning_queue.jsonl"),
    archiveDir,
    "reasoning_queue",
    cutoffMs,
  );
  console.log(
    `[queue-archive] reasoning_queue: archived ${queueResult.archived}, kept ${queueResult.kept}`,
  );

  const feedbackResult = await archiveJsonl(
    path.join(paths.meta, "feedback_signals.jsonl"),
    archiveDir,
    "feedback_signals",
    cutoffMs,
  );
  console.log(
    `[queue-archive] feedback_signals: archived ${feedbackResult.archived}, kept ${feedbackResult.kept}`,
  );

  console.log(
    `[queue-archive] Done. Total archived: ${queueResult.archived + feedbackResult.archived}`,
  );
}

main().catch((err) => {
  console.error("[queue-archive] Fatal error:", err);
  process.exit(1);
});
