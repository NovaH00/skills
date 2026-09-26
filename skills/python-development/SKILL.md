---
name: python-development
description: Standards and best practices for modern Python development. Enforces Astral tools (uv for package management, ty for type checking, ruff for linting and formatting) and pyproject.toml for dependency and configuration management. Use when creating, configuring, structuring, or maintaining Python projects.
---

# Modern Python Development Skill

Standardize Python projects around the modern Astral toolchain and declarative project configuration.

## Core Directives

1. **Package Manager**: Use `uv` by Astral for project initialization, virtual environments, tool execution, and dependency resolution.
2. **Type Checker**: Use `ty` by Astral for fast, incremental type checking and Language Server Protocol support.
3. **Linter & Formatter**: Use `ruff` by Astral for code linting, import sorting, and code formatting.
4. **Configuration Standard**: Store all project metadata, dependencies, and tool settings in `pyproject.toml`. Do not use `requirements.txt`, `setup.py`, `setup.cfg`, or `Pipfile`.

---

## 1. Project & Dependency Management (`uv`)

### Dependency Management Rules
- Use `pyproject.toml` as the single source of truth for dependencies.
- Never manually create or edit `requirements.txt`.
- Track lockfiles with `uv.lock` in source control for reproducible builds.
- Execute project commands inside virtual environments via `uv run`.

### Standard Workflow Commands

| Action | Command | Purpose |
|---|---|---|
| Initialize project | `uv init <project-name>` | Create a new project with modern `pyproject.toml` |
| Add dependency | `uv add <package>` | Add dependency to `[project.dependencies]` and update `uv.lock` |
| Add dev dependency | `uv add --dev <package>` | Add tool to `[dependency-groups.dev]` |
| Remove dependency | `uv remove <package>` | Remove dependency and clean up `uv.lock` |
| Sync environment | `uv sync` | Install exact dependencies defined in `uv.lock` |
| Run tool / command | `uv run <command>` | Run command inside the project virtual environment |
| Ephemeral tool run | `uvx <tool> [args]` | Run a tool without installing it into the project |

---

## 2. Type Checking (`ty`)

### Type Checking Directives
- Use `ty` as the primary static type checker for all Python code.
- Run `ty check` locally and in continuous integration pipelines.
- Write modern Python type annotations (Python 3.10+):
  - Use pipe unions (`str | None`) instead of `Optional[str]` or `Union[str, None]`.
  - Use built-in generic collections (`list[str]`, `dict[str, int]`) instead of `typing.List` or `typing.Dict`.
  - Type-annotate all function signatures (parameters and return types).

### Standard `ty` Commands

```bash
# Run type check across the workspace
uv run ty check

# Run type check in continuous watch mode during development
uv run ty check --watch

# Run directly via uvx if ty is not in the project dependencies
uvx ty check
```

---

## 3. Linting and Formatting (`ruff`)

### Linting and Formatting Directives
- Replace `flake8`, `black`, `isort`, `autoflake`, and `pylint` with `ruff`.
- Format code before committing using `ruff format`.
- Lint and apply safe autofixes using `ruff check --fix`.
- Configure rule selections and exclusions inside `pyproject.toml`.

### Standard `ruff` Commands

```bash
# Check code for lint violations
uv run ruff check

# Check and automatically fix safe lint violations
uv run ruff check --fix

# Format all files in project
uv run ruff format

# Verify formatting without altering files (useful for CI)
uv run ruff format --check
```

---

## 4. `pyproject.toml` Template

Every Python project must use a standard `pyproject.toml` following PEP 621 and Astral tool specifications:

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description goes here"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
    "httpx>=0.28.0",
    "pydantic>=2.10.0",
]

[dependency-groups]
dev = [
    "pytest>=8.3.0",
    "pytest-cov>=6.0.0",
    "ruff>=0.9.0",
    "ty>=0.1.0",
]

[tool.ruff]
target-version = "py311"
line-length = 88

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort (import sorting)
    "UP",     # pyupgrade (modern syntax upgrades)
    "B",      # flake8-bugbear
    "SIM",    # flake8-simplify
    "RUF",    # Ruff-specific rules
]
ignore = []

[tool.ruff.lint.isort]
known-first-party = ["my_project"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.ty]
# Configuration options for ty type checker
```

---

## 5. Standard Project Directory Structure

Use feature-based packaging or clean `src/` layout:

```text
my-project/
├── .gitignore
├── pyproject.toml
├── uv.lock
├── README.md
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── core/
│       │   ├── __init__.py
│       │   └── config.py
│       └── main.py
└── tests/
    ├── __init__.py
    └── test_main.py
```

---

## 6. Daily Development Loop

When developing or reviewing Python code, follow this verification loop:

1. **Install and synchronize dependencies**:
   ```bash
   uv sync
   ```
2. **Format source code**:
   ```bash
   uv run ruff format
   ```
3. **Lint and fix issues**:
   ```bash
   uv run ruff check --fix
   ```
4. **Validate types**:
   ```bash
   uv run ty check
   ```
5. **Run test suite**:
   ```bash
   uv run pytest
   ```
