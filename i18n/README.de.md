[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#schnellstart)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **i18n-Status:** `i18n/` exists and currently includes localized README files for Arabic, German, Spanish, French, Japanese, Korean, Russian, Vietnamese, Simplified Chinese, and Traditional Chinese. This English draft remains the canonical source for incremental updates.

**LazyingArtBot** ist mein persönlicher KI-Assistenten-Stack für **lazying.art**:

**LazyingArtBot** ist auf OpenClaw aufgebaut und für meinen täglichen Workflow angepasst: Multi-Channel-Chat, lokale-first-Kontrolle und E-Mail → Kalender/Erinnerungs-/Notizautomatisierung.

| 🔗 Link | URL | Fokus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Primäre Domain und Status-Dashboard |
| 🤖 Bot-Domain | https://lazying.art | Chat- und Assistent-Einstiegspunkt |
| 🧱 Upstream-Basis | https://github.com/openclaw/openclaw | OpenClaw-Plattform-Basis |
| 📦 Dieses Repo | https://github.com/lachlanchen/LazyingArtBot | LAB-spezifische Anpassungen |

---

## Inhaltsverzeichnis

- [Uebersicht](#uebersicht)
- [Auf einen Blick](#auf-einen-blick)
- [Funktionen](#funktionen)
- [Kernkompetenzen](#kernkompetenzen)
- [Projektstruktur](#projektstruktur)
- [Voraussetzungen](#voraussetzungen)
- [Schnellstart](#schnellstart)
- [Installation](#installation)
- [Nutzung](#nutzung)
- [Konfiguration](#konfiguration)
- [Bereitstellungsmodi](#bereitstellungsmodi)
- [LazyingArt-Workflow-Fokus](#lazyingart-workflow-fokus)
- [Orchestrierungsphilosophie](#orchestrierungsphilosophie)
- [Prompt-Tools in LAB](#prompt-tools-in-lab)
- [Beispiele](#beispiele)
- [Entwicklungsnotizen](#entwicklungsnotizen)
- [Fehlerbehebung](#fehlerbehebung)
- [LAB-Ecosystem-Integrationen](#lab-ecosystem-integrationen)
- [Installation aus dem Quellcode (Kurzreferenz)](#installation-aus-dem-quellcode-kurzreferenz)
- [Roadmap](#roadmap)
- [Mitwirken](#mitwirken)
- [Danksagung](#danksagung)
- [❤️ Support](#-support)
- [Kontakt](#kontakt)
- [Lizenz](#lizenz)

---

## Uebersicht

LAB fokussiert sich auf praktische persönliche Produktivität:

- ✅ Einen Assistenten in den Chat-Kanälen betreiben, die du bereits nutzt.
- 🔐 Daten und Kontrolle auf deinem eigenen Rechner/deinem eigenen Server behalten.
- 📬 Eingehende E-Mails in strukturierte Aktionen umwandeln (Calendar, Reminders, Notes).
- 🛡️ Schutzmechanismen hinzufügen, damit Automatisierung nützlich, aber weiterhin sicher bleibt.

Kurz gesagt: weniger Routinearbeit, bessere Ausführung.

---

## Auf einen Blick

| Bereich | Aktueller Stand in diesem Repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Paketmanager | `pnpm@10.23.0` |
| Kern-CLI | `openclaw` |
| Standard-Lokales Gateway | `127.0.0.1:18789` |
| Standard-Bridge-Port | `127.0.0.1:18790` |
| Primäre Docs | `docs/` (Mintlify) |
| Primäre LAB-Orchestrierung | `orchestral/` + `scripts/prompt_tools/` |
| Ort der i18n-README | `i18n/README.*.md` |

---

## Funktionen

- 🌐 Multi-Channel-Assistenten-Runtime mit lokalem Gateway.
- 🖥️ Browser-Dashboard/Chat-Oberfläche für lokale Operationen.
- 🧰 Tool-gestützte Automatisierungspipeline (Scripts + Prompt-Tools).
- 📨 E-Mail-Triage und Umwandlung in Notes-, Reminders- und Calendar-Aktionen.
- 🧩 Plugin-/Extension-Ökosystem (`extensions/*`) für Kanäle/Provider/Integrationen.
- 📱 Multi-Plattform-Schnittstellen im Repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Kernkompetenzen

| Fähigkeit | Bedeutung in der Praxis |
| --- | --- |
| Multi-Channel-Assistenten-Runtime | Gateway + Agent-Sitzungen über die von dir aktivierten Kanäle |
| Web-Dashboard / Chat | Browser-basierte Kontrolloberfläche für lokale Operationen |
| Tool-gestützte Workflows | Shell-, Dateisystem- und Automatisierungsskript-Ketten |
| E-Mail-Automatisierungspipeline | Parse Mail, klassifiziere Aktionstypen, route zu Notes/Reminders/Calendar und protokolliere Aktionen zur Prüfung/Fehlersuche |

Pipeline-Schritte aus dem aktuellen Workflow:

- eingehende Mail parsen
- Aktionstyp klassifizieren
- in Notes / Reminders / Calendar speichern
- jede Aktion zur Prüfung und Fehlersuche protokollieren

---

## Projektstruktur

High-level repository layout:

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
├─ i18n/                # localized README files
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

Hinweise:

- `scripts/prompt_tools` verweist auf die Orchestrations-Implementierung der Prompt-Tools.
- Im Root-`i18n/` befinden sich die lokalisierten README-Varianten.
- `.github/workflows.disabled/` ist in diesem Snapshot vorhanden; aktives CI-Verhalten sollte vor Nutzung von Workflow-Annahmen validiert werden.

---

## Voraussetzungen

Runtime- und Tooling-Baselines aus diesem Repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` als Basis (siehe `packageManager` in `package.json`)
- Ein konfigurierte Model-Provider-Key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` etc.)
- Optional: Docker + Docker Compose für containerisiertes Gateway/CLI
- Optional für mobile/mac-Builds: Apple/Android-Toolchains je nach Zielplattform

Optionale globale CLI-Installation (entspricht dem Schnellstart-Fluss):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Schnellstart

Runtime-Basis in diesem Repo: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Danach lokales Dashboard und Chat öffnen:

- http://127.0.0.1:18789

Für entfernten Zugriff, gib dein lokales Gateway über einen sicheren eigenen Tunnel frei (z. B. ngrok/Tailscale) und halte die Authentifizierung eingeschaltet.

---

## Installation

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

Ein `docker-compose.yml` ist enthalten mit:

- `openclaw-gateway`
- `openclaw-cli`

Typischer Ablauf:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Häufig benötigte Compose-Variablen:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Nutzung

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

Dev loop (watch mode):

```bash
pnpm gateway:watch
```

UI-Entwicklung:

```bash
pnpm ui:dev
```

Weitere nützliche Betriebsbefehle:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Konfiguration

Umgebungs- und Konfigurationsreferenz ist zwischen `.env` und `~/.openclaw/openclaw.json` aufgeteilt.

1. Starte mit `.env.example`.
2. Setze die Gateway-Authentifizierung (`OPENCLAW_GATEWAY_TOKEN` empfohlen).
3. Setze mindestens einen Model-Provider-Key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Setze Channel-Zugangsinfos nur für Kanäle, die du aktivierst.

Wichtige `.env.example`-Hinweise aus dem Repo:

- Env-Priorität: process env -> `./.env` -> `~/.openclaw/.env` -> config `env`-Block.
- Bestehende nicht-leere Process-Env-Werte werden nicht überschrieben.
- Konfigurationsschlüssel wie `gateway.auth.token` können Env-Fallbacks überschreiben.

Sicherheitskritische Basis vor Internet-Exposition:

- Gateway-Authentifizierung/Pairing aktiviert halten.
- Strenge Allowlisten für eingehende Kanäle einhalten.
- Jede eingehende Nachricht/jede eingehende E-Mail als untrusted input behandeln.
- Mit minimalen Rechten laufen lassen und Logs regelmäßig prüfen.

Wenn du das Gateway ins Internet stellst, erfordere Token-/Passwort-Authentifizierung und vertrauenswürdige Proxy-Konfiguration.

---

## Bereitstellungsmodi

| Modus | Am besten geeignet für | Typischer Befehl |
| --- | --- | --- |
| Lokaler Vordergrundmodus | Entwicklung und Debugging | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Lokaler Daemon | Tägliche Nutzung | `openclaw onboard --install-daemon` |
| Docker | Isolierte Runtime und reproduzierbare Bereitstellungen | `docker compose up -d` |
| Remote Host + Tunnel | Zugriff außerhalb des lokalen LAN | Gateway + sicheren Tunnel betreiben, Auth aktiviert lassen |

Annahme: produktionsreife Reverse-Proxy-Härtung, Secret-Rotation und Backup-Policy sind deploymentspezifisch und sollten pro Umgebung definiert werden.

---

## LazyingArt-Workflow-Fokus

Dieser Fork priorisiert meinen persönlichen Flow auf **lazying.art**:

- 🎨 Eigenes Branding (LAB / Panda-Theme)
- 📱 Mobile-freundliche Dashboard-/Chat-Erfahrung
- 📨 Automail-Pipeline-Varianten (regelgesteuerte, kodexgestützte Speicher-Modi)
- 🧹 Persönliche Bereinigungs- und Senderklassifikationsskripte
- 🗂️ Notes-/Reminders-/Calendar-Routing für echte tägliche Nutzung abgestimmt

Automatisierungs-Arbeitsbereich (lokal):

- `~/.openclaw/workspace/automation/`
- Skriptverweise im Repo: `references/lab-scripts-and-philosophy.md`
- Spezielle Codex-Prompt-Tools: `scripts/prompt_tools/`

---

## Orchestrierungsphilosophie

LAB-Orchestrierung folgt einer Design-Regel:
Schwere Ziele in deterministische Ausführung + fokussierte Prompt-Tool-Ketten zerlegen.

- Deterministische Skripte übernehmen verlässliche Abläufe:
  Terminplanung, Dateirouting, Ausführungsordner, Retries und Ausgabeübergabe.
- Prompt-Tools liefern adaptive Intelligenz:
  Planung, Triage, Kontextsynthese und Entscheidungsfindung unter Unsicherheit.
- Jede Stufe erzeugt wiederverwendbare Artefakte, sodass nachgelagerte Tools stärkere Endnotizen/E-Mails erzeugen können, ohne von Null zu starten.

Zentrale Orchestrierungs-Ketten:

- Unternehmenskette:
  Aufnahme von Unternehmenskontext -> Markt-/Finanzierungs-/wissenschaftliche/rechtliche Intelligence -> konkrete Wachstumsmaßnahmen.
- Auto-Mail-Kette:
  Eingangsmail-Triage -> konservative Ausschlusslogik für geringe Relevanz -> strukturierte Notes-/Reminders-/Calendar-Aktionen.
- Web-Suchkette:
  Ergebnisseiten erfassen -> gezielte Deep Reads mit Screenshot-/Text-Extraktion -> evidenzbasierte Synthese.

---

## Prompt-Tools in LAB

Prompt-Tools sind modular, zusammensetzbar und orchestrationszentriert.
Sie können eigenständig laufen oder als verkettete Stufen in größeren Workflows arbeiten.

- Lese-/Speicher-Operationen:
  Erstelle und aktualisiere Notes-, Reminders- und Calendar-Ausgaben für AutoLife-Workflows.
- Screenshot-/Lese-Operationen:
  Suchseiten und verlinkte Seiten erfassen, dann strukturierten Text für Downstream-Analyse extrahieren.
- Tool-Verbindungs-Operationen:
  Rufe deterministische Skripte auf, tausche Artefakte zwischen Stufen aus und halte Kontext-Kontinuität.

Primärer Ort:

- `scripts/prompt_tools/`

---

## Beispiele

### Beispiel: Nur lokales Gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Beispiel: Agenten bitten, die Tagesplanung zu verarbeiten

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Beispiel: Build aus dem Quellcode + Watch-Schleife

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Beispiel: In Docker ausführen

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Entwicklungsnotizen

- Runtime-Basis: Node `>=22.12.0`.
- Paketmanager-Basis: `pnpm@10.23.0` (`packageManager`-Feld).
- Typische Qualitätsgates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI in der Entwicklung: `pnpm openclaw ...`
- TS-Run-Schleife: `pnpm dev`
- UI-Paketbefehle laufen über Root-Skripte (`pnpm ui:build`, `pnpm ui:dev`).

Typische erweiterte Testbefehle in diesem Repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Zusätzliche Entwicklertools:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Hinweis:

- Build- und Laufbefehle für Mobile/macOS-Apps existieren in `package.json` (`ios:*`, `android:*`, `mac:*`), aber Plattform-Signing-/Provisioning-Anforderungen sind umgebungsspezifisch und in diesem README nicht vollständig dokumentiert.

---

## Fehlerbehebung

### Gateway nicht erreichbar auf `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Auf Portkollisionen und Daemon-Konflikte prüfen. Bei Docker prüfe den zugeordneten Host-Port und den Gesundheitszustand des Services.

### Auth- oder Kanal-Konfigurationsprobleme

- Prüfe `.env`-Werte erneut gegen `.env.example`.
- Stelle sicher, dass mindestens ein Modell-Key konfiguriert ist.
- Prüfe Kanal-Tokens nur für Kanäle, die du tatsächlich aktivierst.

### Build- oder Installationsprobleme

- Führe `pnpm install` erneut mit Node `>=22.12.0` aus.
- Rebuild mit `pnpm ui:build && pnpm build`.
- Falls optionale native Peers fehlen, prüfe Installationslogs auf Kompatibilität von `@napi-rs/canvas` / `node-llama-cpp`.

### Allgemeine Gesundheitschecks

Nutze `openclaw doctor`, um Migrations-/Sicherheits-/Konfigurationsdrift zu erkennen.

### Nützliche Diagnostik

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB-Ecosystem-Integrationen

LAB verbindet meine breiteren KI-Produkte und Forschung-Repos in eine gemeinsame Betriebsebene für Erstellung, Wachstum und Automatisierung.

Profil:

- https://github.com/lachlanchen?tab=repositories

Integrierte Repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatisches Schreiben von Romanen)
- `AutoAppDev` (automatische App-Entwicklung)
- `OrganoidAgent` (Organoid-Forschungsplattform mit Foundation-Vision-Modellen + LLMs)
- `LazyEdit` (KI-gestützte Videobearbeitung: Untertitel/Transkription/Highlights/Metadaten/Untertitel)
- `AutoPublish` (automatische Veröffentlichungspipeline)

Praktische LAB-Integrationsziele:

- Romane automatisch schreiben
- Apps automatisch entwickeln
- Videos automatisch bearbeiten
- Ergebnisse automatisch veröffentlichen
- Organoide automatisch analysieren
- E-Mail-Operationen automatisch handhaben

---

## Installation aus dem Quellcode (Kurzreferenz)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Dev loop:

```bash
pnpm gateway:watch
```

---

## Roadmap

Geplante Richtungen für diesen LAB-Fork (aktive Arbeits-Roadmap):

- Automail-Zuverlässigkeit mit strengerer Sender-/Regelklassifikation ausbauen.
- Orchestrationsstufen-Komponierbarkeit und Artefakt-Nachvollziehbarkeit verbessern.
- Mobile-first-Bedienbarkeit und Remote-Gateway-Verwaltungs-UX weiter stärken.
- Integrationen mit LAB-Ecosystem-Repos für end-to-end automatisierte Produktion vertiefen.
- Sicherheitsstandards und Observability für unbeaufsichtigte Automatisierung weiter härten.

---

## Mitwirken

Dieses Repository fokussiert persönliche LAB-Prioritäten und übernimmt zugleich die Kernarchitektur von OpenClaw.

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) lesen
- Upstream-Dokumentation prüfen: https://docs.openclaw.ai
- Bei Sicherheitsproblemen siehe [`SECURITY.md`](../SECURITY.md)

Wenn du unsicher über LAB-spezifisches Verhalten bist, bestehendes Verhalten beibehalten und Annahmen in PR-Notizen dokumentieren.

---

## Danksagung

LazyingArtBot basiert auf **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Danke an die OpenClaw-Maintainer und die Community für die Kernplattform.

## Kontakt

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue-Tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Sicherheits- oder Schutzbedenken: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## Lizenz

MIT (wie bei Upstream, sofern zutreffend). Siehe `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
