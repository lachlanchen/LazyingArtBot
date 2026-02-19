# Resource Analysis Prompt Tool

This tool turns local operational files into structured, reusable context for downstream
prompt chains.

## Script

- `orchestral/prompt_tools/prompt_resource_analysis.sh`
- Prompt: `orchestral/prompt_tools/resource_analysis_prompt.md`
- Output schema: `orchestral/prompt_tools/resource_analysis_schema.json`

## Example (Lightmind)

```bash
orchestral/prompt_tools/prompt_resource_analysis.sh \
  --company "Lightmind" \
  --resource-root "/Users/lachlan/Library/Containers/com.tencent.WeWorkMac/Data/WeDrive/LightMind Tech Ltd./LightMind Tech Ltd./LightMind_Confidential" \
  --resource-root "/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input" \
  --resource-root "/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output" \
  --output-dir "/Users/lachlan/.openclaw/workspace/AutoLife/MetaNotes/Companies/Lightmind/pipeline_runs/$(date +%Y%m%d-%H%M%S)" \
  --markdown-output "/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output/ResourceAnalysis/$(date +%Y%m%d-%H%M%S)" \
  --model "gpt-5.1-codex-mini" \
  --reasoning "medium"
```

## What the script produces

1. Builds a manifest per resource root (`status`, `file_count`, `total_bytes`, sample files, snippets).
2. Calls Codex with strict JSON schema.
3. Persists:
   - `latest-result.json` in the codex output dir.
   - multiple markdown notes in the requested `--markdown-output` folder.

Downstream chains should use these markdown outputs as direct context so prompts can reference
real files and operational history without repeating full scans every run.

## Company-agnostic reuse

The tool is reusable for any company: change `--company` and resource roots only.
For example:

- one set for confidential docs,
- one set for project Inputs,
- one set for outputs/logs.

If you prefer a single reusable entrypoint, use:

```bash
orchestral/scripts/run_resource_analysis.sh \
  --company "MyCo" \
  --resource-root "/abs/path/to/confidential" \
  --resource-root "/abs/path/to/input"
```

It auto-generates a run folder:

- `~/Documents/LazyingArtBotIO/MyCo/Output/ResourceAnalysis/<RUN_ID>`
