import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { parseDeleteRequest, deleteFromAssistantHub } from "./maybe-run-capture.js";

// ────────────────────────── parseDeleteRequest ──────────────────────────────

describe("parseDeleteRequest", () => {
  it("parses English 'delete' with a name", () => {
    expect(parseDeleteRequest("delete John Smith")).toEqual({ query: "John Smith" });
  });

  it("parses English 'remove' with a name", () => {
    expect(parseDeleteRequest("remove Jane Doe")).toEqual({ query: "Jane Doe" });
  });

  it("parses Traditional Chinese '刪除'", () => {
    expect(parseDeleteRequest("刪除 張三")).toEqual({ query: "張三" });
  });

  it("parses Simplified Chinese '删除'", () => {
    expect(parseDeleteRequest("删除 李四")).toEqual({ query: "李四" });
  });

  it("parses '移除' (remove in Chinese)", () => {
    expect(parseDeleteRequest("移除 王五")).toEqual({ query: "王五" });
  });

  it("parses '取消' (cancel in Chinese)", () => {
    expect(parseDeleteRequest("取消 某項目")).toEqual({ query: "某項目" });
  });

  it("is case-insensitive for English commands", () => {
    expect(parseDeleteRequest("DELETE some card")).toEqual({ query: "some card" });
    expect(parseDeleteRequest("Remove another card")).toEqual({ query: "another card" });
  });

  it("trims surrounding whitespace from the input", () => {
    expect(parseDeleteRequest("  delete  card name  ")).toEqual({ query: "card name" });
  });

  it("returns null for empty string", () => {
    expect(parseDeleteRequest("")).toBeNull();
  });

  it("returns null for plain 'delete' with no query", () => {
    expect(parseDeleteRequest("delete")).toBeNull();
  });

  it("returns null for 'delete   ' (whitespace-only query)", () => {
    expect(parseDeleteRequest("delete   ")).toBeNull();
  });

  it("returns null for unrecognised command prefix", () => {
    expect(parseDeleteRequest("erase something")).toBeNull();
    expect(parseDeleteRequest("cancel item")).toBeNull();
  });

  it("returns null for arbitrary non-command text", () => {
    expect(parseDeleteRequest("今天下午散步半小時")).toBeNull();
  });
});

// ─────────────────────── deleteFromAssistantHub ──────────────────────────────

async function createCardFixture(
  root: string,
  opts: {
    dir: string;
    id: string;
    title: string;
    alreadyDeleted?: boolean;
  },
): Promise<string> {
  const { dir, id, title, alreadyDeleted } = opts;
  await fs.mkdir(dir, { recursive: true });
  const slug = title.toLowerCase().replace(/\s+/g, "_").slice(0, 20);
  const filePath = path.join(dir, `${id}_${slug}.md`);
  const deletedLine = alreadyDeleted ? "\nstatus: deleted" : "";
  const content = [
    "---",
    `id: ${id}`,
    "type: idea",
    `title: ${title}`,
    "created: 2026-02-20",
    "source: telegram",
    "priority: null",
    "due: null",
    'tags: ["idea"]',
    "convert_to_task: false",
    "long_term_memory: false",
    "calendar_entry: false",
    "stage: null",
    "q_status: null",
    "confidence: 0.76",
    "alts: []",
    "dedupe_hint: new",
    "next_best_action: null",
    "links: []",
    "attachments: []",
    "remind_schedule:",
    "  mode: none",
    "  checkpoints: []",
    "  auto_archive_after: null",
    "feedback:",
    "  token: fb_test",
    "  watch_type: none",
    "  expected_horizon_days: null",
    `${deletedLine}`,
    "---",
    "",
    "## 原文",
    "Test content",
    "",
  ].join("\n");
  await fs.writeFile(filePath, content, "utf8");
  return filePath;
}

describe("deleteFromAssistantHub", () => {
  let rootDir: string;
  const prevHubRoot = process.env.CAPTURE_HUB_ROOT;

  beforeEach(async () => {
    rootDir = await fs.mkdtemp(path.join(os.tmpdir(), "hub-delete-"));
    process.env.CAPTURE_HUB_ROOT = rootDir;
  });

  afterEach(async () => {
    if (prevHubRoot === undefined) {
      delete process.env.CAPTURE_HUB_ROOT;
    } else {
      process.env.CAPTURE_HUB_ROOT = prevHubRoot;
    }
    await fs.rm(rootDir, { recursive: true, force: true });
  });

  it("marks a matching card as deleted and returns touchedFiles=1", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id: "2026-02-20-001",
      title: "Test Idea Card",
    });

    const result = await deleteFromAssistantHub("Test Idea Card");
    expect(result.touchedFiles).toBe(1);

    const files = await fs.readdir(ideasDir);
    const cardContent = await fs.readFile(path.join(ideasDir, files[0]), "utf8");
    expect(cardContent).toContain("status: deleted");
  });

  it("is case-insensitive in matching title", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id: "2026-02-20-002",
      title: "Case Sensitive Title",
    });

    const result = await deleteFromAssistantHub("case sensitive title");
    expect(result.touchedFiles).toBe(1);
  });

  it("skips cards already marked as deleted", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id: "2026-02-20-003",
      title: "Already Gone",
      alreadyDeleted: true,
    });

    const result = await deleteFromAssistantHub("Already Gone");
    expect(result.touchedFiles).toBe(0);
  });

  it("returns touchedFiles=0 when no card matches the query", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id: "2026-02-20-004",
      title: "Existing Card",
    });

    const result = await deleteFromAssistantHub("Nonexistent Query XYZ");
    expect(result.touchedFiles).toBe(0);
  });

  it("returns touchedFiles=0 when hub directories are empty", async () => {
    const result = await deleteFromAssistantHub("anything");
    expect(result.touchedFiles).toBe(0);
    expect(result.removedLines).toBe(0);
  });

  it("removes entry from tasks_master.md index when deleting a card", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    const workDir = path.join(rootDir, "02_work");
    await fs.mkdir(workDir, { recursive: true });
    const id = "2026-02-20-005";
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id,
      title: "Indexed Card",
    });
    await fs.writeFile(
      path.join(workDir, "tasks_master.md"),
      `- [ ] Indexed Card (id:${id}) type:idea\n`,
      "utf8",
    );

    const result = await deleteFromAssistantHub("Indexed Card");
    expect(result.touchedFiles).toBe(1);
    expect(result.removedLines).toBe(1);

    const master = await fs.readFile(path.join(workDir, "tasks_master.md"), "utf8");
    expect(master).not.toContain(id);
  });

  it("handles multiple cards matching the query and marks all deleted", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id: "2026-02-20-006",
      title: "Shared Keyword Card",
    });
    const highlightsDir = path.join(rootDir, "03_life", "highlights");
    await createCardFixture(rootDir, {
      dir: highlightsDir,
      id: "2026-02-20-007",
      title: "Another Shared Keyword Card",
    });

    // Both titles contain "Shared Keyword Card"
    const result = await deleteFromAssistantHub("Shared Keyword Card");
    expect(result.touchedFiles).toBe(2);
  });

  it("appends a lifecycle entry with the query after marking deleted", async () => {
    const ideasDir = path.join(rootDir, "03_life", "ideas");
    const id = "2026-02-20-008";
    await createCardFixture(rootDir, {
      dir: ideasDir,
      id,
      title: "Lifecycle Card",
    });

    await deleteFromAssistantHub("Lifecycle Card");

    const files = await fs.readdir(ideasDir);
    const cardContent = await fs.readFile(path.join(ideasDir, files[0]), "utf8");
    expect(cardContent).toContain("deleted:");
    expect(cardContent).toContain("Lifecycle Card");
  });
});
