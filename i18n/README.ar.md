[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#البدء-السريع)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

**LazyingArtBot** هو ستاك المساعد الذكي الشخصي الخاص بي لموقع **lazying.art**:

**LazyingArtBot** مبني فوق OpenClaw ومُعدّل ليتوافق مع سير عملي اليومي: دردشة متعددة القنوات، وتحكم local-first، وأتمتة البريد الإلكتروني إلى تقويم/تذكيرات/ملاحظات.

| 🔗 الرابط           | URL                                          | التركيز                          |
| ------------------- | -------------------------------------------- | -------------------------------- |
| 🌐 الموقع           | https://lazying.art                          | النطاق الأساسي ولوحة حالة الخدمة |
| 🤖 نطاق البوت       | https://lab.lazying.art                      | نقطة دخول المحادثة والمساعد      |
| 🧱 القاعدة الأساسية | https://github.com/openclaw/openclaw         | أساس منصة OpenClaw               |
| 📦 هذا المستودع     | https://github.com/lachlanchen/LazyingArtBot | تخصيصات LAB                      |

---

## فهرس المحتويات

- [نظرة عامة](#نظرة-عامة)
- [نظرة سريعة](#لمحة-سريعة)
- [الميزات](#الميزات)
- [القدرات الأساسية](#القدرات-الأساسية)
- [هيكل المشروع](#هيكل-المشروع)
- [المتطلبات المسبقة](#المتطلبات-المسبقة)
- [البدء السريع](#البدء-السريع)
- [التثبيت](#التثبيت)
- [الاستخدام](#الاستخدام)
- [الإعداد](#الإعداد)
- [أنماط النشر](#أنماط-النشر)
- [تركيز سير عمل LazyingArt](#تركيز-سير-عمل-lazyingart)
- [فلسفة Orchestral](#فلسفة-orchestral)
- [أدوات Prompt في LAB](#أدوات-prompt-في-lab)
- [أمثلة](#أمثلة)
- [ملاحظات التطوير](#ملاحظات-التطوير)
- [استكشاف الأخطاء وإصلاحها](#استكشاف-الأخطاء-وإصلاحها)
- [تكاملات منظومة LAB](#تكاملات-منظومة-lab)
- [التثبيت من المصدر (مرجع سريع)](#التثبيت-من-المصدر-مرجع-سريع)
- [خطة الطريق](#خطة-الطريق)
- [المساهمة](#المساهمة)
- [❤️ Support](#-support)
- [الشكر والتقدير](#الشكر-والتقدير)
- [الترخيص](#الترخيص)

---

## نظرة عامة

يركز LAB على إنتاجية عملية للحياة اليومية:

- ✅ تشغيل مساعد واحد عبر قنوات الدردشة التي تستخدمها بالفعل.
- 🔐 الحفاظ على البيانات والتحكم على جهازك أو خادمك.
- 📬 تحويل البريد الوارد إلى إجراءات منظمة (Calendar, Reminders, Notes).
- 🛡️ إضافة قيود أمان تجعل الأتمتة مفيدة لكن آمنة.

باختصار: أعمال مكتبية أقل، وتنفيذ أفضل.

---

## لمحة سريعة

| المجال                     | الحالة المرجعية في هذا المستودع            |
| -------------------------- | ------------------------------------------ |
| وقت التشغيل                | Node.js `>=22.12.0`                        |
| مدير الحزم                 | `pnpm@10.23.0`                             |
| CLI الأساسي                | `openclaw`                                 |
| البوابة المحلية الافتراضية | `127.0.0.1:18789`                          |
| منفذ الجسر الافتراضي       | `127.0.0.1:18790`                          |
| الوثائق الأساسية           | `docs/` (Mintlify)                         |
| تنسيق LAB الأساسي          | `orchestral/` + `orchestral/prompt_tools/` |
| موقع README متعدد اللغات   | `i18n/README.*.md`                         |

---

## الميزات

- 🌐 وقت تشغيل مساعد متعدد القنوات مع بوابة محلية.
- 🖥️ سطح تشغيل/دردشة للعمليات المحلية عبر المتصفح.
- 🧰 خط أتمتة مُفعّل بالأدوات (scripts + prompt-tools).
- 📨 فرز وتحويل البريد الإلكتروني إلى إجراءات في Notes وReminders وCalendar.
- 🧩 نظام إضافات (`extensions/*`) للقنوات/المزودات/التكاملات.
- 📱 واجهات متعددة المنصات داخل المستودع (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## القدرات الأساسية

| القدرة                        | ما يعنيه ذلك عملياً                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- |
| وقت تشغيل مساعد متعدد القنوات | بوابة + جلسات agent عبر القنوات التي تفعلها                                                               |
| لوحة الويب/الدردشة            | واجهة تحكم بالعمليات المحلية عبر المتصفح                                                                  |
| سير عمل بالأدوات              | سلسلة تنفيذ shell + file + سكربتات أتمتة                                                                  |
| خط أتمتة البريد الإلكتروني    | تحليل الرسائل، تصنيف نوع الإجراء، توجيهها إلى Notes/Reminders/Calendar، وتسجيل الإجراءات للمراجعة/التصحيح |

خطوات خط المعالجة المحفوظة من سير العمل الحالي:

- تحليل البريد الوارد
- تصنيف نوع الإجراء
- الحفظ إلى Notes / Reminders / Calendar
- تسجيل كل إجراء للمراجعة والتصحيح

---

## هيكل المشروع

تخطيط المستودع على مستوى عالي:

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

ملاحظات:

- `orchestral/prompt_tools` يشير إلى تنفيذ أدوات orchestral prompt.
- يوجد في الجذر `i18n/` ملفات README مترجمة.
- `‪.github/workflows.disabled/` موجود في هذه اللحظة؛ تأكد من حالة CI النشطة قبل الاعتماد على افتراضات سير العمل.

---

## المتطلبات المسبقة

الأساسيات التشغيلية والأدوات في هذا المستودع:

- Node.js `>=22.12.0`
- pnpm `10.23.0` كخط أساس (انظر `packageManager` في `package.json`)
- مفتاح مزود نموذج واحد على الأقل (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, إلخ.)
- اختياري: Docker + Docker Compose للبنية المعزولة للبوابة/CLI
- اختياري لبناءات الجوال/mac: سلاسل أدوات Apple/Android بحسب منصة الهدف

تثبيت CLI عالمي اختياري (مطابق لتدفق البدء السريع):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## البدء السريع

الأساس التشغيلي في هذا المستودع: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

ثم افتح لوحة التحكم المحلية:

- http://127.0.0.1:18789

للوصول عن بُعد، اعرض البوابة المحلية عبر نفق آمن (مثلاً ngrok/Tailscale) مع تمكين المصادقة.

---

## التثبيت

### التثبيت من المصدر

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### سير عمل Docker اختياري

يوجد ملف `docker-compose.yml` ويتضمن:

- `openclaw-gateway`
- `openclaw-cli`

التدفق النموذجي:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

متغيرات Compose شائعة الاستخدام:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## الاستخدام

الأوامر الشائعة:

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

حلقة تطوير (watch mode):

```bash
pnpm gateway:watch
```

تطوير واجهة المستخدم:

```bash
pnpm ui:dev
```

أوامر تشغيلية مفيدة إضافية:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## الإعداد

مرجع الإعداد والبيئة مقسم بين `.env` و `~/.openclaw/openclaw.json`.

1. ابدأ من `.env.example`.
2. ضبط مصادقة البوابة (`OPENCLAW_GATEWAY_TOKEN` موصى به).
3. اضبط مفتاح مزود نموذج واحد على الأقل (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, إلخ).
4. اجعل بيانات اعتماد القنوات موجودة فقط للقنوات التي تفعلها.

ملاحظات `.env.example` المهمة والمحافظة عليها من المستودع:

- أولوية المتغيرات: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- القيم غير الفارغة الحالية في process env لا تُستبدل.
- مفاتيح التكوين مثل `gateway.auth.token` يمكنها أن تتقدم على بدائل env.

أساسيات أمنيّة قبل التعرض للإنترنت:

- احتفظ بمصادقة/اقتران البوابة مفعّلة.
- اجعل allowlists صارمة للقنوات الواردة.
- تعامل مع كل رسالة/بريد وارد كمدخل غير موثوق.
- شغّل بأقل صلاحيات وراجع السجلات بانتظام.

إذا عرضت البوابة على الإنترنت، اشترط token/password auth وتكوين proxy موثوق به.

---

## أنماط النشر

| النمط                              | الأفضل لـ                     | الأمر المعتاد                                                 |
| ---------------------------------- | ----------------------------- | ------------------------------------------------------------- |
| التشغيل في الواجهة الأمامية محليًا | التطوير والتصحيح              | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| daemon محلي                        | الاستخدام الشخصي اليومي       | `openclaw onboard --install-daemon`                           |
| Docker                             | تشغيل معزول ونشر قابل للتكرار | `docker compose up -d`                                        |
| مضيف بعيد + نفق                    | الوصول من خارج شبكة المنزل    | شغّل البوابة + نفقًا آمنًا مع إبقاء المصادقة مفعّلة           |

الافتراض: تقوية reverse-proxy على مستوى الإنتاج، تدوير الأسرار، وسياسة النسخ الاحتياطي أمور خاصة بكل بيئة وينبغي تعريفها حسب البيئة.

---

## تركيز سير عمل LazyingArt

هذا الفرع يركز على تدفقي الشخصي في **lazying.art**:

- 🎨 هوية مخصصة (LAB / ثيم الباندا)
- 📱 تجربة لوحة تحكم ودردشة مناسبة للجوال
- 📨 نسخ مختلفة من automail (rule-triggered, codex-assisted save modes)
- 🧹 سكربتات تنظيف شخصي وتصنيف المرسلين
- 🗂️ توجيه Notes/Reminders/Calendar مضبوط لاستخدام يومي فعلي

فضاء العمل الأوتوماتيكي (محلي):

- `~/.openclaw/workspace/automation/`
- مراجع السكربتات في المستودع: `references/lab-scripts-and-philosophy.md`
- أدوات Codex prompt المخصصة: `orchestral/prompt_tools/`

---

## فلسفة Orchestral

تنسيق LAB يتبع قاعدة تصميم واحدة:
تقسيم الأهداف المعقدة إلى تنفيذ حتمي وسلاسل prompt-tool مركزة.

- السكربتات الحتمية تتولى الأنابيب الموثوقة:
  جدولة، توجيه ملفات، تشغيل الأدلة، إعادة المحاولات، وتسليم المخرجات.
- أدوات prompt تتولى الذكاء التكيفي:
  التخطيط، الفرز، تركيب السياق، واتخاذ القرار تحت عدم اليقين.
- كل مرحلة تنتج artifacts قابلة لإعادة الاستخدام بحيث تبني الأدوات اللاحقة مخرجات أقوى بدون البدء من الصفر.

سلاسل orchestral الأساسية:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## أدوات Prompt في LAB

أدوات Prompt معيارية وقابلة للتركيب وتركيزها orchestration-first.
يمكن تشغيلها بشكل مستقل أو كسلاسل مرتبطة في تدفق عمل أكبر.

- عمليات القراءة/الحفظ:
  إنشاء وتحديث مخرجات Notes وReminders وCalendar لعمليات AutoLife.
- عمليات لقطة الشاشة/القراءة:
  التقاط صفحات نتائج البحث والصفحات المرتبطة ثم استخراج نص منظم للتحليل اللاحق.
- عمليات ربط الأدوات:
  استدعاء سكربتات حتمية، تبادل artifacts بين المراحل، والحفاظ على استمرارية السياق.

الموقع الأساسي:

- `orchestral/prompt_tools/`

---

## أمثلة

### مثال: بوابة محلية فقط

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### مثال: اطلب من agent معالجة التخطيط اليومي

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### مثال: بناء المصدر + حلقة المراقبة

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### مثال: التشغيل في Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## ملاحظات التطوير

- خط أساس التشغيل: Node `>=22.12.0`.
- خط أساس مدير الحزم: `pnpm@10.23.0` (حقل `packageManager`).
- بوابات جودة شائعة:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI في طور التطوير: `pnpm openclaw ...`
- حلقة تشغيل TS: `pnpm dev`
- أوامر حزمة الواجهة تُمرَّر عبر سكربتات الجذر (`pnpm ui:build`, `pnpm ui:dev`).

أوامر الاختبار الموسعة الشائعة في هذا المستودع:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

مساعدات تطوير إضافية:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

ملاحظة افتراض:

- توجد أوامر بناء/تشغيل تطبيقات الجوال/macOS في `package.json` (`ios:*`, `android:*`, `mac:*`) لكن متطلبات التوقيع/الـ provisioning خاصة بالبيئة وليست موثقة بالكامل في هذا README.

---

## استكشاف الأخطاء وإصلاحها

### البوابة غير قابلة للوصول على `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

تحقق من تصادم المنافذ وتعارض الـ daemon. إذا كنت تستخدم Docker، تحقق من منفذ host المرتبط وصحة الخدمة.

### مشاكل المصادقة أو إعداد القنوات

- أعد فحص قيم `.env` مقابل `.env.example`.
- تأكد من أن مفتاح نموذج واحد على الأقل مكوّن.
- تحقق من tokens القناة فقط للقنوات التي فعّلتها فعلاً.

### مشاكل البناء أو التثبيت

- أعد تشغيل `pnpm install` باستخدام Node `>=22.12.0`.
- أعد البناء باستخدام `pnpm ui:build && pnpm build`.
- إذا كانت peer dependencies اختيارية مفقودة، راجع سجلات التثبيت لتوافق `@napi-rs/canvas` / `node-llama-cpp`.

### فحوصات الصحة العامة

استخدم `openclaw doctor` لاكتشاف مشكلات الانحراف في الترحيل/الأمن/الإعداد.

### تشخيصات مفيدة

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## تكاملات منظومة LAB

يمزج LAB بين مستودعات منتجاتي وأبحاثي الأوسع في طبقة تشغيل واحدة للإنتاج والنمو والأتمتة.

الملف الشخصي:

- https://github.com/lachlanchen?tab=repositories

المستودعات المدمجة:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (كتابة روايات تلقائيًا)
- `AutoAppDev` (تطوير تطبيقات تلقائي)
- `OrganoidAgent` (منصة أبحاث organoids برؤية أساسية + LLMs)
- `LazyEdit` (تحرير فيديو بمساعدة AI: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (مسار نشر تلقائي)

أهداف التكامل العملي في LAB:

- كتابة الروايات تلقائيًا
- تطوير التطبيقات تلقائيًا
- تحرير الفيديو تلقائيًا
- نشر المخرجات تلقائيًا
- تحليل organoids تلقائيًا
- معالجة عمليات البريد الإلكتروني تلقائيًا

---

## التثبيت من المصدر (مرجع سريع)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

حلقة التطوير:

```bash
pnpm gateway:watch
```

---

## خطة الطريق

اتجاهات خارطة هذا الفرع (قيد العمل):

- توسيع موثوقية automail عبر تصنيف أكثر صرامة للمرسل/القواعد.
- تحسين قابلية تركيب مراحل orchestral وإمكانية تتبع artifacts.
- تقوية تجربة التشغيل mobile-first وإدارة البوابة عن بعد.
- تعميق التكاملات مع مستودعات منظومة LAB لإنتاج مؤتمت من طرف إلى طرف.
- مواصلة تعزيز إعدادات الأمان الافتراضية والمراقبة للأتمتة غير المراقَبة.

---

## المساهمة

يتبع هذا المستودع أولويات LAB الشخصية مع الاعتماد على البنية الأساسية من OpenClaw.

- اقرأ [`CONTRIBUTING.md`](CONTRIBUTING.md)
- راجع وثائق المصدر: https://docs.openclaw.ai
- لمشكلات الأمان، راجع [`SECURITY.md`](SECURITY.md)

إذا لم تكن متأكدًا من سلوك LAB الخاص، حافظ على السلوك القائم ودوّن الافتراضات في ملاحظات PR.

---

## الشكر والتقدير

LazyingArtBot مبني على **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

شكرًا لمحترفي OpenClaw والمجتمع على المنصة الأساسية.

---

## الترخيص

MIT (كما هو الحال في المنبع عند الاقتضاء). راجع `LICENSE`.

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
