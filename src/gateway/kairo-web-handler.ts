import type { IncomingMessage, ServerResponse } from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const APP_PREFIX = "/app";

function resolveKairoWebRoot(): string {
  const moduleDir = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    path.resolve(moduleDir, "../kairo-web"), // from dist/ (tsdown flat bundle)
    path.resolve(moduleDir, "../../kairo-web"), // from dist/gateway/ (nested)
    path.resolve(moduleDir, "../../../kairo-web"), // from src/gateway/ (dev)
    path.resolve(process.cwd(), "kairo-web"), // fallback: cwd
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isDirectory()) {
      return candidate;
    }
  }
  return candidates[0];
}

function contentTypeForExt(ext: string): string {
  switch (ext) {
    case ".html":
      return "text/html; charset=utf-8";
    case ".js":
      return "application/javascript; charset=utf-8";
    case ".css":
      return "text/css; charset=utf-8";
    case ".svg":
      return "image/svg+xml";
    case ".png":
      return "image/png";
    case ".ico":
      return "image/x-icon";
    case ".json":
      return "application/json; charset=utf-8";
    case ".webmanifest":
      return "application/manifest+json; charset=utf-8";
    case ".txt":
      return "text/plain; charset=utf-8";
    default:
      return "application/octet-stream";
  }
}

function applySecurityHeaders(res: ServerResponse): void {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "SAMEORIGIN");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
}

function isSafePath(relPath: string): boolean {
  if (!relPath) {
    return false;
  }
  const normalized = path.posix.normalize(relPath);
  if (normalized.startsWith("../") || normalized === "..") {
    return false;
  }
  if (normalized.includes("\0")) {
    return false;
  }
  return true;
}

const kairoWebRoot = resolveKairoWebRoot();

export function handleKairoWebRequest(req: IncomingMessage, res: ServerResponse): boolean {
  const urlRaw = req.url;
  if (!urlRaw) {
    return false;
  }
  if (req.method !== "GET" && req.method !== "HEAD") {
    return false;
  }

  const url = new URL(urlRaw, "http://localhost");
  const pathname = url.pathname;

  if (pathname !== APP_PREFIX && !pathname.startsWith(`${APP_PREFIX}/`)) {
    return false;
  }

  applySecurityHeaders(res);

  const subPath = pathname.slice(APP_PREFIX.length).replace(/^\/+/, "");
  const requested = subPath && !subPath.endsWith("/") ? subPath : `${subPath}index.html`;
  const fileRel = requested || "index.html";

  if (!isSafePath(fileRel)) {
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Not Found");
    return true;
  }

  const filePath = path.join(kairoWebRoot, fileRel);
  if (!filePath.startsWith(kairoWebRoot)) {
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Not Found");
    return true;
  }

  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    // SPA fallback: return index.html
    const indexPath = path.join(kairoWebRoot, "index.html");
    if (fs.existsSync(indexPath)) {
      res.setHeader("Content-Type", "text/html; charset=utf-8");
      res.setHeader("Cache-Control", "no-cache");
      res.end(fs.readFileSync(indexPath));
      return true;
    }
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Kairo Web not found. Copy kairo-web/ to repo root.");
    return true;
  }

  const ext = path.extname(filePath).toLowerCase();
  const cacheControl = [".js", ".css", ".svg", ".png"].includes(ext)
    ? "public, max-age=3600"
    : "no-cache";

  res.setHeader("Content-Type", contentTypeForExt(ext));
  res.setHeader("Cache-Control", cacheControl);

  if (req.method === "HEAD") {
    res.statusCode = 200;
    res.end();
    return true;
  }

  res.end(fs.readFileSync(filePath));
  return true;
}
