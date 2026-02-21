import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { OpenClawConfig } from "../../config/config.js";
import type { FinalizedMsgContext } from "../templating.js";

const mocks = vi.hoisted(() => ({
  runCaptureAgent: vi.fn(async () => ({
    timezone: "Asia/Shanghai",
    date: "2026-02-20",
    source: "telegram",
    ack: {
      line1: "ack-1",
      line2: "ack-2",
    },
    items: [],
  })),
}));

vi.mock("../../capture-agent/run.js", () => ({
  runCaptureAgent: mocks.runCaptureAgent,
}));

import { maybeRunCapture } from "./maybe-run-capture.js";

const CAPTURE_CFG = {
  capture: {
    enabled: true,
  },
} as unknown as OpenClawConfig;

function makeCtx(partial: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    BodyForCommands: "",
    Surface: "telegram",
    Provider: "telegram",
    MessageSid: "m-default",
    CommandAuthorized: true,
    ...partial,
  };
}

async function withTempEnv(
  vars: Record<string, string | undefined>,
  fn: () => Promise<void>,
): Promise<void> {
  const prev = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(vars)) {
    prev.set(key, process.env[key]);
    if (value === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = value;
    }
  }
  try {
    await fn();
  } finally {
    for (const [key, value] of prev.entries()) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
}

async function createWatchFixture(root: string, id: string): Promise<void> {
  await fs.mkdir(path.join(root, "02_work", "tasks"), { recursive: true });
  await fs.mkdir(path.join(root, "05_meta"), { recursive: true });
  const slug = "sample_watch";
  await fs.writeFile(
    path.join(root, "02_work", "tasks", `${id}_${slug}.md`),
    [
      "---",
      `id: ${id}`,
      "type: watch",
      "title: Sample watch",
      "created: 2026-02-20",
      "source: telegram",
      "priority: null",
      "due: 2026-02-22",
      'tags: ["watch"]',
      "convert_to_task: false",
      "long_term_memory: false",
      "calendar_entry: true",
      "stage: null",
      "q_status: null",
      "confidence: 0.84",
      "alts: []",
      "dedupe_hint: new",
      "next_best_action: null",
      "links: []",
      "attachments: []",
      "remind_schedule:",
      "  mode: auto",
      '  checkpoints: ["2026-02-21"]',
      "  auto_archive_after: 2026-02-22",
      "feedback:",
      "  token: fb_1",
      "  watch_type: watch",
      "  expected_horizon_days: 7",
      "---",
      "",
      "## 原文",
      "hello",
      "message_id: tg-origin-1",
      "",
      "## 你的整理",
      "- Sample watch",
      "",
    ].join("\n"),
    "utf8",
  );
  await fs.writeFile(
    path.join(root, "02_work", "tasks_master.md"),
    `- [ ] Sample watch (id:${id}) type:watch priority:null due:2026-02-22 conf:0.84 tags:watch remind:2026-02-21\n`,
    "utf8",
  );
  await fs.writeFile(
    path.join(root, "02_work", "waiting.md"),
    `- Sample watch (id:${id}) due:2026-02-22 checkpoints:2026-02-21 conf:0.84\n`,
    "utf8",
  );
  await fs.writeFile(
    path.join(root, "05_meta", "reasoning_queue.jsonl"),
    `${JSON.stringify({
      id,
      type: "watch",
      due: "2026-02-22",
      checkpoints: ["2026-02-21"],
      auto_archive_after: "2026-02-22",
      consumed: false,
      confidence: 0.84,
    })}\n`,
    "utf8",
  );
  await fs.writeFile(path.join(root, "05_meta", "feedback_signals.jsonl"), "", "utf8");
}

describe("maybeRunCapture control loop", () => {
  let rootDir = "";
  const prevHubRoot = process.env.CAPTURE_HUB_ROOT;

  beforeEach(async () => {
    rootDir = await fs.mkdtemp(path.join(os.tmpdir(), "capture-control-"));
    process.env.CAPTURE_HUB_ROOT = rootDir;
    mocks.runCaptureAgent.mockClear();
  });

  afterEach(async () => {
    if (prevHubRoot === undefined) {
      delete process.env.CAPTURE_HUB_ROOT;
    } else {
      process.env.CAPTURE_HUB_ROOT = prevHubRoot;
    }
    await fs.rm(rootDir, { recursive: true, force: true });
  });

  it("converts watch to action on `1` command", async () => {
    const id = "2026-02-20-001";
    await createWatchFixture(rootDir, id);

    const result = await maybeRunCapture({
      ctx: makeCtx({
        BodyForCommands: `1 ${id}`,
        MessageSid: "cmd-1",
      }),
      cfg: CAPTURE_CFG,
    });

    expect(result.handled).toBe(true);
    expect(result.payload?.text).toContain("已轉任務");
    expect(result.payload?.text).toContain(id);
    expect(mocks.runCaptureAgent).not.toHaveBeenCalled();

    const card = await fs.readFile(
      path.join(rootDir, "02_work", "tasks", `${id}_sample_watch.md`),
      "utf8",
    );
    expect(card).toContain("type: action");
    expect(card).toContain("stage: active");
    expect(card).toContain("watch_converted:");

    const waiting = await fs.readFile(path.join(rootDir, "02_work", "waiting.md"), "utf8");
    expect(waiting).not.toContain(id);

    const queue = await fs.readFile(path.join(rootDir, "05_meta", "reasoning_queue.jsonl"), "utf8");
    expect(queue).toContain('"consumed":true');
    expect(queue).toContain('"consumed_reason":"watch_converted"');

    const feedback = await fs.readFile(
      path.join(rootDir, "05_meta", "feedback_signals.jsonl"),
      "utf8",
    );
    expect(feedback).toContain('"type":"watch_converted"');
  });

  it("abandons watch on `0` command resolved from reply body", async () => {
    const id = "2026-02-20-002";
    await createWatchFixture(rootDir, id);

    const result = await maybeRunCapture({
      ctx: makeCtx({
        BodyForCommands: "0",
        ReplyToBody: `→ assistant_hub/02_work/tasks/${id}_sample_watch.md`,
        MessageSid: "cmd-2",
      }),
      cfg: CAPTURE_CFG,
    });

    expect(result.handled).toBe(true);
    expect(result.payload?.text).toContain("已停止提醒");
    expect(result.payload?.text).toContain(id);
    expect(mocks.runCaptureAgent).not.toHaveBeenCalled();

    const card = await fs.readFile(
      path.join(rootDir, "02_work", "tasks", `${id}_sample_watch.md`),
      "utf8",
    );
    expect(card).toContain("type: watch");
    expect(card).toContain("stage: archived");
    expect(card).toContain("watch_abandoned:");

    const tasksMaster = await fs.readFile(path.join(rootDir, "02_work", "tasks_master.md"), "utf8");
    expect(tasksMaster).toContain("- [x] Sample watch");
    expect(tasksMaster).toContain("abandoned:");

    const queue = await fs.readFile(path.join(rootDir, "05_meta", "reasoning_queue.jsonl"), "utf8");
    expect(queue).toContain('"consumed":true');
    expect(queue).toContain('"consumed_reason":"watch_abandoned"');

    const feedback = await fs.readFile(
      path.join(rootDir, "05_meta", "feedback_signals.jsonl"),
      "utf8",
    );
    expect(feedback).toContain('"type":"watch_abandoned"');
  });

  it("falls back to regular capture run for non-control text", async () => {
    const result = await maybeRunCapture({
      ctx: makeCtx({
        BodyForCommands: "這是一條普通 capture 訊息",
        MessageSid: "cmd-3",
      }),
      cfg: CAPTURE_CFG,
    });

    expect(result.handled).toBe(true);
    expect(result.payload?.text).toContain("ack-1");
    expect(mocks.runCaptureAgent).toHaveBeenCalledTimes(1);
  });

  it("queues NotebookLM and skips capture when mode=queue_only", async () => {
    await withTempEnv(
      {
        MOLTBOT_NOTEBOOKLM_ENABLED: "1",
        MOLTBOT_NOTEBOOKLM_MODE: "queue_only",
      },
      async () => {
        const result = await maybeRunCapture({
          ctx: makeCtx({
            BodyForCommands: "/nb 幫我研究 OpenAI Agents SDK 最近更新",
            MessageSid: "nb-msg-1",
          }),
          cfg: CAPTURE_CFG,
        });

        expect(result.handled).toBe(true);
        expect(result.payload?.text).toContain("NotebookLM 任務已排隊");
        expect(mocks.runCaptureAgent).not.toHaveBeenCalled();

        const queue = await fs.readFile(
          path.join(rootDir, "05_meta", "notebooklm_requests.jsonl"),
          "utf8",
        );
        expect(queue).toContain('"question":"幫我研究 OpenAI Agents SDK 最近更新"');
        expect(queue).toContain('"source_message_id":"nb-msg-1"');
      },
    );
  });

  it("queues NotebookLM, writes capture, and allows core model when mode=queue_capture_and_model", async () => {
    await withTempEnv(
      {
        MOLTBOT_NOTEBOOKLM_ENABLED: "1",
        MOLTBOT_NOTEBOOKLM_MODE: "queue_capture_and_model",
      },
      async () => {
        const result = await maybeRunCapture({
          ctx: makeCtx({
            BodyForCommands: "/nb 幫我比較 Gemini 與 GPT 的長文研究能力？",
            MessageSid: "nb-msg-2",
          }),
          cfg: CAPTURE_CFG,
        });

        expect(result.handled).toBe(true);
        expect(result.payload).toBeUndefined();
        expect(mocks.runCaptureAgent).toHaveBeenCalledTimes(1);

        const queue = await fs.readFile(
          path.join(rootDir, "05_meta", "notebooklm_requests.jsonl"),
          "utf8",
        );
        expect(queue).toContain('"source_message_id":"nb-msg-2"');
      },
    );
  });
});
