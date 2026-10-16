#!/usr/bin/env bash
#
# Container entrypoint for the AI model server.
#
# The server reads its configuration and models from paths relative to /app
# (./config, ./models).  Unraid/Compose templates mount persistent host
# directories over those paths, which on a fresh install start out empty and
# would otherwise hide the defaults baked into the image.  Seed the default
# config into an empty mount so the very first start works with zero manual
# steps, while never clobbering files the user has already changed.
set -e

DEFAULT_CONFIG_DIR="/opt/app-defaults-config"
APP_CONFIG_DIR="/app/config"
APP_MODELS_DIR="/app/models"

if [ ! -f "${APP_CONFIG_DIR}/config.yaml" ] && [ -d "${DEFAULT_CONFIG_DIR}" ]; then
    echo "[entrypoint] Seeding default config into ${APP_CONFIG_DIR}"
    mkdir -p "${APP_CONFIG_DIR}"
    cp -an "${DEFAULT_CONFIG_DIR}/." "${APP_CONFIG_DIR}/"
fi

# Ensure the models directory exists even if nothing is mounted there yet.
mkdir -p "${APP_MODELS_DIR}"

# Apply pending config/pipeline migrations (idempotent). The native install
# scripts run this once before starting; doing it here keeps mounted volumes
# up to date across image upgrades.
if [ -f /app/migrate.py ]; then
    echo "[entrypoint] Running config migrations"
    (cd /app && python3.12 migrate.py)
fi

exec "$@"
