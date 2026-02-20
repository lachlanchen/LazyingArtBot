import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type {
  CaptureBasePaths,
  CaptureCardFrontmatter,
  CaptureContentParts,
  CaptureDateParts,
  CaptureFileOp,
  CaptureInference,
  CapturePathSet,
  CaptureResolvedPaths,
  CaptureType,
} from "./types.js";

export function resolveHubRoot(): string {
  const fromEnv = process.env.CAPTURE_HUB_ROOT?.trim();
  if (fromEnv) {
    return fromEnv;
  }
  return path.join(os.homedir(), ".openclaw", "workspace", "automation", "assistant_hub");
}

export function resolveHubPaths(root = resolveHubRoot()): CaptureResolvedPaths {
  const base: CaptureBasePaths = {
    root,
    inbox: path.join(root, "00_inbox"),
    work: path.join(root, "02_work"),
    life: path.join(root, "03_life"),
    knowledge: path.join(root, "04_knowledge"),
    meta: path.join(root, "05_meta"),
  };
  return {
    ...base,
    tasks: path.join(base.work, "tasks"),
    projects: path.join(base.work, "projects", "_misc"),
    dailyLogs: path.join(base.life, "daily_logs"),
    ideas: path.join(base.life, "ideas"),
    highlights: path.join(base.life, "highlights"),
    people: path.join(base.knowledge, "people"),
    questions: path.join(base.knowledge, "questions"),
    beliefs: path.join(base.knowledge, "beliefs"),
    references: path.join(base.knowledge, "references"),
  };
}

export async function ensureHubPaths(paths: CaptureResolvedPaths): Promise<void> {
  const required = [
    paths.root,
    paths.inbox,
    paths.work,
    paths.tasks,
    paths.projects,
    paths.life,
    paths.dailyLogs,
    paths.ideas,
    paths.highlights,
    paths.knowledge,
    paths.people,
    paths.questions,
    paths.beliefs,
    paths.references,
    paths.meta,
  ];
  for (const dir of required) {
    await fs.mkdir(dir, { recursive: true });
  }
}

async function writeIfMissing(filePath: string, content: string): Promise<void> {
  try {
    await fs.writeFile(filePath, content, { encoding: "utf8", flag: "wx" });
  } catch {
    // keep existing file untouched
  }
}

export async function ensureHubScaffoldFiles(paths: CaptureResolvedPaths): Promise<void> {
  await writeIfMissing(
    path.join(paths.root, "TAGS.md"),
    "# TAGS\n\n- 用於維護常用 tag 與命名規範。\n",
  );
  await writeIfMissing(
    path.join(paths.root, "index.md"),
    [
      "# assistant_hub",
      "",
      "- `00_inbox/` 原始訊息",
      "- `02_work/` 任務與追蹤",
      "- `03_life/` 生活紀錄",
      "- `04_knowledge/` 知識卡片",
      "- `05_meta/` 系統訊號與回顧",
      "",
    ].join("\n"),
  );

  await writeIfMissing(path.join(paths.work, "tasks_master.md"), "# tasks_master\n\n");
  await writeIfMissing(path.join(paths.work, "waiting.md"), "# waiting\n\n");
  await writeIfMissing(path.join(paths.work, "done.md"), "# done\n\n");
  await writeIfMissing(
    path.join(paths.work, "calendar.md"),
    [
      "# calendar",
      "",
      "| date | title | type | due/checkpoints |",
      "| --- | --- | --- | --- |",
      "",
    ].join("\n"),
  );

  await writeIfMissing(path.join(paths.ideas, "_ideas_index.md"), "# ideas_index\n\n");
  await writeIfMissing(path.join(paths.questions, "_index.md"), "# questions_index\n\n");
  await writeIfMissing(path.join(paths.beliefs, "_index.md"), "# beliefs_index\n\n");

  await writeIfMissing(path.join(paths.meta, "reasoning_queue.jsonl"), "");
  await writeIfMissing(path.join(paths.meta, "feedback_signals.jsonl"), "");
  await writeIfMissing(
    path.join(paths.meta, "capture_agent_weekly_review.md"),
    "# Capture Agent Weekly Review\n\n",
  );
}

function normalizeForSlug(input: string): string {
  const lowered = input.toLowerCase();
  const replaced = lowered.replace(/[^a-z0-9]+/g, "_");
  const trimmed = replaced.replace(/^_+|_+$/g, "");
  return trimmed.slice(0, 24) || "note";
}

export function slugifyTitle(title: string, fallbackType: CaptureType): string {
  const normalized = normalizeForSlug(title);
  if (normalized === "note") {
    return normalizeForSlug(fallbackType);
  }
  return normalized;
}

function frontmatterScalar(value: string | number | boolean | null): string {
  if (value === null) {
    return "null";
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (/^[a-zA-Z0-9_:+./ -]+$/.test(value)) {
    return value;
  }
  return JSON.stringify(value);
}

function frontmatterArray(values: string[]): string {
  if (values.length === 0) {
    return "[]";
  }
  return `[${values.map((value) => JSON.stringify(value)).join(", ")}]`;
}

export function buildCardMarkdown(frontmatter: CaptureCardFrontmatter, body: CaptureContentParts): string {
  const lines: string[] = [];
  lines.push("---");
  lines.push(`id: ${frontmatter.id}`);
  lines.push(`type: ${frontmatter.type}`);
  lines.push(`title: ${frontmatterScalar(frontmatter.title)}`);
  lines.push(`created: ${frontmatter.created}`);
  lines.push(`source: ${frontmatter.source}`);
  lines.push(`priority: ${frontmatter.priority ?? "null"}`);
  lines.push(`due: ${frontmatter.due ?? "null"}`);
  lines.push(`tags: ${frontmatterArray(frontmatter.tags)}`);
  lines.push(`convert_to_task: ${frontmatter.convertToTask}`);
  lines.push(`long_term_memory: ${frontmatter.longTermMemory}`);
  lines.push(`calendar_entry: ${frontmatter.calendarEntry}`);
  lines.push(`stage: ${frontmatter.stage ?? "null"}`);
  lines.push(`q_status: ${frontmatter.qStatus ?? "null"}`);
  lines.push(`confidence: ${frontmatter.confidence.toFixed(2)}`);
  lines.push(`alts: ${frontmatterArray(frontmatter.alts)}`);
  lines.push(`dedupe_hint: ${frontmatter.dedupeHint}`);
  lines.push(`next_best_action: ${frontmatter.nextBestAction ? frontmatterScalar(frontmatter.nextBestAction) : "null"}`);
  lines.push(`links: ${frontmatterArray(frontmatter.links)}`);
  lines.push(`attachments: ${frontmatterArray(frontmatter.attachments)}`);
  lines.push("remind_schedule:");
  lines.push(`  mode: ${frontmatter.remindSchedule.mode}`);
  lines.push(`  checkpoints: ${frontmatterArray(frontmatter.remindSchedule.checkpoints)}`);
  lines.push(`  auto_archive_after: ${frontmatter.remindSchedule.autoArchiveAfter ?? "null"}`);
  lines.push("feedback:");
  lines.push(`  token: ${frontmatter.feedback.token}`);
  lines.push(`  watch_type: ${frontmatter.feedback.watchType}`);
  lines.push(`  expected_horizon_days: ${frontmatter.feedback.expectedHorizonDays ?? "null"}`);
  lines.push("---");
  lines.push("");
  lines.push("## 原文");
  lines.push(body.originalText);
  lines.push("");
  lines.push("## 你的整理");
  lines.push(`- ${body.summaryLine}`);
  lines.push(`- ${body.rationaleLine}`);
  if (body.conservativeLine) {
    lines.push(`- ${body.conservativeLine}`);
  }
  lines.push(`- next_best_action：${body.nextActionLine}`);
  lines.push("");
  lines.push("## Key Facts");
  if (body.keyFacts.length === 0) {
    lines.push("- (none)");
  } else {
    for (const fact of body.keyFacts) {
      lines.push(`- ${fact}`);
    }
  }
  if (body.attachmentLines.length > 0) {
    lines.push("");
    lines.push("## Attachments");
    for (const attachment of body.attachmentLines) {
      lines.push(`- ${attachment}`);
    }
  }
  lines.push("");
  return `${lines.join("\n")}\n`;
}

async function safeReadDir(dirPath: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const out: string[] = [];
    for (const entry of entries) {
      if (entry.isFile()) {
        out.push(path.join(dirPath, entry.name));
      } else if (entry.isDirectory()) {
        const nested = await safeReadDir(path.join(dirPath, entry.name));
        out.push(...nested);
      }
    }
    return out;
  } catch {
    return [];
  }
}

export async function nextDailyId(paths: CaptureResolvedPaths, now: CaptureDateParts): Promise<string> {
  const datePrefix = `${now.ymd}-`;
  const files = await Promise.all([
    safeReadDir(paths.tasks),
    safeReadDir(paths.projects),
    safeReadDir(paths.ideas),
    safeReadDir(paths.highlights),
    safeReadDir(paths.people),
    safeReadDir(paths.questions),
    safeReadDir(paths.beliefs),
    safeReadDir(paths.references),
  ]);
  const merged = files.flat();
  let max = 0;
  for (const filePath of merged) {
    const base = path.basename(filePath);
    if (!base.startsWith(datePrefix)) {
      continue;
    }
    const match = base.match(/^(\d{4}-\d{2}-\d{2})-(\d{3,4})/);
    if (!match) {
      continue;
    }
    const seq = Number(match[2]);
    if (Number.isFinite(seq) && seq > max) {
      max = seq;
    }
  }
  if (max > 0) {
    return `${now.ymd}-${String(max + 1).padStart(3, "0")}`;
  }
  const hmFallback = now.hm.replace(":", "");
  return `${now.ymd}-${hmFallback}`;
}

export function resolveMainPath(params: {
  id: string;
  slug: string;
  type: CaptureInference["type"];
  paths: CaptureResolvedPaths;
  now: CaptureDateParts;
}): string {
  const { id, slug, type, paths, now } = params;
  const filename = `${id}_${slug}.md`;
  switch (type) {
    case "action":
      return path.join(paths.tasks, filename);
    case "timeline":
      return path.join(paths.projects, filename);
    case "watch":
      return path.join(paths.tasks, filename);
    case "idea":
      return path.join(paths.ideas, filename);
    case "question":
      return path.join(paths.questions, filename);
    case "belief":
      return path.join(paths.beliefs, filename);
    case "highlight":
      return path.join(paths.highlights, filename);
    case "reference":
      return path.join(paths.references, filename);
    case "person":
      return path.join(paths.people, filename);
    case "memory":
      return path.join(paths.dailyLogs, `${now.ymd}.md`);
    default:
      return path.join(paths.inbox, filename);
  }
}

export function resolvePathSet(paths: CaptureResolvedPaths, now: CaptureDateParts, source: string): CapturePathSet {
  return {
    mainPath: "",
    inboxPath: path.join(paths.inbox, `${now.ymd}_${source}_inbox.md`),
    tasksMasterPath: path.join(paths.work, "tasks_master.md"),
    waitingPath: path.join(paths.work, "waiting.md"),
    calendarPath: path.join(paths.work, "calendar.md"),
    ideasIndexPath: path.join(paths.ideas, "_ideas_index.md"),
    questionsIndexPath: path.join(paths.questions, "_index.md"),
    beliefsIndexPath: path.join(paths.beliefs, "_index.md"),
    reasoningQueuePath: path.join(paths.meta, "reasoning_queue.jsonl"),
    feedbackSignalsPath: path.join(paths.meta, "feedback_signals.jsonl"),
  };
}

export function escapeTableCell(value: string): string {
  return value.replace(/\|/g, "\\|");
}

export function typeEmoji(type: CaptureType): string {
  switch (type) {
    case "action":
      return "⚡";
    case "timeline":
      return "📍";
    case "watch":
      return "👀";
    case "idea":
      return "💡";
    case "question":
      return "❓";
    case "belief":
      return "🧠";
    case "memory":
      return "📝";
    case "highlight":
      return "✨";
    case "reference":
      return "📖";
    case "person":
      return "👤";
    default:
      return "📝";
  }
}

export async function applyFileOps(ops: CaptureFileOp[]): Promise<void> {
  for (const op of ops) {
    await fs.mkdir(path.dirname(op.path), { recursive: true });
    if (op.op === "append") {
      await fs.appendFile(op.path, op.content, "utf8");
      continue;
    }
    if (op.op === "create") {
      try {
        await fs.writeFile(op.path, op.content, { encoding: "utf8", flag: "wx" });
      } catch {
        await fs.appendFile(op.path, op.content, "utf8");
      }
      continue;
    }
    await fs.writeFile(op.path, op.content, "utf8");
  }
}
