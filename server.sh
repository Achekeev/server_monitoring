set -euo pipefail

REPO_URL="https://github.com/Achekeev/server_monitoring.git"
STACK_DIR="/opt/monitoring"

sudo git config --system --add safe.directory "$STACK_DIR" || true

if [ ! -d "$STACK_DIR" ]; then
	sudo git clone "$REPO_URL" "$STACK_DIR"
else
	echo "REPO already exists"
	git -C "$STACK_DIR" pull --ff-only
fi

cd "$STACK_DIR"

sudo bash install_docker.sh

sudo docker-compose pull 
sudo docker-compose up -d 

