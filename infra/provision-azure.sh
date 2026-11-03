#!/usr/bin/env bash
# =============================================================================
#  ATOMIX - Challenge FIAP 2026 (Marinha do Brasil / CTMSP)
#  DevOps Tools & Cloud Computing - Provisionamento da infraestrutura no Azure
#
#  Integrantes:
#    Gianluca K. Araujo - RM 566765
#    Ruan Ribeiro       - RM 567693
#
#  Cria, via Azure CLI:
#    1. Resource Group
#    2. Virtual Network + Subnet
#    3. Network Security Group com regras de entrada (SSH 22 e API 8080)
#    4. IP público estático (SKU Standard)
#    5. Interface de rede (NIC) ligada à subnet, ao NSG e ao IP público
#    6. Máquina virtual Ubuntu 24.04 LTS
#
#  Uso:
#    az login
#    bash infra/provision-azure.sh
#
#  Variáveis podem ser sobrescritas na chamada, por exemplo:
#    LOCATION=brazilsouth VM_SIZE=Standard_B2ms bash infra/provision-azure.sh
# =============================================================================
set -euo pipefail

# ----------------------------- Parâmetros ------------------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-atomix}"
LOCATION="${LOCATION:-eastus2}"          # Azure for Students restringe regiões; troque se der "RequestDisallowedByAzure"
VNET_NAME="${VNET_NAME:-vnet-atomix}"
VNET_PREFIX="${VNET_PREFIX:-10.10.0.0/16}"
SUBNET_NAME="${SUBNET_NAME:-snet-atomix}"
SUBNET_PREFIX="${SUBNET_PREFIX:-10.10.1.0/24}"
NSG_NAME="${NSG_NAME:-nsg-atomix}"
PIP_NAME="${PIP_NAME:-pip-atomix}"
NIC_NAME="${NIC_NAME:-nic-atomix}"
VM_NAME="${VM_NAME:-vm-atomix}"
VM_SIZE="${VM_SIZE:-Standard_B2s}"      # 2 vCPU / 4 GB RAM (Oracle Free + API)
VM_IMAGE="${VM_IMAGE:-Ubuntu2404}"
ADMIN_USER="${ADMIN_USER:-azureuser}"
OS_DISK_GB="${OS_DISK_GB:-64}"
API_PORT="${API_PORT:-8080}"
TAGS="projeto=atomix disciplina=devops challenge=fiap2026"

log() { printf '\n\033[1;36m[ATOMIX]\033[0m %s\n' "$*"; }

# ----------------------------- Pré-checagem ----------------------------------
log "Verificando login no Azure CLI..."
az account show --query "{assinatura:name, id:id, usuario:user.name}" -o table

# ----------------------------- 1. Resource Group -----------------------------
log "1/6 Criando Resource Group '$RESOURCE_GROUP' em '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags $TAGS \
  -o table

# ----------------------------- 2. Rede virtual -------------------------------
log "2/6 Criando VNet '$VNET_NAME' ($VNET_PREFIX) e Subnet '$SUBNET_NAME' ($SUBNET_PREFIX)..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_PREFIX" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefixes "$SUBNET_PREFIX" \
  --tags $TAGS \
  -o table

# ----------------------------- 3. NSG + regras -------------------------------
log "3/6 Criando NSG '$NSG_NAME' e regras de entrada..."
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG_NAME" \
  --tags $TAGS \
  -o table

# SSH para administrar a VM
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-SSH \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --description "Acesso SSH para administracao da VM" \
  -o table

# API Java (Spring Boot) exposta pelo container atomix-api
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name Allow-API-ATOMIX \
  --priority 1010 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --destination-port-ranges "$API_PORT" \
  --description "API REST ATOMIX (Spring Boot)" \
  -o table

# Obs.: a porta 1521 (Oracle) NAO é liberada. O banco só é acessível
# pela rede Docker interna (atomix-net), entre os containers.

# Associa o NSG à subnet (protege todos os recursos da subnet)
az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --network-security-group "$NSG_NAME" \
  -o none

# ----------------------------- 4. IP público ---------------------------------
log "4/6 Criando IP público estático '$PIP_NAME'..."
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PIP_NAME" \
  --sku Standard \
  --allocation-method Static \
  --version IPv4 \
  --tags $TAGS \
  -o table

# ----------------------------- 5. NIC ----------------------------------------
log "5/6 Criando interface de rede '$NIC_NAME'..."
az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NIC_NAME" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --network-security-group "$NSG_NAME" \
  --public-ip-address "$PIP_NAME" \
  --tags $TAGS \
  -o table

# ----------------------------- 6. VM -----------------------------------------
log "6/6 Criando VM '$VM_NAME' ($VM_SIZE, $VM_IMAGE)... (leva alguns minutos)"
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image "$VM_IMAGE" \
  --size "$VM_SIZE" \
  --nics "$NIC_NAME" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --os-disk-size-gb "$OS_DISK_GB" \
  --storage-sku StandardSSD_LRS \
  --tags $TAGS \
  -o table

# ----------------------------- Evidências ------------------------------------
PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PIP_NAME" \
  --query ipAddress -o tsv)

log "Recursos criados no Resource Group '$RESOURCE_GROUP':"
az resource list --resource-group "$RESOURCE_GROUP" \
  --query "[].{Nome:name, Tipo:type, Local:location}" -o table

log "Regras de entrada do NSG '$NSG_NAME':"
az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" \
  --query "[].{Regra:name, Prioridade:priority, Porta:destinationPortRange, Acesso:access}" -o table

log "Status da VM:"
az vm show -d --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" \
  --query "{VM:name, Estado:powerState, IPPublico:publicIps, IPPrivado:privateIps, Tamanho:hardwareProfile.vmSize}" -o table

cat <<EOF

=============================================================================
 Infraestrutura pronta!

 IP público da VM : $PUBLIC_IP
 Acesso SSH       : ssh $ADMIN_USER@$PUBLIC_IP
 API (após deploy): http://$PUBLIC_IP:$API_PORT/swagger-ui/index.html

 Próximos passos (dentro da VM):
   git clone <URL-DO-REPOSITORIO> atomix && cd atomix
   bash infra/install-docker.sh
   cp .env.example .env   # ajuste as senhas
   docker compose up -d --build
=============================================================================
EOF
