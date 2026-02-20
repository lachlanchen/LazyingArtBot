import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import { toTelegramCaptureInput } from "./telegram-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toTelegramCaptureInput", () => {
  it("maps media understanding text into semanticDesc", () => {
    const out = toTelegramCaptureInput(
      baseCtx({
        Surface: "telegram",
        BodyForCommands: "image capture",
        MessageSid: "tg-msg-1",
        MediaPaths: ["/tmp/pic-1.jpg"],
        MediaTypes: ["image/jpeg"],
        MediaUnderstanding: [
          {
            kind: "image.description",
            attachmentIndex: 0,
            text: "這是一張會議白板照片，含三個行動項目",
            provider: "openai",
          },
        ],
      }),
    );

    expect(out.attachments).toEqual([
      {
        type: "image",
        fileRef: "/tmp/pic-1.jpg",
        semanticDesc: "這是一張會議白板照片，含三個行動項目",
      },
    ]);
  });

  it("attaches transcript to existing audio attachment without duplication", () => {
    const out = toTelegramCaptureInput(
      baseCtx({
        BodyForCommands: "voice capture",
        MessageSid: "tg-msg-2",
        MediaPath: "/tmp/voice.ogg",
        MediaType: "audio/ogg",
        Transcript: "我明天要先完成 demo 版本",
      }),
    );

    expect(out.attachments).toHaveLength(1);
    expect(out.attachments[0]).toMatchObject({
      type: "audio",
      fileRef: "/tmp/voice.ogg",
      transcript: "我明天要先完成 demo 版本",
    });
    expect(String(out.attachments[0]?.semanticDesc ?? "")).toContain("語音逐字稿");
  });

  it("creates transcript-only audio attachment when no media path exists", () => {
    const out = toTelegramCaptureInput(
      baseCtx({
        BodyForCommands: "just transcript",
        MessageSid: "tg-msg-3",
        Transcript: "只記錄語音文字",
      }),
    );

    expect(out.attachments).toEqual([
      {
        type: "audio",
        fileRef: "inline-transcript",
        transcript: "只記錄語音文字",
        semanticDesc: "語音逐字稿：只記錄語音文字",
      },
    ]);
  });
});
