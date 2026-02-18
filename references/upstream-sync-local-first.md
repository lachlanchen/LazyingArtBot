# Upstream Sync (Local-First, Feature-Focused)

This runbook is for pulling updates from `openclaw/openclaw` while keeping LazyingArtBot customizations intact.

## Goal

- Fetch new upstream features and fixes.
- Preserve local product identity and behavior.
- Resolve conflicts in favor of local expectations, then re-apply upstream improvements selectively.

## Protected local surfaces (do not overwrite)

Always treat these as local-first:

- `README.md` (LazyingArt branding/content)
- `README_OPENCLAW.md` (reference snapshot)
- `.github/FUNDING.yml` (sponsor links)
- UI branding/custom UX files (especially under `ui/src/styles/**`, `ui/index.html`, `ui/public/**`)
- Local automation and workflow customizations (for LAB behavior)

## Sync strategy

Use merge-based sync into a dedicated branch, then integrate.

```bash
# 0) Ensure remotes
# origin   -> your fork
# upstream -> openclaw/openclaw

git remote -v

# 1) Start from latest local main
git checkout main
git pull --rebase origin main

# 2) Create sync branch
git checkout -b sync/upstream-YYYYMMDD

# 3) Fetch upstream and merge
git fetch upstream
git merge --no-ff upstream/main
```

## Conflict policy

### 1) Protected files

For protected files, keep local version:

```bash
git checkout --ours README.md README_OPENCLAW.md .github/FUNDING.yml
```

For UI/automation branded files, prefer `--ours` unless a specific upstream fix is required.

### 2) Feature files (default)

For code paths where you want upstream features:

- Resolve conflict manually.
- Start from local implementation intent.
- Port upstream logic into local structure.
- Do **not** blindly take `--theirs` if it breaks local workflow assumptions.

### 3) `.github` and workflows

Keep local CI/release intent first, but import upstream improvements selectively:

- keep local triggers, secrets model, release channels
- adopt upstream reliability/security fixes (permissions, caching, action versions)
- verify fork-safe behavior (no upstream-only secrets or deploy steps)

## Review checklist before merge

- Branding still correct (LAB/panda/lazying.art).
- Automation pipeline behavior unchanged unless intentionally updated.
- Mobile UI customizations still intact.
- Workflow files run in fork context.
- No accidental reintroduction of upstream README/logo text.

## Validation

Run at least:

```bash
pnpm build
pnpm -C ui build
pnpm test
```

(Use targeted tests if full suite is too heavy, but validate touched areas.)

## Finalization

```bash
# Commit conflict resolutions and ports
# (use repo helper for scoped commits)
scripts/committer "chore: sync upstream with local-first conflict policy" <files...>

# Rebase once against current local main if needed
git checkout main
git pull --rebase origin main
git checkout sync/upstream-YYYYMMDD
git rebase main

# Merge back after review
git checkout main
git merge --no-ff sync/upstream-YYYYMMDD
git push origin main
```

## Practical rule

When in doubt: preserve local product behavior first, then port upstream improvements intentionally.
