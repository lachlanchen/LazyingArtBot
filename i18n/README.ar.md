[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

> **LazyingArtBot** هو حزمة مساعدي الشخصي بالذكاء الاصطناعي الخاصة بـ **lazying.art**.
> 
> تم بناؤه فوق OpenClaw وتكييفه مع سير عملي اليومي: دردشة متعددة القنوات، تحكم local-first، وأتمتة البريد الإلكتروني إلى التقويم/التذكيرات/الملاحظات.

| الرابط | URL |
| --- | --- |
| الموقع | https://lazying.art |
| نطاق البوت | https://lazying.art |
| المشروع الأساسي (Upstream) | https://github.com/openclaw/openclaw |
| هذا المستودع | https://github.com/lachlanchen/LazyingArtBot |

---

## جدول المحتويات

- [🧭 نظرة عامة](#-نظرة-عامة)
- [⚡ لمحة سريعة](#-لمحة-سريعة)
- [⚙️ القدرات الأساسية](#️-القدرات-الأساسية)
- [🧱 بنية المشروع](#-بنية-المشروع)
- [📋 المتطلبات المسبقة](#-المتطلبات-المسبقة)
- [🚀 البدء السريع](#-البدء-السريع)
- [🧱 التثبيت](#-التثبيت)
- [🛠️ الاستخدام](#️-الاستخدام)
- [🔐 الإعداد](#-الإعداد)
- [🧩 تركيز سير عمل LazyingArt](#-تركيز-سير-عمل-lazyingart)
- [🎼 فلسفة Orchestral](#-فلسفة-orchestral)
- [🧰 أدوات Prompt في LAB](#-أدوات-prompt-في-lab)
- [💡 أمثلة](#-أمثلة)
- [🧪 ملاحظات التطوير](#-ملاحظات-التطوير)
- [🩺 استكشاف الأخطاء وإصلاحها](#-استكشاف-الأخطاء-وإصلاحها)
- [🌐 تكاملات منظومة LAB](#-تكاملات-منظومة-lab)
- [التثبيت من المصدر](#التثبيت-من-المصدر)
- [🗺️ خارطة الطريق](#️-خارطة-الطريق)
- [🤝 المساهمة](#-المساهمة)
- [❤️ الدعم / الرعاية](#️-الدعم--الرعاية)
- [🙏 الشكر والتقدير](#-الشكر-والتقدير)
- [📄 الترخيص](#-الترخيص)

---

## 🧭 نظرة عامة

يركّز LAB على إنتاجية شخصية عملية:

- تشغيل مساعد واحد عبر قنوات الدردشة التي تستخدمها بالفعل.
- إبقاء البيانات والتحكم على جهازك/خادمك.
- تحويل البريد الإلكتروني الوارد إلى إجراءات منظّمة (Calendar وReminders وNotes).
- إضافة ضوابط أمان تجعل الأتمتة مفيدة وآمنة في الوقت نفسه.

باختصار: أعمال أقل، وتنفيذ أفضل.

---

## ⚡ لمحة سريعة

| المجال | الوضع الحالي في هذا المستودع |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| مدير الحزم | `pnpm@10.23.0` |
| CLI الأساسي | `openclaw` |
| بوابة محلية افتراضية | `127.0.0.1:18789` |
| التوثيق الأساسي | `docs/` (Mintlify) |
| تنسيق LAB الأساسي | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ القدرات الأساسية

- Runtime لمساعد متعدد القنوات (Gateway + جلسات agent).
- لوحة ويب / واجهة دردشة ويب للتحكم.
- سير عمل للوكيل مع أدوات (shell وfiles وسكربتات الأتمتة).
- مسار أتمتة البريد الإلكتروني للعمليات الشخصية:
  - تحليل البريد الوارد
  - تصنيف نوع الإجراء
  - الحفظ في Notes / Reminders / Calendar
  - تسجيل كل إجراء للمراجعة وتصحيح الأخطاء

---

## 🧱 بنية المشروع

التخطيط العام للمستودع:

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

ملاحظات:

- `scripts/prompt_tools` يشير إلى تنفيذ أدوات prompt الخاصة بـ orchestral.
- المجلد الجذري `i18n/` موجود وحاليًا محدود في هذه اللقطة؛ أما التوثيق المترجم فيوجد بشكل أساسي تحت `docs/`.

---

## 📋 المتطلبات المسبقة

الحدود الأساسية للبيئة والأدوات في هذا المستودع:

- Node.js `>=22.12.0`
- خط أساس pnpm هو `10.23.0` (راجع `packageManager` في `package.json`)
- مفتاح مزود نموذج مضبوط (`OPENAI_API_KEY` أو `ANTHROPIC_API_KEY` أو `GEMINI_API_KEY` وغيرها)
- اختياري: Docker + Docker Compose لتشغيل gateway/CLI داخل حاويات

تثبيت CLI عالميًا (اختياري، ومتوافق مع مسار البدء السريع):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 البدء السريع

الحد الأساسي للتشغيل في هذا المستودع: **Node >= 22.12.0** (ضمن `package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

بعد ذلك افتح لوحة التحكم المحلية والدردشة:

- http://127.0.0.1:18789

للوصول عن بُعد، عرّض البوابة المحلية عبر نفق آمن من اختيارك (مثل ngrok/Tailscale) مع إبقاء المصادقة مفعّلة.

---

## 🧱 التثبيت

### التثبيت من المصدر

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### سير عمل Docker (اختياري)

يتضمن المستودع ملف `docker-compose.yml` وفيه:

- `openclaw-gateway`
- `openclaw-cli`

التدفق المعتاد:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

ملاحظة: مسارات الربط (mount) والمنافذ يتم التحكم بها عبر متغيرات compose مثل `OPENCLAW_CONFIG_DIR` و`OPENCLAW_WORKSPACE_DIR` و`OPENCLAW_GATEWAY_PORT` و`OPENCLAW_BRIDGE_PORT`.

---

## 🛠️ الاستخدام

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

تطوير واجهة المستخدم:

```bash
pnpm ui:dev
```

---

## 🔐 الإعداد

مرجع البيئة والإعدادات موزّع بين `.env` و`~/.openclaw/openclaw.json`.

1. ابدأ من `.env.example`.
2. عيّن مصادقة البوابة (`OPENCLAW_GATEWAY_TOKEN` موصى به).
3. عيّن مفتاح مزود نموذج واحد على الأقل (`OPENAI_API_KEY` أو `ANTHROPIC_API_KEY` وغيرها).
4. لا تضبط بيانات اعتماد القنوات إلا للقنوات التي فعّلتها فعليًا.

ملاحظات مهمة من `.env.example` محفوظة كما هي في المستودع:

- أولوية متغيرات البيئة: process env ← `./.env` ← `~/.openclaw/.env` ← كتلة `env` في ملف config.
- القيم غير الفارغة الموجودة مسبقًا في process env لا يتم استبدالها.
- مفاتيح الإعداد مثل `gateway.auth.token` قد تتقدّم على قيم fallback من env.

الحد الأدنى الأمني قبل تعريض الخدمة للإنترنت:

- أبقِ مصادقة/اقتران البوابة مفعّلًا.
- أبقِ allowlists صارمة للقنوات الواردة.
- اعتبر كل رسالة/بريد وارد إدخالًا غير موثوق.
- شغّل بأقل صلاحيات ممكنة وراجع السجلات دوريًا.

إذا قمت بتعريض البوابة للإنترنت، فافرض مصادقة token/password مع إعداد trusted proxy.

---

## 🧩 تركيز سير عمل LazyingArt

هذا التفرع يعطي أولوية لتدفقي الشخصي في **lazying.art**:

- علامة مخصصة (LAB / panda theme)
- تجربة لوحة تحكم/دردشة مناسبة للهاتف
- نسخ متعددة من مسار automail (قواعد تشغيل + أنماط حفظ مدعومة بـ codex)
- سكربتات تنظيف شخصية وتصنيف المرسلين
- توجيه notes/reminders/calendar مضبوط للاستخدام اليومي الواقعي

مساحة عمل الأتمتة (محلي):

- `~/.openclaw/workspace/automation/`
- مراجع السكربتات داخل المستودع: `references/lab-scripts-and-philosophy.md`
- أدوات Codex prompt مخصصة: `scripts/prompt_tools/`

---

## 🎼 فلسفة Orchestral

يتبع تنسيق LAB قاعدة تصميم واحدة:
تفكيك الأهداف الصعبة إلى تنفيذ حتمي + سلاسل prompt-tool مركزة.

- السكربتات الحتمية تتولى الأساسيات الموثوقة:
  الجدولة، توجيه الملفات، أدلة التشغيل، إعادة المحاولة، وتسليم المخرجات.
- أدوات prompt تتولى الذكاء التكيفي:
  التخطيط، الفرز، تركيب السياق، واتخاذ القرار عند عدم اليقين.
- كل مرحلة تُنتج artifacts قابلة لإعادة الاستخدام، بحيث تبني المراحل اللاحقة مخرجات أقوى دون البدء من الصفر.

السلاسل orchestral الأساسية:

- سلسلة ريادة الشركات:
  إدخال سياق الشركة → ذكاء السوق/التمويل/الأبحاث/القانون → إجراءات نمو عملية.
- سلسلة البريد الآلي:
  فرز البريد الوارد → سياسة تخطي محافظة للبريد منخفض القيمة → إجراءات منظمة في Notes/Reminders/Calendar.
- سلسلة بحث الويب:
  التقاط صفحة النتائج → قراءات عميقة مستهدفة مع استخراج screenshots/content → تركيب مدعوم بالأدلة.

---

## 🧰 أدوات Prompt في LAB

أدوات Prompt في LAB معيارية وقابلة للتركيب ومبنية على orchestration-first.
يمكن تشغيلها بشكل مستقل أو كسلسلة مراحل مترابطة ضمن تدفق أكبر.

- عمليات القراءة/الحفظ:
  إنشاء وتحديث مخرجات Notes وReminders وCalendar ضمن عمليات AutoLife.
- عمليات screenshot/read:
  التقاط صفحات البحث والصفحات المرتبطة، ثم استخراج نص منظم للتحليل اللاحق.
- عمليات ربط الأدوات:
  استدعاء السكربتات الحتمية، وتبادل artifacts بين المراحل، والحفاظ على استمرارية السياق.

الموقع الأساسي:

- `scripts/prompt_tools/`

---

## 💡 أمثلة

### مثال: بوابة محلية فقط

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### مثال: طلب من الوكيل معالجة تخطيط اليوم

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### مثال: البناء من المصدر + حلقة watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 ملاحظات التطوير

- الحد الأساسي للتشغيل: Node `>=22.12.0`.
- خط أساس مدير الحزم: `pnpm@10.23.0` (حقل `packageManager`).
- بوابات الجودة الشائعة:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- استخدام CLI أثناء التطوير: `pnpm openclaw ...`
- حلقة تشغيل TypeScript: `pnpm dev`
- أوامر حزمة UI تتم عبر سكربتات الجذر (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 استكشاف الأخطاء وإصلاحها

### لا يمكن الوصول إلى Gateway على `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

تحقق من تعارض المنافذ وتعارضات daemon. وإذا كنت تستخدم Docker، تأكد من منفذ المضيف المربوط وصحة الخدمة.

### مشكلات المصادقة أو إعداد القنوات

- أعد التحقق من قيم `.env` مقارنةً بـ `.env.example`.
- تأكد من ضبط مفتاح نموذج واحد على الأقل.
- تحقق من tokens الخاصة بالقنوات التي فعّلتها فقط.

### فحوصات الصحة العامة

استخدم `openclaw doctor` لاكتشاف مشكلات الترحيل/الأمان/انحراف الإعدادات.

---

## 🌐 تكاملات منظومة LAB

يدمج LAB مستودعاتي الأوسع للمنتجات والأبحاث المعتمدة على الذكاء الاصطناعي في طبقة تشغيل واحدة للإنشاء والنمو والأتمتة.

الملف الشخصي:

- https://github.com/lachlanchen?tab=repositories

المستودعات المتكاملة:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

الأهداف العملية لتكامل LAB:

- كتابة روايات تلقائيًا
- تطوير تطبيقات تلقائيًا
- تحرير الفيديو تلقائيًا
- نشر المخرجات تلقائيًا
- تحليل organoids تلقائيًا
- التعامل مع عمليات البريد الإلكتروني تلقائيًا

---

## التثبيت من المصدر

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

## 🗺️ خارطة الطريق

الاتجاهات المخططة لهذا التفرع من LAB (خارطة عمل):

- توسيع موثوقية automail مع تصنيف أكثر صرامة للمرسلين/القواعد.
- تحسين قابلية تركيب مراحل orchestral وإمكانية تتبع artifacts.
- تعزيز تجربة mobile-first وإدارة البوابة البعيدة.
- تعميق التكامل مع مستودعات منظومة LAB للإنتاج الآلي الكامل.
- الاستمرار في تقوية افتراضات الأمان والقدرة على المراقبة للأتمتة غير المراقبة.

---

## 🤝 المساهمة

يتابع هذا المستودع أولويات LAB الشخصية مع الاحتفاظ بالهيكل الأساسي الموروث من OpenClaw.

- اقرأ [`CONTRIBUTING.md`](CONTRIBUTING.md)
- راجع توثيق المشروع الأساسي: https://docs.openclaw.ai
- لمشكلات الأمان، راجع [`SECURITY.md`](SECURITY.md)

إذا كان سلوك LAB المحدد غير واضح، فاحفظ السلوك الحالي ودوّن الافتراضات في ملاحظات PR.

---

## ❤️ الدعم / الرعاية

إذا كان LAB مفيدًا لسير عملك، يمكنك دعم التطوير المستمر:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- صفحة التبرع: https://chat.lazying.art/donate
- الموقع: https://lazying.art

---

## 🙏 الشكر والتقدير

LazyingArtBot مبني على **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

شكرًا لفريق OpenClaw والمجتمع على المنصة الأساسية.

---

## 📄 الترخيص

MIT (نفس ترخيص upstream حيث ينطبق). راجع `LICENSE`.
