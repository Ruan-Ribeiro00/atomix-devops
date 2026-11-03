#!/usr/bin/env bash
# =============================================================================
#  ATOMIX - Instalação do Docker Engine + Docker Compose na VM (Ubuntu 24.04)
#  Executar DENTRO da VM:  bash infra/install-docker.sh
#  Segue o método oficial (repositório apt da Docker Inc.).
# =============================================================================
set -euo pipefail

log() { printf '\n\033[1;36m[ATOMIX]\033[0m %s\n' "$*"; }

log "Atualizando pacotes do sistema..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg git

log "Adicionando a chave GPG e o repositório oficial do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Instalando Docker Engine, CLI, containerd, Buildx e Compose plugin..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Habilitando o serviço do Docker na inicialização..."
sudo systemctl enable --now docker

log "Permitindo que o usuário '$USER' use o Docker sem sudo..."
sudo usermod -aG docker "$USER"

# Swap de 2 GB: a VM B2s tem 4 GB de RAM e o build Maven + Oracle consomem bastante.
if ! swapon --show | grep -q '/swapfile'; then
  log "Criando swap de 2 GB..."
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
fi

log "Versões instaladas:"
sudo docker --version
sudo docker compose version
git --version
lsb_release -d

cat <<'EOF'

=============================================================================
 Docker instalado!
 Rode "newgrp docker" (ou saia e entre de novo no SSH) para usar o docker
 sem sudo. Teste com:  docker run --rm hello-world
=============================================================================
EOF
