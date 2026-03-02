import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import type { CaptureResolvedPaths, CaptureDateParts } from "./types.js";
import {
  resolveHubPaths,
  resolveHubRoot,
  safeReadDir,
  slugifyTitle,
  buildCardMarkdown,
  escapeTableCell,
  typeEmoji,
  resolveMainPath,
  resolvePathSet,
} from "./hub.js";

const NOW: CaptureDateParts = {
  ymd: "2026-02-20",
  hm: "09:00",
  isoWithOffset: "2026-02-20T09:00:00+08:00",
};

// ───────────────────────────── resolveHubRoot ──────────────────────────────

describe("resolveHubRoot", () => {
  const prevHubRoot = process.env.CAPTURE_HUB_ROOT;

  afterEach(() => {
    if (prevHubRoot === undefined) {
      delete process.env.CAPTURE_HUB_ROOT;
    } else {
      process.env.CAPTURE_HUB_ROOT = prevHubRoot;
    }
  });

  it("returns CAPTURE_HUB_ROOT when set", () => {
    process.env.CAPTURE_HUB_ROOT = "/custom/hub/root";
    expect(resolveHubRoot()).toBe("/custom/hub/root");
  });

  it("returns CAPTURE_HUB_ROOT trimmed", () => {
    process.env.CAPTURE_HUB_ROOT = "  /trimmed/path  ";
    expect(resolveHubRoot()).toBe("/trimmed/path");
  });

  it("falls back to default path under state dir when env var is unset", () => {
    delete process.env.CAPTURE_HUB_ROOT;
    const root = resolveHubRoot();
    expect(root).toContain("assistant_hub");
    expect(root).toContain("automation");
  });
});

// ─────────────────────────── resolveHubPaths ──────────────────────────────

describe("resolveHubPaths", () => {
  it("returns correct subdirectory structure from a given root", () => {
    const root = "/some/root";
    const paths = resolveHubPaths(root);

    expect(paths.root).toBe(root);
    expect(paths.inbox).toBe(path.join(root, "00_inbox"));
    expect(paths.work).toBe(path.join(root, "02_work"));
    expect(paths.life).toBe(path.join(root, "03_life"));
    expect(paths.knowledge).toBe(path.join(root, "04_knowledge"));
    expect(paths.meta).toBe(path.join(root, "05_meta"));
  });

  it("derives nested paths correctly", () => {
    const root = "/hub";
    const paths = resolveHubPaths(root);

    expect(paths.tasks).toBe(path.join(root, "02_work", "tasks"));
    expect(paths.projects).toBe(path.join(root, "02_work", "projects", "_misc"));
    expect(paths.dailyLogs).toBe(path.join(root, "03_life", "daily_logs"));
    expect(paths.ideas).toBe(path.join(root, "03_life", "ideas"));
    expect(paths.highlights).toBe(path.join(root, "03_life", "highlights"));
    expect(paths.people).toBe(path.join(root, "04_knowledge", "people"));
    expect(paths.questions).toBe(path.join(root, "04_knowledge", "questions"));
    expect(paths.beliefs).toBe(path.join(root, "04_knowledge", "beliefs"));
    expect(paths.references).toBe(path.join(root, "04_knowledge", "references"));
  });

  it("uses resolveHubRoot() when no root is provided", () => {
    const paths = resolveHubPaths();
    expect(paths.root).toBe(resolveHubRoot());
  });

  it("handles root with trailing slash consistently", () => {
    const root = "/my/hub";
    const paths = resolveHubPaths(root);
    // path.join normalises slashes - no double slashes
    expect(paths.inbox).not.toContain("//");
    expect(paths.tasks).not.toContain("//");
  });
});

// ─────────────────────────── safeReadDir ──────────────────────────────────

describe("safeReadDir", () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "hub-safeReadDir-"));
  });

  afterEach(async () => {
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  it("returns empty array for a non-existent directory", async () => {
    const result = await safeReadDir(path.join(tmpDir, "does-not-exist"));
    expect(result).toEqual([]);
  });

  it("returns empty array for an empty directory", async () => {
    const result = await safeReadDir(tmpDir);
    expect(result).toEqual([]);
  });

  it("returns file paths for files in a directory", async () => {
    await fs.writeFile(path.join(tmpDir, "a.md"), "content-a");
    await fs.writeFile(path.join(tmpDir, "b.txt"), "content-b");
    const result = await safeReadDir(tmpDir);
    expect(result.length).toBe(2);
    expect(result).toContain(path.join(tmpDir, "a.md"));
    expect(result).toContain(path.join(tmpDir, "b.txt"));
  });

  it("recursively lists files in subdirectories", async () => {
    const sub = path.join(tmpDir, "subdir");
    await fs.mkdir(sub);
    await fs.writeFile(path.join(tmpDir, "top.md"), "top");
    await fs.writeFile(path.join(sub, "nested.md"), "nested");
    const result = await safeReadDir(tmpDir);
    expect(result).toContain(path.join(tmpDir, "top.md"));
    expect(result).toContain(path.join(sub, "nested.md"));
    expect(result.length).toBe(2);
  });

  it("does not include directories themselves, only files", async () => {
    const sub = path.join(tmpDir, "emptySubdir");
    await fs.mkdir(sub);
    const result = await safeReadDir(tmpDir);
    // the empty subdirectory contributes no entries
    expect(result).toEqual([]);
  });
});

// ─────────────────────────── slugifyTitle ─────────────────────────────────

describe("slugifyTitle", () => {
  it("lowercases and replaces spaces with underscores", () => {
    expect(slugifyTitle("Hello World", "memory")).toBe("hello_world");
  });

  it("strips leading and trailing underscores", () => {
    expect(slugifyTitle("!!! title !!!", "idea")).toBe("title");
  });

  it("truncates to 24 characters", () => {
    const long = "abcdefghijklmnopqrstuvwxyz";
    const result = slugifyTitle(long, "action");
    expect(result.length).toBeLessThanOrEqual(24);
  });

  it("falls back to the fallbackType when input normalises to 'note'", () => {
    // All special chars → empty slug → fallback
    expect(slugifyTitle("!!!", "question")).toBe("question");
  });

  it("handles Chinese characters by stripping them (non-ascii become underscores)", () => {
    const result = slugifyTitle("日記 test entry", "memory");
    // Non-ASCII replaced by _, then trimmed
    expect(result).toContain("test_entry");
  });
});

// ─────────────────────────── escapeTableCell ──────────────────────────────

describe("escapeTableCell", () => {
  it("escapes pipe characters", () => {
    expect(escapeTableCell("a | b")).toBe("a \\| b");
  });

  it("passes through strings with no pipes unchanged", () => {
    expect(escapeTableCell("hello world")).toBe("hello world");
  });

  it("escapes multiple pipes", () => {
    expect(escapeTableCell("a | b | c")).toBe("a \\| b \\| c");
  });
});

// ─────────────────────────── typeEmoji ────────────────────────────────────

describe("typeEmoji", () => {
  it("returns correct emoji for each type", () => {
    expect(typeEmoji("action")).toBe("⚡");
    expect(typeEmoji("timeline")).toBe("📍");
    expect(typeEmoji("watch")).toBe("👀");
    expect(typeEmoji("idea")).toBe("💡");
    expect(typeEmoji("question")).toBe("❓");
    expect(typeEmoji("belief")).toBe("🧠");
    expect(typeEmoji("memory")).toBe("📝");
    expect(typeEmoji("highlight")).toBe("✨");
    expect(typeEmoji("reference")).toBe("📖");
    expect(typeEmoji("person")).toBe("👤");
  });
});

// ─────────────────────────── resolveMainPath ──────────────────────────────

describe("resolveMainPath", () => {
  const root = "/hub";
  let paths: CaptureResolvedPaths;

  beforeEach(() => {
    paths = resolveHubPaths(root);
  });

  it("routes action type to tasks directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-001",
      slug: "test_task",
      type: "action",
      paths,
      now: NOW,
    });
    expect(p).toContain("tasks");
    expect(p).toContain("2026-02-20-001_test_task.md");
  });

  it("routes idea type to ideas directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-002",
      slug: "my_idea",
      type: "idea",
      paths,
      now: NOW,
    });
    expect(p).toContain("ideas");
  });

  it("routes person type to people directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-003",
      slug: "john_smith",
      type: "person",
      paths,
      now: NOW,
    });
    expect(p).toContain("people");
  });

  it("routes memory type to daily_logs with date-only filename", () => {
    const p = resolveMainPath({
      id: "2026-02-20-004",
      slug: "unused",
      type: "memory",
      paths,
      now: NOW,
    });
    expect(p).toContain("daily_logs");
    expect(p).toContain("2026-02-20.md");
  });

  it("routes question type to questions directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-005",
      slug: "q",
      type: "question",
      paths,
      now: NOW,
    });
    expect(p).toContain("questions");
  });

  it("routes belief type to beliefs directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-006",
      slug: "my_belief",
      type: "belief",
      paths,
      now: NOW,
    });
    expect(p).toContain("beliefs");
  });

  it("routes reference type to references directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-007",
      slug: "paper",
      type: "reference",
      paths,
      now: NOW,
    });
    expect(p).toContain("references");
  });

  it("routes watch type to tasks directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-008",
      slug: "watch_item",
      type: "watch",
      paths,
      now: NOW,
    });
    expect(p).toContain("tasks");
  });

  it("routes highlight type to highlights directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-009",
      slug: "highlight_item",
      type: "highlight",
      paths,
      now: NOW,
    });
    expect(p).toContain("highlights");
  });

  it("routes timeline type to projects directory", () => {
    const p = resolveMainPath({
      id: "2026-02-20-010",
      slug: "roadmap",
      type: "timeline",
      paths,
      now: NOW,
    });
    expect(p).toContain("projects");
  });
});
