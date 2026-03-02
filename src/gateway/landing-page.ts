import type { IncomingMessage, ServerResponse } from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const LANDING_PREFIX = "/landing";

// Resolve the landing directory relative to this module
// landing/ is at repo root (../../../landing from src/gateway/)
function resolveLandingRoot(): string {
  const moduleDir = path.dirname(fileURLToPath(import.meta.url));
  // From dist/gateway/ go up to repo root, then into landing/
  // The compiled file is in dist/gateway/, so ../../landing
  // But we need to handle both dev (src/) and dist/
  const candidates = [
    path.resolve(moduleDir, "../../landing"), // from dist/gateway/
    path.resolve(moduleDir, "../../../landing"), // from src/gateway/ (dev)
    path.resolve(process.cwd(), "landing"), // fallback: cwd
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isDirectory()) {
      return candidate;
    }
  }
  return candidates[0]; // Return first candidate even if not found yet
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
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".ico":
      return "image/x-icon";
    case ".txt":
      return "text/plain; charset=utf-8";
    default:
      return "application/octet-stream";
  }
}

function applyLandingSecurityHeaders(res: ServerResponse): void {
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

const landingRoot = resolveLandingRoot();

export function handleLandingPageRequest(req: IncomingMessage, res: ServerResponse): boolean {
  const urlRaw = req.url;
  if (!urlRaw) {
    return false;
  }
  if (req.method !== "GET" && req.method !== "HEAD") {
    return false;
  }

  const url = new URL(urlRaw, "http://localhost");
  const pathname = url.pathname;

  // Must be /landing or /landing/*
  if (pathname !== LANDING_PREFIX && !pathname.startsWith(`${LANDING_PREFIX}/`)) {
    return false;
  }

  applyLandingSecurityHeaders(res);

  // Resolve relative path
  const subPath = pathname.slice(LANDING_PREFIX.length).replace(/^\/+/, "");
  const requested = subPath && !subPath.endsWith("/") ? subPath : `${subPath}index.html`;
  const fileRel = requested || "index.html";

  if (!isSafePath(fileRel)) {
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Not Found");
    return true;
  }

  const filePath = path.join(landingRoot, fileRel);
  if (!filePath.startsWith(landingRoot)) {
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Not Found");
    return true;
  }

  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    // Fallback to index.html for SPA-like behavior
    const indexPath = path.join(landingRoot, "index.html");
    if (fs.existsSync(indexPath)) {
      res.setHeader("Content-Type", "text/html; charset=utf-8");
      res.setHeader("Cache-Control", "no-cache");
      res.end(fs.readFileSync(indexPath));
      return true;
    }
    res.statusCode = 404;
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.end("Landing page not found. Build it with Agent 1.");
    return true;
  }

  const ext = path.extname(filePath).toLowerCase();
  res.setHeader("Content-Type", contentTypeForExt(ext));
  res.setHeader("Cache-Control", "no-cache");

  if (req.method === "HEAD") {
    res.statusCode = 200;
    res.end();
    return true;
  }

  res.end(fs.readFileSync(filePath));
  return true;
}
