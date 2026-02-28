[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-быстрый-старт)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)

> 🌍 **Статус i18n:** `i18n/` существует и сейчас включает локализованные файлы README на арабском, немецком, испанском, французском, японском, корейском, русском, вьетнамском, упрощённом китайском и традиционном китайском языках. Этот английский черновик остаётся каноническим источником для инкрементных обновлений.

**LazyingArtBot** — мой личный AI-ассистентный стек для **lazying.art**. Он построен на OpenClaw и адаптирован под мой ежедневный рабочий процесс: многоканальный чат, local-first управление и автоматизация email → calendar/reminder/notes.

| 🔗 Ссылка | URL |
| --- | --- |
| 🌐 Сайт | https://lazying.art |
| 🤖 Домен бота | https://lazying.art |
| 🧱 Базовый репозиторий | https://github.com/openclaw/openclaw |
| 📦 Этот репозиторий | https://github.com/lachlanchen/LazyingArtBot |

---

## Содержание

- [Обзор](#обзор)
- [Кратко](#кратко)
- [Функции](#функции)
- [Базовые возможности](#базовые-возможности)
- [Структура проекта](#структура-проекта)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Установка](#установка)
- [Использование](#использование)
- [Конфигурация](#конфигурация)
- [Режимы развертывания](#режимы-развертывания)
- [Фокус рабочего процесса LazyingArt](#фокус-рабочего-процесса-lazyingart)
- [Оркестровая философия](#оркестровая-философия)
- [Prompt инструменты в LAB](#prompt-инструменты-в-lab)
- [Примеры](#примеры)
- [Заметки по разработке](#заметки-по-разработке)
- [Устранение неполадок](#устранение-неполадок)
- [Интеграции экосистемы LAB](#интеграции-экосистемы-lab)
- [Установка из исходников (краткая справка)](#установка-из-исходников-краткая-справка)
- [Дорожная карта](#дорожная-карта)
- [Вклад в проект](#вклад-в-проект)
- [❤️ Support](#-support)
- [Благодарности](#благодарности)
- [Лицензия](#лицензия)

---

## Обзор

LAB ориентирован на практическую личную продуктивность:

- ✅ Работайте с одним ассистентом во всех используемых чат-каналах.
- 🔐 Держите данные и контроль на своей машине/сервере.
- 📬 Превращайте входящие письма в структурированные действия (Calendar, Reminders, Notes).
- 🛡️ Добавляйте ограничения, чтобы автоматизация оставалась полезной, но безопасной.

Проще говоря: меньше рутины, лучше выполнение.

---

## Кратко

| Область | Текущая база в этом репозитории |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Менеджер пакетов | `pnpm@10.23.0` |
| Основной CLI | `openclaw` |
| Gateway по умолчанию локально | `127.0.0.1:18789` |
| Порт локального моста | `127.0.0.1:18790` |
| Основная документация | `docs/` (Mintlify) |
| Основная оркестровка LAB | `orchestral/` + `scripts/prompt_tools/` |
| Локализация README | `i18n/README.*.md` |

---

## Функции

- 🌐 Многоканальный runtime ассистента с локальным gateway.
- 🖥️ Web-дашборд/чат-канал для локального управления.
- 🧰 Инструментальный автоматизационный pipeline (скрипты + prompt-tools).
- 📨 Триаж электронной почты и конвертация в действия Notes, Reminders и Calendar.
- 🧩 Экосистема плагинов/расширений (`extensions/*`) для каналов, провайдеров и интеграций.
- 📱 Кроссплатформенные поверхности прямо в репозитории (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Базовые возможности

| Возможность | Как это выглядит на практике |
| --- | --- |
| Многоканальный runtime ассистента | Gateway + сессии агента для включённых каналов |
| Web-дашборд / чат | Веб-интерфейс для локального управления |
| Workflows с инструментами | Цепочки исполнения shell + file + automation scripts |
| Pipeline обработки почты | Разбор письма, классификация типа действия, маршрутизация в Notes/Reminders/Calendar, логирование действий для ревью и отладки |

Этапы конвейера из текущего workflow сохранены:

- разбор входящей почты
- классификация типа действия
- сохранение в Notes / Reminders / Calendar
- логирование каждого действия для проверки и отладки

---

## Структура проекта

Выглядит так:

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
├─ README_OPENCLAW.md   # upstream-style reference README
└─ README.md            # this LAB-focused README
```

Примечания:

- `scripts/prompt_tools` — реализация orchestral prompt-tools.
- Корневой `i18n/` содержит локализованные варианты README.
- В этом снимке присутствует `.github/workflows.disabled/`; активное поведение CI лучше проверить перед тем, как опираться на workflow в документации.

---

## Требования

Базовые требования по runtime и инструментам из этого репозитория:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (см. `packageManager` в `package.json`)
- Настроенный ключ модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` и т.д.)
- Опционально: Docker + Docker Compose для контейнеризированного gateway/CLI
- Для мобильной/desktop сборки: соответствующие toolchain Apple/Android

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

Затем откройте локальный dashboard/chatsurface:

- http://127.0.0.1:18789

Для удалённого доступа опубликуйте локальный gateway через собственный защищённый туннель (например, ngrok/Tailscale), и обязательно оставьте включённую аутентификацию.

---

## Установка

### Установка из исходников

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Опциональный Docker workflow

В репозитории есть `docker-compose.yml` с сервисами:

- `openclaw-gateway`
- `openclaw-cli`

Типовой поток:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Переменные compose, обычно требуемые:

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

openclaw health
openclaw doctor
```

---

## Конфигурация

Ссылки на env и конфигурацию разделены между `.env` и `~/.openclaw/openclaw.json`.

1. Начните с `.env.example`.
2. Настройте авторизацию gateway (`OPENCLAW_GATEWAY_TOKEN` рекомендуется).
3. Укажите хотя бы один ключ провайдера модели (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` и т.д.).
4. Задавайте креды каналов только для действительно включённых каналов.

Ключевые замечания `.env.example`, сохранившиеся в репозитории:

- Приоритет env: process env → `./.env` → `~/.openclaw/.env` → блок `env` из config.
- Непустые значения process env не перезаписываются.
- Ключи config вроде `gateway.auth.token` могут иметь более высокий приоритет, чем fallback из env.

Критически важная база безопасности перед открытием в интернет:

- Оставляйте включёнными auth/pairing для gateway.
- Держите строгий allowlist для входящих каналов.
- Считайте каждое входящее сообщение или письмо ненадёжным вводом.
- Запускайте с минимальными привилегиями и регулярно просматривайте логи.

Если открываете gateway в интернет, требуйте token/password auth и надёжную конфигурацию прокси.

---

## Режимы развертывания

| Режим | Лучшее применение | Типичная команда |
| --- | --- | --- |
| Локальный foreground | Разработка и отладка | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Локальный daemon | Ежедневное личное использование | `openclaw onboard --install-daemon` |
| Docker | Изолированный runtime и повторяемые деплои | `docker compose up -d` |
| Удалённый хост + tunnel | Доступ из вне локальной сети | Запуск gateway + безопасного туннеля, с включённой аутентификацией |

Предположение: production-grade hardening reverse-proxy, ротация секретов и политика бэкапов зависят от окружения и должны настраиваться там, где это развёртывание.

---

## Фокус рабочего процесса LazyingArt

Этот форк оптимизирован под личный workflow в **lazying.art**:

- 🎨 кастомный брендинг (LAB / panda theme)
- 📱 интерфейс dashboard/chat, удобный для мобильных устройств
- 📨 варианты automail (правила/режимы сохранения с подсказками Codex)
- 🧹 персональные скрипты очистки и классификации отправителей
- 🗂️ маршрутизация notes/reminders/calendar, настроенная под реальный ежедневный ритм

Рабочее пространство автоматизации (локально):

- `~/.openclaw/workspace/automation/`
- Ссылки на скрипты в репозитории: `references/lab-scripts-and-philosophy.md`
- Специализированные инструменты Codex: `scripts/prompt_tools/`

---

## Оркестровая философия

LAB-оркестрация следует одному правилу дизайна:
разбивать сложные цели на сочетание детерминированного выполнения и цепочек prompt-tools с фокусом на осмысленность.

- Детерминированные скрипты берут на себя надёжную «трубу»:
  планирование расписания, маршрутизацию файлов, каталоги выполнения, повторные попытки и передачу результатов.
- Prompt tools берут адаптивный интеллект:
  планирование, triage, синтез контекста и принятие решений в условиях неопределённости.
- Каждый этап оставляет переиспользуемые артефакты, чтобы downstream-инструменты собирали более сильные итоговые заметки/письма без перезапуска с нуля.

Ключевые оркестровые цепочки:

- Цепочка для компании-предприятия:
  загрузка контекста компании → market/funding/academic/legal intelligence → конкретные actions роста.
- Автоцепочка почты:
  triage входящих писем → консервативная политика пропуска малоценной почты → структурированные действия Notes/Reminders/Calendar.
- Веб-поисковая цепочка:
  захват страницы результатов → углублённое чтение с screenshot/content extraction → синтез с обоснованными доказательствами.

---

## Prompt инструменты в LAB

Prompt tools модульны, составные и ориентированы на оркестрацию.
Они могут выполняться самостоятельно или как связанные этапы в большем workflow.

- Операции чтения/сохранения:
  создание и обновление заметок, напоминаний и событий календаря для автоматических операций.
- Операции screenshot/read:
  захват страниц поиска и связанных страниц, затем структурная выдача текста для последующего анализа.
- Операции tool-connection:
  вызов детерминированных скриптов, обмен артефактами между этапами и поддержание непрерывности контекста.

Основное расположение:

- `scripts/prompt_tools/`

---

## Примеры

### Пример: gateway только локально

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Пример: попросить агента распланировать день

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

### Пример: запуск в Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Заметки по разработке

- Runtime baseline: Node `>=22.12.0`.
- Package manager baseline: `pnpm@10.23.0` (`packageManager` field).
- Базовые quality gates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI в dev: `pnpm openclaw ...`
- TS run loop: `pnpm dev`
- Команды UI-пакета проксируются через root-скрипты (`pnpm ui:build`, `pnpm ui:dev`).

Распространённые расширенные команды тестов в этом репозитории:

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

Примечание по допущению:

- Команды сборки/запуска для мобильных и macOS существуют в `package.json` (`ios:*`, `android:*`, `mac:*`), но требования к signing/provisioning зависят от окружения и не полностью документированы в этом README.

---

## Устранение неполадок

### Gateway недоступен на `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Проверьте конфликты порта и конфликты с демоном. Если используется Docker, проверьте порт на хосте и состояние сервиса.

### Проблемы с auth или конфигурацией каналов

- Повторно проверьте `.env` относительно `.env.example`.
- Убедитесь, что настроен хотя бы один ключ модели.
- Проверьте токены каналов только для реально включённых каналов.

### Ошибки сборки или установки

- Повторите `pnpm install` с Node `>=22.12.0`.
- Пересоберите `pnpm ui:build && pnpm build`.
- Если отсутствуют опциональные native peers, проверьте логи установки на предмет совместимости `@napi-rs/canvas` / `node-llama-cpp`.

### Общие проверки состояния

Используйте `openclaw doctor`, чтобы поймать drift в миграциях, безопасности и конфигурации.

### Полезная диагностика

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Интеграции экосистемы LAB

LAB объединяет мои более широкие AI-продукты и исследовательские репозитории в один слой для создания, роста и автоматизации.

Профиль:

- https://github.com/lachlanchen?tab=repositories

Интегрируемые репозитории:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Практические цели интеграции LAB:

- Автоматическая генерация романов
- Автоматическая разработка приложений
- Автоматическое редактирование видео
- Автоматическая публикация результатов
- Авто-анализ органоидов
- Автоматическая обработка email

---

## Установка из исходников (краткая справка)

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

## Дорожная карта

Планируемые направления для этого форка LAB:

- Расширить надёжность automail с более строгой классификацией отправителей и правил.
- Повысить композиционность оркестровых этапов и трассируемость артефактов.
- Усилить mobile-first UX и удалённое управление gateway.
- Глубже интегрировать репозитории LAB-экосистемы для сквозной автоматизированной production.
- Продолжать укреплять безопасные дефолты и наблюдаемость для работы без присмотра.

---

## Вклад в проект

Этот репозиторий отражает личные приоритеты LAB, сохраняя базовую архитектуру OpenClaw.

- Прочитайте [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Ознакомьтесь с документацией upstream: https://docs.openclaw.ai
- По вопросам безопасности смотрите [`SECURITY.md`](SECURITY.md)

Если есть сомнения в поведении, специфичном для LAB, сохраняйте существующее поведение и фиксируйте допущения в заметках PR.

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Благодарности

LazyingArtBot основан на **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Спасибо команде и сообществу OpenClaw за базовую платформу.

---

## Лицензия

MIT (там же, где применимо, как у upstream). См. `LICENSE`.
