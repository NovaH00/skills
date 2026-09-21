# Project Structure

Organize FastAPI applications by feature under a `src/` layout. Each feature groups its routes, schemas, business logic, and data access.

## Layout Overview

```text
src/
├── __init__.py
├── feature_1/
├── feature_2/
├── ...
├── feature_n/
├── main.py
├── config.py
└── ...
```

> [!NOTE]
> Use valid Python package names (snake_case, e.g. `users`, `auth`, `items`) for feature directories so modules can be imported directly.

### Root Files

* `main.py`: Entry point of the application. Instantiates the `FastAPI` app and includes feature routers.
* `config.py`: Application configuration and environment variable loading (for example with `pydantic-settings`).

## Feature Directory Structure

Each feature encapsulates its domain components:

```text
src/<feature_name>/
├── __init__.py
├── router.py
├── schemas.py
├── models.py
├── services.py
├── dependencies.py
├── exceptions.py
├── repository.py
└── constants.py
```

### Component Responsibilities

| File | Responsibility | Example Content |
| :--- | :--- | :--- |
| `__init__.py` | Marks directory as a Python package | Often empty or exports public symbols |
| `router.py` | `APIRouter` definition and route handlers | `router = APIRouter(...)`, `@router.get("/")` |
| `schemas.py` | Pydantic models for request/response serialization | `UserCreate`, `UserRead`, `UserUpdate` |
| `models.py` | Core domain entities (can also define ORM/database models) | Domain classes (`User`, `Account`) or SQLModel tables |
| `services.py` | Business logic and orchestration | Keeps endpoint handlers thin |
| `dependencies.py` | Feature-specific dependencies | `Annotated[..., Depends(...)]` helpers |
| `exceptions.py` | Custom domain and HTTP exceptions | Domain error classes and handlers |
| `repository.py` | Data access and database query abstraction | CRUD functions and database queries |
| `constants.py` | Feature enums, constants, regex patterns | Feature-level defaults and status enums |

### `models.py` vs `schemas.py`

* `schemas.py` defines API boundary data. Use it for request validation and response formatting.
* `models.py` defines core domain entities. It holds internal business representations. When an application uses a database, these domain entities can also serve as ORM or SQLModel tables. Do not avoid `models.py` when an application lacks a database. Use it whenever domain logic requires internal entity models.

## Guidelines

1. **Create files only when needed**:
   Do not add boilerplate files without purpose. For instance:
   * If a feature uses only standard `fastapi.HTTPException`, omit `exceptions.py`.
   * If a feature does not query a database, omit `repository.py`.
   * If a feature operates entirely on API schemas without separate domain entities, omit `models.py`.
   * If a feature does not require custom dependencies, omit `dependencies.py`.

2. **Keep handlers thin**:
   `router.py` should only handle HTTP concerns (request parsing, response status codes, route definitions). Delegate business rules and data transformations to `services.py`.

3. **Define router parameters on the router**:
   Declare `prefix`, `tags`, and common dependencies directly on the feature's `APIRouter` in `router.py`. In `main.py`, include the router cleanly with `app.include_router(feature_router)`.
