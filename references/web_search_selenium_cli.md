# Web Search Selenium CLI (Reference)

This reference documents a dedicated Selenium-based web search CLI added under `scripts/web_search_selenium_cli/`.

## Added Files

- `scripts/web_search_selenium_cli/search_cli.py`
  - Selenium-powered CLI search tool.
  - Supports engines: `google`, `duckduckgo`, `bing`.
  - Default output is text; optional JSON output via `--output json`.
  - Supports visible browser by default and optional `--headless` mode.
  - Can fetch and use a local ChromeDriver via `--install-driver`.

- `scripts/web_search_selenium_cli/run_search.sh`
  - Wrapper that runs the search CLI inside conda env `clawbot` by default.
  - `--env <name>` overrides conda env.
  - Uses `conda run -n <env>` to keep tool isolated.

- `scripts/web_search_selenium_cli/install_chromedriver.sh`
  - Downloads and extracts ChromeDriver from:
    - `https://storage.googleapis.com/chrome-for-testing-public/145.0.7632.77/mac-x64/chromedriver-mac-x64.zip`
  - Default install path: `~/.local/share/web-search-selenium`

- `scripts/web_search_selenium_cli/requirements.txt`
  - Python dependency list (`selenium>=4.18.0`).

- `scripts/web_search_selenium_cli/README.md`
  - Setup and usage notes.

- `.gitmodules`
  - Adds the vendor submodules:
    - `vendor/openai-cookbook`
    - `vendor/SillyTavern-WebSearch-Selenium`

## Quick setup

```bash
# install selenium in clawbot env
conda run -n clawbot pip install -r scripts/web_search_selenium_cli/requirements.txt

# install driver
scripts/web_search_selenium_cli/install_chromedriver.sh
```

## Usage

```bash
# visible browser (default), text output
scripts/web_search_selenium_cli/run_search.sh --engine duckduckgo --results 5 "openai cookbook"

# JSON output
scripts/web_search_selenium_cli/run_search.sh --engine google --output json --results 3 "lightmind"

# run in another conda env
scripts/web_search_selenium_cli/run_search.sh --env clawbot --engine bing --headless --output json "company updates"
```

## Notes

- ChromeDriver lookup is automatic under `~/.local/share/web-search-selenium`.
- If you want a custom driver binary path, pass `--driver <path>`.
