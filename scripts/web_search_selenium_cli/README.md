# web_search_selenium_cli

Dedicated local toolchain for Selenium-based web search tests.

## Paths

- `search_cli.py` : Python CLI that opens a browser and runs a query.
- `run_search.sh` : Wrapper to execute `search_cli.py` inside a conda env (default `clawbot`).
- `install_chromedriver.sh` : Download and unpack the provided ChromeDriver URL.

## Setup

```bash
# Optional: install Selenium in clawbot env
conda activate clawbot
pip install selenium
```

Install driver (only once):

```bash
scripts/web_search_selenium_cli/install_chromedriver.sh
```

## Usage examples

```bash
# Use default clawbot env, visible browser
scripts/web_search_selenium_cli/run_search.sh "openai cookbook" --engine google --results 5

# Headless mode
scripts/web_search_selenium_cli/run_search.sh --env clawbot --headless --engine duckduckgo --results 5 --query "lightmind"
```

### JSON output

```bash
scripts/web_search_selenium_cli/run_search.sh --engine google --output json "news today"
```

The default driver cache is `~/.local/share/web-search-selenium/chromedriver`.

You can use a specific driver path with `--driver`.
