
#!/usr/bin/env bash
set -eu pipefail

REPO_URL="https://github.com/your-org/server_monitoring.git"
STACK_DIR="/opt/monitoring"     
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"
COMPOSE="docker compose -f $COMPOSE_FILE"

if [[ ! -d $STACK_DIR ]]; then
  echo "[+] Cloning repo into $STACK_DIR"
  sudo git clone "$REPO_URL" "$STACK_DIR"
else
  echo "[+] Repo already exists — pulling latest changes"
  sudo git -C "$STACK_DIR" pull --ff-only
fi

sudo git config --system --add safe.directory "$STACK_DIR" || true

if [[ -d $STACK_DIR/promtail/promtail.yaml ]]; then
  echo "[!] Wrong type: promtail.yaml is a directory — deleting"
  sudo rm -rf "$STACK_DIR/promtail/promtail.yaml"
fi

if [[ -f $STACK_DIR/promtail/promtail.yml && ! -f $STACK_DIR/promtail/promtail.yaml ]]; then
  echo "[+] Renaming promtail.yml → promtail.yaml"
  sudo mv "$STACK_DIR/promtail/promtail.yml" "$STACK_DIR/promtail/promtail.yaml"
fi

if ! command -v docker &>/dev/null; then
  echo "[+] Docker not found — installing"
  sudo bash "$STACK_DIR/install_docker.sh"
fi
if ! docker compose version &>/dev/null; then
  echo "[+] Compose plugin missing — reinstalling Docker"
  sudo bash "$STACK_DIR/install_docker.sh"
fi

echo "[+] Pulling missing images"
$COMPOSE pull --quiet --ignore-pull-failures missing

echo "[+] Starting stopped services"
for svc in $($COMPOSE config --services); do
  cid="$($COMPOSE ps -q "$svc" || true)"
  if [[ -z $cid ]] || ! docker ps -q --no-trunc | grep -q "$cid"; then
    echo "    • $svc"
    $COMPOSE up -d "$svc"
  fi
done

echo "[✓] Monitoring stack is up and running."

