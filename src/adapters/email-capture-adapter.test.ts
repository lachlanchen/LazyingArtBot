import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import { toEmailCaptureInput } from "./email-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toEmailCaptureInput", () => {
  it("maps core email metadata and thread id", () => {
    const ctx = baseCtx({
      Surface: "email",
      BodyForCommands: "follow up this offer",
      MessageSid: "<msg-001@example>",
      MessageThreadId: "thread-abc",
      ReplyToId: "<msg-000@example>",
      SenderId: "alice@example.com",
      Timestamp: 1700000000000,
    });

    const out = toEmailCaptureInput(ctx);
    expect(out.metadata).toMatchObject({
      platform: "email",
      messageId: "<msg-001@example>",
      groupId: "thread-abc",
      replyTo: "<msg-000@example>",
      senderId: "alice@example.com",
    });
  });

  it("maps media refs and transcript to attachments", () => {
    const ctx = baseCtx({
      BodyForCommands: "see attached",
      MessageSid: "mail-2",
      MediaPaths: ["/tmp/offer.pdf"],
      MediaTypes: ["application/pdf"],
      Transcript: "voice note text",
    });

    const out = toEmailCaptureInput(ctx);
    expect(out.attachments).toEqual([
      { type: "file", fileRef: "/tmp/offer.pdf" },
      { type: "audio", fileRef: "inline-transcript", transcript: "voice note text" },
    ]);
  });
});

