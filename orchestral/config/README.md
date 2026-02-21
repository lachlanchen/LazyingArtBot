# Orchestral Configuration

This folder holds canonical defaults and path references used for orchestration documentation.

Current configuration is intentionally lightweight and does not replace per-script environment variables.
Use these values as a single place to align external wrappers and installs.

- `run_pipeline_workspace` style defaults remain in each pipeline script.
- `orchestral/actors/automail2note/install_automail2note_workspace.sh` targets:
  - `~/.openclaw/workspace/automation`
  - `~/Library/Application Scripts/com.apple.mail`

Recommended custom overrides are done through environment variables in your local launcher:

- `SRC_MAIL_APP`
- `DEST_DIR`
- `TARGET_DIR`
