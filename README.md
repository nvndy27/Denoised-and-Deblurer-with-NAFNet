# NAFNet Image Restoration Web App

Web application for image restoration using **NAFNet**.
The app supports two main tasks:

* **Denoise**: remove noise from noisy smartphone images.
* **Deblur**: restore blurred images and improve sharpness.

The system uses a **Flutter Web frontend** and a **Python backend** running pretrained **NAFNet checkpoints**.

---

## 1. Project Overview

This project demonstrates an end-to-end image restoration pipeline:

```text
User uploads image
        ↓
Flutter Web sends image to backend
        ↓
Backend runs NAFNet inference
        ↓
Restored image is returned
        ↓
Web app displays Before / After result
```

The demo focuses on NAFNet because it provides high-quality image restoration results compared to traditional image processing methods.

---

## 2. Main Features

### Denoise

Removes noise from images, especially photos captured in low-light conditions or with high ISO.

* **Model**: NAFNet-SIDD
* **Checkpoint**: `nafnet_sidd_width32.pth`
* **Task**: Image Denoising
* **Dataset used by pretrained model**: SIDD — Smartphone Image Denoising Dataset

### Deblur

Restores blurred images caused by motion blur, camera shake, or defocus.

* **Model**: NAFNet-GoPro
* **Checkpoint**: `nafnet_gopro_width64.pth`
* **Task**: Image Deblurring
* **Dataset used by pretrained model**: GoPro

---

## 3. Tech Stack

### Frontend

* Flutter
* Flutter Web
* Dart
* HTTP multipart request
* Before / After image preview

### Backend

* Python
* FastAPI
* PyTorch
* Pillow / OpenCV
* NAFNet pretrained model

### AI Model

* **NAFNet** — Nonlinear Activation Free Network
* Official repository: https://github.com/megvii-research/NAFNet
