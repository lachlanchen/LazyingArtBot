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


**LazyingArtBot** هي حزمة مساعدي الشخصي للذكاء الاصطناعي الخاصة بـ **lazying.art**.
تم بناؤها فوق OpenClaw وتكييفها لسير عملي اليومي: محادثة متعددة القنوات، وتحكم local-first، وأتمتة البريد الإلكتروني -> التقويم/التذكيرات/الملاحظات.

| 🔗 الرابط | URL |
| --- | --- |
| 🌐 الموقع | https://lazying.art |
| 🤖 نطاق البوت | https://lazying.art |
| 🧱 القاعدة الأساسية (Upstream) | https://github.com/openclaw/openclaw |
| 📦 هذا المستودع | https://github.com/lachlanchen/LazyingArtBot |

---

## جدول المحتويات

- [نظرة عامة](#نظرة-عامة)
- [لمحة سريعة](#لمحة-سريعة)
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
- [خارطة الطريق](#خارطة-الطريق)
- [المساهمة](#المساهمة)
- [❤️ Support](#-support)
- [الشكر والتقدير](#الشكر-والتقدير)
- [الترخيص](#الترخيص)

---

## نظرة عامة

يركّز LAB على إنتاجية شخصية عملية:

- ✅ تشغيل مساعد واحد عبر قنوات المحادثة التي تستخدمها بالفعل.
- 🔐 إبقاء البيانات والتحكم على جهازك/خادمك.
- 📬 تحويل البريد الوارد إلى إجراءات منظّمة (Calendar, Reminders, Notes).
- 🛡️ إضافة حواجز أمان تجعل الأتمتة مفيدة لكنها آمنة.

باختصار: أعمال روتينية أقل، وتنفيذ أفضل.

---

## لمحة سريعة

| المجال | الخط الأساسي الحالي في هذا المستودع |
| --- | --- |
| بيئة التشغيل | Node.js `>=22.12.0` |
| مدير الحزم | `pnpm@10.23.0` |
| CLI الأساسي | `openclaw` |
| البوابة المحلية الافتراضية | `127.0.0.1:18789` |
| منفذ الجسر الافتراضي | `127.0.0.1:18790` |
| الوثائق الأساسية | `docs/` (Mintlify) |
| تنسيق LAB الرئيسي | `orchestral/` + `scripts/prompt_tools/` |
| موقع README متعدد اللغات | `i18n/README.*.md` |

---

## الميزات

- 🌐 بيئة تشغيل مساعد متعددة القنوات مع بوابة محلية.
- 🖥️ لوحة تحكم/محادثة عبر المتصفح للعمليات المحلية.
- 🧰 خط أتمتة مدعوم بالأدوات (scripts + prompt-tools).
- 📨 فرز البريد وتحويله إلى إجراءات Notes وReminders وCalendar.
- 🧩 منظومة plugins/extensions (`extensions/*`) للقنوات/المزودات/التكاملات.
- 📱 واجهات متعددة المنصات داخل المستودع (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## القدرات الأساسية

| القدرة | معناها عمليًا |
| --- | --- |
| بيئة تشغيل مساعد متعددة القنوات | جلسات Gateway + agent عبر القنوات التي تفعّلها |
| لوحة ويب / محادثة | واجهة تحكم عبر المتصفح للعمليات المحلية |
| سير عمل مدعوم بالأدوات | سلاسل تنفيذ shell + file + automation script |
| خط أتمتة البريد الإلكتروني | تحليل البريد، تصنيف نوع الإجراء، توجيهه إلى Notes/Reminders/Calendar، وتسجيل الإجراءات للمراجعة/تصحيح الأخطاء |

خطوات الخط المحفوظة من سير العمل الحالي:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## هيكل المشروع

تخطيط المستودع على مستوى عالٍ:

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

- يشير `scripts/prompt_tools` إلى تنفيذ أدوات prompt ضمن orchestral.
- يحتوي جذر `i18n/` على نسخ README المترجمة.
- يوجد `.github/workflows.disabled/` في هذه اللقطة؛ يجب التحقق من سلوك CI الفعلي قبل الاعتماد على افتراضات سير العمل.

---

## المتطلبات المسبقة

خطوط الأساس الخاصة ببيئة التشغيل والأدوات في هذا المستودع:

- Node.js `>=22.12.0`
- خط أساس pnpm هو `10.23.0` (راجع `packageManager` في `package.json`)
- مفتاح مزوّد نموذج واحد على الأقل (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, إلخ)
- اختياري: Docker + Docker Compose لتشغيل gateway/CLI ضمن حاويات
- اختياري لبناءات الموبايل/mac: سلاسل أدوات Apple/Android حسب المنصة المستهدفة

تثبيت CLI عالمي اختياري (يطابق تدفق البدء السريع):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## البدء السريع

خط أساس بيئة التشغيل في هذا المستودع: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

ثم افتح لوحة التحكم المحلية والمحادثة:

- http://127.0.0.1:18789

للوصول عن بُعد، عرّض البوابة المحلية عبر نفق آمن من اختيارك (مثل ngrok/Tailscale) مع إبقاء المصادقة مفعلة.

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

يتضمن `docker-compose.yml` ما يلي:

- `openclaw-gateway`
- `openclaw-cli`

تدفق نموذجي:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

متغيرات Compose المطلوبة غالبًا:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## الاستخدام

أوامر شائعة:

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

حلقة التطوير (watch mode):

```bash
pnpm gateway:watch
```

تطوير الواجهة:

```bash
pnpm ui:dev
```

أوامر تشغيلية إضافية مفيدة:

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

مرجع البيئة والإعداد مقسّم بين `.env` و `~/.openclaw/openclaw.json`.

1. ابدأ من `.env.example`.
2. اضبط مصادقة البوابة (يوصى بـ `OPENCLAW_GATEWAY_TOKEN`).
3. اضبط مفتاح مزود نموذج واحد على الأقل (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, إلخ).
4. اضبط بيانات اعتماد القنوات التي تفعّلها فقط.

ملاحظات مهمة من `.env.example` محفوظة من المستودع:

- أسبقية متغيرات البيئة: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- القيم غير الفارغة الموجودة مسبقًا في process env لا يتم تجاوزها.
- مفاتيح الإعداد مثل `gateway.auth.token` يمكن أن تتقدم على بدائل env.

الخط الأساسي الأمني قبل التعرض للإنترنت:

- أبقِ مصادقة/اقتران البوابة مفعّلين.
- اجعل قوائم السماح صارمة للقنوات الواردة.
- تعامل مع كل رسالة/بريد وارد على أنه إدخال غير موثوق.
- شغّل بأقل صلاحيات ممكنة وراجع السجلات بانتظام.

إذا عرّضت البوابة للإنترنت، فاشترط مصادقة token/password وإعداد trusted proxy.

---

## أنماط النشر

| النمط | الأنسب لـ | أمر نموذجي |
| --- | --- | --- |
| Local foreground | التطوير وتصحيح الأخطاء | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | الاستخدام الشخصي اليومي | `openclaw onboard --install-daemon` |
| Docker | بيئة تشغيل معزولة ونشر قابل للتكرار | `docker compose up -d` |
| Remote host + tunnel | الوصول من خارج الشبكة المنزلية | تشغيل gateway + نفق آمن، مع إبقاء المصادقة مفعلة |

افتراض: تقوية reverse-proxy على مستوى الإنتاج، وتدوير الأسرار، وسياسات النسخ الاحتياطي تعتمد على بيئة النشر ويجب تعريفها لكل بيئة.

---

## تركيز سير عمل LazyingArt

هذا التفرع يركز على تدفقي الشخصي في **lazying.art**:

- 🎨 هوية مخصصة (LAB / panda theme)
- 📱 تجربة لوحة تحكم/محادثة صديقة للموبايل
- 📨 تنويعات خط automail (rule-triggered, codex-assisted save modes)
- 🧹 سكربتات تنظيف شخصية وتصنيف المرسلين
- 🗂️ توجيه Notes/Reminders/Calendar مضبوط للاستخدام اليومي الفعلي

مساحة عمل الأتمتة (محليًا):

- `~/.openclaw/workspace/automation/`
- مراجع السكربتات في المستودع: `references/lab-scripts-and-philosophy.md`
- أدوات Codex prompt المخصصة: `scripts/prompt_tools/`

---

## فلسفة Orchestral

يتبع تنسيق LAB قاعدة تصميم واحدة:
تقسيم الأهداف الصعبة إلى تنفيذ حتمي + سلاسل prompt-tool مركزة.

- تتولى السكربتات الحتمية الأعمال الموثوقة:
  الجدولة، وتوجيه الملفات، وأدلة التشغيل، وإعادة المحاولة، وتسليم المخرجات.
- تتولى أدوات prompt الذكاء التكيفي:
  التخطيط، والفرز، وتوليف السياق، واتخاذ القرار تحت عدم اليقين.
- كل مرحلة تُنتج artifacts قابلة لإعادة الاستخدام لكي تبني المراحل اللاحقة مخرجات أقوى دون البدء من الصفر.

السلاسل الأساسية في orchestral:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## أدوات Prompt في LAB

أدوات Prompt معيارية، قابلة للتركيب، وتبدأ من مبدأ orchestration-first.
يمكن تشغيلها بشكل مستقل أو كمراحل مترابطة داخل سير عمل أكبر.

- عمليات القراءة/الحفظ:
  إنشاء وتحديث مخرجات Notes وReminders وCalendar لعمليات AutoLife.
- عمليات لقطة الشاشة/القراءة:
  التقاط صفحات نتائج البحث والصفحات المرتبطة ثم استخراج نص منظم للتحليل اللاحق.
- عمليات ربط الأدوات:
  استدعاء السكربتات الحتمية، وتبادل artifacts بين المراحل، والحفاظ على استمرارية السياق.

الموقع الرئيسي:

- `scripts/prompt_tools/`

---

## أمثلة

### مثال: بوابة محلية فقط

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### مثال: اطلب من الوكيل معالجة التخطيط اليومي

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

- خط أساس بيئة التشغيل: Node `>=22.12.0`.
- خط أساس مدير الحزم: `pnpm@10.23.0` (حقل `packageManager`).
- بوابات الجودة الشائعة:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI أثناء التطوير: `pnpm openclaw ...`
- حلقة تشغيل TS: `pnpm dev`
- أوامر حزمة الواجهة ممررة عبر سكربتات الجذر (`pnpm ui:build`, `pnpm ui:dev`).

أوامر اختبار موسعة شائعة في هذا المستودع:

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

- توجد أوامر بناء/تشغيل تطبيقات الموبايل/macOS في `package.json` (`ios:*`, `android:*`, `mac:*`)، لكن متطلبات التوقيع/provisioning خاصة بالبيئة وليست موثقة بالكامل في هذا README.

---

## استكشاف الأخطاء وإصلاحها

### لا يمكن الوصول إلى Gateway على `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

تحقق من تعارض المنافذ وتعارضات daemon. إذا كنت تستخدم Docker، فتأكد من منفذ الاستضافة المربوط وصحة الخدمة.

### مشكلات المصادقة أو إعداد القنوات

- أعد فحص قيم `.env` مقارنةً بـ `.env.example`.
- تأكد من إعداد مفتاح نموذج واحد على الأقل.
- تحقق من tokens القنوات للقنوات التي فعّلتها بالفعل فقط.

### مشكلات البناء أو التثبيت

- أعد تشغيل `pnpm install` مع Node `>=22.12.0`.
- أعد البناء باستخدام `pnpm ui:build && pnpm build`.
- إذا كانت peer dependencies الأصلية الاختيارية مفقودة، فراجع سجلات التثبيت لتوافق `@napi-rs/canvas` / `node-llama-cpp`.

### فحوصات الصحة العامة

استخدم `openclaw doctor` لاكتشاف مشكلات الانحراف المرتبطة بالترحيل/الأمان/الإعداد.

### أدوات تشخيص مفيدة

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## تكاملات منظومة LAB

يدمج LAB مستودعات منتجاتي وأبحاثي الأوسع في طبقة تشغيل واحدة للإنتاج والنمو والأتمتة.

الملف الشخصي:

- https://github.com/lachlanchen?tab=repositories

المستودعات المدمجة:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (كتابة روايات تلقائية)
- `AutoAppDev` (تطوير تطبيقات تلقائي)
- `OrganoidAgent` (منصة أبحاث العضيّات بنماذج رؤية تأسيسية + LLMs)
- `LazyEdit` (تحرير فيديو بمساعدة الذكاء الاصطناعي: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (مسار نشر تلقائي)

أهداف التكامل العملية في LAB:

- كتابة الروايات تلقائيًا
- تطوير التطبيقات تلقائيًا
- تحرير الفيديو تلقائيًا
- نشر المخرجات تلقائيًا
- تحليل العضيّات تلقائيًا
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

## خارطة الطريق

الاتجاهات المخطط لها لهذا التفرع من LAB (خارطة عمل):

- توسيع موثوقية automail عبر تصنيف أكثر صرامة للمرسل/القواعد.
- تحسين قابلية تركيب مراحل orchestral وإمكانية تتبع artifacts.
- تعزيز تجربة العمليات mobile-first وإدارة البوابة عن بُعد.
- تعميق التكاملات مع مستودعات منظومة LAB للإنتاج المؤتمت من البداية للنهاية.
- الاستمرار في تقوية إعدادات الأمان الافتراضية والرصد للأتمتة غير المراقبة.

---

## المساهمة

يتتبع هذا المستودع أولويات LAB الشخصية مع وراثة البنية المعمارية الأساسية من OpenClaw.

- اقرأ [`CONTRIBUTING.md`](CONTRIBUTING.md)
- راجع وثائق المنبع: https://docs.openclaw.ai
- لمشكلات الأمان، راجع [`SECURITY.md`](SECURITY.md)

إذا لم تكن متأكدًا من سلوك LAB الخاص، فحافظ على السلوك الحالي ووثّق الافتراضات في ملاحظات PR.

---

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## الشكر والتقدير

يعتمد LazyingArtBot على **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

شكرًا لفريق OpenClaw والمجتمع على المنصة الأساسية.

---

## الترخيص

MIT (مثل المنبع حيث ينطبق). راجع `LICENSE`.
