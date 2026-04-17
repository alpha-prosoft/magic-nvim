To verify UI changes using Playwright via nREPL. Server URL is in `.web-url`. nREPL port is in `.nrepl-port`.

Use `rep` (nREPL client at ~/.local/bin/rep) to send Playwright commands. It reads `.nrepl-port` automatically.

## Workflow

1. Load helpers: `rep '(require (quote [testing.repl :refer [page restart stop]]))'`
2. Navigate to the page you changed: `rep '(.navigate @page "URL")'`
3. Assert elements exist using locators: `rep '(.textContent (.locator @page "CSS_SELECTOR"))'`
4. Chain it all: `rep '(require (quote [testing.repl :refer [page restart stop]]))' '(.navigate @page "URL")' '(.textContent (.locator @page "h1"))'`

## Key commands

| Command | What it does |
|---|---|
| `(.navigate @page "URL")` | Go to page |
| `(.locator @page "selector")` | Find element |
| `(.textContent (.locator @page "sel"))` | Get text |
| `(restart)` | Fresh browser |
| `(stop)` | Close everything |

## Auth

Test user: `test-admin@dev01.alpha-prosoft.com`. Password in AWS Param Store at `/dev01/test-admin_dev01_alpha-prosoft_com/password`.
