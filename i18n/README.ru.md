[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-быстрый-старт)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

>
> Примечание: каталог `i18n/` уже существует и сейчас включает Arabic. Дополнительные локализованные варианты README обновляются по одному, чтобы сохранять согласованность с исходником.

**LazyingArtBot** — мой персональный стек AI-ассистента для **lazying.art**.  
Он построен на базе OpenClaw и адаптирован под мои ежедневные сценарии: многоканальный чат, local-first управление и автоматизацию email → calendar/reminder/notes.

| Ссылка | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| Этот репозиторий | https://github.com/lachlanchen/LazyingArtBot |

---

## Содержание

- [🧭 Обзор](#-обзор)
- [⚡ Кратко](#-кратко)
- [⚙️ Основные возможности](#️-основные-возможности)
- [🧱 Структура проекта](#-структура-проекта)
- [📋 Предварительные требования](#-предварительные-требования)
- [🚀 Быстрый старт](#-быстрый-старт)
- [🧱 Установка](#-установка)
- [🛠️ Использование](#️-использование)
- [🔐 Конфигурация](#-конфигурация)
- [🧩 Фокус рабочих процессов LazyingArt](#-фокус-рабочих-процессов-lazyingart)
- [🎼 Философия оркестрации](#-философия-оркестрации)
- [🧰 Prompt tools в LAB](#-prompt-tools-в-lab)
- [💡 Примеры](#-примеры)
- [🧪 Заметки для разработки](#-заметки-для-разработки)
- [🩺 Устранение неполадок](#-устранение-неполадок)
- [🌐 Интеграции экосистемы LAB](#-интеграции-экосистемы-lab)
- [Установка из исходников](#установка-из-исходников)
- [🗺️ Дорожная карта](#️-дорожная-карта)
- [🤝 Вклад в проект](#-вклад-в-проект)
- [❤️ Поддержка / Sponsor](#️-поддержка--sponsor)
- [🙏 Благодарности](#-благодарности)
- [📄 Лицензия](#-лицензия)

---

## 🧭 Обзор

LAB сфокусирован на практической персональной продуктивности:

- Запускайте одного ассистента во всех чат-каналах, которыми уже пользуетесь.
- Храните данные и управление на своей машине/сервере.
- Преобразуйте входящие email в структурированные действия (Calendar, Reminders, Notes).
- Добавляйте защитные ограничения, чтобы автоматизация оставалась полезной и безопасной.

Кратко: меньше рутины, лучше исполнение.

---

## ⚡ Кратко

| Область | Текущий базовый уровень в этом репозитории |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Менеджер пакетов | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Локальный gateway по умолчанию | `127.0.0.1:18789` |
| Основная документация | `docs/` (Mintlify) |
| Основная оркестрация LAB | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Основные возможности

- Рантайм ассистента для нескольких каналов (Gateway + agent sessions).
- Web dashboard / web chat как единая поверхность управления.
- Workflows агента с инструментами (shell, files, automation scripts).
- Пайплайн автоматизации email для личных операций:
  - разбор входящей почты
  - классификация типа действия
  - сохранение в Notes / Reminders / Calendar
  - логирование каждого действия для ревью и отладки

---

## 🧱 Структура проекта

Структура репозитория верхнего уровня:

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

Примечания:

- `scripts/prompt_tools` указывает на реализацию orchestral prompt-tool.
- Корневой `i18n/` существует и в этом снимке пока минимален; локализованная документация в основном находится в `docs/`.

---

## 📋 Предварительные требования

Базовые требования по runtime и инструментам из этого репозитория:

- Node.js `>=22.12.0`
- Базовая версия pnpm `10.23.0` (см. `packageManager` в `package.json`)
- Настроенный ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Опционально: Docker + Docker Compose для контейнерного gateway/CLI

Опциональная глобальная установка CLI (соответствует flow быстрого старта):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Быстрый старт

Базовый runtime в этом репозитории: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Затем откройте локальную панель и чат:

- http://127.0.0.1:18789

Для удалённого доступа публикуйте локальный gateway через собственный безопасный туннель (например, ngrok/Tailscale) и держите аутентификацию включённой.

---

## 🧱 Установка

### Установка из исходников

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Опциональный workflow с Docker

Включён `docker-compose.yml` со следующими сервисами:

- `openclaw-gateway`
- `openclaw-cli`

Типовой flow:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Примечание: пути монтирования и порты управляются переменными compose, такими как `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT` и `OPENCLAW_BRIDGE_PORT`.

---

## 🛠️ Использование

Частые команды:

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

Цикл разработки (watch mode):

```bash
pnpm gateway:watch
```

Разработка UI:

```bash
pnpm ui:dev
```

---

## 🔐 Конфигурация

Справка по environment и config разделена между `.env` и `~/.openclaw/openclaw.json`.

1. Начните с `.env.example`.
2. Настройте auth gateway (`OPENCLAW_GATEWAY_TOKEN` рекомендуется).
3. Задайте как минимум один ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Указывайте креды каналов только для тех каналов, которые вы включаете.

Важные примечания из `.env.example`, сохранённые из репозитория:

- Приоритет env: process env → `./.env` → `~/.openclaw/.env` → блок `env` в config.
- Существующие непустые значения process env не перезаписываются.
- Ключи config, такие как `gateway.auth.token`, могут иметь приоритет над fallback из env.

Критически важная база безопасности перед публикацией в интернет:

- Держите auth/pairing gateway включёнными.
- Поддерживайте строгие allowlist для входящих каналов.
- Считайте каждое входящее сообщение/email недоверенным вводом.
- Запускайте с минимальными привилегиями и регулярно просматривайте логи.

Если вы открываете gateway в интернет, требуйте token/password auth и доверенную конфигурацию proxy.

---

## 🧩 Фокус рабочих процессов LazyingArt

Этот форк приоритизирует мой персональный поток работы в **lazying.art**:

- кастомный брендинг (LAB / panda theme)
- mobile-friendly опыт dashboard/chat
- варианты automail-пайплайна (rule-triggered, codex-assisted save modes)
- скрипты личной очистки и классификации отправителей
- маршрутизация notes/reminders/calendar, настроенная под реальную повседневную работу

Рабочее пространство автоматизации (локально):

- `~/.openclaw/workspace/automation/`
- Ссылки на скрипты в репозитории: `references/lab-scripts-and-philosophy.md`
- Выделенные Codex prompt tools: `scripts/prompt_tools/`

---

## 🎼 Философия оркестрации

Оркестрация LAB следует одному правилу дизайна:  
разбивать сложные цели на детерминированное исполнение + цепочки специализированных prompt tools.

- Детерминированные скрипты берут на себя надёжную обвязку:
  планирование, маршрутизацию файлов, run-директории, ретраи и передачу результатов.
- Prompt tools обеспечивают адаптивный интеллект:
  планирование, triage, синтез контекста и принятие решений в условиях неопределённости.
- Каждый этап генерирует переиспользуемые артефакты, чтобы последующие инструменты могли собирать более сильные итоговые notes/email, не начиная с нуля.

Ключевые orchestral-цепочки:

- Цепочка предпринимательства компании:
  ingestion контекста компании → market/funding/academic/legal intelligence → конкретные действия для роста.
- Цепочка auto mail:
  triage входящей почты → консервативная skip-политика для низкоценных писем → структурированные действия Notes/Reminders/Calendar.
- Цепочка web search:
  capture страниц выдачи → целевые глубокие чтения со screenshot/content extraction → синтез на основе доказательств.

---

## 🧰 Prompt tools в LAB

Prompt tools модульные, композиционные и в первую очередь ориентированы на оркестрацию.  
Они могут запускаться отдельно или как связанные этапы в более крупном workflow.

- Операции чтения/сохранения:
  создание и обновление результатов Notes, Reminders и Calendar для операций AutoLife.
- Операции screenshot/read:
  захват поисковых страниц и страниц по ссылкам с последующим извлечением структурированного текста для дальнейшего анализа.
- Операции соединения инструментов:
  вызов детерминированных скриптов, обмен артефактами между этапами и поддержание непрерывности контекста.

Основное расположение:

- `scripts/prompt_tools/`

---

## 💡 Примеры

### Пример: gateway только локально

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Пример: попросить агента обработать ежедневное планирование

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Пример: сборка из исходников + watch loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 Заметки для разработки

- Базовый runtime: Node `>=22.12.0`.
- Базовый менеджер пакетов: `pnpm@10.23.0` (поле `packageManager`).
- Типовые quality gates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI в режиме разработки: `pnpm openclaw ...`
- Цикл запуска TS: `pnpm dev`
- Команды UI-пакета проксируются через root scripts (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Устранение неполадок

### Gateway недоступен на `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Проверьте конфликты порта и конфликты daemon-процессов. Если используете Docker, проверьте проброшенный порт хоста и состояние сервиса.

### Проблемы с auth или конфигурацией каналов

- Ещё раз сверьте значения `.env` с `.env.example`.
- Убедитесь, что настроен хотя бы один ключ модели.
- Проверяйте токены каналов только для реально включённых каналов.

### Общая проверка состояния

Используйте `openclaw doctor` для обнаружения проблем миграции/безопасности/дрейфа конфигурации.

---

## 🌐 Интеграции экосистемы LAB

LAB объединяет мои более широкие AI-продукты и исследовательские репозитории в один операционный слой для создания, роста и автоматизации.

Профиль:

- https://github.com/lachlanchen?tab=repositories

Интегрированные репозитории:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Практические цели интеграции LAB:

- Auto write novels
- Auto develop apps
- Auto edit videos
- Auto publish outputs
- Auto analyze organoids
- Auto handle email operations

---

## Установка из исходников

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Цикл разработки:

```bash
pnpm gateway:watch
```

---

## 🗺️ Дорожная карта

Запланированные направления для этого LAB-форка (рабочая roadmap):

- Расширить надёжность automail за счёт более строгой классификации отправителей/правил.
- Улучшить композиционность этапов orchestral и трассируемость артефактов.
- Усилить mobile-first операции и UX удалённого управления gateway.
- Углубить интеграции с репозиториями экосистемы LAB для сквозного автоматизированного производства.
- Продолжать усиление безопасных настроек по умолчанию и наблюдаемости для unattended automation.

---

## 🤝 Вклад в проект

Этот репозиторий отражает персональные приоритеты LAB, наследуя базовую архитектуру OpenClaw.

- Прочитайте [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Ознакомьтесь с документацией апстрима: https://docs.openclaw.ai
- По вопросам безопасности см. [`SECURITY.md`](SECURITY.md)

Если есть неопределённость в LAB-специфичном поведении, сохраняйте существующее поведение и документируйте предположения в заметках к PR.

---

## ❤️ Поддержка / Sponsor

Если LAB помогает вашему workflow, поддержите дальнейшую разработку:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Благодарности

LazyingArtBot основан на **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Спасибо мейнтейнерам и сообществу OpenClaw за базовую платформу.

---

## 📄 Лицензия

MIT (как и у апстрима там, где применимо). См. `LICENSE`.
