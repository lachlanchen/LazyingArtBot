[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-inicio-rápido)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

**LazyingArtBot** es mi stack personal de asistente de IA para **lazying.art**.  
Está construido sobre OpenClaw y adaptado a mis flujos diarios: chat multicanal, control local-first y automatización de email → calendario/recordatorios/notas.

| Link | URL |
| --- | --- |
| Sitio web | https://lazying.art |
| Dominio del bot | https://lazying.art |
| Base upstream | https://github.com/openclaw/openclaw |
| Este repositorio | https://github.com/lachlanchen/LazyingArtBot |

---

## Tabla de contenido

- [🧭 Resumen](#-resumen)
- [⚡ De un vistazo](#-de-un-vistazo)
- [⚙️ Capacidades principales](#️-capacidades-principales)
- [🧱 Estructura del proyecto](#-estructura-del-proyecto)
- [📋 Prerrequisitos](#-prerrequisitos)
- [🚀 Inicio rápido](#-inicio-rápido)
- [🧱 Instalación](#-instalación)
- [🛠️ Uso](#️-uso)
- [🔐 Configuración](#-configuración)
- [🧩 Enfoque de flujo de trabajo de LazyingArt](#-enfoque-de-flujo-de-trabajo-de-lazyingart)
- [🎼 Filosofía orquestal](#-filosofía-orquestal)
- [🧰 Prompt tools en LAB](#-prompt-tools-en-lab)
- [💡 Ejemplos](#-ejemplos)
- [🧪 Notas de desarrollo](#-notas-de-desarrollo)
- [🩺 Solución de problemas](#-solución-de-problemas)
- [🌐 Integraciones del ecosistema LAB](#-integraciones-del-ecosistema-lab)
- [Instalar desde código fuente](#instalar-desde-código-fuente)
- [🗺️ Hoja de ruta](#️-hoja-de-ruta)
- [🤝 Contribuir](#-contribuir)
- [❤️ Soporte / Patrocinio](#️-soporte--patrocinio)
- [🙏 Agradecimientos](#-agradecimientos)
- [📄 Licencia](#-licencia)

---

## 🧭 Resumen

LAB se centra en productividad personal práctica:

- Ejecutar un asistente en los canales de chat que ya usas.
- Mantener datos y control en tu propia máquina/servidor.
- Convertir correo entrante en acciones estructuradas (Calendar, Reminders, Notes).
- Añadir guardrails para que la automatización sea útil pero segura.

En resumen: menos trabajo repetitivo, mejor ejecución.

---

## ⚡ De un vistazo

| Área | Baseline actual en este repositorio |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Gestor de paquetes | `pnpm@10.23.0` |
| CLI principal | `openclaw` |
| Gateway local por defecto | `127.0.0.1:18789` |
| Documentación principal | `docs/` (Mintlify) |
| Orquestación principal de LAB | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Capacidades principales

- Runtime de asistente multicanal (Gateway + sesiones de agente).
- Dashboard web / superficie de control por chat web.
- Flujos de agente con herramientas habilitadas (shell, archivos, scripts de automatización).
- Pipeline de automatización de correo para operaciones personales:
  - analizar correo entrante
  - clasificar tipo de acción
  - guardar en Notes / Reminders / Calendar
  - registrar cada acción para revisión y depuración

---

## 🧱 Estructura del proyecto

Estructura de alto nivel del repositorio:

```text
.
├─ src/                 # runtime principal, gateway, canales, CLI, infra
├─ extensions/          # plugins opcionales de canal/proveedor/autenticación
├─ orchestral/          # pipelines de orquestación LAB + prompt tools
├─ scripts/             # utilidades de build/dev/test/release
├─ ui/                  # paquete de UI para dashboard web
├─ apps/                # apps macOS / iOS / Android
├─ docs/                # documentación Mintlify
├─ references/          # referencias y notas operativas de LAB
├─ test/                # suites de pruebas
├─ .env.example         # plantilla de entorno
├─ docker-compose.yml   # contenedores de gateway + CLI
├─ README_OPENCLAW.md   # README de referencia más amplio estilo upstream
└─ README.md            # este README enfocado en LAB
```

Notas:

- `scripts/prompt_tools` apunta a la implementación de prompt tools de orchestral.
- El directorio raíz `i18n/` existe y actualmente es mínimo en este snapshot; la documentación localizada vive principalmente en `docs/`.

---

## 📋 Prerrequisitos

Baselines de runtime y herramientas de este repositorio:

- Node.js `>=22.12.0`
- baseline de pnpm `10.23.0` (ver `packageManager` en `package.json`)
- Una clave de proveedor de modelo configurada (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Opcional: Docker + Docker Compose para gateway/CLI en contenedores

Instalación global opcional del CLI (coincide con el flujo de inicio rápido):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Inicio rápido

Baseline de runtime en este repositorio: **Node >= 22.12.0** (engine de `package.json`).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Luego abre el dashboard local y chatea:

- http://127.0.0.1:18789

Para acceso remoto, expón tu gateway local mediante tu propio túnel seguro (por ejemplo ngrok/Tailscale) y mantén la autenticación habilitada.

---

## 🧱 Instalación

### Install from source

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

Nota: las rutas de montaje y puertos se controlan mediante variables de compose como `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT` y `OPENCLAW_BRIDGE_PORT`.

---

## 🛠️ Uso

Comandos comunes:

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

---

## 🔐 Configuración

La referencia de entorno y configuración está dividida entre `.env` y `~/.openclaw/openclaw.json`.

1. Empieza desde `.env.example`.
2. Configura auth del gateway (`OPENCLAW_GATEWAY_TOKEN` recomendado).
3. Configura al menos una clave de proveedor de modelo (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Solo configura credenciales de canal para los canales que habilites.

Notas importantes de `.env.example` preservadas del repositorio:

- Precedencia de entorno: process env → `./.env` → `~/.openclaw/.env` → bloque `env` de config.
- Los valores no vacíos existentes en process env no se sobrescriben.
- Claves de config como `gateway.auth.token` pueden tener prioridad sobre fallbacks de entorno.

Baseline crítica de seguridad antes de exponer a internet:

- Mantén habilitados auth/pairing del gateway.
- Mantén allowlists estrictas para canales entrantes.
- Trata cada mensaje/email entrante como entrada no confiable.
- Ejecuta con mínimo privilegio y revisa logs con regularidad.

Si expones el gateway a internet, exige auth por token/contraseña y configuración de proxy confiable.

---

## 🧩 Enfoque de flujo de trabajo de LazyingArt

Este fork prioriza mi flujo personal en **lazying.art**:

- branding personalizado (LAB / tema panda)
- experiencia de dashboard/chat amigable para móvil
- variantes del pipeline automail (modos de guardado activados por reglas y asistidos por codex)
- scripts personales de limpieza y clasificación de remitentes
- enrutamiento de notas/recordatorios/calendario ajustado para uso diario real

Espacio de trabajo de automatización (local):

- `~/.openclaw/workspace/automation/`
- Referencias de scripts en el repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools dedicados de Codex: `scripts/prompt_tools/`

---

## 🎼 Filosofía orquestal

La orquestación de LAB sigue una regla de diseño:  
dividir objetivos difíciles en ejecución determinista + cadenas de prompt tools enfocadas.

- Los scripts deterministas se encargan de la plomería confiable:
  scheduling, file routing, run directories, retries y output handoff.
- Las prompt tools se encargan de la inteligencia adaptativa:
  planificación, triaje, síntesis de contexto y toma de decisiones bajo incertidumbre.
- Cada etapa emite artefactos reutilizables para que las herramientas posteriores compongan mejores notas/correos finales sin empezar desde cero.

Cadenas orquestales principales:

- Cadena de emprendimiento empresarial:
  ingesta de contexto empresarial → inteligencia de mercado/financiación/academia/legal → acciones concretas de crecimiento.
- Cadena de correo automático:
  triaje de correo entrante → política conservadora de omisión para correo de bajo valor → acciones estructuradas en Notes/Reminders/Calendar.
- Cadena de búsqueda web:
  captura de página de resultados → lecturas profundas dirigidas con extracción de capturas/contenido → síntesis respaldada por evidencia.

---

## 🧰 Prompt tools en LAB

Las prompt tools son modulares, componibles y orientadas a la orquestación.  
Pueden ejecutarse de forma independiente o como etapas enlazadas dentro de un flujo mayor.

- Operaciones de lectura/guardado:
  crear y actualizar salidas de Notes, Reminders y Calendar para operaciones AutoLife.
- Operaciones de captura/lectura:
  capturar páginas de búsqueda y páginas enlazadas, luego extraer texto estructurado para análisis posteriores.
- Operaciones de conexión de herramientas:
  llamar scripts deterministas, intercambiar artefactos entre etapas y mantener continuidad de contexto.

Ubicación principal:

- `scripts/prompt_tools/`

---

## 💡 Ejemplos

### Ejemplo: gateway solo local

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ejemplo: pedir al agente que procese la planificación diaria

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Ejemplo: build desde código + bucle watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 Notas de desarrollo

- Baseline de runtime: Node `>=22.12.0`.
- Baseline de gestor de paquetes: `pnpm@10.23.0` (campo `packageManager`).
- Puertas de calidad comunes:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI en desarrollo: `pnpm openclaw ...`
- Bucle de ejecución TS: `pnpm dev`
- Los comandos del paquete UI se exponen vía scripts raíz (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Solución de problemas

### Gateway no accesible en `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Verifica colisiones de puertos y conflictos de daemon. Si usas Docker, valida el puerto mapeado en host y la salud del servicio.

### Problemas de auth o configuración de canales

- Vuelve a revisar los valores de `.env` frente a `.env.example`.
- Asegúrate de tener configurada al menos una clave de modelo.
- Verifica tokens de canal solo para los canales que realmente habilitaste.

### Comprobaciones generales de estado

Usa `openclaw doctor` para detectar problemas de migración/seguridad/desviaciones de configuración.

---

## 🌐 Integraciones del ecosistema LAB

LAB integra mis repos de producto e investigación de IA dentro de una capa operativa para creación, crecimiento y automatización.

Perfil:

- https://github.com/lachlanchen?tab=repositories

Repos integrados:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (escritura automática de novelas)
- `AutoAppDev` (desarrollo automático de apps)
- `OrganoidAgent` (plataforma de investigación de organoides con modelos de visión fundacionales + LLMs)
- `LazyEdit` (edición de video asistida por IA: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (pipeline de publicación automática)

Objetivos prácticos de integración LAB:

- Escribir novelas automáticamente
- Desarrollar apps automáticamente
- Editar videos automáticamente
- Publicar resultados automáticamente
- Analizar organoides automáticamente
- Gestionar operaciones de email automáticamente

---

## Instalar desde código fuente

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

## 🗺️ Hoja de ruta

Direcciones planificadas para este fork de LAB (hoja de ruta activa):

- Ampliar la fiabilidad de automail con una clasificación de remitentes/reglas más estricta.
- Mejorar la componibilidad de etapas orquestales y la trazabilidad de artefactos.
- Reforzar operaciones mobile-first y la UX de gestión remota del gateway.
- Profundizar integraciones con repos del ecosistema LAB para una producción automatizada end-to-end.
- Seguir endureciendo defaults de seguridad y observabilidad para automatización desatendida.

---

## 🤝 Contribuir

Este repositorio sigue prioridades personales de LAB mientras hereda la arquitectura principal de OpenClaw.

- Lee [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Revisa la documentación upstream: https://docs.openclaw.ai
- Para problemas de seguridad, consulta [`SECURITY.md`](SECURITY.md)

Si no tienes certeza sobre comportamientos específicos de LAB, conserva el comportamiento existente y documenta supuestos en notas del PR.

---

## ❤️ Soporte / Patrocinio

Si LAB te ayuda en tu flujo de trabajo, apoya el desarrollo continuo:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Página de donaciones: https://chat.lazying.art/donate
- Sitio web: https://lazying.art

---

## 🙏 Agradecimientos

LazyingArtBot está basado en **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Gracias al equipo mantenedor y a la comunidad de OpenClaw por la plataforma base.

---

## 📄 Licencia

MIT (igual que upstream donde corresponda). Consulta `LICENSE`.
