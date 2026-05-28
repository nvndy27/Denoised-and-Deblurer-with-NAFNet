import shutil
from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile

from app.config import ALLOWED_EXTENSIONS, ALLOWED_IMAGE_TYPES


def ensure_parent_dir(path: str | Path) -> None:
    """Create parent directory for a file path."""
    Path(path).parent.mkdir(parents=True, exist_ok=True)


def get_file_extension(filename: str) -> str:
    """Return lowercase file extension."""
    return Path(filename or "").suffix.lower()


def generate_unique_filename(original_filename: str, suffix: str = "") -> str:
    """Create an UUID filename and never reuse the uploaded name."""
    ext = suffix if suffix else get_file_extension(original_filename)
    if not ext:
        ext = ".png"
    if not ext.startswith("."):
        ext = f".{ext}"
    return f"{uuid4().hex}{ext.lower()}"


async def validate_upload_image(upload_file: UploadFile, max_size_mb: int = 10) -> None:
    """Validate extension, content type, and size without consuming the upload."""
    ext = get_file_extension(upload_file.filename or "")
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Only jpg, jpeg, png, webp images are allowed")
    if upload_file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Unsupported content type: {upload_file.content_type}")

    current_pos = upload_file.file.tell()
    upload_file.file.seek(0, 2)
    size_bytes = upload_file.file.tell()
    upload_file.file.seek(current_pos)
    if size_bytes > max_size_mb * 1024 * 1024:
        raise HTTPException(status_code=413, detail=f"Image is larger than {max_size_mb} MB")


def save_upload_file(upload_file: UploadFile, destination_path: str | Path) -> Path:
    """Save UploadFile to destination without overwriting existing files."""
    destination = Path(destination_path)
    ensure_parent_dir(destination)
    if destination.exists():
        raise FileExistsError(f"Destination already exists: {destination}")
    upload_file.file.seek(0)
    with destination.open("wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    return destination
