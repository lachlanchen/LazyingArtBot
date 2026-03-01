/**
 * DashScope Qwen-TTS HTTP provider.
 * Calls qwen3-tts-flash (or similar) and downloads the returned WAV,
 * then converts to OGG Vorbis via sox for Telegram voice-bubble compatibility.
 */
import { execSync } from "node:child_process";
import { mkdtempSync, writeFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

const QWEN_TTS_ENDPOINT =
  "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation";

const DEFAULT_MODEL = "qwen3-tts-flash";
const DEFAULT_VOICE = "Cherry";
const DEFAULT_TIMEOUT_MS = 60_000;

export type QwenTtsConfig = {
  apiKey: string;
  model?: string;
  voice?: string;
  timeoutMs?: number;
};

type QwenTtsResponse = {
  output: {
    audio: {
      url: string;
      data?: string;
    };
    finish_reason: string;
  };
  usage: { characters: number };
  request_id: string;
};

export async function dashscopeCosyTTS(params: {
  text: string;
  config: QwenTtsConfig;
}): Promise<{ audioPath: string; cleanup: () => void }> {
  const { text, config } = params;
  const timeoutMs = config.timeoutMs ?? DEFAULT_TIMEOUT_MS;

  // 1. Call Qwen-TTS API
  const response = await fetch(QWEN_TTS_ENDPOINT, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: config.model ?? DEFAULT_MODEL,
      input: {
        text,
        voice: config.voice ?? DEFAULT_VOICE,
      },
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "(no body)");
    throw new Error(`Qwen-TTS API error ${response.status}: ${body}`);
  }

  const json = (await response.json()) as QwenTtsResponse;
  const audioUrl = json.output?.audio?.url;
  if (!audioUrl) {
    throw new Error(`Qwen-TTS: no audio URL in response: ${JSON.stringify(json)}`);
  }

  // 2. Download WAV from the pre-signed URL
  const wavResponse = await fetch(audioUrl, {
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!wavResponse.ok) {
    throw new Error(`Qwen-TTS: failed to download audio from URL (${wavResponse.status})`);
  }
  const wavBuffer = Buffer.from(await wavResponse.arrayBuffer());

  // 3. Save WAV and convert to OGG Vorbis using sox
  const tempDir = mkdtempSync(path.join(tmpdir(), "tts-"));
  const wavPath = path.join(tempDir, `voice-${Date.now()}.wav`);
  const oggPath = path.join(tempDir, `voice-${Date.now()}.ogg`);

  writeFileSync(wavPath, wavBuffer);

  try {
    execSync(`sox "${wavPath}" -C 5 "${oggPath}" 2>/dev/null`, { timeout: 30_000 });
  } catch {
    // If sox fails, fall back to WAV (won't be voice-bubble but still works)
    return {
      audioPath: wavPath,
      cleanup: () => {
        try {
          execSync(`rm -rf "${tempDir}"`, { stdio: "ignore" });
        } catch {}
      },
    };
  }

  return {
    audioPath: existsSync(oggPath) ? oggPath : wavPath,
    cleanup: () => {
      try {
        execSync(`rm -rf "${tempDir}"`, { stdio: "ignore" });
      } catch {}
    },
  };
}
