FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y python3.12 && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.12 get-pip.py && \
    rm get-pip.py

# Set Python 3.12 as the default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install pip dependencies
COPY install/requirements.txt .
COPY install/requirements-base.txt .
RUN python3.12 -m pip install -r requirements.txt

# Install FFmpeg with CUDA/NVDEC support
# Pass --build-arg GITHUB_TOKEN=<token> to avoid GitHub API rate limits.
ARG GITHUB_TOKEN=""
COPY scripts/install_ffmpeg_cuda.py /tmp/install_ffmpeg_cuda.py
RUN GITHUB_TOKEN="${GITHUB_TOKEN}" python3.12 /tmp/install_ffmpeg_cuda.py --prefix /usr/local && rm /tmp/install_ffmpeg_cuda.py

# Copy the wheel file and install it
COPY dist/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl /tmp/
RUN python3.12 -m pip install /tmp/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl

# Expose the port FastAPI runs on
EXPOSE 8000

# Bake in the server source so the published image is self-contained. models/
# and data/ are excluded via .dockerignore so user model blobs and local data
# are never baked into the image.
WORKDIR /app
COPY server.py migrate.py select_models.sh select_models.ps1 start.sh start.ps1 ./
COPY lib ./lib
COPY config ./config

# Keep a pristine copy of the default config so the entrypoint can seed a
# mounted (initially empty) /app/config on first run.
RUN cp -a /app/config /opt/app-defaults-config

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Command to run the server.py script
CMD ["python3.12", "server.py"]