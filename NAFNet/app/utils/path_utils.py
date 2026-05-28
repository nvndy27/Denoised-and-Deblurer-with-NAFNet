from pathlib import Path

from app.config import settings


def get_project_root() -> Path:
    """Return backend project root."""
    return settings.project_root


def resolve_path(path_value: str | Path) -> Path:
    """Resolve relative paths from backend root."""
    path = Path(path_value)
    return path if path.is_absolute() else get_project_root() / path


def safe_join(base_dir: str | Path, *paths: str) -> Path:
    """Safely join paths and prevent path traversal outside base_dir."""
    base = resolve_path(base_dir).resolve()
    final_path = base.joinpath(*paths).resolve()
    if base != final_path and base not in final_path.parents:
        raise ValueError("Unsafe path detected")
    return final_path
