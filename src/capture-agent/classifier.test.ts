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
