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
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **Statut i18n :** `i18n/` existe et contient actuellement des README localisés en arabe, allemand, espagnol, français, japonais, coréen, russe, vietnamien, chinois simplifié et chinois traditionnel. Cette version anglaise reste la source canonique pour les mises à jour incrémentales.

**LazyingArtBot** est ma stack d’assistant IA personnelle pour **lazying.art** :

**LazyingArtBot** est construit sur OpenClaw et adapté à mes flux de travail quotidiens : chat multi-canal, contrôle local-first et automatisation email → calendrier/rappels/notes.

| 🔗 Lien | URL | Focus |
| --- | --- | --- |
| 🌐 Site web | https://lazying.art | Domaine principal et tableau de bord d’état |
| 🤖 Domaine du bot | https://lazying.art | Point d’entrée chat et assistant |
| 🧱 Base upstream | https://github.com/openclaw/openclaw | Fondation de la plateforme OpenClaw |
| 📦 Ce dépôt | https://github.com/lachlanchen/LazyingArtBot | Adaptations spécifiques à LAB |

---

## Table des matières

- [Aperçu](#aperçu)
- [En bref](#en-bref)
- [Fonctionnalités](#fonctionnalités)
- [Capacités principales](#capacités-principales)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [Démarrage rapide](#démarrage-rapide)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Configuration](#configuration)
- [Modes de déploiement](#modes-de-déploiement)
- [Focus du workflow LazyingArt](#focus-du-workflow-lazyingart)
- [Philosophie orchestrale](#philosophie-orchestrale)
- [Prompt tools dans LAB](#prompt-tools-dans-lab)
- [Exemples](#exemples)
- [Notes de développement](#notes-de-développement)
- [Dépannage](#dépannage)
- [Intégrations de l’écosystème LAB](#intégrations-de-lecosystème-lab)
- [Installation depuis les sources (référence rapide)](#installation-depuis-les-sources-référence-rapide)
- [Feuille de route](#feuille-de-route)
- [Contribution](#contribution)
- [Remerciements](#remerciements)
- [❤️ Support](#-support)
- [Licence](#licence)

---

## Aperçu

LAB mise l’accent sur la productivité personnelle concrète :

- ✅ Exécuter un seul assistant sur les canaux de chat que vous utilisez déjà.
- 🔐 Conserver les données et le contrôle sur votre propre machine/serveur.
- 📬 Transformer les emails entrants en actions structurées (Calendar, Reminders, Notes).
- 🛡️ Ajouter des garde-fous pour que l’automatisation reste utile et sûre.

En bref : moins de travail manuel, une exécution plus fiable.

---

## En bref

| Domaine | État actuel dans ce dépôt |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Gestionnaire de paquets | `pnpm@10.23.0` |
| CLI principal | `openclaw` |
| Passerelle locale par défaut | `127.0.0.1:18789` |
| Port de pont par défaut | `127.0.0.1:18790` |
| Docs principales | `docs/` (Mintlify) |
| Orchestration LAB principale | `orchestral/` + `scripts/prompt_tools/` |
| Emplacement i18n du README | `i18n/README.*.md` |

---

## Fonctionnalités

- 🌐 Runtime d’assistant multi-canal avec passerelle locale.
- 🖥️ Tableau de bord/chat navigateur pour les opérations locales.
- 🧰 Pipeline d’automatisation outillé (scripts + prompt-tools).
- 📨 Tri des emails et conversion en actions Notes, Reminders et Calendar.
- 🧩 Écosystème de plugins/extensions (`extensions/*`) pour les canaux/fournisseurs/intégrations.
- 📱 Interfaces multi-plateforme incluses dans le dépôt (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacités principales

| Capacité | Ce que cela signifie concrètement |
| --- | --- |
| Runtime d’assistant multi-canal | Gateway + sessions d’agent sur les canaux que vous activez |
| Tableau de bord / chat web | Interface de contrôle basée sur navigateur pour les opérations locales |
| Workflows avec outils | Chaînes de scripts shell + fichiers + automatisation |
| Pipeline d’automatisation email | Analyse des mails entrants, classification du type d’action, routage vers Notes/Reminders/Calendar, journalisation des actions pour revue et débogage |

Étapes du pipeline conservées dans le flux de travail actuel :

- analyse des mails entrants
- classification du type d’action
- enregistrement dans Notes / Reminders / Calendar
- journalisation de chaque action pour revue et débogage

---

## Structure du projet

Organisation générale du dépôt :

```text
.
├─ src/                 # runtime principal, passerelle, canaux, CLI, infra
├─ extensions/          # plugins de canal/fournisseur/auth optionnels
├─ orchestral/          # pipelines d'orchestration LAB + prompt tools
├─ scripts/             # scripts de build/dev/tests/release
├─ ui/                  # package de l’UI du tableau de bord web
├─ apps/                # apps macOS / iOS / Android
├─ docs/                # documentation Mintlify
├─ references/          # références et notes opérationnelles LAB
├─ test/                # suites de tests
├─ i18n/                # README localisés
├─ .env.example         # modèle d’environnement
├─ docker-compose.yml   # passerelle + conteneurs CLI
├─ README_OPENCLAW.md   # référence README de type upstream
└─ README.md            # README centré LAB (ce document)
```

Notes :

- `scripts/prompt_tools` pointe vers l’implémentation d’orchestration des prompt tools.
- La racine `i18n/` contient les variantes localisées du README.
- `.github/workflows.disabled/` est présent dans ce snapshot ; le comportement CI actif doit être vérifié avant de s’appuyer dessus.

---

## Prérequis

Référentiel et baseline d’exécution :

- Node.js `>=22.12.0`
- pnpm `10.23.0` en base (voir `packageManager` dans `package.json`)
- Au moins une clé de fournisseur de modèle configurée (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Optionnel : Docker + Docker Compose pour une passerelle/CLI conteneurisés
- Optionnel pour les builds mobile/mac : chaînes Apple/Android selon la cible

Installation globale optionnelle du CLI (conforme au flux quick-start) :

```bash
npm install -g openclaw@latest
# ou
pnpm add -g openclaw@latest
```

---

## Démarrage rapide

Runtime de référence dans ce dépôt : **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# ou
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Puis ouvrez le tableau de bord local et le chat :

- http://127.0.0.1:18789

Pour un accès distant, exposez votre passerelle locale via votre tunnel sécurisé (par ex. ngrok/Tailscale) et conservez l’authentification activée.

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

### Flux Docker optionnel

Un `docker-compose.yml` est fourni avec :

- `openclaw-gateway`
- `openclaw-cli`

Flux typique :

```bash
cp .env.example .env
# au minimum : OPENCLAW_GATEWAY_TOKEN et vos clés de fournisseur de modèle
docker compose up -d
```

Variables Compose fréquemment requises :

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Utilisation

Commandes courantes :

```bash
# Intégrer et installer le daemon utilisateur
openclaw onboard --install-daemon

# Lancer la passerelle en premier plan
openclaw gateway run --bind loopback --port 18789 --verbose

# Envoyer un message direct via les canaux configurés
openclaw message send --to +1234567890 --message "Hello from LAB"

# Interroger directement l’agent
openclaw agent --message "Create today checklist" --thinking high
```

Boucle de dev (watch mode) :

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

La référence de configuration est répartie entre `.env` et `~/.openclaw/openclaw.json`.

1. Commencez par `.env.example`.
2. Configurez l’authentification de la passerelle (`OPENCLAW_GATEWAY_TOKEN` recommandé).
3. Définissez au moins une clé de fournisseur de modèle (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Définissez uniquement les identifiants des canaux que vous activez.

Points importants de `.env.example` (issus du dépôt) :

- Priorité d’environnements : process env -> `./.env` -> `~/.openclaw/.env` -> bloc `env` de la config.
- Les valeurs process env non vides existantes ne sont pas remplacées.
- Des clés de config comme `gateway.auth.token` peuvent primer sur les valeurs de repli env.

Pré-requis de sécurité critique avant exposition sur Internet :

- Gardez l’authentification/pairing de la passerelle activé.
- Maintenez des allowlists strictes pour les canaux entrants.
- Traitez chaque message/email entrant comme une entrée non fiable.
- Utilisez le principe du moindre privilège et révisez régulièrement les logs.

Si vous exposez la passerelle à Internet, exigez une authentification par token/mot de passe et une configuration de proxy de confiance.

---

## Modes de déploiement

| Mode | Idéal pour | Commande typique |
| --- | --- | --- |
| Local en premier plan | Développement et débogage | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Usage personnel quotidien | `openclaw onboard --install-daemon` |
| Docker | Runtime isolé et déploiements reproductibles | `docker compose up -d` |
| Hôte distant + tunnel | Accès depuis l’extérieur du LAN | Lancez la passerelle + un tunnel sécurisé en gardant l’authentification activée |

Hypothèse : le durcissement de reverse proxy en production, la rotation des secrets et la politique de sauvegarde sont spécifiques à chaque environnement.

---

## Focus du workflow LazyingArt

Ce fork privilégie mon flux personnel sur **lazying.art** :

- 🎨 branding personnalisé (thème LAB / panda)
- 📱 expérience dashboard/chat optimisée pour mobile
- 📨 variantes du pipeline automail (modes déclenchés par règles, sauvegarde assistée par codex)
- 🧹 scripts personnels de nettoyage et de classification des expéditeurs
- 🗂️ routage Notes/Rappels/Calendar adapté à une utilisation quotidienne réelle

Espace de travail d’automatisation (local) :

- `~/.openclaw/workspace/automation/`
- Références de scripts dans le dépôt : `references/lab-scripts-and-philosophy.md`
- Prompt tools codex dédiées : `scripts/prompt_tools/`

---

## Philosophie orchestrale

L’orchestration LAB suit une règle simple :

Décomposer les objectifs complexes en exécution déterministe + chaînes de prompt tools ciblées.

- Les scripts déterministes gèrent le pipeline fiable : planification, routage des fichiers, répertoires d’exécution, retries, et transfert des sorties.
- Les prompt tools gèrent l’intelligence adaptative : planification, triage, synthèse de contexte et prise de décision en cas d’incertitude.
- Chaque étape produit des artefacts réutilisables pour que les outils suivants composent des notes/emails finaux plus robustes sans repartir de zéro.

Chaînes orchestrales principales :

- Chaîne d’entrepreneuriat :
  ingestion du contexte entreprise -> intelligence marché/financement/universitaire/légale -> actions de croissance concrètes.
- Chaîne auto-mail :
  triage des mails entrants -> politique de skip prudente pour les messages peu utiles -> actions structurées Notes/Reminders/Calendar.
- Chaîne de recherche web :
  capture des pages de résultats -> lectures profondes ciblées avec capture de screenshot/extraction de contenu -> synthèse appuyée sur des preuves.

---

## Prompt tools dans LAB

Les prompt tools sont modulaires, composables et orientées orchestration.
Elles peuvent fonctionner seules ou reliées en étapes dans un workflow plus large.

- Opérations de lecture/sauvegarde :
  créer et mettre à jour les sorties Notes, Reminders et Calendar pour les opérations AutoLife.
- Opérations de capture/lecture :
  capturer les pages de recherche et leurs pages liées, puis extraire du texte structuré pour l’analyse aval.
- Opérations de connexion d’outils :
  appeler des scripts déterministes, échanger des artefacts entre étapes et conserver la continuité du contexte.

Emplacement principal :

- `scripts/prompt_tools/`

---

## Exemples

### Exemple : passerelle locale uniquement

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Exemple : demander à l’agent de préparer une planification quotidienne

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

### Exemple : exécution dans Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Notes de développement

- Runtime de base : Node `>=22.12.0`.
- Baseline gestionnaire de paquets : `pnpm@10.23.0` (`packageManager`).
- Contrôles qualité courants :

```bash
pnpm check          # format + vérifications TS + lint
pnpm build          # build de la sortie dist
pnpm test           # suite de tests
pnpm test:coverage  # exécution avec couverture
```

- CLI en dev : `pnpm openclaw ...`
- Boucle TS : `pnpm dev`
- Les commandes UI sont proxifiées via les scripts racine (`pnpm ui:build`, `pnpm ui:dev`).

Commandes de tests étendus courantes dans ce dépôt :

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Aides de dev supplémentaires :

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Note d’hypothèse :

- Les commandes de build/run des apps mobile/macOS existent dans `package.json` (`ios:*`, `android:*`, `mac:*`) mais les exigences de signature et de provisioning sont spécifiques à l’environnement et pas entièrement documentées dans ce README.

---

## Dépannage

### Passerelle inaccessible sur `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Vérifiez les collisions de port et les conflits de daemon. Si vous utilisez Docker, vérifiez le port mappé côté hôte et la santé du service.

### Problèmes d’authentification ou de configuration de canaux

- Revalidez les valeurs de `.env` par rapport à `.env.example`.
- Vérifiez qu’au moins une clé de modèle est configurée.
- Vérifiez les tokens de canaux uniquement pour les canaux réellement activés.

### Problèmes de build ou d’installation

- Relancez `pnpm install` avec Node `>=22.12.0`.
- Recompilez avec `pnpm ui:build && pnpm build`.
- Si des dépendances natives optionnelles manquent, vérifiez les logs d’installation pour la compatibilité de `@napi-rs/canvas` / `node-llama-cpp`.

### Vérifications santé générales

Utilisez `openclaw doctor` pour détecter les dérives de migration/sécurité/configuration.

### Diagnostics utiles

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Intégrations de l’écosystème LAB

LAB regroupe mes dépôts IA produit/recherche dans une couche opérationnelle unique pour la création, la croissance et l’automatisation.

Profil :

- https://github.com/lachlanchen?tab=repositories

Dépôts intégrés :

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (rédaction automatique de romans)
- `AutoAppDev` (développement d’applications automatisé)
- `OrganoidAgent` (plateforme de recherche organoïde avec vision modeles foundation + LLMs)
- `LazyEdit` (édition vidéo assistée par IA : sous-titrage/transcription/temps forts/méta-données/sous-titres)
- `AutoPublish` (pipeline de publication automatique)

Objectifs d’intégration LAB concrets :

- Rédiger automatiquement des romans
- Développer automatiquement des applications
- Monter automatiquement des vidéos
- Publier automatiquement les résultats
- Analyser automatiquement des organoïdes
- Gérer automatiquement les opérations email

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

Axes prévus pour ce fork LAB (roadmap de travail) :

- Renforcer la fiabilité de l’automail avec une classification expéditeur/règle plus stricte.
- Améliorer la composition des étapes orchestrales et la traçabilité des artefacts.
- Renforcer le mobile-first et l’UX de gestion distante de la passerelle.
- Approfondir les intégrations avec les dépôts de l’écosystème LAB pour une production automatisée de bout en bout.
- Continuer à durcir les valeurs par défaut de sécurité et l’observabilité pour l’automatisation non supervisée.

---

## Contribution

Ce dépôt suit des priorités LAB personnelles tout en réutilisant l’architecture centrale d’OpenClaw.

- Lire [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Consulter la documentation amont : https://docs.openclaw.ai
- Pour les questions de sécurité, voir [`SECURITY.md`](SECURITY.md)

En cas d’incertitude sur un comportement spécifique à LAB, conservez le comportement existant et documentez les hypothèses dans vos notes de PR.

---

## Remerciements

LazyingArtBot est basé sur **OpenClaw** :

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Merci aux mainteneurs et à la communauté OpenClaw pour la plateforme de base.

---

## Licence

MIT (identique à l’amont quand applicable). Voir `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
