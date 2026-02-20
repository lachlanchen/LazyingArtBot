import fs from "node:fs/promises";
import path from "node:path";
import { ensureHubPaths, ensureHubScaffoldFiles, resolveHubPaths, typeEmoji } from "../../src/capture-agent/hub.js";

export type QueueEntry = {
  token?: string;
  id?: string;
  type?: string;
  priority?: string | null;
  tags?: string[];
  confidence?: number;
  calendar_entry?: boolean;
  due?: string | null;
  checkpoints?: string[];
  auto_archive_after?: string | null;
  ts?: string;
  consumed?: boolean;
};

export type FeedbackSignal = {
  token?: string;
  type?: string;
  id?: string;
  date?: string;
  created_at?: string;
  [key: string]: unknown;
};

export async function initHub() {
  const paths = resolveHubPaths();
  await ensureHubPaths(paths);
  await ensureHubScaffoldFiles(paths);
  return paths;
}

export function envBool(name: string, fallback: boolean): boolean {
  const raw = process.env[name]?.trim().toLowerCase();
  if (!raw) {
    return fallback;
  }
  return raw === "1" || raw === "true" || raw === "yes" || raw === "on";
}

export function tokyoYmd(now = new Date()): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now);
}

export function shiftYmd(ymd: string, days: number): string {
  const [year, month, day] = ymd.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + days);
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function dayDiff(fromYmd: string, toYmd: string): number {
  const [fy, fm, fd] = fromYmd.split("-").map(Number);
  const [ty, tm, td] = toYmd.split("-").map(Number);
  const from = new Date(Date.UTC(fy, fm - 1, fd));
  const to = new Date(Date.UTC(ty, tm - 1, td));
  return Math.round((to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000));
}

export async function readText(filePath: string): Promise<string> {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch {
    return "";
  }
}

export async function writeText(filePath: string, content: string): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, content, "utf8");
}

export async function appendText(filePath: string, content: string): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.appendFile(filePath, content, "utf8");
}

export async function readJsonl<T extends object>(filePath: string): Promise<T[]> {
  const raw = await readText(filePath);
  if (!raw.trim()) {
    return [];
  }
  const rows: T[] = [];
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    try {
      rows.push(JSON.parse(trimmed) as T);
    } catch {
      // skip malformed line
    }
  }
  return rows;
}

export async function appendJsonlUnique(params: {
  filePath: string;
  rows: FeedbackSignal[];
}): Promise<number> {
  const existing = await readJsonl<FeedbackSignal>(params.filePath);
  const tokens = new Set(existing.map((row) => String(row.token ?? "")).filter(Boolean));
  const toAppend = params.rows.filter((row) => {
    const token = String(row.token ?? "");
    if (!token || tokens.has(token)) {
      return false;
    }
    tokens.add(token);
    return true;
  });
  if (toAppend.length === 0) {
    return 0;
  }
  await appendText(
    params.filePath,
    toAppend.map((row) => `${JSON.stringify(row)}\n`).join(""),
  );
  return toAppend.length;
}

export async function writeJsonl(params: {
  filePath: string;
  rows: object[];
}): Promise<void> {
  const content = params.rows.map((row) => JSON.stringify(row)).join("\n");
  await writeText(params.filePath, content ? `${content}\n` : "");
}

async function walkMarkdown(dirPath: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const files: string[] = [];
    for (const entry of entries) {
      const full = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        files.push(...(await walkMarkdown(full)));
      } else if (entry.isFile() && entry.name.endsWith(".md")) {
        files.push(full);
      }
    }
    return files;
  } catch {
    return [];
  }
}

function extractField(content: string, key: string): string | null {
  const hit = content.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  if (!hit?.[1]) {
    return null;
  }
  const value = hit[1].trim().replace(/^"(.*)"$/, "$1");
  return value || null;
}

export async function buildCardIndex(root: string): Promise<Map<string, { title: string; type: string; path: string }>> {
  const files = await walkMarkdown(root);
  const out = new Map<string, { title: string; type: string; path: string }>();
  for (const filePath of files) {
    const base = path.basename(filePath);
    if (base.startsWith("_") || base === "index.md" || base === "TAGS.md") {
      continue;
    }
    const content = await readText(filePath);
    if (!content.startsWith("---\n")) {
      continue;
    }
    const id = extractField(content, "id");
    if (!id) {
      continue;
    }
    const title = extractField(content, "title") ?? id;
    const type = extractField(content, "type") ?? "memory";
    out.set(id, { title, type, path: filePath });
  }
  return out;
}

export function escapeCell(value: string): string {
  return value.replace(/\|/g, "\\|");
}

export function labelType(type: string | undefined): string {
  const normalized = (type ?? "memory").trim() || "memory";
  return `${typeEmoji(normalized as never)} ${normalized}`;
}
