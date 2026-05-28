import importlib
import logging
import sys
from pathlib import Path
from typing import Any

import numpy as np
import yaml
from PIL import Image

from app.config import get_device, get_nafnet_repo_dir
from app.services.image_service import open_image_rgb, resize_if_too_large, save_image_rgb
from app.services.model_registry import get_model_config

logger = logging.getLogger(__name__)


class NafnetService:
    """Connect FastAPI backend to the cloned backend/NAFNet repository."""

    def __init__(self) -> None:
        self.device = get_device()
        self.nafnet_dir = get_nafnet_repo_dir()
        self.loaded_models: dict[str, Any] = {}
        self._prepare_repo_path()

    def _prepare_repo_path(self) -> None:
        """Add NAFNet folders to sys.path without moving or cloning them."""
        if not self.nafnet_dir.exists():
            logger.warning("NAFNet directory not found: %s", self.nafnet_dir)
            return
        basicsr_dir = self.nafnet_dir / "basicsr"
        for path in [self.nafnet_dir, basicsr_dir]:
            path_str = str(path)
            if path.exists() and path_str not in sys.path:
                sys.path.insert(0, path_str)
        logger.info("Using NAFNet repo: %s", self.nafnet_dir)

    def restore_image(self, input_path: str, output_path: str, model_name: str | None = None) -> str:
        """Restore image (denoise/deblur) using NAFNet. Throw exception if weight/config is missing."""
        model_config = get_model_config(model_name)
        if not model_config["weight_exists"]:
            raise FileNotFoundError(f"Checkpoint file not found: {model_config['weight_path']}")
        if not model_config["config_exists"]:
            raise FileNotFoundError(f"Config file not found: {model_config['config_path']}")
        
        self._run_real_nafnet(input_path, output_path, model_config)
        return model_config["name"]

    def _load_model(self, model_config: dict[str, Any]) -> Any:
        """Lazy-load a NAFNet model from YAML config and checkpoint."""
        name = model_config["name"]
        if name in self.loaded_models:
            return self.loaded_models[name]

        import torch

        config_path = self.nafnet_dir / Path(model_config["config_path"]).relative_to("NAFNet/NAFNet-main")
        weight_path = self.nafnet_dir.parent.parent / model_config["weight_path"]
        
        logger.info("Loading checkpoint from: %s", weight_path)
        logger.info("Target device: %s", self.device)

        with config_path.open("r", encoding="utf-8") as file:
            option = yaml.safe_load(file)

        net_opt = dict(option["network_g"])
        net_opt.pop("type", None)

        # Real NAFNet architecture import from the cloned repository.
        arch_module = importlib.import_module("basicsr.models.archs.NAFNet_arch")
        NAFNet = getattr(arch_module, "NAFNet")
        model = NAFNet(**net_opt)

        checkpoint = torch.load(weight_path, map_location=self.device)
        state_dict = self._extract_state_dict(checkpoint)
        model.load_state_dict(state_dict, strict=False)
        model.to(self.device)
        model.eval()
        self.loaded_models[name] = model
        logger.info("Model %s loaded successfully on %s", name, self.device)
        return model

    def _extract_state_dict(self, checkpoint: Any) -> dict[str, Any]:
        """Support common NAFNet checkpoint formats."""
        if isinstance(checkpoint, dict):
            for key in ["params", "params_ema", "state_dict", "model"]:
                if key in checkpoint and isinstance(checkpoint[key], dict):
                    return checkpoint[key]
        return checkpoint

    def _run_real_nafnet(self, input_path: str, output_path: str, model_config: dict[str, Any]) -> None:
        """Run real PyTorch NAFNet inference with padding/cropping and save PNG output."""
        import torch
        import torch.nn.functional as F
        import time

        start_time = time.perf_counter()

        model = self._load_model(model_config)
        image = resize_if_too_large(open_image_rgb(input_path), max_side=1024)
        array = np.asarray(image).astype(np.float32) / 255.0

        # Calculate padding
        h, w = array.shape[0], array.shape[1]
        factor = 64
        pad_h = (factor - (h % factor)) % factor
        pad_w = (factor - (w % factor)) % factor

        tensor = torch.from_numpy(array).permute(2, 0, 1).unsqueeze(0).to(self.device)
        
        if pad_h > 0 or pad_w > 0:
            if h > pad_h and w > pad_w:
                tensor = F.pad(tensor, (0, pad_w, 0, pad_h), mode='reflect')
            else:
                tensor = F.pad(tensor, (0, pad_w, 0, pad_h), mode='constant', value=0.0)

        with torch.no_grad():
            output = model(tensor)
            if isinstance(output, (list, tuple)):
                output = output[0]
            
            # Crop padding back
            if pad_h > 0 or pad_w > 0:
                output = output[:, :, :h, :w]
            
            output = output.clamp(0, 1).squeeze(0).detach().cpu()

        output_array = (output.permute(1, 2, 0).numpy() * 255.0).round().astype(np.uint8)
        save_image_rgb(Image.fromarray(output_array), output_path)

        inference_time = time.perf_counter() - start_time
        logger.info("Inference time: %.4f seconds", inference_time)


nafnet_service = NafnetService()
