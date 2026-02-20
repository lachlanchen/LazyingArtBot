import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import { toFeishuCaptureInput } from "./feishu-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toFeishuCaptureInput", () => {
  it("maps group message metadata using GroupSubject and reply fields", () => {
    const ctx = baseCtx({
      Surface: "feishu",
      BodyForCommands: "飛書 capture 測試",
      MessageSid: "om_123",
      ChatType: "group",
      GroupSubject: "oc_group_001",
      ReplyToId: "om_prev",
      SenderId: "ou_sender_1",
      Timestamp: 1700000000000,
    });

    const out = toFeishuCaptureInput(ctx);
    expect(out.content).toBe("飛書 capture 測試");
    expect(out.metadata).toMatchObject({
      platform: "feishu",
      messageId: "om_123",
      groupId: "oc_group_001",
      replyTo: "om_prev",
      senderId: "ou_sender_1",
    });
  });

  it("parses group id from chat:<id> when GroupSubject is missing", () => {
    const ctx = baseCtx({
      BodyForCommands: "channel message",
      MessageSid: "om_456",
      ChatType: "channel",
      To: "chat:oc_group_321",
    });

    const out = toFeishuCaptureInput(ctx);
    expect(out.metadata.groupId).toBe("oc_group_321");
  });

  it("maps media paths/types and transcript into attachments", () => {
    const ctx = baseCtx({
      BodyForCommands: "see attachments",
      MessageSid: "om_789",
      MediaPaths: ["/tmp/a.jpg", "/tmp/b.mp4"],
      MediaTypes: ["image/jpeg", "video/mp4"],
      Transcript: "語音逐字稿",
    });

    const out = toFeishuCaptureInput(ctx);
    expect(out.attachments).toEqual([
      { type: "image", fileRef: "/tmp/a.jpg" },
      { type: "video", fileRef: "/tmp/b.mp4" },
      { type: "audio", fileRef: "inline-transcript", transcript: "語音逐字稿" },
    ]);
  });
});

