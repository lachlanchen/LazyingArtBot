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

> 🌍 **i18n-Status:** `i18n/` ist vorhanden und enthält derzeit lokalisierte README-Dateien für Arabisch, Deutsch, Spanisch, Französisch, Japanisch, Koreanisch, Russisch, Vietnamesisch, vereinfachtes und traditionelles Chinesisch. Diese englische Fassung bleibt die kanonische Referenz für inkrementelle Updates.

**LazyingArtBot** ist mein persönlicher KI-Assistenten-Stack für **lazying.art**.
Es basiert auf OpenClaw und ist für meinen täglichen Workflow adaptiert: Multi-Channel-Chat, lokale Erstkontrolle und E-Mail-zu-Kalender-/Erinnerungs-/Notiz-Automatisierung.

| 🔗 Link | URL | Fokus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Primäre Domain und Status-Dashboard |
| 🤖 Bot-Domain | https://lazying.art | Einstiegspunkt für Chat und Assistent |
| 🧱 Upstream-Basis | https://github.com/openclaw/openclaw | OpenClaw-Plattform |
| 📦 Dieses Repo | https://github.com/lachlanchen/LazyingArtBot | LAB-spezifische Anpassungen |

---

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Auf einen Blick](#auf-einen-blick)
- [Funktionen](#funktionen)
- [Kernfunktionen](#kernfunktionen)
- [Projektstruktur](#projektstruktur)
- [Voraussetzungen](#voraussetzungen)
- [Schnellstart](#schnellstart)
- [Installation](#installation)
- [Nutzung](#nutzung)
- [Konfiguration](#konfiguration)
- [Bereitstellungsmodi](#bereitstellungsmodi)
- [LazyingArt-Workflow-Fokus](#lazyingart-workflow-fokus)
- [Orchestrationsphilosophie](#orchestrationsphilosophie)
- [Prompt-Tools in LAB](#prompt-tools-in-lab)
- [Beispiele](#beispiele)
- [Entwicklungshinweise](#entwicklungshinweise)
- [Fehlerbehebung](#fehlerbehebung)
- [LAB-Ekosystem-Integrationen](#lab-ökosystem-integrationen)
- [Installation aus dem Quellcode (Kurzanleitung)](#installation-aus-dem-quellcode-kurzanleitung)
- [Roadmap](#roadmap)
- [Mitwirken](#mitwirken)
- [❤️ Support](#-support)
- [Danksagung](#danksagung)
- [Lizenz](#lizenz)

---

## Überblick

LAB konzentriert sich auf praktische persönliche Produktivität:

- ✅ Einen Assistenten in Chatkanälen betreiben, die du bereits nutzt.
- 🔐 Daten und Kontrolle auf deinem eigenen Rechner/deinem eigenen Server behalten.
- 📬 Eingehende E-Mails in strukturierte Aktionen umwandeln (Calendar, Reminders, Notes).
- 🛡️ Guardrails hinzufügen, damit Automatisierung nützlich, aber trotzdem sicher bleibt.

Kurz gesagt: weniger Routinearbeit, bessere Ausführung.

---

## Auf einen Blick

| Bereich | Aktueller Stand in diesem Repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Paketmanager | `pnpm@10.23.0` |
| Kern-CLI | `openclaw` |
| Standard-Gateway lokal | `127.0.0.1:18789` |
| Standard-Bridge-Port | `127.0.0.1:18790` |
| Primäre Dokumentation | `docs/` (Mintlify) |
| Primäre LAB-Orchestrierung | `orchestral/` + `scripts/prompt_tools/` |
| Standort der i18n-README | `i18n/README.*.md` |

---

## Funktionen

- 🌐 Multi-Channel-Assistenten-Runtime mit lokalem Gateway.
- 🖥️ Browser-Dashboard/Chat-Oberfläche für lokale Operationen.
- 🧰 Tool-fähige Automatisierungspipeline (Skripte + Prompt-Tools).
- 📨 E-Mail-Triage und Umwandlung in Notes-, Reminders- und Calendar-Aktionen.
- 🧩 Plugin-/Erweiterungsökosystem (`extensions/*`) für Kanäle/Provider/Integrationen.
- 📱 Multi-Platform-Schnittstellen im Repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Kernfunktionen

| Fähigkeit | Bedeutung in der Praxis |
| --- | --- |
| Multi-Channel-Assistenten-Runtime | Gateway + Agent-Sessions über die Kanäle, die du aktivierst |
| Web-Dashboard / Chat | Browser-basierte Steueroberfläche für lokale Operationen |
| Tool-gestützte Workflows | Ketten aus Shell-, Datei- und Automatisierungs-Skripten |
| E-Mail-Automatisierungspipeline | E-Mails parsen, Aktionstyp klassifizieren, zu Notes/Reminders/Calendar routen und Aktionen zur Prüfung/Fehlersuche protokollieren |

Pipeline-Schritte aus dem aktuellen Workflow:

- eingehende E-Mail parsen
- Aktionstyp klassifizieren
- in Notes / Reminders / Calendar speichern
- jede Aktion zur Prüfung und Fehlersuche protokollieren

---

## Projektstruktur

Übersichtliches Repository-Layout:

```text
.
├─ src/                 # core runtime, gateway, channels, CLI, infra
├─ extensions/          # optionale Kanal-/Provider-/Auth-Plugins
├─ orchestral/          # LAB-Orchestrierungs-Pipelines + Prompt-Tools
├─ scripts/             # build/dev/test/release Hilfen
├─ ui/                  # web dashboard UI package
├─ apps/                # macOS / iOS / Android apps
├─ docs/                # Mintlify documentation
├─ references/          # LAB references and operating notes
├─ test/                # test suites
├─ i18n/                # lokalisierte README-Dateien
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI container
├─ README_OPENCLAW.md   # größere upstream-orientierte Referenz-README
└─ README.md            # dieses LAB-orientierte README
```

Hinweise:

- `scripts/prompt_tools` verweist auf die Orchestrated-Prompt-Tool-Implementierung.
- Das Root-`i18n/` enthält lokalisierte README-Varianten.
- `.github/workflows.disabled/` ist in diesem Snapshot vorhanden; das aktive CI-Verhalten sollte vor Annahmen zu Workflows geprüft werden.

---

## Voraussetzungen

Runtime- und Tooling-Baselines aus diesem Repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` als Baseline (siehe `packageManager` in `package.json`)
- Ein konfigurierter Model-Provider-Key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` usw.)
- Optional: Docker + Docker Compose für containerisiertes Gateway/CLI
- Optional für mobile/macOS Builds: Apple/Android Toolchains je nach Zielplattform

Optionale globale CLI-Installation (entsprechender Quickstart-Fluss):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Schnellstart

Runtime-Baseline in diesem Repo: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Danach lokales Dashboard und Chat öffnen:

- http://127.0.0.1:18789

Für Remote-Zugriff gib dein lokales Gateway über einen eigenen sicheren Tunnel frei (z. B. ngrok/Tailscale) und lasse die Authentifizierung aktiviert.

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

Eine `docker-compose.yml` ist enthalten mit:

- `openclaw-gateway`
- `openclaw-cli`

Typischer Ablauf:

```bash
cp .env.example .env
# mindestens: OPENCLAW_GATEWAY_TOKEN und deinen Modellanbieter-Schlüssel setzen
docker compose up -d
```

Typischerweise erforderliche Compose-Variablen:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Nutzung

Häufige Befehle:

```bash
# Onboarding durchführen und Benutzer-Daemon installieren
openclaw onboard --install-daemon

# Gateway im Vordergrund starten
openclaw gateway run --bind loopback --port 18789 --verbose

# Direkte Nachricht über konfigurierte Kanäle senden
openclaw message send --to +1234567890 --message "Hello from LAB"

# Agenten direkt anfragen
openclaw agent --message "Erstelle eine Prioritätenliste für heutige Aufgaben" --thinking high
```

Entwicklungs-Loop (Watch-Modus):

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

Umgebungs- und Konfigurationsreferenz sind auf `.env` und `~/.openclaw/openclaw.json` aufgeteilt.

1. Starte mit `.env.example`.
2. Setze die Gateway-Authentifizierung (`OPENCLAW_GATEWAY_TOKEN` empfohlen).
3. Setze mindestens einen Model-Provider-Key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` usw.).
4. Setze nur Channel-Credentials für Kanäle, die du wirklich aktivierst.

Wichtige Hinweise aus `.env.example`, wie im Repo erhalten:

- Env-Prio: process env -> `./.env` -> `~/.openclaw/.env` -> config `env`-Block.
- Bestehende, nicht leere Process-Env-Werte werden nicht überschrieben.
- Konfigurationsschlüssel wie `gateway.auth.token` können Umgebungs-Fallbacks überlagern.

Sicherheitskritische Baseline vor Internet-Zugriff:

- Halte Gateway-Authentifizierung/Pairing aktiviert.
- Halte Allowlisten für eingehende Channels strikt.
- Behandle jede eingehende Nachricht/jedes E-Mail als untrusted input.
- Mit minimalen Rechten laufen lassen und Logs regelmäßig prüfen.

Wenn du das Gateway ins Internet freigibst, aktiviere zwingend Token-/Passwort-Authentifizierung und eine vertrauenswürdige Proxy-Konfiguration.

---

## Bereitstellungsmodi

| Modus | Geeignet für | Typischer Befehl |
| --- | --- | --- |
| Lokaler Vordergrundmodus | Entwicklung und Debugging | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Lokaler Daemon | Tägliche Nutzung | `openclaw onboard --install-daemon` |
| Docker | Isolierte Runtime und wiederholbare Deployments | `docker compose up -d` |
| Remoter Host + Tunnel | Zugriff von außerhalb deines Heimnetzes | Gateway + sicheren Tunnel betreiben, Auth aktiviert lassen |

Annahme: Produktionsreife Reverse-Proxy-Härtung, Secret-Rotation und Backup-Policy sind deploymentspezifisch und sollten pro Umgebung definiert werden.

---

## LazyingArt-Workflow-Fokus

Dieser Fork priorisiert meinen persönlichen Flow auf **lazying.art**:

- 🎨 Eigenes Branding (LAB / Panda-Thema)
- 📱 Mobile-freundliche Dashboard-/Chat-Erfahrung
- 📨 AutoMail-Pipeline-Varianten (regelgetriebene und codex-unterstützte Speichermodi)
- 🧹 Persönliche Bereinigungs- und Senderklassifikationsskripte
- 🗂️ Notes-/Reminders-/Calendar-Routing für echte tägliche Nutzung abgestimmt

Automation Workspace (lokal):

- `~/.openclaw/workspace/automation/`
- Skriptbezüge im Repo: `references/lab-scripts-and-philosophy.md`
- Dedizierte Codex Prompt-Tools: `scripts/prompt_tools/`

---

## Orchestrationsphilosophie

LAB-Orchestrierung folgt einer Design-Regel:
Komplexe Ziele in deterministische Ausführung + fokussierte Prompt-Tool-Ketten zerlegen.

- Deterministische Skripte übernehmen zuverlässiges Plumbing:
  Terminplanung, Dateirouting, Run-Verzeichnisse, Retries und Output-Handover.
- Prompt-Tools liefern adaptive Intelligenz:
  Planung, Triage, Kontextsynthese und Entscheidungsfindung unter Unsicherheit.
- Jede Stufe erzeugt wiederverwendbare Artefakte, sodass nachgelagerte Tools stärkere finale Notizen/E-Mails ohne Neuaufbau schreiben können.

Wichtige Orchestrierungsketten:

- Unternehmerketten:
  Unternehmenskontext-Aufnahme -> Markt-/Finanzierungs-/wissenschaftliche/rechtliche Intelligence -> konkrete Wachstumsmaßnahmen.
- AutoMail-Kette:
  Eingangsmail-Triage -> konservative Auslassungsregeln für Niedrigwertiges -> strukturierte Notes-/Reminders-/Calendar-Aktionen.
- Webrecherche-Kette:
  Erfassung von Ergebnisseiten -> gezielte Tiefenauswertung mit Screenshot-/Text-Extraktion -> evidenzgestützte Synthese.

---

## Prompt-Tools in LAB

Prompt-Tools sind modular, kombinierbar und orchestrierungszentriert.
Sie können eigenständig laufen oder als verkettete Stufen in größeren Workflows arbeiten.

- Lese-/Speicher-Operationen:
  Erstellung und Aktualisierung von Notes-, Reminders- und Calendar-Ausgaben für AutoLife-Workflows.
- Screenshot-/Lese-Operationen:
  Suchseiten und verlinkte Seiten erfassen, anschließend strukturierten Text für Folgeanalysen extrahieren.
- Tool-Verbindungs-Operationen:
  Deterministische Skripte aufrufen, Artefakte zwischen Stufen austauschen und Kontextkontinuität halten.

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
openclaw agent --message "Überprüfe den heutigen Posteingang und erstelle einen priorisierten Aufgabenplan" --thinking high
```

### Beispiel: Quellcode-Build + Watch-Schleife

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

## Entwicklungshinweise

- Runtime-Basis: Node `>=22.12.0`.
- Paketmanager-Basis: `pnpm@10.23.0` (`packageManager` Feld).
- Übliche Qualitätsprüfungen:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI in der Entwicklung: `pnpm openclaw ...`
- TS-Run-Loop: `pnpm dev`
- UI-Paket-Befehle kommen über Root-Skripte (`pnpm ui:build`, `pnpm ui:dev`).

Übliche erweiterte Testbefehle in diesem Repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Weitere Hilfen:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Annahme:

- Mobile/macOS Build- und Laufbefehle sind in `package.json` vorhanden (`ios:*`, `android:*`, `mac:*`), aber Plattform-Signing/Provisioning-Anforderungen sind umgebungsspezifisch und hier nicht vollständig dokumentiert.

---

## Fehlerbehebung

### Gateway nicht erreichbar unter `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Prüfe auf Portkollisionen und Daemon-Konflikte. Bei Docker verifiziere gemappten Host-Port und Service-Health.

### Auth- oder Channel-Konfigurationsprobleme

- Prüfe `.env`-Werte erneut gegen `.env.example`.
- Stelle sicher, dass mindestens ein Modell-Key konfiguriert ist.
- Verifiziere Channel-Tokens nur für Kanäle, die du wirklich aktivierst.

### Build- oder Installationsprobleme

- `pnpm install` erneut mit Node `>=22.12.0` ausführen.
- Neu bauen mit `pnpm ui:build && pnpm build`.
- Wenn optionale native Peers fehlen, prüfe Installationslogs auf Kompatibilität von `@napi-rs/canvas` / `node-llama-cpp`.

### Allgemeine Gesundheitsprüfungen

Nutze `openclaw doctor`, um Migrations-/Sicherheits-/Konfigurationsdrift zu erkennen.

### Nützliche Diagnostik

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB-Ökosystem-Integrationen

LAB bündelt meine breiteren KI-Produkt- und Forschungs-Repos in eine gemeinsame Betriebsschicht für Erstellung, Wachstum und Automatisierung.

Profil:

- https://github.com/lachlanchen?tab=repositories

Integrierte Repositories:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatisches Schreiben von Romanen)
- `AutoAppDev` (automatische App-Entwicklung)
- `OrganoidAgent` (Organoid-Forschungsplattform mit Foundation-Vision-Modellen + LLMs)
- `LazyEdit` (KI-gestützte Videobearbeitung: Untertitel, Transkription, Highlights, Metadaten)
- `AutoPublish` (automatische Veröffentlichungspipeline)

Praktische LAB-Integrationsziele:

- Romane automatisch schreiben
- Apps automatisch entwickeln
- Videos automatisch schneiden/bearbeiten
- Inhalte automatisch veröffentlichen
- Organoide automatisch analysieren
- E-Mail-Operationen automatisch verarbeiten

---

## Installation aus dem Quellcode (Kurzanleitung)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Entwicklungsschleife:

```bash
pnpm gateway:watch
```

---

## Roadmap

Geplante Richtungen für diesen LAB-Fork (aktive Arbeits-Roadmap):

- Ausbaus der AutoMail-Zuverlässigkeit mit strengerer Sender-/Regelklassifikation.
- Verbessern der Komponierbarkeit von Orchestrationsstufen und Nachvollziehbarkeit von Artefakten.
- Stärkung eines mobile-first Betriebs und der UX für Remote-Gateway-Management.
- Vertiefung der Integration mit LAB-Ökosystem-Repositories für end-to-end automatisierte Produktion.
- Weiteres Härten von Security-Defaults und Observability für unbeaufsichtigte Automatisierung.

---

## Mitwirken

Dieses Repository folgt persönlichen LAB-Prioritäten und übernimmt gleichzeitig die Kernarchitektur von OpenClaw.

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) lesen
- Upstream-Doku prüfen: https://docs.openclaw.ai
- Für Sicherheitsfragen siehe [`SECURITY.md`](../SECURITY.md)

Falls Verhalten auf LAB-spezifische Aspekte unklar sind, bestehendes Verhalten beibehalten und Annahmen in den PR-Notizen dokumentieren.

---

## Danksagung

LazyingArtBot basiert auf **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Danke an die OpenClaw-Maintainer und die Community für die Kernplattform.

---

## Lizenz

MIT (soweit im Upstream passend). Siehe `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
