[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#demarrage-rapide)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)

> 🌍 **Statut i18n :** `i18n/` existe et inclut actuellement des README localisés en arabe, allemand, espagnol, français, japonais, coréen, russe, vietnamien, chinois simplifié et chinois traditionnel. Cette version anglaise reste la source canonique pour les mises à jour incrémentales.

**LazyingArtBot** est ma stack d'assistant IA personnelle pour **lazying.art**.
Elle est construite sur OpenClaw et adaptée à mes flux de travail quotidiens : chat multicanal, contrôle local-first et automatisation email -> calendrier/rappels/notes.

| 🔗 Lien | URL |
| --- | --- |
| 🌐 Site web | https://lazying.art |
| 🤖 Domaine du bot | https://lazying.art |
| 🧱 Base upstream | https://github.com/openclaw/openclaw |
| 📦 Ce dépôt | https://github.com/lachlanchen/LazyingArtBot |

---

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [En bref](#en-bref)
- [Fonctionnalités](#fonctionnalites)
- [Capacités principales](#capacites-principales)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prerequis)
- [Démarrage rapide](#demarrage-rapide)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Configuration](#configuration)
- [Modes de déploiement](#modes-de-deploiement)
- [Focus du workflow LazyingArt](#focus-du-workflow-lazyingart)
- [Philosophie orchestrale](#philosophie-orchestrale)
- [Prompt tools dans LAB](#prompt-tools-dans-lab)
- [Exemples](#exemples)
- [Notes de développement](#notes-de-developpement)
- [Dépannage](#depannage)
- [Intégrations de l'écosystème LAB](#integrations-de-lecosysteme-lab)
- [Installation depuis les sources (référence rapide)](#installation-depuis-les-sources-reference-rapide)
- [Feuille de route](#feuille-de-route)
- [Contribution](#contribution)
- [❤️ Support](#-support)
- [Remerciements](#remerciements)
- [Licence](#licence)

---

## Vue d'ensemble

LAB est orienté productivité personnelle pragmatique :

- ✅ Exécuter un seul assistant sur les canaux de chat que vous utilisez déjà.
- 🔐 Garder les données et le contrôle sur votre propre machine/serveur.
- 📬 Convertir les emails entrants en actions structurées (Calendar, Reminders, Notes).
- 🛡️ Ajouter des garde-fous pour que l'automatisation reste utile et sûre.

En bref : moins de tâches répétitives, meilleure exécution.

---

## En bref

| Domaine | Base actuelle dans ce dépôt |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Gestionnaire de paquets | `pnpm@10.23.0` |
| CLI principal | `openclaw` |
| Gateway local par défaut | `127.0.0.1:18789` |
| Port de bridge par défaut | `127.0.0.1:18790` |
| Documentation principale | `docs/` (Mintlify) |
| Orchestration LAB principale | `orchestral/` + `scripts/prompt_tools/` |
| Emplacement README i18n | `i18n/README.*.md` |

---

## Fonctionnalités

- 🌐 Runtime d'assistant multicanal avec un gateway local.
- 🖥️ Tableau de bord/chat dans le navigateur pour les opérations locales.
- 🧰 Pipeline d'automatisation avec outils (scripts + prompt-tools).
- 📨 Triage des emails et conversion en actions Notes, Reminders et Calendar.
- 🧩 Écosystème de plugins/extensions (`extensions/*`) pour canaux/providers/intégrations.
- 📱 Surfaces multi-plateformes dans le dépôt (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacités principales

| Capacité | Ce que cela signifie en pratique |
| --- | --- |
| Runtime d'assistant multicanal | Gateway + sessions d'agent sur les canaux que vous activez |
| Tableau de bord / chat web | Surface de contrôle dans le navigateur pour les opérations locales |
| Workflows avec outils activés | Chaînes d'exécution shell + fichiers + scripts d'automatisation |
| Pipeline d'automatisation email | Analyse des emails, classification du type d'action, routage vers Notes/Reminders/Calendar, journalisation des actions pour revue/débogage |

Étapes de pipeline conservées du workflow actuel :

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Structure du projet

Organisation générale du dépôt :

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

Notes :

- `scripts/prompt_tools` pointe vers l'implémentation orchestration des prompt-tools.
- Le dossier racine `i18n/` contient les variantes localisées du README.
- `.github/workflows.disabled/` est présent dans ce snapshot ; le comportement CI actif doit être vérifié avant de se baser sur des hypothèses de workflow.

---

## Prérequis

Bases runtime et outillage de ce dépôt :

- Node.js `>=22.12.0`
- Baseline pnpm `10.23.0` (voir `packageManager` dans `package.json`)
- Une clé de fournisseur de modèle configurée (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Optionnel : Docker + Docker Compose pour un gateway/CLI conteneurisé
- Optionnel pour les builds mobile/mac : toolchains Apple/Android selon la plateforme cible

Installation globale optionnelle du CLI (alignée sur le flux quick-start) :

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Démarrage rapide

Baseline runtime dans ce dépôt : **Node >= 22.12.0** (engine `package.json`).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Puis ouvrez le dashboard local et le chat :

- http://127.0.0.1:18789

Pour un accès distant, exposez votre gateway local via votre propre tunnel sécurisé (par exemple ngrok/Tailscale) et gardez l'authentification activée.

---

## Installation

### Installation depuis les sources

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Workflow Docker optionnel

Un `docker-compose.yml` est inclus avec :

- `openclaw-gateway`
- `openclaw-cli`

Flux typique :

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Variables Compose couramment requises :

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Utilisation

Commandes courantes :

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

Boucle de dev (mode watch) :

```bash
pnpm gateway:watch
```

Développement UI :

```bash
pnpm ui:dev
```

Autres commandes opérationnelles utiles :

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Configuration

La référence env/config est partagée entre `.env` et `~/.openclaw/openclaw.json`.

1. Commencez depuis `.env.example`.
2. Définissez l'auth gateway (`OPENCLAW_GATEWAY_TOKEN` recommandé).
3. Définissez au moins une clé de fournisseur de modèle (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Définissez uniquement les identifiants des canaux que vous activez.

Points importants de `.env.example` conservés du dépôt :

- Priorité env : process env -> `./.env` -> `~/.openclaw/.env` -> bloc config `env`.
- Les valeurs process env existantes et non vides ne sont pas écrasées.
- Les clés de config comme `gateway.auth.token` peuvent primer sur les fallbacks env.

Base de sécurité critique avant exposition à Internet :

- Gardez l'auth/pairing du gateway activé.
- Gardez des allowlists strictes pour les canaux entrants.
- Traitez chaque message/email entrant comme une entrée non fiable.
- Exécutez avec le principe du moindre privilège et vérifiez régulièrement les logs.

Si vous exposez le gateway à Internet, imposez une authentification token/mot de passe et une configuration de proxy de confiance.

---

## Modes de déploiement

| Mode | Idéal pour | Commande typique |
| --- | --- | --- |
| Local au premier plan | Développement et débogage | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Usage personnel quotidien | `openclaw onboard --install-daemon` |
| Docker | Runtime isolé et déploiements reproductibles | `docker compose up -d` |
| Hôte distant + tunnel | Accès hors réseau local | Exécuter le gateway + tunnel sécurisé, garder l'auth activée |

Hypothèse : le durcissement reverse-proxy de niveau production, la rotation des secrets et la politique de sauvegarde dépendent de chaque environnement.

---

## Focus du workflow LazyingArt

Ce fork priorise mon flux personnel sur **lazying.art** :

- 🎨 branding personnalisé (thème LAB / panda)
- 📱 expérience dashboard/chat mobile-friendly
- 📨 variantes du pipeline automail (modes de sauvegarde déclenchés par règles, assistés par codex)
- 🧹 scripts personnels de nettoyage et de classification des expéditeurs
- 🗂️ routage notes/rappels/calendrier ajusté pour un usage quotidien réel

Workspace d'automatisation (local) :

- `~/.openclaw/workspace/automation/`
- Références de scripts dans le dépôt : `references/lab-scripts-and-philosophy.md`
- Prompt tools Codex dédiés : `scripts/prompt_tools/`

---

## Philosophie orchestrale

L'orchestration LAB suit une règle de conception :
décomposer les objectifs difficiles en exécution déterministe + chaînes de prompt-tools ciblées.

- Les scripts déterministes gèrent la plomberie fiable :
  planification, routage de fichiers, répertoires d'exécution, retries et transmission des sorties.
- Les prompt-tools gèrent l'intelligence adaptative :
  planification, triage, synthèse de contexte et prise de décision en incertitude.
- Chaque étape émet des artefacts réutilisables pour que les outils en aval puissent composer de meilleures notes/emails finaux sans repartir de zéro.

Chaînes orchestrales principales :

- Chaîne d'entrepreneuriat d'entreprise :
  ingestion du contexte entreprise -> intelligence marché/financement/academique/juridique -> actions de croissance concrètes.
- Chaîne auto mail :
  triage des emails entrants -> politique de skip conservatrice pour les emails à faible valeur -> actions structurées Notes/Reminders/Calendar.
- Chaîne de recherche web :
  capture des pages de résultats -> lectures approfondies ciblées avec extraction screenshot/contenu -> synthèse appuyée sur des preuves.

---

## Prompt tools dans LAB

Les prompt-tools sont modulaires, composables et orientés orchestration.
Ils peuvent s'exécuter indépendamment ou comme étapes liées dans un workflow plus large.

- Opérations de lecture/sauvegarde :
  créer et mettre à jour des sorties Notes, Reminders et Calendar pour les opérations AutoLife.
- Opérations de capture/lecture :
  capturer les pages de recherche et les pages liées, puis extraire du texte structuré pour l'analyse en aval.
- Opérations de connexion d'outils :
  appeler des scripts déterministes, échanger des artefacts entre étapes et maintenir la continuité du contexte.

Emplacement principal :

- `scripts/prompt_tools/`

---

## Exemples

### Exemple : gateway local uniquement

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Exemple : demander à l'agent de traiter la planification quotidienne

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Exemple : build source + boucle watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Exemple : exécuter avec Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Notes de développement

- Baseline runtime : Node `>=22.12.0`.
- Baseline gestionnaire de paquets : `pnpm@10.23.0` (champ `packageManager`).
- Gates qualité courants :

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI en dev : `pnpm openclaw ...`
- Boucle d'exécution TS : `pnpm dev`
- Les commandes du package UI sont proxifiées via les scripts racine (`pnpm ui:build`, `pnpm ui:dev`).

Commandes de test étendues courantes dans ce dépôt :

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Aides de développement supplémentaires :

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Note d'hypothèse :

- Les commandes de build/run des apps mobile/macOS existent dans `package.json` (`ios:*`, `android:*`, `mac:*`), mais les exigences de signature/provisionnement dépendent de l'environnement et ne sont pas entièrement documentées dans ce README.

---

## Dépannage

### Gateway inaccessible sur `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Vérifiez les collisions de ports et les conflits de daemon. Si vous utilisez Docker, vérifiez le port hôte mappé et l'état de santé du service.

### Problèmes d'auth ou de configuration de canaux

- Revérifiez les valeurs `.env` par rapport à `.env.example`.
- Assurez-vous qu'au moins une clé de modèle est configurée.
- Vérifiez les tokens de canaux uniquement pour les canaux réellement activés.

### Problèmes de build ou d'installation

- Relancez `pnpm install` avec Node `>=22.12.0`.
- Rebuild avec `pnpm ui:build && pnpm build`.
- Si des peers natifs optionnels sont manquants, inspectez les logs d'installation pour la compatibilité `@napi-rs/canvas` / `node-llama-cpp`.

### Vérifications générales de santé

Utilisez `openclaw doctor` pour détecter les problèmes de migration/sécurité/dérive de configuration.

### Diagnostics utiles

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Intégrations de l'écosystème LAB

LAB intègre mes dépôts IA de produit et de recherche dans une couche opérationnelle unique pour la création, la croissance et l'automatisation.

Profil :

- https://github.com/lachlanchen?tab=repositories

Dépôts intégrés :

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Objectifs d'intégration LAB concrets :

- Auto write novels
- Auto develop apps
- Auto edit videos
- Auto publish outputs
- Auto analyze organoids
- Auto handle email operations

---

## Installation depuis les sources (référence rapide)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Boucle de dev :

```bash
pnpm gateway:watch
```

---

## Feuille de route

Directions prévues pour ce fork LAB (feuille de route de travail) :

- Étendre la fiabilité automail avec une classification expéditeur/règles plus stricte.
- Améliorer la composabilité des étapes orchestrales et la traçabilité des artefacts.
- Renforcer les opérations mobile-first et l'UX de gestion distante du gateway.
- Approfondir les intégrations avec les dépôts de l'écosystème LAB pour une production automatisée de bout en bout.
- Continuer à renforcer les valeurs par défaut de sécurité et l'observabilité pour l'automatisation sans supervision.

---

## Contribution

Ce dépôt suit des priorités LAB personnelles tout en héritant de l'architecture cœur d'OpenClaw.

- Lire [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Consulter la documentation upstream : https://docs.openclaw.ai
- Pour les sujets de sécurité, voir [`SECURITY.md`](SECURITY.md)

En cas d'incertitude sur un comportement spécifique à LAB, préservez le comportement existant et documentez les hypothèses dans les notes de PR.

---

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Remerciements

LazyingArtBot est basé sur **OpenClaw** :

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Merci aux mainteneurs et à la communauté OpenClaw pour la plateforme de base.

---

## Licence

MIT (identique à l'upstream quand applicable). Voir `LICENSE`.
