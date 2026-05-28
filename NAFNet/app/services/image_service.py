from pathlib import Path

from PIL import Image, ImageFilter


def open_image_rgb(path: str | Path) -> Image.Image:
    """Open image as RGB."""
    with Image.open(path) as image:
        return image.convert("RGB")


def resize_if_too_large(image: Image.Image, max_side: int = 1024) -> Image.Image:
    """Resize image if longest side is greater than max_side."""
    width, height = image.size
    longest = max(width, height)
    if longest <= max_side:
        return image
    scale = max_side / longest
    new_size = (max(1, int(width * scale)), max(1, int(height * scale)))
    return image.resize(new_size, Image.Resampling.LANCZOS)


def save_image_rgb(image: Image.Image, path: str | Path) -> Path:
    """Save image as PNG RGB."""
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path, format="PNG")
    return output_path


def copy_as_png(input_path: str | Path, output_path: str | Path) -> Path:
    """Convert input image to PNG output."""
    image = resize_if_too_large(open_image_rgb(input_path))
    return save_image_rgb(image, output_path)


def apply_mock_denoise(input_path: str | Path, output_path: str | Path) -> Path:
    """Mock denoise fallback using Pillow smoothing filters."""
    image = resize_if_too_large(open_image_rgb(input_path))
    image = image.filter(ImageFilter.MedianFilter(size=3)).filter(ImageFilter.SMOOTH_MORE)
    return save_image_rgb(image, output_path)


def apply_mock_deblur(input_path: str | Path, output_path: str | Path) -> Path:
    """Mock deblur fallback using Pillow sharpening filters."""
    image = resize_if_too_large(open_image_rgb(input_path))
    image = image.filter(ImageFilter.SHARPEN).filter(ImageFilter.EDGE_ENHANCE)
    return save_image_rgb(image, output_path)
