#!/usr/bin/env -S node --import tsx
import fs from "node:fs";

type ToolInput = {
  request_id?: string;
  title?: string;
  question?: string;
  priority?: string | null;
  tags?: string[];
  context?: string[];
};

function readInput(): ToolInput {
  const raw = fs.readFileSync(0, "utf8").trim();
  if (!raw) {
    return {};
  }
  try {
    return JSON.parse(raw) as ToolInput;
  } catch {
    return { question: raw };
  }
}

function truncate(input: string, limit: number): string {
  if (input.length <= limit) {
    return input;
  }
  return `${input.slice(0, Math.max(0, limit - 3)).trim()}...`;
}

function main() {
  const input = readInput();
  const question = (input.question ?? "").trim() || "未提供問題";
  const title = (input.title ?? "").trim() || truncate(question, 28);
  const context = Array.isArray(input.context)
    ? input.context.filter((line) => typeof line === "string" && line.trim())
    : [];
  const tagList = Array.isArray(input.tags)
    ? input.tags.filter((tag) => typeof tag === "string" && tag.trim())
    : [];

  const output = {
    summary: `【Mock】已完成 NotebookLM 摘要：${truncate(title, 42)}`,
    key_points: [
      `問題重點：${truncate(question, 64)}`,
      context.length > 0 ? `上下文：${truncate(String(context[0]), 56)}` : "上下文：未提供",
      `優先級：${input.priority ?? "P2"}`,
    ],
    action_items: [
      "確認是否需要轉成任務卡",
      "如需追蹤，設定下一個 checkpoint",
      "補充來源鏈接或引用材料",
    ],
    sources: [
      {
        title: "NotebookLM Mock Source",
        url: "https://example.com/notebooklm-mock",
        note: `request_id=${input.request_id ?? "unknown"} tags=${tagList.join(",") || "none"}`,
      },
    ],
    confidence: 0.78,
    raw_text: `mock_tool_response: ${question}`,
  };

  process.stdout.write(`${JSON.stringify(output)}\n`);
}

main();
