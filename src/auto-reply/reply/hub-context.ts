import fs from "node:fs/promises";
import path from "node:path";
import { resolveHubPaths, resolveHubRoot } from "../../capture-agent/hub.js";

const HUB_CONTEXT_MAX_CHARS = 5600;
const TZ = "Asia/Shanghai";

// ---- Module-level I/O cache (5-minute TTL) ----
const _cache = new Map<string, { data: unknown; expiry: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

function getCached<T>(key: string): T | undefined {
  const entry = _cache.get(key);
  if (!entry || Date.now() > entry.expiry) {
    _cache.delete(key);
    return undefined;
  }
  return entry.data as T;
}

function setCache<T>(key: string, data: T): T {
  _cache.set(key, { data, expiry: Date.now() + CACHE_TTL });
  return data;
}
// ---- End cache ----

function getYmd(offsetDays = 0): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

async function readTail(filePath: string, maxChars: number): Promise<string | null> {
  const cacheKey = `${filePath}:${maxChars}`;
  const cached = getCached<string | null>(cacheKey);
  if (cached !== undefined) {
    return cached;
  }

  try {
    const content = await fs.readFile(filePath, "utf8");
    const trimmed = content.trim();
    if (!trimmed) {
      return setCache(cacheKey, null);
    }
    const result = trimmed.length > maxChars ? "...\n" + trimmed.slice(-maxChars) : trimmed;
    return setCache(cacheKey, result);
  } catch {
    return setCache(cacheKey, null);
  }
}

function extractUnchecked(content: string, maxLines = 10): string {
  return content
    .split("\n")
    .filter((l) => l.includes("- [ ]"))
    .slice(-maxLines)
    .join("\n");
}

async function readDir(dirPath: string): Promise<string[]> {
  const cacheKey = `dir:${dirPath}`;
  const cached = getCached<string[]>(cacheKey);
  if (cached !== undefined) {
    return cached;
  }

  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const result = entries
      .filter((e) => e.isFile() && e.name.endsWith(".md") && !e.name.startsWith("_"))
      .map((e) => path.join(dirPath, e.name));
    return setCache(cacheKey, result);
  } catch {
    return setCache(cacheKey, []);
  }
}

async function readDirRecent(
  dirPath: string,
  maxFiles: number,
  maxCharsEach: number,
): Promise<string | null> {
  const cacheKey = `dirRecent:${dirPath}:${maxFiles}:${maxCharsEach}`;
  const cached = getCached<string | null>(cacheKey);
  if (cached !== undefined) {
    return cached;
  }

  const files = await readDir(dirPath);
  if (files.length === 0) {
    return setCache(cacheKey, null);
  }

  // Sort by mtime descending (most recent first)
  const withMtimes = await Promise.all(
    files.map(async (f) => {
      const stat = await fs.stat(f).catch(() => null);
      return { f, mtime: stat?.mtimeMs ?? 0 };
    }),
  );
  withMtimes.sort((a, b) => b.mtime - a.mtime);

  const snippets: string[] = [];
  for (const { f } of withMtimes.slice(0, maxFiles)) {
    const content = await readTail(f, maxCharsEach);
    if (content) {
      snippets.push(`### ${path.basename(f, ".md")}\n${content}`);
    }
  }
  const result = snippets.length > 0 ? snippets.join("\n\n") : null;
  return setCache(cacheKey, result);
}

async function readAllBelief(dirPath: string, maxCharsEach: number): Promise<string | null> {
  const cacheKey = `belief:${dirPath}:${maxCharsEach}`;
  const cached = getCached<string | null>(cacheKey);
  if (cached !== undefined) {
    return cached;
  }

  const files = await readDir(dirPath);
  if (files.length === 0) {
    return setCache(cacheKey, null);
  }
  const snippets: string[] = [];
  for (const f of files.toSorted()) {
    const content = await readTail(f, maxCharsEach);
    if (content) {
      snippets.push(`### ${path.basename(f, ".md")}\n${content}`);
    }
  }
  const result = snippets.length > 0 ? snippets.join("\n\n") : null;
  return setCache(cacheKey, result);
}

// ---- Adaptive section filtering by agent type ----

export interface HubContextOpts {
  agentId?: string;
}

// Sections to SKIP per agent type. "main" (Planner) always gets all sections.
const AGENT_SECTION_SKIP: Record<string, Set<string>> = {
  // Executor only needs task-execution context: daily log, tasks, waiting, calendar.
  // Skip heavy narrative sections that are irrelevant for cron/task runs.
  executor: new Set(["beliefs", "people", "patterns", "roadmap", "tophub", "monthly"]),
  // Reviewer needs patterns, roadmap, monthly for reflection; skip ephemeral feed/email.
  reviewer: new Set(["email", "tophub", "calendar", "people", "beliefs"]),
};

function shouldIncludeSection(agentId: string | undefined, section: string): boolean {
  if (!agentId || agentId === "main") {
    return true;
  }
  const skip = AGENT_SECTION_SKIP[agentId];
  return !skip?.has(section);
}

// ---- End adaptive filtering ----

export async function buildHubContext(opts?: HubContextOpts): Promise<string> {
  const agentId = opts?.agentId;
  const hubPaths = resolveHubPaths();
  const today = getYmd(0);
  const yesterday = getYmd(-1);
  const sections: string[] = [];

  // Today's daily log (recent entries) — always included for all agents
  const todayLog = await readTail(path.join(hubPaths.dailyLogs, `${today}.md`), 1500);
  if (todayLog) {
    sections.push(`## 今日記錄 (${today})\n${todayLog}`);
  } else {
    // Fall back to yesterday if today is empty
    const yesterdayLog = await readTail(path.join(hubPaths.dailyLogs, `${yesterday}.md`), 1000);
    if (yesterdayLog) {
      sections.push(`## 昨日記錄 (${yesterday})\n${yesterdayLog}`);
    }
  }

  // Unchecked tasks — always included for all agents
  const tasksMaster = await readTail(path.join(hubPaths.work, "tasks_master.md"), 4000);
  if (tasksMaster) {
    const unchecked = extractUnchecked(tasksMaster, 8);
    if (unchecked) {
      sections.push(`## 待辦\n${unchecked}`);
    }
  }

  // Email inboxes — gmail.md + all *-mail.md (auto-discovered, new providers need no code change)
  if (shouldIncludeSection(agentId, "email")) {
    const emailSections: string[] = [];
    const gmail = await readTail(path.join(hubPaths.work, "gmail.md"), 400);
    if (gmail && gmail.split("\n").filter((l) => l.trim()).length > 1) {
      emailSections.push(gmail);
    }
    const workDirCacheKey = `rawdir:${hubPaths.work}`;
    let workEntries = getCached<string[]>(workDirCacheKey);
    if (workEntries === undefined) {
      try {
        workEntries = await fs.readdir(hubPaths.work);
      } catch {
        workEntries = [];
      }
      setCache(workDirCacheKey, workEntries);
    }
    const mailFiles = workEntries.filter((f) => f.endsWith("-mail.md")).toSorted(); // stable order
    for (const f of mailFiles) {
      const content = await readTail(path.join(hubPaths.work, f), 400);
      if (content && content.split("\n").filter((l) => l.trim()).length > 1) {
        emailSections.push(content);
      }
    }
    if (emailSections.length > 0) {
      sections.push(`## 郵件\n${emailSections.join("\n\n")}`);
    }
  }

  // Tophub hot topics (written by tophub-digest cron at 07:08)
  if (shouldIncludeSection(agentId, "tophub")) {
    const tophub = await readTail(path.join(hubPaths.work, "tophub-digest.md"), 400);
    if (tophub && tophub.split("\n").filter((l) => l.trim()).length > 3) {
      sections.push(`## 今日熱榜\n${tophub}`);
    }
  }

  // Calendar (written by daily-calendar cron at 07:00)
  if (shouldIncludeSection(agentId, "calendar")) {
    const calendarRaw = await readTail(path.join(hubPaths.work, "calendar.md"), 1200);
    if (calendarRaw && calendarRaw.includes("|")) {
      sections.push(`## 日曆\n${calendarRaw}`);
    }
  }

  // Roadmap (quarterly milestones & goals)
  if (shouldIncludeSection(agentId, "roadmap")) {
    const roadmap = await readTail(path.join(hubPaths.knowledge, "roadmap.md"), 600);
    if (roadmap) {
      sections.push(`## 路線圖\n${roadmap}`);
    }
  }

  // Waiting / watch items — always included for all agents
  const waiting = await readTail(path.join(hubPaths.work, "waiting.md"), 800);
  if (waiting && !waiting.startsWith("# waiting\n\n") && waiting !== "# waiting") {
    sections.push(`## 追蹤中\n${waiting}`);
  }

  // Monthly digests (last 2 months, written by monthly compression cron on 1st)
  if (shouldIncludeSection(agentId, "monthly")) {
    const monthlyDigestDir = path.join(hubPaths.knowledge, "monthly_digest");
    const monthlyContext = await readDirRecent(monthlyDigestDir, 2, 300);
    if (monthlyContext) {
      sections.push(`## 近期月摘要\n${monthlyContext}`);
    }
  }

  // Behaviour patterns (maintained by LLM weekly on Mondays)
  if (shouldIncludeSection(agentId, "patterns")) {
    const patterns = await readTail(path.join(hubPaths.knowledge, "patterns.md"), 400);
    if (patterns && patterns.split("\n").filter((l) => l.trim()).length > 2) {
      sections.push(`## 行為模式\n${patterns}`);
    }
  }

  // People / contact cards (most recently updated, up to 3)
  if (shouldIncludeSection(agentId, "people")) {
    const peopleContext = await readDirRecent(hubPaths.people, 3, 400);
    if (peopleContext) {
      sections.push(`## 相關聯絡人\n${peopleContext}`);
    }
  }

  // Wisdom / beliefs (all files, condensed)
  if (shouldIncludeSection(agentId, "beliefs")) {
    const beliefsContext = await readAllBelief(hubPaths.beliefs, 300);
    if (beliefsContext) {
      sections.push(`## 決策智慧\n${beliefsContext}`);
    }
  }

  if (sections.length === 0) {
    return "";
  }

  const body = sections.join("\n\n");
  const capped =
    body.length > HUB_CONTEXT_MAX_CHARS
      ? body.slice(0, HUB_CONTEXT_MAX_CHARS) + "\n...(截斷)"
      : body;

  return [
    "## 近期記憶 (capture 記憶系統)",
    "以下是自動從 assistant_hub 讀取的近期背景資料，供你了解最近發生的事：",
    "",
    capped,
  ].join("\n");
}
