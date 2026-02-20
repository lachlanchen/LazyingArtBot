import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  runCaptureAgent: vi.fn(async () => ({
    timezone: "Asia/Shanghai",
    date: "2026-02-18",
    source: "wechat",
    ack: {
      line1: "已收",
      line2: "#1 watch",
      line3: "3=轉任務",
    },
    items: [],
  })),
}));

vi.mock("../capture-agent/run.js", () => ({
  runCaptureAgent: mocks.runCaptureAgent,
}));

const originalFetch = globalThis.fetch;

afterEach(() => {
  vi.unstubAllGlobals();
  globalThis.fetch = originalFetch;
});

const { normalizeWechatWebhookPayload, processWechatCaptureWebhook, sendWechatbotAck } = await import(
  "./wechat-capture-webhook.js"
);

describe("normalizeWechatWebhookPayload", () => {
  it("parses payload from root object", () => {
    const payload = normalizeWechatWebhookPayload({
      content: "hello",
      type: "text",
      wxid: "msg-1",
      roomid: "room-1",
      sender: "wx-self",
      isMentioned: true,
    });

    expect(payload).toMatchObject({
      content: "hello",
      type: "text",
      wxid: "msg-1",
      roomid: "room-1",
      sender: "wx-self",
      isMentioned: true,
    });
  });

  it("parses payload from nested data object", () => {
    const payload = normalizeWechatWebhookPayload({
      data: {
        content: "nested",
        type: "image",
        url: "https://example.com/a.jpg",
        wxid: "msg-2",
      },
    });

    expect(payload).toMatchObject({
      content: "nested",
      type: "image",
      url: "https://example.com/a.jpg",
      wxid: "msg-2",
    });
  });

  it("returns null for non-object values", () => {
    expect(normalizeWechatWebhookPayload(null)).toBeNull();
    expect(normalizeWechatWebhookPayload("bad-payload")).toBeNull();
  });
});

describe("processWechatCaptureWebhook", () => {
  beforeEach(() => {
    mocks.runCaptureAgent.mockClear();
  });

  it("skips group messages not mentioned", async () => {
    const out = await processWechatCaptureWebhook({
      payload: {
        content: "hello",
        wxid: "msg-3",
        roomid: "room-3",
        sender: "wx-other",
        isMentioned: false,
      },
      options: {
        selfWxid: "wx-self",
        requireMentionInGroup: true,
      },
    });

    expect(out).toEqual({ handled: false, reason: "group_not_mentioned" });
    expect(mocks.runCaptureAgent).not.toHaveBeenCalled();
  });

  it("skips direct messages from non-self sender", async () => {
    const out = await processWechatCaptureWebhook({
      payload: {
        content: "hello",
        wxid: "msg-4",
        sender: "wx-other",
      },
      options: {
        selfWxid: "wx-self",
      },
    });

    expect(out).toEqual({ handled: false, reason: "dm_not_self_sender" });
    expect(mocks.runCaptureAgent).not.toHaveBeenCalled();
  });

  it("skips payload missing message id", async () => {
    const out = await processWechatCaptureWebhook({
      payload: {
        content: "hello",
      },
    });

    expect(out).toEqual({ handled: false, reason: "missing_message_id" });
    expect(mocks.runCaptureAgent).not.toHaveBeenCalled();
  });

  it("processes mentioned group message and builds ack target", async () => {
    const out = await processWechatCaptureWebhook({
      payload: {
        content: "capture this",
        type: "image",
        url: "https://example.com/image.jpg",
        wxid: "msg-5",
        roomid: "room-5",
        sender: "wx-other",
        isMentioned: "true",
      },
      options: {
        selfWxid: "wx-self",
        applyWrites: false,
        outputMode: "json",
      },
    });

    expect(out.handled).toBe(true);
    if (!out.handled) {
      return;
    }

    expect(out.captureInput.metadata).toMatchObject({
      platform: "wechat",
      messageId: "msg-5",
      groupId: "room-5",
      senderId: "wx-other",
    });
    expect(out.ackTarget).toBe("room-5");
    expect(out.ackText).toBe("已收\n#1 watch\n3=轉任務");

    expect(mocks.runCaptureAgent).toHaveBeenCalledTimes(1);
    expect(mocks.runCaptureAgent).toHaveBeenCalledWith(
      expect.objectContaining({
        applyWrites: false,
        outputMode: "json",
        input: expect.objectContaining({
          content: "capture this",
          metadata: expect.objectContaining({ messageId: "msg-5" }),
        }),
      }),
    );
  });
});

describe("sendWechatbotAck", () => {
  it("posts text ack payload to default reply route", async () => {
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => "",
    });
    vi.stubGlobal("fetch", fetchSpy);

    const out = await sendWechatbotAck({
      baseUrl: "http://127.0.0.1:8789",
      to: "room-9",
      content: "ack line 1\nack line 2",
    });

    expect(out).toMatchObject({
      ok: true,
      status: 200,
      url: "http://127.0.0.1:8789/webhook/msg/v2",
    });
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    expect(fetchSpy).toHaveBeenCalledWith(
      "http://127.0.0.1:8789/webhook/msg/v2",
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({
          "content-type": "application/json",
        }),
      }),
    );

    const requestInit = fetchSpy.mock.calls[0]?.[1] as { body?: string } | undefined;
    const body = JSON.parse(requestInit?.body ?? "{}") as {
      to?: string;
      type?: string;
      content?: string;
    };
    expect(body).toMatchObject({
      to: "room-9",
      type: "text",
      content: "ack line 1\nack line 2",
    });
  });

  it("returns failure with response text when reply api is not ok", async () => {
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: false,
      status: 403,
      text: async () => "forbidden",
    });
    vi.stubGlobal("fetch", fetchSpy);

    const out = await sendWechatbotAck({
      baseUrl: "http://127.0.0.1:8789",
      path: "/webhook/msg/v2",
      to: "wxid-1",
      content: "hello",
      token: "abc-token",
    });

    expect(out.ok).toBe(false);
    expect(out.status).toBe(403);
    expect(out.error).toContain("forbidden");
    expect(fetchSpy).toHaveBeenCalledWith(
      "http://127.0.0.1:8789/webhook/msg/v2",
      expect.objectContaining({
        headers: expect.objectContaining({
          "x-wechatbot-token": "abc-token",
        }),
      }),
    );
  });

  it("fails fast when required params are missing", async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);

    const out = await sendWechatbotAck({
      baseUrl: "",
      to: "room-1",
      content: "hello",
    });

    expect(out).toMatchObject({
      ok: false,
      status: null,
      error: "missing_base_url_or_target_or_content",
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
