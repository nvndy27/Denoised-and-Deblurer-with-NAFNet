FROM python:3.10-slim

# Install system dependencies required by OpenCV and PyTorch
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create user with UID 1000 as required by Hugging Face Spaces
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"
ENV HOME=/home/user
ENV TORCH_HOME=/home/user/.cache/torch

WORKDIR /app

# Copy requirements and install python packages
COPY --chown=user ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# Copy all project files and set ownership
COPY --chown=user . /app

# Expose default Hugging Face Space port
EXPOSE 7860

# Start FastAPI server on port 7860
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]
