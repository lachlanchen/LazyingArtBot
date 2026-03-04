[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#inicio-r%C3%A1pido)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **Estado de i18n:** `i18n/` ya existe y actualmente incluye README localizados en árabe, alemán, español, francés, japonés, coreano, ruso, vietnamita, chino simplificado y chino tradicional. Esta versión en inglés sigue siendo la fuente canónica para actualizaciones incrementales.

**LazyingArtBot** es mi asistente personal de IA para **lazying.art**:

**LazyingArtBot** está construido sobre OpenClaw y adaptado a mis flujos de trabajo diarios: chat multicanal, control local-first y automatización de correo electrónico hacia calendario, recordatorios y notas.

| 🔗 Enlace           | URL                                          | Enfoque                              |
| ------------------- | -------------------------------------------- | ------------------------------------ |
| 🌐 Sitio web        | https://lazying.art                          | Dominio principal y panel de estado  |
| 🤖 Dominio del bot  | https://lab.lazying.art                      | Punto de entrada de chat y asistente |
| 🧱 Base upstream    | https://github.com/openclaw/openclaw         | Plataforma base de OpenClaw          |
| 📦 Este repositorio | https://github.com/lachlanchen/LazyingArtBot | Adaptaciones específicas de LAB      |

---

## Tabla de contenidos

- [Resumen general](#resumen-general)
- [A primera vista](#a-primera-vista)
- [Funciones](#funciones)
- [Capacidades principales](#capacidades-principales)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Inicio rápido](#inicio-r%C3%A1pido)
- [Instalación](#instalacion)
- [Uso](#uso)
- [Configuración](#configuracion)
- [Modos de despliegue](#modos-de-despliegue)
- [Enfoque del flujo LazyingArt](#enfoque-del-flujo-lazyingart)
- [Filosofía orquestal](#filosofia-orquestal)
- [Herramientas de prompt en LAB](#herramientas-de-prompt-en-lab)
- [Ejemplos](#ejemplos)
- [Notas de desarrollo](#notas-de-desarrollo)
- [Solución de problemas](#solucion-de-problemas)
- [Integraciones del ecosistema LAB](#integraciones-del-ecosistema-lab)
- [Instalación desde fuente (referencia rápida)](#instalacion-desde-fuente-referencia-r%C3%A1pida)
- [Hoja de ruta](#hoja-de-ruta)
- [Contribuciones](#contribuciones)
- [Agradecimientos](#agradecimientos)
- [❤️ Support](#-support)
- [Contacto](#contacto)
- [Licencia](#licencia)

---

## Resumen general

LAB se centra en productividad personal práctica:

- ✅ Ejecuta un único asistente en los canales de chat que ya usas.
- 🔐 Mantiene tus datos y el control en tu propia máquina/servidor.
- 📬 Convierte correos entrantes en acciones estructuradas (Calendario, Recordatorios, Notas).
- 🛡️ Añade guardrails para que la automatización sea útil y, a la vez, segura.

En resumen: menos trabajo repetitivo, mejor ejecución.

---

## A primera vista

| Área                         | Línea base actual en este repositorio      |
| ---------------------------- | ------------------------------------------ |
| Runtime                      | Node.js `>=22.12.0`                        |
| Gestor de paquetes           | `pnpm@10.23.0`                             |
| CLI principal                | `openclaw`                                 |
| Gateway local por defecto    | `127.0.0.1:18789`                          |
| Puerto de puente por defecto | `127.0.0.1:18790`                          |
| Docs principales             | `docs/` (Mintlify)                         |
| Orquestación principal LAB   | `orchestral/` + `orchestral/prompt_tools/` |
| Ubicación i18n del README    | `i18n/README.*.md`                         |

---

## Funciones

- 🌐 Runtime de asistente multicanal con gateway local.
- 🖥️ Superficie de dashboard/chat en navegador para operaciones locales.
- 🧰 Pipeline de automatización con herramientas habilitadas (scripts + prompt-tools).
- 📨 Triaje de correo electrónico y conversión en acciones de Notas, Recordatorios y Calendario.
- 🧩 Ecosistema de plugins/extensiones (`extensions/*`) para canales, proveedores e integraciones.
- 📱 Superficies multiplataforma en el repositorio (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacidades principales

| Capacidad                            | Qué significa en la práctica                                                                                                        |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Runtime de asistente multicanal      | Gateway + sesiones de agente en los canales que habilites                                                                           |
| Dashboard/chat web                   | Superficie de control basada en navegador para operaciones locales                                                                  |
| Flujos con herramientas habilitadas  | Cadenas de ejecución de shell + archivos + scripts de automatización                                                                |
| Pipeline de automatización de correo | Analiza correo, clasifica el tipo de acción, enruta a Notas/Recordatorios/Calendario y registra acciones para revisión y depuración |

Etapas del pipeline conservadas del flujo actual:

- analizar correo entrante
- clasificar tipo de acción
- guardar en Notas / Recordatorios / Calendario
- registrar cada acción para revisión y depuración

---

## Estructura del proyecto

Diseño general del repositorio:

```text
.
├─ src/                 # core runtime, gateway, channels, CLI, infra
├─ extensions/          # optional channel/provider/auth plugins
├─ orchestral/          # pipelines de orquestación LAB + prompt tools
├─ scripts/             # helpers de build/dev/test/release
├─ ui/                  # paquete web del dashboard
├─ apps/                # apps de macOS / iOS / Android
├─ docs/                # documentación Mintlify
├─ references/          # referencias LAB y notas operativas
├─ test/                # suites de pruebas
├─ i18n/                # README localizados
├─ .env.example         # plantilla de entorno
├─ docker-compose.yml   # contenedores de gateway + CLI
├─ README_OPENCLAW.md   # README de referencia de estilo upstream
└─ README.md            # este README enfocado en LAB
```

Notas:

- `orchestral/prompt_tools` apunta a la implementación de prompt-tools orquestal.
- La carpeta raíz `i18n/` contiene variantes localizadas del README.
- `.github/workflows.disabled/` está presente en esta instantánea; el comportamiento activo de CI debe verificarse antes de asumir nada.

---

## Requisitos previos

Líneas base de runtime y herramientas de este repositorio:

- Node.js `>=22.12.0`
- pnpm `10.23.0` (ver `packageManager` en `package.json`)
- Una clave de proveedor de modelo configurada (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Opcional: Docker + Docker Compose para gateway/CLI en contenedor
- Opcional para builds mobile/mac: toolchains de Apple/Android según la plataforma objetivo

Instalación global opcional del CLI (coincide con el flujo de inicio rápido):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Inicio rápido

Línea base de runtime en este repositorio: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Luego abre el dashboard y el chat local:

- http://127.0.0.1:18789

Para acceso remoto, expón tu gateway local a través de tu propio túnel seguro (por ejemplo ngrok/Tailscale) y mantén autenticación habilitada.

---

## Instalación

### Instalar desde fuente

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Flujo opcional con Docker

Incluye un `docker-compose.yml` con:

- `openclaw-gateway`
- `openclaw-cli`

Flujo típico:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Variables de Compose usadas con frecuencia:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Uso

Comandos frecuentes:

```bash
# Onboard e instalación de daemon de usuario
openclaw onboard --install-daemon

# Ejecutar gateway en primer plano
openclaw gateway run --bind loopback --port 18789 --verbose

# Enviar un mensaje directo via canales configurados
openclaw message send --to +1234567890 --message "Hello from LAB"

# Consultar al agente directamente
openclaw agent --message "Create today checklist" --thinking high
```

Bucle de desarrollo (watch mode):

```bash
pnpm gateway:watch
```

Desarrollo UI:

```bash
pnpm ui:dev
```

Comandos operativos útiles adicionales:

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

La referencia de entorno y configuración está distribuida entre `.env` y `~/.openclaw/openclaw.json`.

1. Parte desde `.env.example`.
2. Configura autenticación del gateway (`OPENCLAW_GATEWAY_TOKEN` recomendado).
3. Configura al menos una clave de proveedor de modelos (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Configura credenciales de canal solo para los canales que habilites.

Notas importantes de `.env.example` preservadas del repositorio:

- Precedencia de env: entorno del proceso -> `./.env` -> `~/.openclaw/.env` -> bloque `env` de config.
- Los valores no vacíos existentes en entorno de proceso no se sobrescriben.
- Claves de configuración como `gateway.auth.token` pueden tener prioridad sobre fallback de entorno.

Línea base de seguridad antes de exponer a internet:

- Mantén autenticación/pareja (pairing) de gateway habilitada.
- Mantén allowlists estrictas para canales entrantes.
- Trata cada mensaje/correo entrante como entrada no confiable.
- Opera con el principio de menor privilegio y revisa logs con regularidad.

Si expones el gateway a internet, exige autenticación por token/contraseña y configuración de proxy confiable.

---

## Modos de despliegue

| Modo                | Ideal para                               | Comando típico                                                     |
| ------------------- | ---------------------------------------- | ------------------------------------------------------------------ |
| Primer plano local  | Desarrollo y depuración                  | `openclaw gateway run --bind loopback --port 18789 --verbose`      |
| Daemon local        | Uso personal diario                      | `openclaw onboard --install-daemon`                                |
| Docker              | Runtime aislado y despliegues repetibles | `docker compose up -d`                                             |
| Host remoto + túnel | Acceso desde fuera de LAN doméstica      | Ejecuta gateway + túnel seguro, manteniendo autenticación activada |

Suposición: endurecimiento de reverse-proxy en producción, rotación de secretos y política de respaldo son específicos de cada despliegue y deben definirse por entorno.

---

## Enfoque del flujo LazyingArt

Este fork prioriza mi flujo personal en **lazying.art**:

- 🎨 Marca personalizada (tema LAB / panda)
- 📱 Experiencia de dashboard/chat amigable para móvil
- 📨 Variantes de pipeline automail (modo activado por reglas, modos de guardado asistidos por codex)
- 🧹 Scripts de limpieza personal y clasificación de remitentes
- 🗂️ Enrutamiento de notas/recordatorios/calendario ajustado para uso diario real

Espacio de automatización local:

- `~/.openclaw/workspace/automation/`
- Referencias en el repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools de Codex dedicados: `orchestral/prompt_tools/`

---

## Filosofía orquestal

La orquestación LAB sigue una regla de diseño:
convertir objetivos complejos en ejecución determinista + cadenas de prompt-tools enfocadas.

- Los scripts deterministas gestionan operaciones confiables de infraestructura:
  programación, enrutado de archivos, directorios de ejecución, reintentos y traspaso de salidas.
- Las prompt tools gestionan inteligencia adaptativa:
  planificación, triaje, síntesis de contexto y toma de decisiones bajo incertidumbre.
- Cada etapa emite artefactos reutilizables para que herramientas posteriores puedan componer notas/correos finales más sólidos sin partir desde cero.

Cadenas orquestales principales:

- Cadena de emprendimiento empresarial:
  ingestión de contexto de empresa -> inteligencia de mercado/funding/académica/legal -> acciones concretas de crecimiento.
- Cadena automail:
  triaje de correo entrante -> política conservadora de omisión para correo de bajo valor -> acciones estructuradas de Notas/Recordatorios/Calendario.
- Cadena de búsqueda web:
  captura de página de resultados -> lecturas profundas dirigidas con captura de pantalla/extracción de contenido -> síntesis con evidencia.

---

## Herramientas de prompt en LAB

Las prompt tools son modulares, composables y orientadas a orquestación.
Pueden ejecutarse de forma independiente o como etapas enlazadas en flujos más grandes.

- Operaciones de leer/guardar:
  crear y actualizar salidas de Notas, Recordatorios y Calendario para operaciones AutoLife.
- Operaciones de captura/lectura:
  capturar páginas de búsqueda y páginas enlazadas, luego extraer texto estructurado para análisis posterior.
- Operaciones de conexión entre herramientas:
  invocar scripts deterministas, intercambiar artefactos entre etapas y mantener continuidad de contexto.

Ubicación principal:

- `orchestral/prompt_tools/`

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

### Ejemplo: build del source + watch loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Ejemplo: ejecutar con Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Notas de desarrollo

- Línea base de runtime: Node `>=22.12.0`.
- Línea base de gestor de paquetes: `pnpm@10.23.0` (`packageManager` field).
- Controles de calidad habituales:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # construir salida de dist
pnpm test           # suites de pruebas
pnpm test:coverage  # ejecución de cobertura
```

- CLI en desarrollo: `pnpm openclaw ...`
- Bucle TS: `pnpm dev`
- Los comandos del paquete UI se promedian por scripts raiz (`pnpm ui:build`, `pnpm ui:dev`).

Comandos extendidos de prueba comunes en este repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Helpers de desarrollo adicionales:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Nota de suposición:

- Los comandos de build/run de apps móviles/macOS existen en `package.json` (`ios:*`, `android:*`, `mac:*`), pero requisitos de firma/provisioning de plataforma son específicos del entorno y no están completamente documentados en este README.

---

## Solución de problemas

### Gateway no accesible en `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Revisa colisiones de puertos y conflictos de daemon. Si usas Docker, verifica el puerto mapeado en el host y la salud del servicio.

### Problemas de autenticación o configuración de canal

- Revisa de nuevo los valores de `.env` contra `.env.example`.
- Asegura tener al menos una clave de modelo configurada.
- Verifica tokens de canal solo para los canales que realmente habilitaste.

### Problemas de build o instalación

- Reejecuta `pnpm install` con Node `>=22.12.0`.
- Reconstruye con `pnpm ui:build && pnpm build`.
- Si faltan peers nativos opcionales, revisa logs de instalación para compatibilidad de `@napi-rs/canvas` / `node-llama-cpp`.

### Comprobaciones de salud generales

Usa `openclaw doctor` para detectar desalineaciones de migración/seguridad/configuración.

### Diagnóstico útil

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Integraciones del ecosistema LAB

LAB integra mis repositorios de producto e investigación de IA en una única capa operativa para creación, crecimiento y automatización.

Perfil:

- https://github.com/lachlanchen?tab=repositories

Repositorios integrados:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (escritura automática de novelas)
- `AutoAppDev` (desarrollo automático de apps)
- `OrganoidAgent` (plataforma de investigación de organoides con modelos de visión fundacionales + LLMs)
- `LazyEdit` (edición de video asistida por IA: subtítulos/transcripción/destacar puntos clave/metadatos)
- `AutoPublish` (pipeline de publicación automática)

Objetivos prácticos de integración LAB:

- Autoescribir novelas
- Auto desarrollar apps
- Auto editar videos
- Auto publicar resultados
- Auto analizar organoides
- Auto gestionar operaciones de correo electrónico

---

## Instalación desde fuente (referencia rápida)

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

Direcciones planeadas para este fork de LAB (hoja de ruta en curso):

- Expandir la fiabilidad de automail con clasificación de remitente/reglas más estricta.
- Mejorar la composabilidad entre etapas orquestales y la trazabilidad de artefactos.
- Fortalecer la operación mobile-first y el UX de administración remota del gateway.
- Profundizar integraciones con repositorios del ecosistema LAB para una producción automatizada de extremo a extremo.
- Mantener y endurecer defaults de seguridad y observabilidad para automatización sin supervisión.

---

## Contribuciones

Este repositorio conserva prioridades personales de LAB mientras hereda la arquitectura base de OpenClaw.

- Lee [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Revisa la documentación upstream: https://docs.openclaw.ai
- Para problemas de seguridad, consulta [`SECURITY.md`](SECURITY.md)

Si tienes dudas sobre comportamiento específico de LAB, conserva la conducta existente y documenta supuestos en las notas del PR.

---

## Agradecimientos

LazyingArtBot se basa en **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Gracias a los mantenedores y comunidad de OpenClaw por la plataforma base.

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contacto

- Sitio web: https://lazying.art
- Repositorio: https://github.com/lachlanchen/LazyingArtBot
- Seguimiento de incidencias: https://github.com/lachlanchen/LazyingArtBot/issues
- Incidentes de seguridad o riesgos: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## Licencia

MIT (igual que upstream donde aplique). Consulta `LICENSE`.
