[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#%D0%B1%D1%8B%D1%81%D1%82%D1%80%D1%8B%D0%B9-%D1%81%D1%82%D0%B0%D1%80%D1%82)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **Статус i18n:** `i18n/` существует и в настоящий момент включает локализованные README на арабском, немецком, испанском, французском, японском, корейском, русском, вьетнамском, упрощённом и традиционном китайском. Этот англоязычный черновик остаётся каноническим источником для инкрементальных обновлений.

**LazyingArtBot** — мой персональный AI-ассистентный стек для **lazying.art**.

**LazyingArtBot** построен на основе OpenClaw и адаптирован под мой ежедневный рабочий процесс: многоканальный чат, локальный контроль и автоматизация email → календарь/напоминания/заметки.

| 🔗 Link | URL | Focus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Основной домен и панель статуса |
| 🤖 Bot domain | https://lazying.art | Точка входа для чата и ассистента |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | Платформа OpenClaw |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | Специфичные настройки LAB |

---

## Содержание

- [Обзор](#%D0%BE%D0%B1%D0%B7%D0%BE%D1%80)
- [Краткий обзор](#%D0%BA%D1%80%D0%B0%D1%82%D0%BA%D0%B8%D0%B9-%D0%BE%D0%B1%D0%B7%D0%BE%D1%80)
- [Возможности](#%D0%B2%D0%BE%D0%B7%D0%BC%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D0%B8)
- [Ключевые возможности](#%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%B2%D1%8B%D0%B5-%D0%B2%D0%BE%D0%B7%D0%BC%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D0%B8)
- [Структура проекта](#%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%82%D1%83%D1%80%D0%B0-%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B0)
- [Требования](#%D1%82%D1%80%D0%B5%D0%B1%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)
- [Быстрый старт](#%D0%B1%D1%8B%D1%81%D1%82%D1%80%D1%8B%D0%B9-%D1%81%D1%82%D0%B0%D1%80%D1%82)
- [Установка](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0)
- [Использование](#%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5)
- [Конфигурация](#%D0%BA%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F)
- [Режимы развертывания](#%D1%80%D0%B5%D0%B6%D0%B8%D0%BC%D1%8B-%D1%80%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)
- [Фокус рабочего процесса LazyingArt](#%D1%84%D0%BE%D0%BA%D1%83%D1%81-%D1%80%D0%B0%D0%B1%D0%BE%D1%87%D0%B5%D0%B3%D0%BE-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D1%81%D1%81%D0%B0-lazyingart)
- [Философия оркестрации](#%D1%84%D0%B8%D0%BB%D0%BE%D1%81%D0%BE%D1%84%D0%B8%D1%8F-%D0%BE%D1%80%D0%BA%D0%B5%D1%81%D1%82%D1%80%D0%B0%D1%86%D0%B8%D0%B8)
- [Prompt-инструменты в LAB](#prompt-%D0%B8%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B-%D0%B2-lab)
- [Примеры](#%D0%BF%D1%80%D0%B8%D0%BC%D0%B5%D1%80%D1%8B)
- [Заметки по разработке](#%D0%B7%D0%B0%D0%BC%D0%B5%D1%82%D0%BA%D0%B8-%D0%BF%D0%BE-%D1%80%D0%B0%D0%B7%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%BA%D0%B5)
- [Устранение неполадок](#%D1%83%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5-%D0%BD%D0%B5%D0%BF%D0%BE%D0%BB%D0%B0%D0%B4%D0%BE%D0%BA)
- [Интеграции экосистемы LAB](#%D0%B8%D0%BD%D1%82%D0%B5%D0%B3%D1%80%D0%B0%D1%86%D0%B8%D0%B8-%D1%8D%D0%BA%D0%BE%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D1%8B-lab)
- [Установка из исходного кода (краткая справка)](#%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%B8%D0%B7-%D0%B8%D1%81%D1%85%D0%BE%D0%B4%D0%BD%D0%BE%D0%B3%D0%BE-%D0%BA%D0%BE%D0%B4%D0%B0-%D0%BA%D1%80%D0%B0%D1%82%D0%BA%D0%B0%D1%8F-%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%BA%D0%B0)
- [Дорожная карта](#%D0%B4%D0%BE%D1%80%D0%BE%D0%B6%D0%BD%D0%B0%D1%8F-%D0%BA%D0%B0%D1%80%D1%82%D0%B0)
- [Участие](#%D1%83%D1%87%D0%B0%D1%81%D1%82%D0%B8%D0%B5)
- [Благодарности](#%D0%B1%D0%BB%D0%B0%D0%B3%D0%BE%D0%B4%D0%B0%D1%80%D0%BD%D0%BE%D1%81%D1%82%D0%B8)
- [❤️ Support](#-support)
- [Лицензия](#%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%8F)

---

## Обзор

LAB ориентирован на практичную личную продуктивность:

- ✅ Запускать одного ассистента во всех уже используемых вами чат-каналах.
- 🔐 Держать данные и управление на вашем собственном устройстве/сервере.
- 📬 Преобразовывать входящую почту в структурированные действия (Calendar, Reminders, Notes).
- 🛡️ Добавлять ограничения, чтобы автоматизация была полезной и при этом безопасной.

Итог: меньше рутины, лучшее выполнение.

---

## Краткий обзор

| Область | Текущее состояние в этом репозитории |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Менеджер пакетов | `pnpm@10.23.0` |
| Основной CLI | `openclaw` |
| Локальный шлюз по умолчанию | `127.0.0.1:18789` |
| Порт локального моста по умолчанию | `127.0.0.1:18790` |
| Основная документация | `docs/` (Mintlify) |
| Основная оркестрация LAB | `orchestral/` + `scripts/prompt_tools/` |
| Расположение README i18n | `i18n/README.*.md` |

---

## Возможности

- 🌐 Многоканальный runtime ассистента с локальным шлюзом.
- 🖥️ Браузерная панель/чат для локального управления.
- 🧰 Pipeline автоматизации с инструментами (скрипты + prompt-tools).
- 📨 Триаж почты и преобразование в действия Notes, Reminders и Calendar.
- 🧩 Экосистема плагинов/расширений (`extensions/*`) для каналов, провайдеров и интеграций.
- 📱 Мультиплатформенные поверхности в репозитории (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Ключевые возможности

| Возможность | Что это означает на практике |
| --- | --- |
| Многоканальный runtime ассистента | Gateway и сессии агента по всем включённым каналам |
| Web dashboard / chat | Панель управления в браузере для локальных операций |
| Workflows с инструментами | Цепочки выполнения shell-/файловых и автоматизационных скриптов |
| Pipeline email-автоматизации | Парсинг писем, классификация типа действия, маршрутизация в Notes/Reminders/Calendar и логирование для проверки/дебага |

Этапы pipeline из текущего рабочего процесса сохранены:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Структура проекта

Общий макет репозитория:

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

Примечания:

- `scripts/prompt_tools` указывает на реализацию orchestral prompt-tools.
- В корне `i18n/` лежат локализованные варианты README.
- В этом снимке присутствует `.github/workflows.disabled/`; поведение активного CI стоит проверить перед тем как опираться на предположения.

---

## Требования

Базовые требования к окружению и инструментам из этого репозитория:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (см. `packageManager` в `package.json`)
- Настроенный ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` и т.д.)
- По желанию: Docker + Docker Compose для контейнеризированного gateway/CLI
- Для сборок под mobile/mac: Apple/Android toolchains в зависимости от целевой платформы

Опциональная глобальная установка CLI (как в quick-start):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Быстрый старт

Базовый runtime в этом репозитории: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

После этого откройте локальную панель/чат:

- http://127.0.0.1:18789

Для удалённого доступа поднимайте локальный gateway через ваш собственный защищённый туннель (например, ngrok/Tailscale) и оставляйте аутентификацию включённой.

---

## Установка

### Установка из исходного кода

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Дополнительный сценарий Docker

В репозитории есть `docker-compose.yml` с:

- `openclaw-gateway`
- `openclaw-cli`

Типичный порядок:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Чаще всего требуются переменные Compose:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Использование

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

Дополнительные полезные команды эксплуатации:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Конфигурация

Справка по окружению и конфигурации разделена между `.env` и `~/.openclaw/openclaw.json`.

1. Начните с `.env.example`.
2. Настройте auth для gateway (`OPENCLAW_GATEWAY_TOKEN` рекомендуется).
3. Установите хотя бы один ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` и т.д.).
4. Добавляйте креденшелы только для каналов, которые реально используете.

Важные примечания из `.env.example`:

- Приоритет переменных: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- Непустые значения process env не переопределяются.
- Конфигурационные ключи вроде `gateway.auth.token` могут иметь приоритет над env fallback.

Критичные меры безопасности перед открытием в интернет:

- Оставляйте включёнными auth/pairing для gateway.
- Держите строгие allowlist'ы для входящих каналов.
- Считайте каждое входящее сообщение/письмо ненадёжным вводом.
- Запускайте с минимально необходимыми привилегиями и регулярно просматривайте логи.

Если вы открываете gateway в интернет, включите token/password auth и доверенную конфигурацию прокси.

---

## Режимы развертывания

| Режим | Для чего подходит | Типичная команда |
| --- | --- | --- |
| Локальный foreground | Разработка и отладка | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Локальный daemon | Ежедневное личное использование | `openclaw onboard --install-daemon` |
| Docker | Изолированный runtime и повторяемые деплои | `docker compose up -d` |
| Remote host + tunnel | Доступ из вне домашней сети | Запустите gateway + защищённый туннель, auth оставьте включённым |

Предположение: production-grade hardening reverse-proxy, ротация секретов и политика бэкапов зависят от среды и должны задаваться отдельно.

---

## Фокус рабочего процесса LazyingArt

Эта форк-ветка фокусируется на моём личном процессе в **lazying.art**:

- 🎨 Собственный брендинг (LAB / тема panda)
- 📱 Удобный мобильный dashboard/chat
- 📨 Варианты automail pipeline (режимы сохранения по правилам и с ассистентной поддержкой codex)
- 🧹 Личные скрипты очистки и классификации отправителей
- 🗂️ Маршрутизация notes/reminders/calendar, настроенная под реальную ежедневную работу

Локальная зона автоматизации:

- `~/.openclaw/workspace/automation/`
- Скриптовые ссылки в репозитории: `references/lab-scripts-and-philosophy.md`
- Специализированные Codex prompt-tools: `scripts/prompt_tools/`

---

## Философия оркестрации

LAB-оркестрация держится одной практической идеи: разбивать сложные цели на детерминированное выполнение и целевые цепочки prompt-инструментов.

- Детерминированные скрипты берут на себя надежную «трубу»:
  планирование, маршрутизацию файлов, каталоги запусков, ретраи и передачу выходных данных.
- Prompt-инструменты обрабатывают адаптивный интеллект:
  планирование, triage, синтез контекста и принятие решений в условиях неопределенности.
- На каждом этапе создаются повторно используемые артефакты, чтобы downstream-инструменты могли собирать более сильные итоговые notes/email без «начала с нуля».

Ключевые оркестровые цепочки:

- Цепочка предпринимательских задач:
  инжест контекста компании -> рынок/финансирование/академические/юридические данные -> конкретные действия по росту.
- Цепочка Auto mail:
  triage входящей почты -> консервативная политика пропуска низкоприоритетной почты -> структурированные actions Notes/Reminders/Calendar.
- Цепочка web search:
  захват страницы результатов -> целенаправленный deep read со скриншотом/экстракцией контента -> синтез на основе доказательств.

---

## Prompt-инструменты в LAB

Prompt-инструменты модульные, композиционные и построенные вокруг оркестрации.
Они могут работать независимо или как связные этапы в более крупном workflow.

- Операции чтения/сохранения:
  создание и обновление outputs для Notes, Reminders и Calendar в AutoLife-сценариях.
- Операции screenshot/read:
  захват страниц поиска и связанных страниц, затем извлечение структурированного текста для последующего анализа.
- Операции tool-connection:
  запуск детерминированных скриптов, обмен артефактами между этапами и поддержка непрерывности контекста.

Основное расположение:

- `scripts/prompt_tools/`

---

## Примеры

### Пример: только локальный gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Пример: попросить агента составить план на день

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Пример: сборка из исходников + watch-loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Пример: запуск в Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Заметки по разработке

- Runtime baseline: Node `>=22.12.0`.
- Базовый менеджер пакетов: `pnpm@10.23.0` (`packageManager` field).
- Основные quality gates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI в разработке: `pnpm openclaw ...`
- TS-цикл: `pnpm dev`
- Команды UI-пакета проксируются через root-скрипты (`pnpm ui:build`, `pnpm ui:dev`).

Расширенные команды тестирования в этом репозитории:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Дополнительные команды для девелопа:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Примечание:

- Команды сборки и запуска iOS/macOS приложений есть в `package.json` (`ios:*`, `android:*`, `mac:*`), но требования подписи и provisioning зависят от среды и не полностью описаны в этом README.

---

## Устранение неполадок

### Gateway не доступен на `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Проверьте конфликты портов и даемона. Если используется Docker, проверьте проксированный хост-порт и состояние сервиса.

### Проблемы с аутентификацией или конфигом каналов

- Повторно проверьте значения в `.env` относительно `.env.example`.
- Убедитесь, что настроен хотя бы один ключ модели.
- Проверьте токены каналов только для тех каналов, которые действительно включены.

### Проблемы со сборкой или установкой

- Запустите заново `pnpm install` с Node `>=22.12.0`.
- Пересоберите: `pnpm ui:build && pnpm build`.
- Если отсутствуют опциональные native peers, проверьте логи установки на совместимость `@napi-rs/canvas` / `node-llama-cpp`.

### Общая диагностика состояния

Для выявления миграционных/безопасностных/конфигурационных дрейфов используйте `openclaw doctor`.

### Полезные диагностические команды

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Интеграции экосистемы LAB

LAB объединяет мои AI-продуктовые и исследовательские репозитории в единый рабочий слой для создания, роста и автоматизации.

Профиль:

- https://github.com/lachlanchen?tab=repositories

Интегрированные репозитории:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (автоматическая генерация романов)
- `AutoAppDev` (автоматическая разработка приложений)
- `OrganoidAgent` (исследовательская платформа Organoid с foundation vision models + LLM)
- `LazyEdit` (AI-помощник монтажа видео: субтитры/транскрипции/тайминги/метаданные)
- `AutoPublish` (pipeline автоматической публикации)

Практические цели интеграции LAB:

- Автоматически писать романы
- Автоматически разрабатывать приложения
- Автоматически редактировать видео
- Автоматически публиковать результаты
- Автоматически анализировать органоиды
- Автоматически обрабатывать почту

---

## Установка из исходного кода (краткая справка)

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

## Дорожная карта

Планируемые направления для этой форк-ветки LAB (рабочая roadmap):

- Повысить надёжность automail через более строгую классификацию отправителей/правил.
- Улучшить композиционность оркестровых стадий и трассируемость артефактов.
- Усилить mobile-first операции и UX управления удалённым gateway.
- Расширить интеграции с репозиториями экосистемы LAB для end-to-end автоматизированного производства.
- Продолжить усиление security defaults и наблюдаемости для автономной автоматизации.

---

## Участие

Этот репозиторий сохраняет личные приоритеты LAB и опирается на базовую архитектуру OpenClaw.

- [Прочитать `CONTRIBUTING.md`](../CONTRIBUTING.md)
- Изучить документацию upstream: https://docs.openclaw.ai
- Для вопросов безопасности см. [`SECURITY.md`](../SECURITY.md)

Если поведение LAB неочевидно, сохраните существующую логику и зафиксируйте предположения в PR-заметках.

---

## Благодарности

LazyingArtBot основан на **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Спасибо команде и сообществу OpenClaw за платформу.

---

## Лицензия

MIT (то же, что и upstream, где применимо). См. `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
