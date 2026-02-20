import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import { toWhatsAppCaptureInput } from "./whatsapp-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toWhatsAppCaptureInput", () => {
  it("maps group chat metadata", () => {
    const ctx = baseCtx({
      Surface: "whatsapp",
      BodyForCommands: "whatsapp capture",
      MessageSid: "wamid.abc",
      ChatType: "group",
      From: "120363401234567890@g.us",
      ReplyToId: "wamid.prev",
      SenderId: "12345@s.whatsapp.net",
      Timestamp: 1700000000000,
    });

    const out = toWhatsAppCaptureInput(ctx);
    expect(out.metadata).toMatchObject({
      platform: "whatsapp",
      messageId: "wamid.abc",
      groupId: "120363401234567890@g.us",
      replyTo: "wamid.prev",
      senderId: "12345@s.whatsapp.net",
    });
  });

  it("maps media types from MediaTypes[]", () => {
    const ctx = baseCtx({
      BodyForCommands: "media",
      MessageSid: "wamid.2",
      MediaPaths: ["/tmp/a.jpg"],
      MediaTypes: ["image/jpeg"],
    });

    const out = toWhatsAppCaptureInput(ctx);
    expect(out.attachments).toEqual([{ type: "image", fileRef: "/tmp/a.jpg" }]);
  });
});

