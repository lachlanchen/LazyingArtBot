#!/usr/bin/env -S node --import tsx
import path from "node:path";
import { envBool, initHub, readJsonl, writeJsonl, writeText } from "./_utils.js";

type PriorityLabel = "P0" | "P1" | "P2" | "P3";

type NotebookLmRequest = {
  id: string;
  created_at: string;
  updated_at: string;
  status: "queued" | "running" | "done" | "failed";
  source: string;
  question: string;
  title?: string;
  priority?: PriorityLabel | null;
  tags?: string[];
  context?: string[];
  push?: boolean;
  attempts?: number;
  result_id?: string;
  last_error?: string | null;
};

type ParsedArgs = {
  question: string;
  title?: string;
  source?: string;
  priority?: PriorityLabel | null;
  tags: string[];
  context: string[];
  push?: boolean;
};

function nowDateParts(now = new Date()): { ymd: string; hm: string; ss: string } {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const parts = formatter.formatToParts(now);
  const byType = new Map(parts.map((part) => [part.type, part.value]));
  const y = byType.get("year") ?? "1970";
  const m = byType.get("month") ?? "01";
  const d = byType.get("day") ?? "01";
  const h = byType.get("hour") ?? "00";
  const min = byType.get("minute") ?? "00";
  const sec = byType.get("second") ?? "00";
  return {
    ymd: `${y}-${m}-${d}`,
    hm: `${h}${min}`,
    ss: sec,
  };
}

function randomSuffix(): string {
  return String(Math.floor(Math.random() * 10_000)).padStart(4, "0");
}

function normalizePriority(input: string | null | undefined): PriorityLabel | null {
  if (!input) {
    return null;
  }
  const hit = input.toUpperCase().match(/\bP([0-3])\b/);
  if (!hit?.[1]) {
    return null;
  }
  return `P${hit[1]}` as PriorityLabel;
}

function usageAndExit(message?: string): never {
  if (message) {
    console.error(`capture:notebooklm-enqueue error=${message}`);
  }
  console.error(
    [
      "Usage:",
      '  pnpm moltbot:capture:notebooklm-enqueue -- "你的問題"',
      '  pnpm moltbot:capture:notebooklm-enqueue -- --question "你的問題" --title "主題" --priority P1 --tag work --context "聚焦風險"',
      "",
      "Env fallback:",
      "  CAPTURE_NOTEBOOKLM_QUERY",
    ].join("\n"),
  );
  process.exit(2);
}

function parseArgs(argv: string[]): ParsedArgs {
  let question = "";
  let title: string | undefined;
  let source: string | undefined;
  let priority: PriorityLabel | null | undefined;
  const tags: string[] = [];
  const context: string[] = [];
  let push: boolean | undefined;
  const freeText: string[] = [];

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === "--") {
      const trailing = argv.slice(i + 1).filter(Boolean);
      freeText.push(...trailing);
      break;
    }
    if (token === "--question") {
      question = argv[i + 1] ?? "";
      i += 1;
      continue;
    }
    if (token === "--title") {
      title = argv[i + 1] ?? "";
      i += 1;
      continue;
    }
    if (token === "--source") {
      source = argv[i + 1] ?? "";
      i += 1;
      continue;
    }
    if (token === "--priority") {
      priority = normalizePriority(argv[i + 1] ?? "");
      i += 1;
      continue;
    }
    if (token === "--tag") {
      const value = (argv[i + 1] ?? "").trim();
      if (value) {
        tags.push(value);
      }
      i += 1;
      continue;
    }
    if (token === "--context") {
      const value = (argv[i + 1] ?? "").trim();
      if (value) {
        context.push(value);
      }
      i += 1;
      continue;
    }
    if (token === "--push") {
      push = true;
      continue;
    }
    if (token === "--no-push") {
      push = false;
      continue;
    }
    if (token.startsWith("--")) {
      usageAndExit(`unknown_flag:${token}`);
    }
    freeText.push(token);
  }

  const fallbackQuestion = freeText.join(" ").trim();
  return {
    question: question.trim() || fallbackQuestion,
    title: title?.trim() || undefined,
    source: source?.trim() || undefined,
    priority,
    tags,
    context,
    push,
  };
}

async function main() {
  const parsed = parseArgs(process.argv.slice(2));
  const fromEnv = (process.env.CAPTURE_NOTEBOOKLM_QUERY ?? "").trim();
  const question = parsed.question || fromEnv;
  if (!question) {
    usageAndExit("missing_question");
  }

  const source = parsed.source || (process.env.CAPTURE_NOTEBOOKLM_SOURCE ?? "").trim() || "manual";
  const pushDefault = envBool("CAPTURE_NOTEBOOKLM_REQUEST_PUSH_DEFAULT", true);
  const push = parsed.push ?? pushDefault;

  const envTags = (process.env.CAPTURE_NOTEBOOKLM_TAGS ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  const tags = Array.from(new Set([...envTags, ...parsed.tags]));

  const envContexts = (process.env.CAPTURE_NOTEBOOKLM_CONTEXTS ?? "")
    .split("|")
    .map((item) => item.trim())
    .filter(Boolean);
  const contexts = Array.from(new Set([...envContexts, ...parsed.context]));

  const now = new Date();
  const parts = nowDateParts(now);
  const id = `nb-${parts.ymd.replace(/-/g, "")}-${parts.hm}${parts.ss}-${randomSuffix()}`;
  const createdAt = now.toISOString();

  const paths = await initHub();
  const queuePath = path.join(paths.meta, "notebooklm_requests.jsonl");
  const queue = await readJsonl<NotebookLmRequest>(queuePath);

  const request: NotebookLmRequest = {
    id,
    created_at: createdAt,
    updated_at: createdAt,
    status: "queued",
    source,
    question,
    title: parsed.title,
    priority: parsed.priority ?? null,
    tags,
    context: contexts,
    push,
    attempts: 0,
    last_error: null,
  };

  queue.push(request);
  await writeJsonl({
    filePath: queuePath,
    rows: queue,
  });

  const previewPath = path.join(paths.meta, "notebooklm_enqueue_last.md");
  await writeText(
    previewPath,
    [
      "# notebooklm_enqueue_last",
      "",
      `id: ${request.id}`,
      `created_at: ${request.created_at}`,
      `source: ${request.source}`,
      `priority: ${request.priority ?? "null"}`,
      `push: ${request.push ? "1" : "0"}`,
      `queue_size: ${queue.length}`,
      "",
      "## title",
      request.title ?? "(none)",
      "",
      "## question",
      request.question,
      "",
      "## context",
      ...(request.context && request.context.length > 0
        ? request.context.map((line) => `- ${line}`)
        : ["- (none)"]),
      "",
      "## tags",
      ...(request.tags && request.tags.length > 0
        ? request.tags.map((line) => `- ${line}`)
        : ["- (none)"]),
      "",
    ].join("\n"),
  );

  console.log(
    `capture:notebooklm-enqueue queued=1 id=${request.id} source=${source} push=${push ? "1" : "0"} queue_size=${queue.length}`,
  );
}

await main();
