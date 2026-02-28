[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#inicio-rápido)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)

> 🌍 **Estado de i18n:** `i18n/` existe y actualmente incluye archivos README localizados para árabe, alemán, español, francés, japonés, coreano, ruso, vietnamita, chino simplificado y chino tradicional. Este borrador en inglés sigue siendo la fuente canónica para actualizaciones incrementales.

**LazyingArtBot** es mi stack personal de asistente de IA para **lazying.art**.
Está construido sobre OpenClaw y adaptado a mis flujos de trabajo diarios: chat multicanal, control local-first y automatización de email -> calendario/recordatorios/notas.

| 🔗 Enlace | URL |
| --- | --- |
| 🌐 Sitio web | https://lazying.art |
| 🤖 Dominio del bot | https://lazying.art |
| 🧱 Base upstream | https://github.com/openclaw/openclaw |
| 📦 Este repositorio | https://github.com/lachlanchen/LazyingArtBot |

---

## Tabla de contenido

- [Resumen](#resumen)
- [De un vistazo](#de-un-vistazo)
- [Características](#características)
- [Capacidades principales](#capacidades-principales)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Inicio rápido](#inicio-rápido)
- [Instalación](#instalación)
- [Uso](#uso)
- [Configuración](#configuración)
- [Modos de despliegue](#modos-de-despliegue)
- [Enfoque del flujo de trabajo LazyingArt](#enfoque-del-flujo-de-trabajo-lazyingart)
- [Filosofía orchestral](#filosofía-orchestral)
- [Prompt tools en LAB](#prompt-tools-en-lab)
- [Ejemplos](#ejemplos)
- [Notas de desarrollo](#notas-de-desarrollo)
- [Resolución de problemas](#resolución-de-problemas)
- [Integraciones del ecosistema LAB](#integraciones-del-ecosistema-lab)
- [Instalar desde código fuente (referencia rápida)](#instalar-desde-código-fuente-referencia-rápida)
- [Hoja de ruta](#hoja-de-ruta)
- [Contribuir](#contribuir)
- [❤️ Support](#-support)
- [Agradecimientos](#agradecimientos)
- [Licencia](#licencia)

---

## Resumen

LAB se centra en la productividad personal práctica:

- ✅ Ejecutar un asistente en los canales de chat que ya usas.
- 🔐 Mantener los datos y el control en tu propia máquina/servidor.
- 📬 Convertir correos entrantes en acciones estructuradas (Calendar, Reminders, Notes).
- 🛡️ Añadir guardrails para que la automatización sea útil pero segura.

En resumen: menos trabajo repetitivo, mejor ejecución.

---

## De un vistazo

| Área | Línea base actual en este repositorio |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Gestor de paquetes | `pnpm@10.23.0` |
| CLI principal | `openclaw` |
| Gateway local por defecto | `127.0.0.1:18789` |
| Puerto bridge por defecto | `127.0.0.1:18790` |
| Documentación principal | `docs/` (Mintlify) |
| Orquestación principal de LAB | `orchestral/` + `scripts/prompt_tools/` |
| Ubicación del README i18n | `i18n/README.*.md` |

---

## Características

- 🌐 Runtime de asistente multicanal con gateway local.
- 🖥️ Dashboard/chat en navegador para operaciones locales.
- 🧰 Pipeline de automatización habilitada por herramientas (scripts + prompt-tools).
- 📨 Triaje de correo y conversión a acciones en Notes, Reminders y Calendar.
- 🧩 Ecosistema de plugins/extensiones (`extensions/*`) para canales/proveedores/integraciones.
- 📱 Superficies multiplataforma dentro del repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacidades principales

| Capacidad | Qué significa en la práctica |
| --- | --- |
| Runtime de asistente multicanal | Gateway + sesiones de agente en los canales que habilites |
| Dashboard web / chat | Superficie de control basada en navegador para operaciones locales |
| Flujos habilitados por herramientas | Cadenas de ejecución con shell + archivos + scripts de automatización |
| Pipeline de automatización de email | Parsea correo, clasifica tipo de acción, enruta a Notes/Reminders/Calendar y registra acciones para revisión/debug |

Pasos del pipeline conservados del flujo actual:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Estructura del proyecto

Estructura de alto nivel del repositorio:

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

Notas:

- `scripts/prompt_tools` apunta a la implementación de prompt-tools de orchestral.
- El `i18n/` raíz contiene variantes localizadas del README.
- `.github/workflows.disabled/` está presente en este snapshot; conviene verificar el comportamiento activo de CI antes de asumir workflows.

---

## Requisitos previos

Líneas base de runtime y tooling de este repositorio:

- Node.js `>=22.12.0`
- Línea base de pnpm `10.23.0` (ver `packageManager` en `package.json`)
- Una clave configurada de proveedor de modelos (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Opcional: Docker + Docker Compose para gateway/CLI en contenedores
- Opcional para builds móviles/mac: toolchains de Apple/Android según la plataforma objetivo

Instalación global opcional del CLI (coincide con el flujo de inicio rápido):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Inicio rápido

Línea base de runtime en este repo: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Después abre el dashboard/chat local:

- http://127.0.0.1:18789

Para acceso remoto, expón tu gateway local mediante tu túnel seguro (por ejemplo ngrok/Tailscale) y mantén la autenticación habilitada.

---

## Instalación

### Instalar desde código fuente

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Flujo opcional con Docker

Se incluye un `docker-compose.yml` con:

- `openclaw-gateway`
- `openclaw-cli`

Flujo típico:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Variables de Compose que suelen ser necesarias:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Uso

Comandos habituales:

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

Bucle de desarrollo (watch mode):

```bash
pnpm gateway:watch
```

Desarrollo de UI:

```bash
pnpm ui:dev
```

Comandos operativos adicionales útiles:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Configuración

La referencia de entorno y config se divide entre `.env` y `~/.openclaw/openclaw.json`.

1. Empieza desde `.env.example`.
2. Configura la autenticación del gateway (`OPENCLAW_GATEWAY_TOKEN` recomendado).
3. Configura al menos una clave de proveedor de modelos (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Configura credenciales de canal solo para los canales que habilites.

Notas importantes de `.env.example` conservadas del repo:

- Prioridad de variables: process env -> `./.env` -> `~/.openclaw/.env` -> bloque `env` de config.
- Los valores no vacíos ya presentes en process env no se sobrescriben.
- Claves de config como `gateway.auth.token` pueden tener prioridad sobre fallbacks de env.

Línea base de seguridad crítica antes de exponer a internet:

- Mantén habilitada la autenticación/emparejamiento del gateway.
- Mantén estrictas las allowlists para canales entrantes.
- Trata cada mensaje/correo entrante como entrada no confiable.
- Ejecuta con privilegio mínimo y revisa logs con regularidad.

Si expones el gateway a internet, exige auth por token/contraseña y configuración de proxy confiable.

---

## Modos de despliegue

| Modo | Mejor para | Comando típico |
| --- | --- | --- |
| Primer plano local | Desarrollo y debugging | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Uso personal diario | `openclaw onboard --install-daemon` |
| Docker | Runtime aislado y despliegues repetibles | `docker compose up -d` |
| Host remoto + túnel | Acceso fuera de la red local | Ejecutar gateway + túnel seguro, con auth habilitada |

Supuesto: el hardening de reverse-proxy de nivel producción, la rotación de secretos y la política de backups dependen de cada despliegue y deben definirse por entorno.

---

## Enfoque del flujo de trabajo LazyingArt

Este fork prioriza mi flujo personal en **lazying.art**:

- 🎨 branding personalizado (LAB / tema panda)
- 📱 experiencia de dashboard/chat optimizada para móvil
- 📨 variantes de pipeline automail (modos de guardado por reglas y asistidos por codex)
- 🧹 scripts personales de limpieza y clasificación de remitentes
- 🗂️ enrutamiento de notas/recordatorios/calendario ajustado al uso diario real

Workspace de automatización (local):

- `~/.openclaw/workspace/automation/`
- Referencias de scripts en el repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools de Codex dedicadas: `scripts/prompt_tools/`

---

## Filosofía orchestral

La orquestación de LAB sigue una regla de diseño:
dividir objetivos difíciles en ejecución determinista + cadenas enfocadas de prompt-tools.

- Los scripts deterministas se encargan del plumbing confiable:
  scheduling, enrutamiento de archivos, directorios de ejecución, retries y handoff de salida.
- Las prompt tools se encargan de la inteligencia adaptativa:
  planificación, triaje, síntesis de contexto y toma de decisiones bajo incertidumbre.
- Cada etapa emite artefactos reutilizables para que las herramientas aguas abajo compongan notas/correos finales más sólidos sin empezar desde cero.

Cadenas orchestral principales:

- Cadena de emprendimiento empresarial:
  ingesta de contexto de empresa -> inteligencia de mercado/financiación/academia/legal -> acciones concretas de crecimiento.
- Cadena auto mail:
  triaje de correo entrante -> política conservadora de descarte para correo de bajo valor -> acciones estructuradas en Notes/Reminders/Calendar.
- Cadena de búsqueda web:
  captura de páginas de resultados -> lecturas profundas dirigidas con extracción de screenshot/contenido -> síntesis respaldada por evidencia.

---

## Prompt tools en LAB

Las prompt tools son modulares, componibles y orientadas a la orquestación.
Pueden ejecutarse de forma independiente o como etapas enlazadas en un flujo más grande.

- Operaciones de lectura/guardado:
  crear y actualizar salidas de Notes, Reminders y Calendar para operaciones de AutoLife.
- Operaciones de captura/lectura:
  capturar páginas de búsqueda y páginas enlazadas, y luego extraer texto estructurado para análisis posteriores.
- Operaciones de conexión de herramientas:
  invocar scripts deterministas, intercambiar artefactos entre etapas y mantener continuidad de contexto.

Ubicación principal:

- `scripts/prompt_tools/`

---

## Ejemplos

### Ejemplo: gateway solo local

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ejemplo: pedir al agente procesar la planificación diaria

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Ejemplo: build desde source + bucle watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Ejemplo: ejecutar en Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Notas de desarrollo

- Línea base de runtime: Node `>=22.12.0`.
- Línea base del gestor de paquetes: `pnpm@10.23.0` (campo `packageManager`).
- Puertas de calidad comunes:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI en dev: `pnpm openclaw ...`
- Bucle TS: `pnpm dev`
- Los comandos del paquete UI se exponen a través de scripts raíz (`pnpm ui:build`, `pnpm ui:dev`).

Comandos de test extendidos comunes en este repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Helpers adicionales de desarrollo:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Nota de supuesto:

- Los comandos de build/run para apps móvil/macOS existen en `package.json` (`ios:*`, `android:*`, `mac:*`), pero los requisitos de firma/provisionamiento son específicos del entorno y no están documentados por completo en este README.

---

## Resolución de problemas

### El gateway no es accesible en `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Comprueba colisiones de puerto y conflictos con el daemon. Si usas Docker, verifica el puerto mapeado en host y la salud del servicio.

### Problemas de auth o configuración de canales

- Revisa de nuevo los valores de `.env` frente a `.env.example`.
- Asegúrate de tener configurada al menos una clave de modelo.
- Verifica tokens de canal solo para los canales que realmente habilitaste.

### Problemas de build o instalación

- Ejecuta de nuevo `pnpm install` con Node `>=22.12.0`.
- Reconstruye con `pnpm ui:build && pnpm build`.
- Si faltan peers nativos opcionales, revisa logs de instalación para compatibilidad de `@napi-rs/canvas` / `node-llama-cpp`.

### Comprobaciones generales de salud

Usa `openclaw doctor` para detectar problemas de migración/seguridad/desviación de configuración.

### Diagnósticos útiles

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Integraciones del ecosistema LAB

LAB integra mis repos de producto e investigación de IA en una sola capa operativa para creación, crecimiento y automatización.

Perfil:

- https://github.com/lachlanchen?tab=repositories

Repos integrados:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Objetivos prácticos de integración en LAB:

- Auto escribir novelas
- Auto desarrollar apps
- Auto editar videos
- Auto publicar resultados
- Auto analizar organoides
- Auto gestionar operaciones de email

---

## Instalar desde código fuente (referencia rápida)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Bucle de desarrollo:

```bash
pnpm gateway:watch
```

---

## Hoja de ruta

Direcciones planificadas para este fork LAB (roadmap de trabajo):

- Expandir la fiabilidad de automail con una clasificación más estricta de remitentes/reglas.
- Mejorar la componibilidad de etapas orchestral y la trazabilidad de artefactos.
- Reforzar operaciones mobile-first y la UX de gestión remota del gateway.
- Profundizar integraciones con repos del ecosistema LAB para producción automatizada end-to-end.
- Seguir endureciendo defaults de seguridad y observabilidad para automatización desatendida.

---

## Contribuir

Este repositorio sigue prioridades personales de LAB mientras hereda la arquitectura base de OpenClaw.

- Lee [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- Revisa la documentación upstream: https://docs.openclaw.ai
- Para problemas de seguridad, consulta [`SECURITY.md`](../SECURITY.md)

Si tienes dudas sobre comportamiento específico de LAB, conserva el comportamiento existente y documenta los supuestos en las notas del PR.

---

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Agradecimientos

LazyingArtBot está basado en **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Gracias al equipo mantenedor y a la comunidad de OpenClaw por la plataforma base.

---

## Licencia

MIT (igual que upstream cuando corresponda). Consulta `LICENSE`.
