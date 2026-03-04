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

> 🌍 **État i18n :** `i18n/` existe et contient actuellement des README localisés en arabe, allemand, espagnol, français, japonais, coréen, russe, vietnamien, chinois simplifié et chinois traditionnel. Cette version anglaise reste la source canonique pour les mises à jour incrémentales.

**LazyingArtBot** est ma stack d’assistant IA personnelle pour **lazying.art** :

**LazyingArtBot** est construit sur OpenClaw et adapté à mes flux de travail quotidiens : chat multi-canaux, contrôle local-first, et automatisation e-mail → calendrier/rappels/notes.

| 🔗 Lien           | URL                                          | Objectif                                    |
| ----------------- | -------------------------------------------- | ------------------------------------------- |
| 🌐 Site web       | https://lazying.art                          | Domaine principal et tableau de bord d’état |
| 🤖 Domaine du bot | https://lab.lazying.art                      | Point d’entrée chat et assistant            |
| 🧱 Base amont     | https://github.com/openclaw/openclaw         | Fondation de la plateforme OpenClaw         |
| 📦 Ce dépôt       | https://github.com/lachlanchen/LazyingArtBot | Adaptations spécifiques au LAB              |

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
- [Outils de prompt dans LAB](#outils-de-prompt-dans-lab)
- [Exemples](#exemples)
- [Notes de développement](#notes-de-développement)
- [Dépannage](#dépannage)
- [Intégrations de l’écosystème LAB](#intégrations-de-lécosystème-lab)
- [Installer depuis la source (référence rapide)](#installer-depuis-la-source-référence-rapide)
- [Feuille de route](#feuille-de-route)
- [Contribution](#contribution)
- [Remerciements](#remerciements)
- [❤️ Support](#-support)
- [Contact](#contact)
- [Licence](#licence)

---

## Aperçu

LAB se concentre sur la productivité personnelle concrète :

- ✅ Faire fonctionner un assistant unique sur les canaux de chat que vous utilisez déjà.
- 🔐 Conserver vos données et votre contrôle sur votre propre machine/serveur.
- 📬 Transformer l’e-mail entrant en actions structurées (Calendrier, Rappels, Notes).
- 🛡️ Ajouter des garde-fous pour que l’automatisation reste utile, mais sûre.

En bref : moins de tâches répétitives, une exécution plus fluide.

---

## En bref

| Domaine                      | Référence actuelle dans ce dépôt           |
| ---------------------------- | ------------------------------------------ |
| Runtime                      | Node.js `>=22.12.0`                        |
| Gestionnaire de paquets      | `pnpm@10.23.0`                             |
| CLI principal                | `openclaw`                                 |
| Passerelle locale par défaut | `127.0.0.1:18789`                          |
| Port du pont par défaut      | `127.0.0.1:18790`                          |
| Documentation principale     | `docs/` (Mintlify)                         |
| Orchestration LAB principale | `orchestral/` + `orchestral/prompt_tools/` |
| Emplacement des README i18n  | `i18n/README.*.md`                         |

---

## Fonctionnalités

- 🌐 Runtime assistant multi-canaux avec passerelle locale.
- 🖥️ Interface web et surface de chat pour les opérations locales.
- 🧰 Pipeline d’automatisation piloté par outils (scripts + prompt-tools).
- 📨 Tri des e-mails et conversion en actions Notes, Rappels et Calendrier.
- 🧩 Écosystème de plugins/extensions (`extensions/*`) pour canaux/fournisseurs/intégrations.
- 📱 Interfaces multi-plateformes dans le repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Capacités principales

| Capacité                         | Ce que cela signifie concrètement                                                                                                        |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Runtime assistant multi-canaux   | Passerelle + sessions d’agent entre les canaux que vous activez                                                                          |
| Tableau de bord web / chat       | Surface de contrôle basée sur le navigateur pour les opérations locales                                                                  |
| Workflows pilotés par outils     | Chaînes d’exécution scriptées : shell + fichiers + automation                                                                            |
| Pipeline d’automatisation e-mail | Analyse des e-mails, classification du type d’action, routage vers Notes/Rappels/Calendrier, journalisation des actions pour revue/debug |

Étapes du pipeline conservées du workflow actuel :

- analyser les e-mails entrants
- classer le type d’action
- enregistrer dans Notes / Rappels / Calendrier
- journaliser chaque action pour revue et debugging

---

## Structure du projet

Aperçu de l’organisation du dépôt :

```text
.
├─ src/                 # runtime principal, passerelle, canaux, CLI, infra
├─ extensions/          # plugins optionnels pour canaux/fournisseurs/auth
├─ orchestral/          # orchestration LAB + outils de prompts
├─ scripts/             # scripts build/dev/test/release
├─ ui/                  # package de l’interface web du tableau de bord
├─ apps/                # applications macOS / iOS / Android
├─ docs/                # documentation Mintlify
├─ references/          # références LAB et notes opérationnelles
├─ test/                # suites de tests
├─ i18n/                # variantes localisées des README
├─ .env.example         # modèle d’environnement
├─ docker-compose.yml   # conteneurs passerelle + CLI
├─ README_OPENCLAW.md   # référence README de style upstream
└─ README.md            # ce README orienté LAB
```

Remarques :

- `orchestral/prompt_tools` pointe vers l’implémentation des prompt-tools orchestraux.
- Le dossier racine `i18n/` contient les variantes localisées des README.
- `.github/workflows.disabled/` est présent dans cet instantané ; le comportement CI actif doit être validé avant de s’y fier.

---

## Prérequis

Référentiels runtime et outils de ce dépôt :

- Node.js `>=22.12.0`
- pnpm `10.23.0` de base (voir le champ `packageManager` dans `package.json`)
- Une clé fournisseur de modèle configurée (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Optionnel : Docker + Docker Compose pour la passerelle/CLI en conteneur
- Optionnel pour les builds mobile/mac : toolchains Apple/Android selon la cible

Installation globale optionnelle du CLI (cohérente avec le flux de démarrage rapide) :

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Démarrage rapide

Référence runtime de ce dépôt : **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Puis ouvrez le tableau de bord local et le chat :

- http://127.0.0.1:18789

Pour un accès distant, exposez votre passerelle locale via votre tunnel sécurisé (ex. ngrok/Tailscale) en gardant l’authentification activée.

---

## Installation

### Installer depuis la source

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

Variables de compose généralement requises :

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Utilisation

Commandes courantes :

```bash
# Démarrer et installer le démon utilisateur
openclaw onboard --install-daemon

# Exécuter la passerelle au premier plan
openclaw gateway run --bind loopback --port 18789 --verbose

# Envoyer un message direct via les canaux configurés
openclaw message send --to +1234567890 --message "Hello from LAB"

# Interroger directement l’agent
openclaw agent --message "Create today checklist" --thinking high
```

Boucle de dev (watch) :

```bash
pnpm gateway:watch
```

Développement UI :

```bash
pnpm ui:dev
```

Commandes opérationnelles utiles supplémentaires :
Commandes opérationnelles utiles supplémentaires :

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

La référence de configuration/environnements est répartie entre `.env` et `~/.openclaw/openclaw.json`.

1. Commencez depuis `.env.example`.
2. Définissez l’authentification de la passerelle (`OPENCLAW_GATEWAY_TOKEN` recommandé).
3. Configurez au moins une clé fournisseur de modèle (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Définissez seulement les identifiants de canaux pour les canaux que vous activez.

Notes importantes de `.env.example` conservées depuis le dépôt :

- Priorité des envs : variables d’environnement -> `./.env` -> `~/.openclaw/.env` -> bloc `env` de la config.
- Les valeurs non vides déjà définies dans l’environnement process ne sont pas remplacées.
- Les clés de config comme `gateway.auth.token` peuvent prendre la priorité sur les fallback env.

Base de sécurité minimale avant exposition internet :

- Gardez l’authentification/pairing de la passerelle activés.
- Maintenez des allowlists strictes pour les canaux entrants.
- Traitez chaque message/e-mail entrant comme une entrée non fiable.
- Exécutez avec le principe du moindre privilège et passez en revue les logs régulièrement.

Si vous exposez la passerelle à Internet, exigez une authentification token/mot de passe et une configuration proxy de confiance.

---

## Modes de déploiement

| Mode                  | Le mieux pour                                | Commande typique                                                    |
| --------------------- | -------------------------------------------- | ------------------------------------------------------------------- |
| Premier plan local    | Développement et débogage                    | `openclaw gateway run --bind loopback --port 18789 --verbose`       |
| Démon local           | Usage personnel quotidien                    | `openclaw onboard --install-daemon`                                 |
| Docker                | Runtime isolé et déploiements reproductibles | `docker compose up -d`                                              |
| Hôte distant + tunnel | Accès en dehors du réseau local              | Exécuter la passerelle + tunnel sécurisé, en gardant l’auth activée |

Hypothèse : le durcissement production-level d’un reverse-proxy, la rotation des secrets et la politique de sauvegarde sont spécifiques au déploiement et doivent être définis par environnement.

---

## Focus du workflow LazyingArt

Ce fork priorise mon flux personnel sur **lazying.art** :

- 🎨 branding personnalisé (LAB / thème panda)
- 📱 expérience dashboard/chat optimisée mobile
- 📨 variantes de pipeline automail (règles déclenchées, modes de sauvegarde assistés par codex)
- 🧹 scripts de nettoyage perso et de classification des expéditeurs
- 🗂️ routage notes/rappels/calendrier ajusté pour une utilisation quotidienne réelle

Espace de travail d’automatisation (local) :

- `~/.openclaw/workspace/automation/`
- Références de script dans le dépôt : `references/lab-scripts-and-philosophy.md`
- Outils de prompt dédiés à Codex : `orchestral/prompt_tools/`

---

## Philosophie orchestrale

L’orchestration LAB suit une règle de conception :
décomposer les objectifs difficiles en exécution déterministe + chaînes de prompt-tools ciblées.

- Les scripts déterministes gèrent les raccordements fiables :
  planification, routage de fichiers, répertoires d’exécution, retries et passage de sortie.
- Les prompt tools gèrent l’intelligence adaptative :
  planification, triage, synthèse de contexte et prise de décision dans l’incertitude.
- Chaque étape produit des artefacts réutilisables pour que les outils aval composent de meilleures notes/e-mails finaux sans repartir de zéro.

Chaînes orchestrales principales :

- Chaîne d’entrepreneuriat d’entreprise :
  ingestion du contexte entreprise -> intelligence marché/financement/academique/légale -> actions de croissance concrètes.
- Chaîne d’auto-mail :
  triage des e-mails entrants -> politique de skip prudente pour les courriers peu utiles -> actions structurées Notes/Rappels/Calendrier.
- Chaîne de recherche web :
  capture de page de résultats -> lectures approfondies ciblées avec capture d’écran/extraction de contenu -> synthèse basée sur preuves.

---

## Outils de prompt dans LAB

Les prompt tools sont modulaires, composables et pensés d’abord pour l’orchestration.
Ils peuvent fonctionner indépendamment ou comme étapes chaînées dans un workflow plus large.

- Opérations de lecture/enregistrement :
  création et mise à jour de Notes, Rappels et sorties Calendrier pour les opérations AutoLife.
- Opérations capture/lecture :
  capturer pages de recherche et pages liées, puis extraire un texte structuré pour l’analyse en aval.
- Opérations de connexion d’outils :
  appeler des scripts déterministes, échanger des artefacts entre étapes et maintenir la continuité du contexte.

Emplacement principal :

- `orchestral/prompt_tools/`

---

## Exemples

### Exemple : passerelle local-only

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Exemple : demander à l’agent de traiter la planification quotidienne

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Exemple : compilation source + boucle watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Exemple : exécuter dans Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Notes de développement

- Baseline runtime : Node `>=22.12.0`.
- Package manager baseline : `pnpm@10.23.0` (champ `packageManager`).
- Gateaux qualité courants :

```bash
pnpm check          # format + vérifications ts + lint
pnpm build          # générer dist
pnpm test           # suite de tests
pnpm test:coverage  # exécution couverture
```

- CLI en dev : `pnpm openclaw ...`
- Boucle TS : `pnpm dev`
- Les commandes du package UI sont proxifiées via les scripts racine (`pnpm ui:build`, `pnpm ui:dev`).

Commandes e2e prolongées courantes dans ce dépôt :

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

- Les commandes de build/run d’apps mobiles/mac existent dans `package.json` (`ios:*`, `android:*`, `mac:*`) mais les exigences de signing/provisioning sont spécifiques à l’environnement et pas pleinement documentées dans ce README.

---

## Dépannage

### Passerelle inaccessible sur `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Vérifiez les collisions de port et les conflits de daemons. Si vous utilisez Docker, vérifiez le port hôte mappé et l’état de santé du service.

### Problèmes d’auth ou de configuration de canaux

- Re-vérifiez les valeurs de `.env` avec `.env.example`.
- Assurez-vous qu’au moins une clé de modèle est configurée.
- Vérifiez les jetons de canal uniquement pour les canaux effectivement activés.

### Problèmes de build ou d’installation

- Relancez `pnpm install` avec Node `>=22.12.0`.
- Rebuild avec `pnpm ui:build && pnpm build`.
- Si des dépendances natives optionnelles manquent, consultez les logs d’installation pour la compatibilité `@napi-rs/canvas` / `node-llama-cpp`.

### Vérifications de santé générales

Utilisez `openclaw doctor` pour détecter les dérives de migration/sécurité/config.

### Diagnostics utiles

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Intégrations de l’écosystème LAB

LAB regroupe mes autres dépôts IA et recherche dans une couche d’exploitation unique pour la création, la croissance et l’automatisation.

Profil :

- https://github.com/lachlanchen?tab=repositories

Dépôts intégrés :

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (rédaction automatique de romans)
- `AutoAppDev` (développement d’applications automatique)
- `OrganoidAgent` (plateforme de recherche sur les organoïdes avec modèles de vision de fondation + LLM)
- `LazyEdit` (édition vidéo assistée par IA : captions/transcription/highlights/métadonnées/sous-titres)
- `AutoPublish` (pipeline de publication automatique)

Objectifs d’intégration pratique du LAB :

- Rédaction automatique de romans
- Développement automatique d’applications
- Édition automatique de vidéos
- Publication automatique des résultats
- Analyse automatique d’organoïdes
- Gestion automatique des e-mails

---

## Installer depuis la source (référence rapide)

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

Directions planifiées pour ce fork LAB (feuille de route de travail) :

- Renforcer la fiabilité de l’automail avec une classification expéditeur/règle plus stricte.
- Améliorer la composabilité des étapes orchestrales et la traçabilité des artefacts.
- Renforcer l’UX mobile-first et la gestion à distance du gateway.
- Approfondir les intégrations avec les dépôts de l’écosystème LAB pour une production automatisée de bout en bout.
- Poursuivre le durcissement des paramètres de sécurité et d’observabilité pour l’automatisation non supervisée.

---

## Contribution

Ce dépôt suit les priorités personnelles du LAB tout en reprenant l’architecture principale d’OpenClaw.

- Lisez [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Consultez la documentation en amont : https://docs.openclaw.ai
- Pour les problèmes de sécurité, consultez [`SECURITY.md`](SECURITY.md)

Si vous n’êtes pas sûr du comportement spécifique au LAB, préservez le comportement existant et documentez les hypothèses dans les notes de PR.

---

## Remerciements

LazyingArtBot s’appuie sur **OpenClaw** :

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Remerciements aux mainteneurs et à la communauté OpenClaw pour la plateforme principale.

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Site web : https://lazying.art
- Dépôt : https://github.com/lachlanchen/LazyingArtBot
- Suivi des issues : https://github.com/lachlanchen/LazyingArtBot/issues
- Problèmes de sécurité ou de sûreté : https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## Licence

MIT (comme en amont lorsque applicable). Voir `LICENSE`.
