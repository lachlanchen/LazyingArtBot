import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import {
  toWechatCaptureInput,
  toWechatCaptureInputFromWebhook,
} from "./wechat-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toWechatCaptureInput", () => {
  it("maps chat context fields for group messages", () => {
    const ctx = baseCtx({
      Surface: "wechat",
      BodyForCommands: "wechat capture test",
      MessageSid: "wx-msg-1",
      ChatType: "group",
      From: "wechat:group:room-1",
      ReplyToId: "wx-msg-0",
      SenderId: "wx-sender-1",
      Timestamp: 1700000000000,
    });

    const out = toWechatCaptureInput(ctx);
    expect(out.metadata).toMatchObject({
      platform: "wechat",
      messageId: "wx-msg-1",
      groupId: "room-1",
      replyTo: "wx-msg-0",
      senderId: "wx-sender-1",
    });
  });

  it("maps media attachment type from MediaTypes[]", () => {
    const out = toWechatCaptureInput(
      baseCtx({
        BodyForCommands: "media",
        MessageSid: "wx-msg-2",
        MediaPaths: ["/tmp/a.jpg"],
        MediaTypes: ["image/jpeg"],
      }),
    );
    expect(out.attachments).toEqual([{ type: "image", fileRef: "/tmp/a.jpg" }]);
  });
});

describe("toWechatCaptureInputFromWebhook", () => {
  it("maps wechatbot webhook payload", () => {
    const out = toWechatCaptureInputFromWebhook({
      content: "from webhook",
      type: "image",
      url: "https://wechat.example/img.jpg",
      roomid: "room-2",
      wxid: "msg-2",
      sender: "sender-2",
      reply_to_message_id: "msg-1",
      timestamp: "2026-02-18T00:00:00Z",
    });
    expect(out).toMatchObject({
      content: "from webhook",
      attachments: [{ type: "image", fileRef: "https://wechat.example/img.jpg" }],
      metadata: {
        platform: "wechat",
        messageId: "msg-2",
        groupId: "room-2",
        replyTo: "msg-1",
        senderId: "sender-2",
      },
    });
  });
});

