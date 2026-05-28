from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    app_name: str
    device: str
    mock_mode: bool


class ModelInfo(BaseModel):
    name: str
    task: str
    weight_path: str
    config_path: str
    description: str
    input_type: str
    is_default: bool
    weight_exists: bool = False


class ModelListResponse(BaseModel):
    success: bool
    models: list[ModelInfo]
    default_model: str


class DenoiseJsonResponse(BaseModel):
    success: bool
    model_used: str
    input_filename: str
    output_filename: str
    output_url: str
    processing_time_ms: float


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    details: str | None = None
