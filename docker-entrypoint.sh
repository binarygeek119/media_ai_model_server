#!/usr/bin/env bash
#
# Container entrypoint for the AI model server.
#
# The server reads its configuration and models from paths relative to /app
# (./config, ./models).  Unraid/Compose templates mount persistent host
# directories over those paths, which on a fresh install start out empty and
# would otherwise hide the defaults baked into the image.
#
# Merge the baked defaults into the mounted config on every start, copying only
# files that are missing (cp -n). This seeds a fresh install AND back-fills new
# default files added by image upgrades (e.g. new pipeline-glue configs), while
# never clobbering config or model files the user has already changed.
set -e

DEFAULT_CONFIG_DIR="/opt/app-defaults-config"
APP_CONFIG_DIR="/app/config"
APP_MODELS_DIR="/app/models"

if [ -d "${DEFAULT_CONFIG_DIR}" ]; then
    echo "[entrypoint] Merging default config into ${APP_CONFIG_DIR} (missing files only)"
    mkdir -p "${APP_CONFIG_DIR}"
    cp -an "${DEFAULT_CONFIG_DIR}/." "${APP_CONFIG_DIR}/" || \
        echo "[entrypoint] WARNING: could not merge default config (is the Config path writable?)"
fi

# Ensure the models directory exists even if nothing is mounted there yet.
mkdir -p "${APP_MODELS_DIR}"

# Apply pending config/pipeline migrations (idempotent). The native install
# scripts run this once before starting; doing it here keeps mounted volumes
# up to date across image upgrades. A migration failure is not fatal on its own
# - let the server surface the real error.
if [ -f /app/migrate.py ]; then
    echo "[entrypoint] Running config migrations"
    (cd /app && python3.12 migrate.py) || \
        echo "[entrypoint] WARNING: config migrations failed; continuing"
fi

exec "$@"
