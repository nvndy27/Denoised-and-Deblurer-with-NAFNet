import time
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, JSONResponse

from app.config import API_PREFIX, APP_NAME, MAX_IMAGE_SIZE_MB, OUTPUT_DIR, UPLOAD_DIR, USE_MOCK_INFERENCE, get_device
from app.services.file_service import generate_unique_filename, save_upload_file, validate_upload_image
from app.services.model_registry import get_available_models, get_default_model, get_model_config, model_weight_exists
from app.services.nafnet_service import nafnet_service

router = APIRouter()


@router.get("/health")
def health_check() -> dict:
    """Health endpoint returning backend status and the device in use."""
    return {"status": "ok", "device": get_device()}


@router.get("/models")
def list_models() -> dict:
    """Return available NAFNet models, their tasks, and availability status."""
    available_models = get_available_models()
    
    result_models = []
    for model in available_models:
        result_models.append({
            "model_id": model["name"],
            "task": model["task"],
            "description": model["description"],
            "available": model["weight_exists"]
        })
        
    return {
        "success": True,
        "default_model": get_default_model()["name"],
        "models": result_models,
    }


async def _save_input_and_make_output(file: UploadFile) -> tuple[Path, Path]:
    await validate_upload_image(file, max_size_mb=MAX_IMAGE_SIZE_MB)
    input_name = generate_unique_filename(file.filename or "input.png")
    output_name = generate_unique_filename(file.filename or "output.png", suffix=".png")
    input_path = UPLOAD_DIR / input_name
    output_path = OUTPUT_DIR / output_name
    save_upload_file(file, input_path)
    return input_path, output_path


@router.post("/restore")
async def restore(
    file: UploadFile = File(...), 
    task: str = Form(default="denoise"),
    model_id: str | None = Form(default=None)
):
    """Restore image (denoise/deblur) and return direct PNG."""
    if not file or not file.filename:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Missing image file", "detail": "No file was uploaded."}
        )
    
    # 1. Validate task and model_id
    if task not in ("denoise", "deblur"):
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Invalid task", "detail": f"Task '{task}' is not supported. Supported: denoise, deblur"}
        )

    if not model_id:
        if task == "deblur":
            model_id = "nafnet_gopro_width64"
        else:
            model_id = "nafnet_sidd_width32"

    if model_id not in ("nafnet_sidd_width32", "nafnet_gopro_width64"):
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Invalid model_id", "detail": f"Model ID '{model_id}' is not supported. Supported: nafnet_sidd_width32, nafnet_gopro_width64"}
        )

    # 2. Check checkpoint existence (HTTP 503 if missing)
    if not model_weight_exists(model_id):
        return JSONResponse(
            status_code=503,
            content={"success": False, "error": "Checkpoint unavailable", "detail": f"Checkpoint file for '{model_id}' not found in backend/weights."}
        )

    try:
        input_path, output_path = await _save_input_and_make_output(file)
        
        # Measure inference time
        start_time = time.perf_counter()
        nafnet_service.restore_image(str(input_path), str(output_path), model_name=model_id)
        inference_time_ms = (time.perf_counter() - start_time) * 1000
        
        if not output_path.exists():
            return JSONResponse(
                status_code=500,
                content={
                    "success": False,
                    "error": "Restoration failed",
                    "detail": "The model failed to generate an output image."
                }
            )

        # Calculate Laplacian variance and image quality metrics
        import cv2
        import numpy as np
        img_in = cv2.imread(str(input_path), cv2.IMREAD_GRAYSCALE)
        img_out = cv2.imread(str(output_path), cv2.IMREAD_GRAYSCALE)
        
        if img_in is not None and img_out is not None:
            if img_in.shape != img_out.shape:
                img_in = cv2.resize(img_in, (img_out.shape[1], img_out.shape[0]), interpolation=cv2.INTER_AREA)
        
        var_in = cv2.Laplacian(img_in, cv2.CV_64F).var() if img_in is not None else 0
        var_out = cv2.Laplacian(img_out, cv2.CV_64F).var() if img_out is not None else 0
        
        # Check for color distortion / clipping artifacts (e.g. green grid artifacts)
        color_distorted = False
        img_in_color = cv2.imread(str(input_path))
        img_out_color = cv2.imread(str(output_path))
        
        if img_in_color is not None and img_out_color is not None:
            if img_in_color.shape != img_out_color.shape:
                img_in_color = cv2.resize(img_in_color, (img_out_color.shape[1], img_out_color.shape[0]), interpolation=cv2.INTER_AREA)
            
            # 1. Check for extreme green spikes (often caused by NAFNet overflow in G channel)
            # In BGR: [..., 0] is Blue, [..., 1] is Green, [..., 2] is Red
            out_green_pixels = (img_out_color[:, :, 1] > 180) & (img_out_color[:, :, 2] < 120) & (img_out_color[:, :, 0] < 120)
            in_green_pixels = (img_in_color[:, :, 1] > 180) & (img_in_color[:, :, 2] < 120) & (img_in_color[:, :, 0] < 120)
            
            green_increase = np.sum(out_green_pixels) - np.sum(in_green_pixels)
            
            # 2. Check for severe hue shifts in bright areas (like yellow flower center turning green/cyan)
            # Convert to HSV to check Hue
            hsv_in = cv2.cvtColor(img_in_color, cv2.COLOR_BGR2HSV)
            hsv_out = cv2.cvtColor(img_out_color, cv2.COLOR_BGR2HSV)
            
            # Bright regions (Value > 150)
            bright_mask = hsv_in[:, :, 2] > 150
            if np.any(bright_mask):
                hue_diff = np.abs(hsv_out[:, :, 0].astype(int) - hsv_in[:, :, 0].astype(int))
                hue_diff = np.minimum(hue_diff, 180 - hue_diff)
                significant_hue_change = np.sum((hue_diff > 20) & bright_mask)
                total_bright_pixels = np.sum(bright_mask)
                if total_bright_pixels > 0 and (significant_hue_change / total_bright_pixels) > 0.05:
                    color_distorted = True
                    
            if green_increase > 100:
                color_distorted = True

        score = 85.0
        if task == "deblur":
            if var_in > 0:
                improvement = (var_out - var_in) / var_in
                score = min(99.0, max(75.0, 75.0 + improvement * 50.0))
            else:
                score = 88.0
        else:
            if var_in > 0:
                reduction = (var_in - var_out) / var_in
                score = min(99.0, max(80.0, 80.0 + reduction * 25.0))
            else:
                score = 90.0

        if color_distorted:
            # Penalize score for visible color artifacts
            score = max(55.0, score - 20.0)

        brightness_in = float(np.mean(img_in)) if img_in is not None else 127.0
        contrast_in = float(np.std(img_in)) if img_in is not None else 40.0
        contrast_out = float(np.std(img_out)) if img_out is not None else 40.0

        input_size = input_path.stat().st_size
        output_size = output_path.stat().st_size

        return FileResponse(
            output_path,
            media_type="image/png",
            filename=output_path.name,
            headers={
                "X-Model-Used": model_id,
                "X-Inference-Mode": "real",
                "X-Inference-Time-Ms": f"{inference_time_ms:.1f}",
                "X-Processing-Device": nafnet_service.device,
                "X-Quality-Score": f"{score:.1f}",
                "X-Input-Size-Bytes": str(input_size),
                "X-Output-Size-Bytes": str(output_size),
                "X-Brightness-In": f"{brightness_in:.1f}",
                "X-Contrast-In": f"{contrast_in:.1f}",
                "X-Contrast-Out": f"{contrast_out:.1f}",
                "X-Lap-Var-In": f"{var_in:.1f}",
                "X-Lap-Var-Out": f"{var_out:.1f}",
                "X-Color-Distortion": "true" if color_distorted else "false",
            },
        )
    except HTTPException as exc:
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "error": "Invalid image", "detail": exc.detail}
        )
    except Exception as exc:
        return JSONResponse(
            status_code=500,
            content={"success": False, "error": "Inference error", "detail": f"An error occurred during inference: {str(exc)}"}
        )
    finally:
        file.file.close()


@router.post("/restore-json")
async def restore_json(
    file: UploadFile = File(...), 
    task: str = Form(default="denoise"),
    model_id: str | None = Form(default=None)
):
    """Return restoration result metadata and output URL."""
    start = time.perf_counter()
    if not file or not file.filename:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Missing image file", "detail": "No file was uploaded."}
        )
        
    # 1. Validate task and model_id
    if task not in ("denoise", "deblur"):
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Invalid task", "detail": f"Task '{task}' is not supported. Supported: denoise, deblur"}
        )

    if not model_id:
        if task == "deblur":
            model_id = "nafnet_gopro_width64"
        else:
            model_id = "nafnet_sidd_width32"

    if model_id not in ("nafnet_sidd_width32", "nafnet_gopro_width64"):
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Invalid model_id", "detail": f"Model ID '{model_id}' is not supported. Supported: nafnet_sidd_width32, nafnet_gopro_width64"}
        )

    # 2. Check checkpoint existence (HTTP 503 if missing)
    if not model_weight_exists(model_id):
        return JSONResponse(
            status_code=503,
            content={"success": False, "error": "Checkpoint unavailable", "detail": f"Checkpoint file for '{model_id}' not found in backend/weights."}
        )

    try:
        input_path, output_path = await _save_input_and_make_output(file)
        nafnet_service.restore_image(str(input_path), str(output_path), model_name=model_id)
        
        if not output_path.exists():
            return JSONResponse(
                status_code=500,
                content={
                    "success": False,
                    "error": "Restoration failed",
                    "detail": "The model failed to generate an output image."
                }
            )

        return {
            "success": True,
            "model_used": model_id,
            "inference_mode": "real",
            "input_filename": input_path.name,
            "output_filename": output_path.name,
            "output_url": f"{API_PREFIX}/outputs/{output_path.name}",
            "processing_time_ms": round((time.perf_counter() - start) * 1000, 2),
        }
    except HTTPException as exc:
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "error": "Invalid image", "detail": exc.detail}
        )
    except Exception as exc:
        return JSONResponse(
            status_code=500,
            content={"success": False, "error": "Inference error", "detail": f"An error occurred during inference: {str(exc)}"}
        )
    finally:
        file.file.close()



@router.get("/outputs/{filename}")
def get_output(filename: str) -> FileResponse:
    """Download generated output image."""
    safe_name = Path(filename).name
    output_path = OUTPUT_DIR / safe_name
    if not output_path.exists():
        raise HTTPException(status_code=404, detail="Output image not found")
    return FileResponse(output_path, media_type="image/png", filename=output_path.name)
