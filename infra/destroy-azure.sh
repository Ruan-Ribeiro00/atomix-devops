#!/usr/bin/env bash
# =============================================================================
#  ATOMIX - Exclusão dos recursos do Azure após os testes
#  Uso:  bash infra/destroy-azure.sh
#  Tire print da saída final (comprovação exigida no PDF de entrega).
# =============================================================================
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-atomix}"

log() { printf '\n\033[1;36m[ATOMIX]\033[0m %s\n' "$*"; }

log "Recursos que serão excluídos em '$RESOURCE_GROUP':"
az resource list --resource-group "$RESOURCE_GROUP" \
  --query "[].{Nome:name, Tipo:type}" -o table || true

log "Excluindo o Resource Group '$RESOURCE_GROUP' (aguarde, leva alguns minutos)..."
az group delete --name "$RESOURCE_GROUP" --yes

log "Comprovação da exclusão:"
echo "Data/hora: $(date '+%d/%m/%Y %H:%M:%S %Z')"
echo "Assinatura: $(az account show --query name -o tsv)"
echo -n "az group exists --name $RESOURCE_GROUP  =>  "
az group exists --name "$RESOURCE_GROUP"

log "Resource Groups restantes na assinatura:"
az group list --query "[].{Nome:name, Local:location, Estado:properties.provisioningState}" -o table
