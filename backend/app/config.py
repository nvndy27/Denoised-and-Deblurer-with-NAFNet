from pathlib import Path

try:
    import torch
except Exception:  # pragma: no cover
    torch = None

BASE_DIR = Path(__file__).resolve().parents[1]
NAFNET_DIR = BASE_DIR / "NAFNet"
NAFNET_MAIN_DIR = NAFNET_DIR / "NAFNet-main"
WEIGHTS_DIR = BASE_DIR / "weights"
UPLOAD_DIR = BASE_DIR / "uploads"
OUTPUT_DIR = BASE_DIR / "outputs"
LOGS_DIR = BASE_DIR / "logs"

APP_NAME = "NAFNet Denoising API"
API_PREFIX = "/api"
DEFAULT_MODEL_NAME = "nafnet_sidd_width32"
USE_MOCK_INFERENCE = False
DEVICE = "auto"
MAX_IMAGE_SIZE_MB = 10
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "application/octet-stream"}


def get_nafnet_repo_dir() -> Path:
    """Return actual cloned NAFNet repo directory."""
    if (NAFNET_MAIN_DIR / "basicsr").exists():
        return NAFNET_MAIN_DIR
    return NAFNET_DIR


def get_device() -> str:
    """Resolve device: CUDA when available, otherwise CPU."""
    if DEVICE.lower() != "auto":
        return DEVICE
    if torch is not None and torch.cuda.is_available():
        return "cuda"
    return "cpu"


def ensure_directories() -> None:
    """Create runtime directories if they do not exist."""
    for directory in [UPLOAD_DIR, OUTPUT_DIR, WEIGHTS_DIR, LOGS_DIR]:
        directory.mkdir(parents=True, exist_ok=True)
