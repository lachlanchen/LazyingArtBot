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

> 🌍 **Статус i18n:** `i18n/` существует и сейчас включает локализованные README-файлы для арабского, немецкого, испанского, французского, японского, корейского, русского, вьетнамского, упрощённого и традиционного китайского языков. Этот английский черновик остаётся каноническим источником при инкрементальных обновлениях.

**LazyingArtBot** — это мой персональный AI-ассистентный стек для **lazying.art**:

**LazyingArtBot** построен на OpenClaw и адаптирован под мои повседневные рабочие процессы: мультиканальный чат, локально-первичный контроль и автоматизация цепочки email → календарь/напоминания/заметки.

| 🔗 Ссылка | URL | Назначение |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Основной домен и панель статуса |
| 🤖 Bot domain | https://lazying.art | Точка входа для чата и ассистента |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | Базовая платформа OpenClaw |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | Адаптации LAB |

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
- [Особенности рабочего процесса LazyingArt](#%D0%B0%D1%82%D1%80%D0%B8%D0%B1%D1%83%D1%82%D1%8B-%D1%80%D0%B0%D0%B1%D0%BE%D1%87%D0%B5%D0%B3%D0%BE-%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D1%81%D1%81%D0%B0-lazyingart)
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
- [Контакты](#%D0%BA%D0%BE%D0%BD%D1%82%D0%B0%D0%BA%D1%82%D1%8B)
- [Лицензия](#%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%8F)

---

## Обзор

LAB ориентирован на практичную личную продуктивность:

- ✅ Запускайте одного ассистента во всех используемых вами чат-каналах.
- 🔐 Храните данные и контроль на своём устройстве/сервере.
- 📬 Преобразуйте входящую почту в структурированные действия (Calendar, Reminders, Notes).
- 🛡️ Добавляйте защитные ограничения, чтобы автоматизация была полезной и при этом безопасной.

Проще говоря: меньше рутинной работы и лучшее исполнение.

---

## Краткий обзор

| Область | Текущий базовый уровень в этом репозитории |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Менеджер пакетов | `pnpm@10.23.0` |
| Основной CLI | `openclaw` |
| Локальный шлюз по умолчанию | `127.0.0.1:18789` |
| Порт локального моста по умолчанию | `127.0.0.1:18790` |
| Основная документация | `docs/` (Mintlify) |
| Основная LAB-оркестрация | `orchestral/` + `scripts/prompt_tools/` |
| Расположение i18n README | `i18n/README.*.md` |

---

## Возможности

- 🌐 Многоканальный runtime ассистента с локальным шлюзом.
- 🖥️ Web-дашборд/чат для локальных операций.
- 🧰 Автоматизационный pipeline с инструментами (скрипты + prompt-tools).
- 📨 Триаж писем и преобразование в задачи Notes, Reminders и Calendar.
- 🧩 Экосистема плагинов/расширений (`extensions/*`) для каналов, поставщиков и интеграций.
- 📱 Кроссплатформенные поверхности в одном репозитории (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Ключевые возможности

| Возможность | Что это означает на практике |
| --- | --- |
| Многоканальный runtime ассистента | Gateway и сессии агента по всем включённым каналам |
| Веб-дашборд / чат | Панель управления в браузере для локальных операций |
| Workflows с инструментами | Цепочки выполнения shell-, файловых и автоматизационных скриптов |
| Pipeline e-mail-автоматизации | Разбор писем, классификация типа действия, маршрутизация в Notes/Reminders/Calendar и логирование для ревью/отладки |

Этапы pipeline из текущего рабочего процесса сохранены:

- разбор входящей почты
- классификация типа действия
- сохранение в Notes / Reminders / Calendar
- логирование каждого действия для проверки и отладки

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
- Корень `i18n/` хранит локализованные версии README.
- В этой сборке присутствует `.github/workflows.disabled/`; поведение активного CI лучше перепроверить перед опорой на него.

---

## Требования

Базовые требования к окружению и инструментам из этого репозитория:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (см. `packageManager` в `package.json`)
- Настроенный ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` и т.д.)
- Необязательно: Docker + Docker Compose для контейнерного запуска gateway/CLI
- Необязательно для сборки мобильных/mac-приложений: инструменты Apple/Android согласно целевой платформе

Необязательная глобальная установка CLI (как в quick-start):

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

Затем откройте локальную панель и чат:

- http://127.0.0.1:18789

Для удалённого доступа безопасно выставьте локальный gateway через ваш туннель (например, ngrok/Tailscale) и оставьте аутентификацию включённой.

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

### Дополнительный Docker-подход

В репозитории есть `docker-compose.yml` с компонентами:

- `openclaw-gateway`
- `openclaw-cli`

Обычно так:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Обычно требуется указать переменные Compose:

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

Dev loop (watch mode):

```bash
pnpm gateway:watch
```

UI-разработка:

```bash
pnpm ui:dev
```

Дополнительные полезные эксплуатационные команды:

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

1. Начинайте с `.env.example`.
2. Настройте авторизацию gateway (`OPENCLAW_GATEWAY_TOKEN` рекомендуется).
3. Укажите минимум один ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` и т.д.).
4. Добавляйте учётные данные каналов только для каналов, которые реально включены.

Ключевые замечания `.env.example`:

- Порядок приоритета: process env -> `./.env` -> `~/.openclaw/.env` -> блок config `env`.
- Непустые значения process env не перезаписываются.
- Конфигурационные ключи вроде `gateway.auth.token` могут иметь приоритет над fallback env.

Критичные меры безопасности перед открытием в интернет:

- Оставляйте gateway auth/pairing включённым.
- Поддерживайте строгие allowlist для входящих каналов.
- Рассматривайте каждое входящее сообщение/письмо как недоверенный ввод.
- Запускайте с минимальными привилегиями и регулярно просматривайте логи.

Если публикуете gateway в интернет, используйте token/password auth и доверенную проксирующую конфигурацию.

---

## Режимы развертывания

| Режим | Лучшее применение | Типичная команда |
| --- | --- | --- |
| Локальный foreground | Разработка и отладка | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Локальный daemon | Ежедневное личное использование | `openclaw onboard --install-daemon` |
| Docker | Изолированный runtime и воспроизводимые деплои | `docker compose up -d` |
| Remote host + tunnel | Доступ извне домашней локальной сети | Запустите gateway + защищённый туннель, оставьте auth включённым |

Предполагается, что production hardening reverse-proxy, ротация секретов и политика резервного копирования — это требования конкретной среды и должны быть определены под окружение.

---

## Особенности рабочего процесса LazyingArt

Эта форк-ветка ориентирована на мой личный поток работы в **lazying.art**:

- 🎨 Собственный брендинг (LAB / тема panda)
- 📱 Удобный для мобильных устройств опыт dashboard/chat
- 📨 Варианты automail (режимы сохранения по правилам и с поддержкой codex)
- 🧹 Личные скрипты очистки и классификации отправителей
- 🗂️ Маршрутизация notes/reminders/calendar, настроенная под реальную ежедневную работу

Локальная зона автоматизации:

- `~/.openclaw/workspace/automation/`
- Ссылки на скрипты в репозитории: `references/lab-scripts-and-philosophy.md`
- Специализированные Codex prompt-tools: `scripts/prompt_tools/`

---

## Философия оркестрации

LAB-оркестрация опирается на один принцип: разбивать сложные цели на предсказуемые этапы выполнения и цепочки prompt-tools.

- Детерминированные скрипты берут на себя надёжную “трубу”:
  планирование, маршрутизацию файлов, каталоги запусков, повторы и передачу результатов.
- Prompt-tools обрабатывают адаптивный интеллект:
  планирование, triage, синтез контекста и принятие решений под неопределённостью.
- На каждом этапе формируются переиспользуемые артефакты, чтобы downstream-инструменты могли собирать более сильные финальные notes/email без “старта с нуля”.

Ключевые оркестровые цепочки:

- Компании и предпринимательская цепочка:
  интеграция контекста компании -> рыночные/финансовые/научные/юридические инсайты -> конкретные действия по росту.
- Цепочка Auto mail:
  triage входящей почты -> консервативная политика отсева низкоприоритетных писем -> структурированные actions Notes/Reminders/Calendar.
- Цепочка web search:
  capture страницы результатов -> точечный deep read со скриншотом/извлечением контента -> синтез на основе доказательств.

---

## Prompt-инструменты в LAB

Prompt-инструменты модульные, компонуемые и оркестрационные.
Они могут работать отдельно или как связанные этапы в более крупном workflow.

- Операции чтения/сохранения:
  создание и обновление outputs для Notes, Reminders и Calendar в сценариях AutoLife.
- Операции screenshot/read:
  захват страниц поиска и связанных страниц, затем извлечение структурированного текста для downstream анализа.
- Операции tool-connection:
  запуск детерминированных скриптов, обмен артефактами между этапами и сохранение непрерывности контекста.

Основное расположение:

- `scripts/prompt_tools/`

---

## Примеры

### Пример: только локальный gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Пример: попросить агента обработать дневное планирование

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Пример: сборка из исходного кода + watch-loop

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

- CLI в режиме разработки: `pnpm openclaw ...`
- TS-цикл: `pnpm dev`
- Команды UI-пакета проксируются через root scripts (`pnpm ui:build`, `pnpm ui:dev`).

Расширенные команды тестирования в этом репозитории:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Дополнительные служебные команды:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Примечание:

- Команды сборки и запуска iOS/macOS приложений находятся в `package.json` (`ios:*`, `android:*`, `mac:*`), но требования подписи и provisioning зависят от среды и не полностью описаны в этом README.

---

## Устранение неполадок

### Gateway недоступен на `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Проверьте конфликты портов и конкуренцию демонов. Если используете Docker, проверьте проброс порта хоста и состояние сервиса.

### Ошибки авторизации или конфигурации каналов

- Повторно проверьте значения в `.env` по сравнению с `.env.example`.
- Убедитесь, что настроен минимум один ключ модели.
- Проверяйте токены каналов только для тех каналов, которые реально включены.

### Проблемы со сборкой или установкой

- Перезапустите `pnpm install` с Node `>=22.12.0`.
- Пересоберите с `pnpm ui:build && pnpm build`.
- Если не хватает optional native peers, проверьте логи установки на предмет совместимости `@napi-rs/canvas` / `node-llama-cpp`.

### Общие проверки состояния

Для поиска проблем миграции/безопасности/конфигурации используйте `openclaw doctor`.

### Полезная диагностика

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Интеграции экосистемы LAB

LAB объединяет мои AI-ориентированные продуктовые и исследовательские репозитории в единый рабочий слой для создания, роста и автоматизации.

Профиль:

- https://github.com/lachlanchen?tab=repositories

Интегрированные репозитории:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (автоматическое написание романов)
- `AutoAppDev` (автоматическая разработка приложений)
- `OrganoidAgent` (платформа органоидных исследований с foundation vision models + LLM)
- `LazyEdit` (AI-помощник монтажа видео: субтитры, расшифровка, highlights, метаданные)
- `AutoPublish` (автоматический конвейер публикации)

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

Планируемые направления для этой LAB-ветки (рабочая roadmap):

- Повысить надёжность automail через более строгую классификацию отправителей и правил.
- Улучшить компонуемость оркестровых стадий и трассируемость артефактов.
- Усилить mobile-first операции и UX управления удалённым gateway.
- Глубже интегрировать репозитории экосистемы LAB для сквозной автоматизированной production.
- Продолжить усиление security defaults и наблюдаемости для автономной автоматизации.

---

## Участие

Этот репозиторий отражает личные приоритеты LAB и опирается на архитектуру OpenClaw.

- Прочитать [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- Изучить upstream-документацию: https://docs.openclaw.ai
- По вопросам безопасности см. [`SECURITY.md`](../SECURITY.md)

Если поведение LAB кажется неочевидным, сохраняйте существующую логику и фиксируйте допущения в примечаниях к PR.

---

## Благодарности

LazyingArtBot построен на базе **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Спасибо команде и сообществу OpenClaw за базовую платформу.

## Контакты

- Сайт: https://lazying.art
- Репозиторий: https://github.com/lachlanchen/LazyingArtBot
- Трекер задач: https://github.com/lachlanchen/LazyingArtBot/issues
- Вопросы безопасности или доверия: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## Лицензия

MIT (то же, что и в upstream, где применимо). См. `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
