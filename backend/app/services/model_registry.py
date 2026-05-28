from pathlib import Path
from typing import Any

from app.config import BASE_DIR, DEFAULT_MODEL_NAME

models: dict[str, dict[str, Any]] = {
    "nafnet_sidd_width32": {
        "name": "nafnet_sidd_width32",
        "task": "denoise",
        "weight_path": "weights/nafnet_sidd_width32.pth",
        "config_path": "NAFNet/NAFNet-main/options/test/SIDD/NAFNet-width32.yml",
        "description": "NAFNet SIDD denoising model, width 32",
        "input_type": "rgb",
        "is_default": True,
    },
    "nafnet_gopro_width64": {
        "name": "nafnet_gopro_width64",
        "task": "deblur",
        "weight_path": "weights/nafnet_gopro_width64.pth",
        "config_path": "NAFNet/NAFNet-main/options/test/GoPro/NAFNet-width64.yml",
        "description": "NAFNet GoPro deblurring model, width 64",
        "input_type": "rgb",
        "is_default": False,
    },
}


def _resolve(relative_path: str) -> Path:
    return BASE_DIR / relative_path


def _with_status(model: dict[str, Any]) -> dict[str, Any]:
    item = dict(model)
    item["weight_exists"] = _resolve(item["weight_path"]).exists()
    item["config_exists"] = _resolve(item["config_path"]).exists()
    return item


def get_available_models() -> list[dict[str, Any]]:
    """Return registered models with weight/config status."""
    return [_with_status(model) for model in models.values()]


def get_default_model() -> dict[str, Any]:
    """Return default model config."""
    if DEFAULT_MODEL_NAME in models:
        return _with_status(models[DEFAULT_MODEL_NAME])
    for model in models.values():
        if model.get("is_default"):
            return _with_status(model)
    return _with_status(next(iter(models.values())))


def get_model_config(model_name: str | None) -> dict[str, Any]:
    """Return selected model config or default config."""
    if not model_name:
        return get_default_model()
    if model_name not in models:
        raise ValueError(f"Unknown model '{model_name}'. Available: {', '.join(models)}")
    return _with_status(models[model_name])


def model_weight_exists(model_name: str | None) -> bool:
    """Check if selected model checkpoint exists."""
    return bool(get_model_config(model_name)["weight_exists"])


def model_config_exists(model_name: str | None) -> bool:
    """Check if selected model YAML config exists."""
    return bool(get_model_config(model_name)["config_exists"])
