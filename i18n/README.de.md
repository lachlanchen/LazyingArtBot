[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-schnellstart)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

>
> Hinweis: `i18n/` ist vorhanden und enthält in diesem Snapshot derzeit Arabisch. Weitere lokalisierte README-Varianten werden einzeln gepflegt, damit sie mit den Quell-Updates konsistent bleiben.

**LazyingArtBot** ist mein persönlicher KI-Assistenten-Stack für **lazying.art**.  
Er basiert auf OpenClaw und wurde für meine täglichen Workflows angepasst: Multi-Channel-Chat, Local-First-Steuerung und E-Mail → Kalender/Erinnerungen/Notizen-Automatisierung.

| Link | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot-Domain | https://lazying.art |
| Upstream-Basis | https://github.com/openclaw/openclaw |
| Dieses Repo | https://github.com/lachlanchen/LazyingArtBot |

---

## Inhaltsverzeichnis

- [🧭 Überblick](#-überblick)
- [⚡ Auf einen Blick](#-auf-einen-blick)
- [⚙️ Kernfunktionen](#️-kernfunktionen)
- [🧱 Projektstruktur](#-projektstruktur)
- [📋 Voraussetzungen](#-voraussetzungen)
- [🚀 Schnellstart](#-schnellstart)
- [🧱 Installation](#-installation)
- [🛠️ Nutzung](#️-nutzung)
- [🔐 Konfiguration](#-konfiguration)
- [🧩 LazyingArt-Workflow-Fokus](#-lazyingart-workflow-fokus)
- [🎼 Orchestral-Philosophie](#-orchestral-philosophie)
- [🧰 Prompt-Tools in LAB](#-prompt-tools-in-lab)
- [💡 Beispiele](#-beispiele)
- [🧪 Entwicklungshinweise](#-entwicklungshinweise)
- [🩺 Fehlerbehebung](#-fehlerbehebung)
- [🌐 LAB-Ökosystem-Integrationen](#-lab-ökosystem-integrationen)
- [Install from source](#install-from-source)
- [🗺️ Roadmap](#️-roadmap)
- [🤝 Beitragen](#-beitragen)
- [❤️ Unterstützung / Sponsoring](#️-unterstützung--sponsoring)
- [🙏 Danksagung](#-danksagung)
- [📄 Lizenz](#-lizenz)

---

## 🧭 Überblick

LAB konzentriert sich auf praktische persönliche Produktivität:

- Einen Assistenten über die Chat-Kanäle betreiben, die du bereits nutzt.
- Daten und Kontrolle auf deiner eigenen Maschine bzw. deinem eigenen Server behalten.
- Eingehende E-Mails in strukturierte Aktionen umwandeln (Kalender, Erinnerungen, Notizen).
- Guardrails hinzufügen, damit Automatisierung nützlich bleibt und trotzdem sicher ist.

Kurz gesagt: weniger Routinearbeit, bessere Ausführung.

---

## ⚡ Auf einen Blick

| Bereich | Aktuelle Basis in diesem Repo |
| --- | --- |
| Laufzeit | Node.js `>=22.12.0` |
| Paketmanager | `pnpm@10.23.0` |
| Core-CLI | `openclaw` |
| Standard lokales Gateway | `127.0.0.1:18789` |
| Primäre Doku | `docs/` (Mintlify) |
| Primäre LAB-Orchestrierung | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Kernfunktionen

- Multi-Channel-Assistenten-Laufzeit (Gateway + Agent-Sessions).
- Web-Dashboard / Web-Chat als Steueroberfläche.
- Tool-fähige Agent-Workflows (Shell, Dateien, Automatisierungsskripte).
- E-Mail-Automatisierungspipeline für persönliche Abläufe:
  - eingehende E-Mails parsen
  - Aktionstyp klassifizieren
  - in Notes / Reminders / Calendar speichern
  - jede Aktion für Review und Debugging protokollieren

---

## 🧱 Projektstruktur

Repository-Layout auf hoher Ebene:

```text
.
├─ src/                 # core runtime, gateway, channels, CLI, infra
├─ extensions/          # optional channel/provider/auth plugins
├─ orchestral/          # LAB orchestration pipelines + prompt tools
├─ scripts/             # build/dev/test/release helpers
├─ ui/                  # web dashboard UI package
├─ apps/                # macOS / iOS / Android apps
├─ docs/                # Mintlify documentation
├─ references/          # LAB references and operating notes
├─ test/                # test suites
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

Hinweise:

- `scripts/prompt_tools` verweist auf die Prompt-Tool-Implementierung der Orchestral-Schicht.
- Das Root-`i18n/` ist vorhanden und in diesem Snapshot noch minimal; lokalisierte Dokumentation liegt primär unter `docs/`.

---

## 📋 Voraussetzungen

Laufzeit- und Tooling-Basis aus diesem Repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` als Basis (siehe `packageManager` in `package.json`)
- Ein konfigurierter Model-Provider-Key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` usw.)
- Optional: Docker + Docker Compose für containerisiertes Gateway/CLI

Optionale globale CLI-Installation (entspricht dem Schnellstart-Flow):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Schnellstart

Laufzeitbasis in diesem Repo: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Anschließend das lokale Dashboard und den Chat öffnen:

- http://127.0.0.1:18789

Für Remote-Zugriff das lokale Gateway über einen eigenen sicheren Tunnel veröffentlichen (z. B. ngrok/Tailscale) und Authentifizierung aktiviert lassen.

---

## 🧱 Installation

### Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Optionaler Docker-Workflow

Eine `docker-compose.yml` ist enthalten mit:

- `openclaw-gateway`
- `openclaw-cli`

Typischer Ablauf:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Hinweis: Mount-Pfade und Ports werden über Compose-Variablen wie `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT` und `OPENCLAW_BRIDGE_PORT` gesteuert.

---

## 🛠️ Nutzung

Häufige Befehle:

```bash
# Onboard and install user daemon
openclaw onboard --install-daemon

# Run gateway in foreground
openclaw gateway run --bind loopback --port 18789 --verbose

# Send a direct message via configured channels
openclaw message send --to +1234567890 --message "Hello from LAB"

# Ask the agent directly
openclaw agent --message "Create today checklist" --thinking high
```

Entwicklungsloop (Watch-Modus):

```bash
pnpm gateway:watch
```

UI-Entwicklung:

```bash
pnpm ui:dev
```

---

## 🔐 Konfiguration

Umgebungsvariablen und Konfigurationsreferenz sind auf `.env` und `~/.openclaw/openclaw.json` aufgeteilt.

1. Mit `.env.example` starten.
2. Gateway-Auth setzen (`OPENCLAW_GATEWAY_TOKEN` empfohlen).
3. Mindestens einen Model-Provider-Key setzen (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` usw.).
4. Nur Channel-Credentials für tatsächlich aktivierte Channels setzen.

Wichtige `.env.example`-Hinweise aus dem Repo beibehalten:

- Env-Priorität: Prozess-Env → `./.env` → `~/.openclaw/.env` → Config-`env`-Block.
- Vorhandene nicht-leere Prozess-Env-Werte werden nicht überschrieben.
- Config-Keys wie `gateway.auth.token` können Vorrang vor Env-Fallbacks haben.

Sicherheitskritische Basis vor Internet-Exposition:

- Gateway-Auth/Pairing aktiviert lassen.
- Allowlists für eingehende Channels strikt halten.
- Jede eingehende Nachricht/E-Mail als nicht vertrauenswürdige Eingabe behandeln.
- Mit minimalen Rechten ausführen und Logs regelmäßig prüfen.

Wenn du das Gateway ins Internet veröffentlichst, Token/Passwort-Auth und vertrauenswürdige Proxy-Konfiguration erzwingen.

---

## 🧩 LazyingArt-Workflow-Fokus

Dieser Fork priorisiert meinen persönlichen Flow bei **lazying.art**:

- eigenes Branding (LAB / Panda-Thema)
- mobilfreundliche Dashboard-/Chat-Erfahrung
- Automail-Pipeline-Varianten (regelgetriggert, codex-unterstützte Speicher-Modi)
- persönliche Bereinigungs- und Sender-Klassifizierungs-Skripte
- Notes/Reminders/Calendar-Routing, abgestimmt auf den realen Alltag

Automatisierungs-Workspace (lokal):

- `~/.openclaw/workspace/automation/`
- Skript-Referenzen im Repo: `references/lab-scripts-and-philosophy.md`
- Dedizierte Codex-Prompt-Tools: `scripts/prompt_tools/`

---

## 🎼 Orchestral-Philosophie

LAB-Orchestrierung folgt einer Designregel:  
schwierige Ziele in deterministische Ausführung + fokussierte Prompt-Tool-Ketten zerlegen.

- Deterministische Skripte übernehmen verlässliche Infrastruktur:
  Scheduling, Datei-Routing, Run-Verzeichnisse, Retries und Output-Handoff.
- Prompt-Tools übernehmen adaptive Intelligenz:
  Planung, Triage, Kontextsynthese und Entscheidungen unter Unsicherheit.
- Jede Stufe erzeugt wiederverwendbare Artefakte, damit nachgelagerte Tools stärkere finale Notizen/E-Mails erstellen können, ohne bei null zu starten.

Kern-Orchestral-Ketten:

- Unternehmens-/Entrepreneurship-Kette:
  Unternehmenskontext-Ingestion → Markt-/Funding-/Academic-/Legal-Intelligence → konkrete Wachstumsmaßnahmen.
- Auto-Mail-Kette:
  Inbound-Mail-Triage → konservative Skip-Policy für E-Mails mit geringem Wert → strukturierte Notes/Reminders/Calendar-Aktionen.
- Web-Search-Kette:
  Suchergebnisseiten-Capture → gezielte Deep-Reads mit Screenshot-/Content-Extraktion → evidenzbasierte Synthese.

---

## 🧰 Prompt-Tools in LAB

Prompt-Tools sind modular, kombinierbar und orchestration-first.  
Sie können unabhängig laufen oder als verknüpfte Stufen in größeren Workflows.

- Read/Save-Operationen:
  Notes-, Reminders- und Calendar-Ausgaben für AutoLife-Operationen erstellen und aktualisieren.
- Screenshot/Read-Operationen:
  Suchseiten und verlinkte Seiten erfassen und dann strukturierten Text für nachgelagerte Analyse extrahieren.
- Tool-Connection-Operationen:
  deterministische Skripte aufrufen, Artefakte zwischen Stufen austauschen und Kontextkontinuität erhalten.

Primärer Ort:

- `scripts/prompt_tools/`

---

## 💡 Beispiele

### Beispiel: nur lokales Gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Beispiel: Agent für Tagesplanung anfragen

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Beispiel: Source-Build + Watch-Loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 Entwicklungshinweise

- Laufzeitbasis: Node `>=22.12.0`.
- Paketmanager-Basis: `pnpm@10.23.0` (Feld `packageManager`).
- Häufige Quality Gates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI in der Entwicklung: `pnpm openclaw ...`
- TS-Run-Loop: `pnpm dev`
- UI-Paketbefehle werden über Root-Skripte bereitgestellt (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Fehlerbehebung

### Gateway nicht erreichbar auf `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Auf Port-Kollisionen und Daemon-Konflikte prüfen. Bei Docker das gemappte Host-Port und den Service-Status verifizieren.

### Auth- oder Channel-Konfigurationsprobleme

- `.env`-Werte erneut gegen `.env.example` prüfen.
- Sicherstellen, dass mindestens ein Model-Key konfiguriert ist.
- Channel-Tokens nur für tatsächlich aktivierte Channels verifizieren.

### Allgemeine Health-Checks

`openclaw doctor` nutzen, um Migrations-/Security-/Konfigurationsdrift zu erkennen.

---

## 🌐 LAB-Ökosystem-Integrationen

LAB integriert meine breiteren KI-Produkt- und Forschungs-Repositories in eine gemeinsame Betriebsschicht für Kreation, Wachstum und Automatisierung.

Profil:

- https://github.com/lachlanchen?tab=repositories

Integrierte Repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Praktische LAB-Integrationsziele:

- Romane automatisch schreiben
- Apps automatisch entwickeln
- Videos automatisch bearbeiten
- Inhalte automatisch veröffentlichen
- Organoide automatisch analysieren
- E-Mail-Abläufe automatisch bearbeiten

---

## Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Entwicklungsloop:

```bash
pnpm gateway:watch
```

---

## 🗺️ Roadmap

Geplante Richtungen für diesen LAB-Fork (Arbeits-Roadmap):

- Automail-Zuverlässigkeit mit strengerer Sender-/Regelklassifizierung ausbauen.
- Komponierbarkeit der Orchestral-Stufen und Nachvollziehbarkeit von Artefakten verbessern.
- Mobile-First-Betrieb und UX für Remote-Gateway-Management stärken.
- Integrationen mit LAB-Ökosystem-Repos für End-to-End-automatisierte Produktion vertiefen.
- Security-Defaults und Observability für unbeaufsichtigte Automatisierung weiter härten.

---

## 🤝 Beitragen

Dieses Repository folgt persönlichen LAB-Prioritäten und erbt zugleich die Kernarchitektur von OpenClaw.

- [`CONTRIBUTING.md`](CONTRIBUTING.md) lesen
- Upstream-Doku prüfen: https://docs.openclaw.ai
- Für Security-Themen: [`SECURITY.md`](SECURITY.md)

Bei Unsicherheit über LAB-spezifisches Verhalten bestehendes Verhalten beibehalten und Annahmen in PR-Notizen dokumentieren.

---

## ❤️ Unterstützung / Sponsoring

Wenn LAB deinen Workflow unterstützt, kannst du die Weiterentwicklung unterstützen:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Spenden-Seite: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Danksagung

LazyingArtBot basiert auf **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Danke an die OpenClaw-Maintainer und die Community für die Kernplattform.

---

## 📄 Lizenz

MIT (soweit wie im Upstream anwendbar). Siehe `LICENSE`.
