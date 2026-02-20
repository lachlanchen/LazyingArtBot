import { describe, expect, it } from "vitest";
import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import { toGenericCaptureInput } from "./generic-capture-adapter.js";

function baseCtx(overrides: Partial<FinalizedMsgContext>): FinalizedMsgContext {
  return {
    CommandAuthorized: true,
    ...overrides,
  };
}

describe("toGenericCaptureInput", () => {
  it("falls back platform to surface/provider and maps core fields", () => {
    const ctx = baseCtx({
      Surface: "discord",
      BodyForCommands: "generic capture",
      MessageSid: "m1",
      ChatType: "channel",
      GroupSubject: "dev-chat",
      ReplyToId: "m0",
      SenderId: "u1",
      Timestamp: 1700000000000,
    });

    const out = toGenericCaptureInput(ctx);
    expect(out.metadata).toMatchObject({
      platform: "discord",
      messageId: "m1",
      groupId: "dev-chat",
      replyTo: "m0",
      senderId: "u1",
    });
  });

  it("keeps attachments empty when no media exists", () => {
    const out = toGenericCaptureInput(
      baseCtx({
        BodyForCommands: "plain text",
        MessageSid: "m2",
      }),
    );
    expect(out.attachments).toEqual([]);
  });
});

