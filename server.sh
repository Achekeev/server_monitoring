#!/usr/bin/env bash
set -eu pipefail

REPO_URL="https://github.com/your-org/server_monitoring.git"
STACK_DIR="/opt/monitoring"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"
COMPOSE="docker compose -f $COMPOSE_FILE"

# --- 1. clone / pull -------------------------------------------------
if [[ ! -d $STACK_DIR ]]; then
  sudo git clone "$REPO_URL" "$STACK_DIR"
else
  sudo git -C "$STACK_DIR" pull --ff-only
fi
sudo git config --system --add safe.directory "$STACK_DIR" || true

# --- 2. fix promtail.yaml path --------------------------------------
if [[ -d $STACK_DIR/promtail/promtail.yaml ]]; then
  sudo rm -rf "$STACK_DIR/promtail/promtail.yaml"
fi
if [[ -f $STACK_DIR/promtail/promtail.yml && ! -f $STACK_DIR/promtail/promtail.yaml ]]; then
  sudo mv "$STACK_DIR/promtail/promtail.yml" "$STACK_DIR/promtail/promtail.yaml"
fi

# --- 3. install Docker + compose plugin if absent -------------------
if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null; then
  sudo bash "$STACK_DIR/install_docker.sh"
fi

# --- 4. pull images that are not yet present ------------------------
echo "[+] Pulling images (skip existing)"
$COMPOSE pull --quiet --ignore-pull-failures

# --- 5. up: start / recreate only if needed -------------------------
echo "[+] Starting / updating services"
$COMPOSE up -d

echo "[✓] Stack is up."

