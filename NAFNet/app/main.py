import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import APP_NAME, API_PREFIX, ensure_directories
from app.routes.denoise_routes import router as denoise_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")

app = FastAPI(title=APP_NAME, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=[
        "X-Inference-Time-Ms",
        "X-Processing-Device",
        "X-Quality-Score",
        "X-Input-Size-Bytes",
        "X-Output-Size-Bytes",
        "X-Inference-Mode",
        "X-Model-Used",
        "X-Brightness-In",
        "X-Contrast-In",
        "X-Contrast-Out",
        "X-Lap-Var-In",
        "X-Lap-Var-Out",
        "X-Color-Distortion",
        "x-inference-time-ms",
        "x-processing-device",
        "x-quality-score",
        "x-input-size-bytes",
        "x-output-size-bytes",
        "x-inference-mode",
        "x-model-used",
        "x-brightness-in",
        "x-contrast-in",
        "x-contrast-out",
        "x-lap-var-in",
        "x-lap-var-out",
        "x-color-distortion"
    ]
)


@app.on_event("startup")
def startup_event() -> None:
    """Create required backend folders on startup."""
    ensure_directories()
    
    # Pre-load NAFNet model at startup if mock mode is disabled
    from app.config import USE_MOCK_INFERENCE
    if not USE_MOCK_INFERENCE:
        try:
            from app.services.model_registry import get_default_model
            from app.services.nafnet_service import nafnet_service
            logger = logging.getLogger("app.main")
            logger.info("Pre-loading NAFNet model on startup...")
            model_config = get_default_model()
            nafnet_service._load_model(model_config)
            logger.info("NAFNet model pre-loaded successfully.")
        except Exception as e:
            logger = logging.getLogger("app.main")
            logger.error(f"Failed to pre-load NAFNet model at startup: {e}")


app.include_router(denoise_router, prefix=API_PREFIX)
app.include_router(denoise_router)

