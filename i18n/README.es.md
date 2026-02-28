[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#inicio-rapido)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **Estado de i18n:** `i18n/` ya existe y actualmente incluye README localizados en árabe, alemán, español, francés, japonés, coreano, ruso, vietnamita, chino simplificado y chino tradicional. Esta versión en inglés sigue siendo la fuente canónica para actualizaciones incrementales.

**LazyingArtBot** es mi conjunto personal de herramientas de IA para **lazying.art**:

**LazyingArtBot** está construido sobre OpenClaw y adaptado para mis flujos diarios: chat multicanal, control local-first y automatización de correo electrónico hacia calendario/recordatorios/notas.

| 🔗 Enlace | URL | Enfoque |
| --- | --- | --- |
| 🌐 Sitio web | https://lazying.art | Dominio principal y panel de estado |
| 🤖 Dominio del bot | https://lazying.art | Punto de entrada de chat y asistente |
| 🧱 Base upstream | https://github.com/openclaw/openclaw | Fundamento de la plataforma OpenClaw |
| 📦 Este repositorio | https://github.com/lachlanchen/LazyingArtBot | Adaptaciones específicas de LAB |

---

## Tabla de contenidos

- [Visión general](#vision-general)
- [A primera vista](#a-primera-vista)
- [Características](#caracteristicas)
- [Capacidades principales](#capacidades-principales)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Inicio rápido](#inicio-rapido)
- [Instalación](#instalacion)
- [Uso](#uso)
- [Configuración](#configuracion)
- [Modos de despliegue](#modos-de-despliegue)
- [Enfoque de flujo LazyingArt](#enfoque-de-flujo-lazyingart)
- [Filosofía orquestal](#filosofia-orquestal)
- [Herramientas de prompt en LAB](#herramientas-de-prompt-en-lab)
- [Ejemplos](#ejemplos)
- [Notas de desarrollo](#notas-de-desarrollo)
- [Solución de problemas](#solucion-de-problemas)
- [Integraciones del ecosistema LAB](#integraciones-del-ecosistema-lab)
- [Instalar desde fuente (referencia rápida)](#instalar-desde-fuente-referencia-rapida)
- [Hoja de ruta](#hoja-de-ruta)
- [Contribución](#contribucion)
- [Agradecimientos](#agradecimientos)
- [❤️ Support](#-support)
- [Licencia](#licencia)

---

## Vision general

LAB se centra en la productividad personal práctica:

- ✅ Ejecuta un único asistente en los canales de chat que ya usas.
- 🔐 Mantén los datos y el control en tu propia máquina/servidor.
- 📬 Convierte correos entrantes en acciones estructuradas (Calendario, Recordatorios, Notas).
- 🛡️ Añade barreras de seguridad para que la automatización sea útil sin perder seguridad.

En corto: menos trabajo manual, mejor ejecución.

---

## A primera vista

| Área | Línea base actual en este repositorio |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Gestor de paquetes | `pnpm@10.23.0` |
| CLI principal | `openclaw` |
| Puerta de enlace local por defecto | `127.0.0.1:18789` |
| Puerto de puente por defecto | `127.0.0.1:18790` |
| Documentación principal | `docs/` (Mintlify) |
| Orquestación LAB principal | `orchestral/` + `scripts/prompt_tools/` |
| Ubicación de i18n de README | `i18n/README.*.md` |

---

## Caracteristicas

- 🌐 Runtime de asistente multicanal con una gateway local.
- 🖥️ Superficie de dashboard/chat en navegador para operaciones locales.
- 🧰 Cadena de automatización con herramientas habilitadas (scripts + prompt-tools).
- 📨 Triaje de correo electrónico y conversión en acciones de Notas, Recordatorios y Calendario.
- 🧩 Ecosistema de plugins/extensiones (`extensions/*`) para canales/proveedores/integraciones.
- 📱 Interfaces multiplataforma en el repositorio (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacidades principales

| Capacidad | Qué significa en la práctica |
| --- | --- |
| Runtime de asistente multicanal | Gateway + sesiones de agente en los canales que habilites |
| Dashboard/chat web | Superficie de control basada en navegador para operaciones locales |
| Flujos con herramientas habilitadas | Cadenas de ejecución de shell + archivos + scripts de automatización |
| Pipeline de automatización de correo | Analiza correo, clasifica el tipo de acción, enruta a Notas/Recordatorios/Calendario y registra acciones para revisión/debugging |

Etapas del pipeline preservadas del flujo actual:

- analizar correo entrante
- clasificar tipo de acción
- guardar en Notas / Recordatorios / Calendario
- registrar cada acción para revisión y depuración

---

## Estructura del proyecto

Disposición general del repositorio:

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

- `scripts/prompt_tools` apunta a la implementación de prompt-tools orquestal.
- La carpeta raíz `i18n/` contiene variantes localizadas del README.
- `.github/workflows.disabled/` está presente en esta instantánea; el comportamiento de CI activo debería verificarse antes de depender de suposiciones sobre pipelines.

---

## Requisitos previos

Líneas base de runtime y herramientas de este repositorio:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (ver `packageManager` en `package.json`)
- Una clave de proveedor de modelo configurada (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Opcional: Docker + Docker Compose para gateway/CLI contenedorizados
- Opcional para builds móviles/mac: toolchains de Apple/Android según la plataforma objetivo

Instalación global opcional de CLI (coincide con el flujo de inicio rápido):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Inicio rapido

Línea base del runtime en este repositorio: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Luego abre el dashboard local y el chat:

- http://127.0.0.1:18789

Para acceso remoto, expón tu gateway local a través de un túnel seguro propio (por ejemplo, ngrok/Tailscale) y mantén la autenticación activada.

---

## Instalacion

### Instalar desde fuente

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Flujo opcional de Docker

Incluye un `docker-compose.yml` con:

- `openclaw-gateway`
- `openclaw-cli`

Flujo típico:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Variables de Compose requeridas con frecuencia:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Uso

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

Bucle de desarrollo (modo observación):

```bash
pnpm gateway:watch
```

Desarrollo de UI:

```bash
pnpm ui:dev
```

Comandos operacionales útiles adicionales:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Configuracion

La referencia de entorno y configuración está repartida entre `.env` y `~/.openclaw/openclaw.json`.

1. Parte desde `.env.example`.
2. Configura la autenticación de gateway (`OPENCLAW_GATEWAY_TOKEN` recomendado).
3. Configura al menos una clave de proveedor de modelo (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Configura credenciales de canal solo para canales que habilites.

Notas importantes de `.env.example` preservadas del repositorio:

- Precedencia de variables: process env -> `./.env` -> `~/.openclaw/.env` -> bloque `env` de configuración.
- Los valores de process env no vacíos existentes no se sobrescriben.
- Claves de configuración como `gateway.auth.token` pueden tener prioridad sobre los fallbacks de entorno.

Línea base crítica de seguridad antes de exponer a internet:

- Mantén la autenticación y el emparejamiento de gateway habilitados.
- Mantén allowlists estrictas para canales entrantes.
- Trata cada mensaje/correo entrante como entrada no confiable.
- Ejecuta con privilegio mínimo y revisa logs regularmente.

Si expones el gateway a internet, exige autenticación por token/contraseña y configuración de proxy de confianza.

---

## Modos de despliegue

| Modo | Mejor para | Comando típico |
| --- | --- | --- |
| Proceso en primer plano local | Desarrollo y depuración | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Uso personal diario | `openclaw onboard --install-daemon` |
| Docker | Runtime aislado y despliegues repetibles | `docker compose up -d` |
| Host remoto + túnel | Acceso desde fuera de la red local | Ejecuta gateway + túnel seguro, mantén la autenticación activada |

Suposición: el endurecimiento de reverse-proxy en producción, rotación de secretos y política de copias de seguridad dependen del entorno y deben definirse por entorno.

---

## Enfoque de flujo LazyingArt

Este fork prioriza mi flujo personal en **lazying.art**:

- 🎨 Marca personalizada (tema LAB / panda)
- 📱 Experiencia de dashboard/chat orientada a móvil
- 📨 Variantes de pipeline automail (modos de guardado por regla y con ayuda de codex)
- 🧹 Scripts de limpieza personal y clasificación de remitentes
- 🗂️ Enrutamiento de notas/recordatorios/calendario ajustado para uso diario real

Espacio de automatización (local):

- `~/.openclaw/workspace/automation/`
- Referencias de scripts en repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools de Codex dedicadas: `scripts/prompt_tools/`

---

## Filosofía orquestal

La orquestación LAB sigue una regla de diseño:
dividir objetivos difíciles en cadenas deterministas de ejecución + prompt-tools focalizados.

- Los scripts deterministas se encargan de tareas confiables de infraestructura:
  programación, enrutamiento de archivos, directorios de ejecución, reintentos y entrega de salida.
- Las prompt tools se encargan de inteligencia adaptativa:
  planificación, triaje, síntesis de contexto y toma de decisiones bajo incertidumbre.
- Cada etapa emite artefactos reutilizables para que las herramientas siguientes puedan componer notas/correos finales más sólidos sin partir de cero.

Cadenas orquestales principales:

- Cadena de emprendimiento:
  ingesta de contexto empresarial -> inteligencia de mercado/funding/académica/legal -> acciones concretas de crecimiento.
- Cadena de automail:
  triaje de correo entrante -> política de omisión conservadora para correo de bajo valor -> acciones estructuradas de Notas/Recordatorios/Calendario.
- Cadena de búsqueda web:
  captura de página de resultados -> lecturas profundas enfocadas con extracción de captura de pantalla/contenido -> síntesis con evidencia.

---

## Herramientas de prompt en LAB

Las prompt tools son modulares, componibles y priorizan la orquestación.
Pueden ejecutarse de forma independiente o como etapas enlazadas en un flujo más grande.

- Operaciones de leer/guardar:
  crear y actualizar salidas de Notas, Recordatorios y Calendario para operaciones AutoLife.
- Operaciones de captura/lectura:
  capturar páginas de búsqueda y páginas enlazadas, luego extraer texto estructurado para análisis posterior.
- Operaciones de conexión entre herramientas:
  ejecutar scripts deterministas, intercambiar artefactos entre etapas y mantener continuidad de contexto.

Ubicación principal:

- `scripts/prompt_tools/`

---

## Ejemplos

### Ejemplo: gateway solo local

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ejemplo: pedir al agente que procese la planificación diaria

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Ejemplo: build de fuente + bucle watch

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
- Línea base de gestor de paquetes: `pnpm@10.23.0` (`packageManager` field).
- Controles de calidad comunes:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI en desarrollo: `pnpm openclaw ...`
- Bucle TS: `pnpm dev`
- Los comandos de UI del paquete se invocan vía scripts raíz (`pnpm ui:build`, `pnpm ui:dev`).

Comandos extendidos de pruebas comunes en este repositorio:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Herramientas de desarrollo adicionales:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Nota de suposición:

- Los comandos de build/run de apps móviles/macOS existen en `package.json` (`ios:*`, `android:*`, `mac:*`), pero los requisitos de firma/provisión de plataforma dependen del entorno y no están totalmente documentados en este README.

---

## Solucion de problemas

### Gateway no accesible en `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Comprueba colisiones de puertos y conflictos de daemon. Si usas Docker, verifica el puerto mapeado del host y la salud del servicio.

### Problemas de autenticación o configuración de canal

- Revisa de nuevo los valores de `.env` contra `.env.example`.
- Asegura que al menos una clave de modelo esté configurada.
- Verifica tokens de canal solo para canales que realmente habilitaste.

### Problemas de build o instalación

- Vuelve a ejecutar `pnpm install` con Node `>=22.12.0`.
- Vuelve a compilar con `pnpm ui:build && pnpm build`.
- Si faltan peers nativos opcionales, revisa logs de instalación para compatibilidad de `@napi-rs/canvas` / `node-llama-cpp`.

### Verificaciones de salud generales

Usa `openclaw doctor` para detectar problemas de migración/seguridad/configuración.

### Diagnósticos útiles

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Integraciones del ecosistema LAB

LAB integra mis repositorios de producto e investigación de IA en una sola capa operativa para crear, crecer y automatizar.

Perfil:

- https://github.com/lachlanchen?tab=repositories

Repositorios integrados:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (escritura automática de novelas)
- `AutoAppDev` (desarrollo automático de apps)
- `OrganoidAgent` (plataforma de investigación de organoides con modelos de visión fundacionales + LLMs)
- `LazyEdit` (edición de video asistida por IA: subtítulos/transcripción/puntos clave/metadatos)
- `AutoPublish` (pipeline de publicación automática)

Objetivos prácticos de integración LAB:

- Autoescribir novelas
- Autodesarrollar aplicaciones
- Autoeditar videos
- Autopublicar resultados
- Autoanalizar organoides
- Auto gestionar operaciones de correo electrónico

---

## Instalar desde fuente (referencia rápida)

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

Direcciones planeadas para este fork de LAB (roadmap en curso):

- Expandir la fiabilidad de automail con clasificación de remitente/regla más estricta.
- Mejorar la composabilidad de etapas orquestales y la trazabilidad de artefactos.
- Fortalecer la operativa mobile-first y la UX de administración remota de gateway.
- Profundizar integraciones con repositorios del ecosistema LAB para producción automatizada de extremo a extremo.
- Seguir endureciendo los valores de seguridad por defecto y la observabilidad para automatización sin supervisión.

---

## Contribucion

Este repositorio sigue prioridades personales de LAB mientras hereda la arquitectura central de OpenClaw.

- Lee [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Revisa la documentación upstream: https://docs.openclaw.ai
- Para problemas de seguridad, ver [`SECURITY.md`](SECURITY.md)

Si tienes dudas sobre el comportamiento específico de LAB, conserva el comportamiento existente y documenta supuestos en las notas de PR.

---

## Agradecimientos

LazyingArtBot se basa en **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Gracias a los mantenedores y la comunidad de OpenClaw por la plataforma base.

---

## Licencia

MIT (igual que en upstream donde aplique). Ver `LICENSE`.



## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
