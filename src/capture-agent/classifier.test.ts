import { describe, expect, it } from "vitest";
import { classifyCaptureInput } from "./classifier.js";

const NOW = {
  ymd: "2026-02-20",
  hm: "09:00",
  isoWithOffset: "2026-02-20T09:00:00+08:00",
} as const;

function classify(content: string) {
  return classifyCaptureInput(
    {
      content,
      attachments: [],
      metadata: {
        platform: "telegram",
        messageId: "m-1",
        timestamp: "2026-02-20T09:00:00.000Z",
      },
    },
    NOW,
    {},
  );
}

describe("capture classifier P1 coverage", () => {
  it("classifies action via strong task signal", () => {
    const out = classify("請幫我跟進這個 PR，今天要做");
    expect(out.type).toBe("action");
  });

  it("classifies timeline via timeline terms/range", () => {
    const out = classify("3/01-3/15 roadmap 里程碑安排，分三個階段");
    expect(out.type).toBe("timeline");
  });

  it("classifies person and keeps due from relative date", () => {
    const out = classify("跟 @ken 對齊合約條款，明天 09:30 提醒我");
    expect(out.type).toBe("person");
    expect(out.due).toBe("2026-02-21 09:30");
  });

  it("classifies watch for pure time-structured note", () => {
    const out = classify("2026-03-01 18:00 提醒續費");
    expect(out.type).toBe("watch");
    expect(out.due).toBe("2026-03-01 18:00");
  });

  it("classifies question", () => {
    const out = classify("這個方案如何落地？");
    expect(out.type).toBe("question");
  });

  it("classifies reference when URL appears", () => {
    const out = classify("參考資料：https://example.com/paper");
    expect(out.type).toBe("reference");
  });

  it("classifies belief", () => {
    const out = classify("我相信長期主義比短期套利更重要，這是我的原則。");
    expect(out.type).toBe("belief");
  });

  it("classifies highlight", () => {
    const out = classify("重點：先做最小可行版本，這句收藏這句。");
    expect(out.type).toBe("highlight");
  });

  it("classifies idea from no-task + ideation signal", () => {
    const out = classify("只是記一下，這是個新想法。");
    expect(out.type).toBe("idea");
  });

  it("falls back to memory", () => {
    const out = classify("今天下午散步半小時。");
    expect(out.type).toBe("memory");
  });

  it("derives priority from urgency keyword", () => {
    const out = classify("這件很緊急，今天要處理。");
    expect(out.priority).toBe("P0");
  });

  it("parses month/day due into future date", () => {
    const out = classify("3/27 10:00 提醒我交報告");
    expect(out.due).toBe("2026-03-27 10:00");
  });
});

describe("capture classifier P2 coverage – additional edge cases", () => {
  it("classifies reference when URL appears without extra keywords", () => {
    const out = classify("https://github.com/openai/openai-python");
    expect(out.type).toBe("reference");
    expect(out.tags).toContain("link");
  });

  it("classifies highlight when '金句' keyword is present", () => {
    const out = classify("金句：stay hungry, stay foolish — Jobs");
    expect(out.type).toBe("highlight");
  });

  it("classifies idea from '點子' keyword without task signal", () => {
    const out = classify("一個新點子：用 AR 顯示每日待辦");
    expect(out.type).toBe("idea");
  });

  it("derives P1 priority from '重要' keyword", () => {
    const out = classify("重要：這個決策要今天前完成");
    expect(out.priority).toBe("P1");
  });

  it("derives P2 priority from 'later' keyword", () => {
    const out = classify("later 再來看看這個 repo");
    expect(out.priority).toBe("P2");
  });

  it("respects explicit P3 label in text", () => {
    const out = classify("P3 low priority backlog item");
    expect(out.priority).toBe("P3");
  });

  it("hard no-task signal overrides idea and keeps type as idea", () => {
    const out = classify("只是記一下，有個靈感，不要變成待辦");
    expect(out.type).toBe("idea");
    expect(out.convertToTask).toBe(false);
  });

  it("hard force-task signal sets convertToTask=true", () => {
    const out = classify("請幫我跟進 PR review，推進進度");
    expect(out.convertToTask).toBe(true);
    expect(out.type).toBe("action");
  });

  it("confidence drops and dedupeHint becomes possible_duplicate when context matches", () => {
    const content = "這個方案如何落地？";
    const outFresh = classifyCaptureInput(
      {
        content,
        attachments: [],
        metadata: { platform: "telegram", messageId: "m-a", timestamp: "2026-02-20T09:00:00.000Z" },
      },
      NOW,
      {},
    );
    const outWithContext = classifyCaptureInput(
      {
        content,
        attachments: [],
        metadata: { platform: "telegram", messageId: "m-b", timestamp: "2026-02-20T09:00:00.000Z" },
      },
      NOW,
      { recentText: content },
    );
    expect(outWithContext.confidence).toBeLessThan(outFresh.confidence);
    expect(outWithContext.dedupeHint).toBe("possible_duplicate");
  });

  it("extracts ISO due date with time component", () => {
    const out = classify("2026-04-15 14:30 提醒開會");
    expect(out.due).toBe("2026-04-15 14:30");
    expect(out.type).toBe("watch");
  });

  it("extracts due via '後天' (day after tomorrow)", () => {
    const out = classify("後天 09:00 提醒我開會");
    expect(out.due).toBe("2026-02-22 09:00");
  });

  it("classifies belief with Simplified Chinese '信念' keyword", () => {
    const out = classify("信念：做事要有始有終，不輕易放棄。");
    expect(out.type).toBe("belief");
  });

  it("classifies person from Chinese person+action pattern", () => {
    const out = classify("跟 @alex 對齊需求，確認方向");
    expect(out.type).toBe("person");
  });

  it("adds 'deadline' tag when due date is present", () => {
    const out = classify("2026-05-01 提醒交稅");
    expect(out.tags).toContain("deadline");
  });

  it("source is mapped correctly for feishu platform", () => {
    const out = classifyCaptureInput(
      {
        content: "test",
        attachments: [],
        metadata: { platform: "feishu", messageId: "m-1", timestamp: "2026-02-20T09:00:00.000Z" },
      },
      NOW,
      {},
    );
    expect(out.source).toBe("feishu");
  });

  it("source is mapped correctly for lark platform alias", () => {
    const out = classifyCaptureInput(
      {
        content: "test",
        attachments: [],
        metadata: { platform: "lark", messageId: "m-2", timestamp: "2026-02-20T09:00:00.000Z" },
      },
      NOW,
      {},
    );
    expect(out.source).toBe("feishu");
  });

  it("source falls back to generic for unknown platform", () => {
    const out = classifyCaptureInput(
      {
        content: "test",
        attachments: [],
        metadata: {
          platform: "unknownplatform",
          messageId: "m-3",
          timestamp: "2026-02-20T09:00:00.000Z",
        },
      },
      NOW,
      {},
    );
    expect(out.source).toBe("generic");
  });

  it("very long content has title truncated to 18 characters", () => {
    const longContent = "a".repeat(1000);
    const out = classify(longContent);
    expect(out.title.length).toBeLessThanOrEqual(18);
  });

  it("whitespace-only content falls back to memory type", () => {
    const out = classify("   ");
    expect(out.type).toBe("memory");
  });

  it("knownTags from context are applied to the result", () => {
    const out = classifyCaptureInput(
      {
        content: "product roadmap 討論",
        attachments: [],
        metadata: { platform: "telegram", messageId: "m-4", timestamp: "2026-02-20T09:00:00.000Z" },
      },
      NOW,
      { knownTags: ["#roadmap", "#product"] },
    );
    expect(out.tags).toContain("roadmap");
    expect(out.tags).toContain("product");
  });

  it("long_term_memory is set when 'pin' keyword is present", () => {
    const out = classify("pin this idea for later reference");
    expect(out.longTermMemory).toBe(true);
  });

  it("long_term_memory is set when '永久記錄' is present", () => {
    const out = classify("永久記錄：這是重要的人生原則");
    expect(out.longTermMemory).toBe(true);
  });

  it("classifies timeline via 'sprint' keyword", () => {
    const out = classify("sprint 3 計劃：完成登入模組");
    expect(out.type).toBe("timeline");
  });

  it("classifies reference when '參考' keyword appears with a URL", () => {
    const out = classify("參考 https://docs.example.com/api");
    expect(out.type).toBe("reference");
    expect(out.tags).toContain("link");
  });

  it("urgent keyword in Simplified Chinese sets P0", () => {
    const out = classify("马上处理这个线上 bug");
    expect(out.priority).toBe("P0");
  });
});
