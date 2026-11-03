#!/usr/bin/env bash
# =============================================================================
#  ATOMIX - Teste do CRUD completo de Aplicações Nucleares pela API na VM Azure
#
#  Uso (do seu computador, NUNCA localhost):
#    bash scripts/test-crud.sh <IP_PUBLICO_DA_VM>
#  Requer: curl e jq  (Mac: brew install jq | Ubuntu: sudo apt install -y jq)
#
#  Endpoints esperados (API Java):
#    POST   /api/aplicacoes
#    GET    /api/aplicacoes
#    GET    /api/aplicacoes/{id}
#    PUT    /api/aplicacoes/{id}
#    DELETE /api/aplicacoes/{id}
#    GET    /api/aplicacoes/busca?texto=...
# =============================================================================
set -euo pipefail

VM_IP="${1:?Informe o IP público da VM. Ex.: bash scripts/test-crud.sh 20.10.30.40}"
case "$VM_IP" in localhost|127.*) echo "Use o IP público da VM do Azure, não localhost."; exit 1;; esac
BASE="http://${VM_IP}:${API_PORT:-8080}/api/aplicacoes"
HDR=(-H "Content-Type: application/json" -H "Accept: application/json")

step() { printf '\n\033[1;35m==== %s ====\033[0m\n' "$*"; }
call() { # método url [json]
  local method="$1" url="$2" body="${3:-}"
  local out status
  echo "> $method $url"
  if [ -n "$body" ]; then
    out=$(curl -sS -X "$method" "${HDR[@]}" -d "$body" -w '\n%{http_code}' "$url")
  else
    out=$(curl -sS -X "$method" "${HDR[@]}" -w '\n%{http_code}' "$url")
  fi
  status="${out##*$'\n'}"; out="${out%$'\n'*}"
  if [ -n "$out" ]; then echo "$out" | jq . 2>/dev/null || echo "$out"; fi
  echo "HTTP $status"
}
LIST='(if type == "array" then . else .content end)[] | "\(.idAplicacao // .id)\t\(.titulo)"'

# ------------------------------------------------------------------ CREATE --
step "CREATE - cadastrando 5 aplicações nucleares"
IDS=()
while IFS= read -r payload; do
  resp=$(curl -sS -X POST "${HDR[@]}" -d "$payload" "$BASE")
  echo "$resp" | jq .
  IDS+=("$(echo "$resp" | jq -r '.idAplicacao // .id')")
done <<'JSON'
{"idArea":1,"titulo":"Cintilografia com tecnécio-99m","descricao":"Um radiofármaco com tecnécio-99m é injetado e uma gama-câmara registra sua distribuição no coração, ossos, rins ou tireoide.","beneficio":"É um dos exames de medicina nuclear mais usados no mundo para avaliar o funcionamento dos órgãos."}
{"idArea":2,"titulo":"Técnica do inseto estéril","descricao":"Machos de pragas como a mosca-das-frutas são esterilizados com radiação e soltos no campo; ao acasalar, não geram descendentes.","beneficio":"Controla pragas agrícolas reduzindo o uso de agrotóxicos."}
{"idArea":3,"titulo":"Medidores nucleares de nível e espessura","descricao":"Fontes radioativas seladas medem, sem contato, o nível de líquidos em tanques e a espessura de papel, plástico e aço nas linhas de produção.","beneficio":"Controle de qualidade contínuo e preciso, sem parar a produção."}
{"idArea":4,"titulo":"Enriquecimento de urânio por ultracentrífugas","descricao":"Ultracentrífugas desenvolvidas pela Marinha do Brasil (CTMSP) aumentam a proporção de urânio-235 para produzir combustível nuclear.","beneficio":"Autonomia do Brasil no ciclo do combustível nuclear."}
{"idArea":5,"titulo":"Datação por carbono-14","descricao":"A medição do carbono-14 restante em ossos, madeira e tecidos indica há quanto tempo o organismo morreu.","beneficio":"Permite datar achados arqueológicos e fósseis com dezenas de milhares de anos."}
JSON
echo "IDs criados: ${IDS[*]}"

# -------------------------------------------------------------------- READ --
step "READ - listando todas as aplicações (id e título)"
echo "> GET $BASE"
curl -sS "${HDR[@]}" "$BASE" | jq -r "$LIST"

step "READ - consultando a aplicação ${IDS[0]}"
call GET "$BASE/${IDS[0]}"

step "READ - busca por texto (texto=urânio)"
call GET "$BASE/busca?texto=ur%C3%A2nio"

# ------------------------------------------------------------------ UPDATE --
step "UPDATE - alterando a aplicação ${IDS[0]}"
call PUT "$BASE/${IDS[0]}" '{"idArea":1,"titulo":"Cintilografia com tecnécio-99m (atualizado)","descricao":"Exame de imagem que usa tecnécio-99m e gama-câmara para avaliar coração, ossos, rins e tireoide.","beneficio":"Diagnóstico funcional rápido, com baixa dose de radiação para o paciente."}'

step "UPDATE - consultando novamente para comprovar a alteração"
call GET "$BASE/${IDS[0]}"

# ------------------------------------------------------------------ DELETE --
step "DELETE - excluindo a aplicação ${IDS[4]}"
call DELETE "$BASE/${IDS[4]}"

step "DELETE - consultando o registro excluído (esperado: 404)"
call GET "$BASE/${IDS[4]}"

step "Lista final (o registro ${IDS[4]} não deve aparecer)"
curl -sS "${HDR[@]}" "$BASE" | jq -r "$LIST"
