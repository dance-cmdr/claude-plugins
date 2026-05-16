# Adapter: PythonAnywhere

Project-specific configuration for the PythonAnywhere codebase. Referenced by workflow skills (`spec`, `plan`, `dev`, `validate`) for test commands, conventions, and file patterns.

## Test Matrix

| Type | Skill | Direct Command (Parallels VM) |
|------|-------|-------------------------------|
| Unit | `run_django_unit` or `test` | `manage.py test {path} -v2` |
| Nobrowser FT | `run_nobrowser` | `pytest {file} -v` |
| Playwright FT | `run_playwright` | `pytest {file} -v` |
| Browser FT | `run_all` | Selenium via Vagrant VM |

**Scoped validation** (during `/dev`): run unit tests for affected app. Example: if editing `accounts/management/commands/foo.py`, run `accounts.tests.test_foo`.

**Broad validation** (during `/validate`): run full unit suite + relevant nobrowser FTs.

## Lint

- `ruff check --fix` (skip if ruff not available in environment)

## Conventions

- **Specs**: `docs/specs/`
- **ADRs**: `docs/`
- **Test writing**: skills `write_django_unit`, `write_nobrowser`
- **Code review**: skill `code_review` with checklist at `_review/CHECKLIST.md`
- **Import style**: ruff-first, all imports at top of file, grouped stdlib / third-party / project, alphabetical within groups
- **Commit style**: descriptive messages, single logical change per commit
- **Branch naming**: ticket-based (e.g., `PA-541-feature-description`)

## File Patterns

- **Django models**: `server/djangoproject/*/models.py`
- **Management commands**: `server/djangoproject/*/management/commands/`
- **Unit tests**: `server/djangoproject/*/tests/`
- **Nobrowser FTs**: `tests/nobrowser/`
- **Playwright FTs**: `tests/playwright_fts/`
- **Browser FTs**: `tests/browser/fts/`
- **Templates**: `server/djangoproject/templates/`
- **Static files**: `server/djangoproject/static/`

## Environment

- **VM**: Parallels Desktop (Apple Silicon), Ubuntu 24.04 ARM64
- **Python venv**: `$PA_VENV` (default `~/PythonAnywhere/venv39`)
- **Django project root**: `server/djangoproject/`
