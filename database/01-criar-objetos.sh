#!/bin/bash
# =============================================================================
#  ATOMIX - Inicialização do Oracle (roda só na 1ª subida do container)
#  Conecta como o usuário da aplicação (APP_USER) e executa, em ordem, os
#  scripts de database/sql/ (montada em /opt/atomix/sql): 01_ddl.sql (tabelas,
#  sequences, constraints) e 02_plsql.sql (procedures, tipos e functions) do
#  projeto de Banco de Dados, e 03_inserts.sql quando existir.
#  Os DROPs do início do DDL dão erro na 1ª execução: é esperado e ignorado.
#  Funciona tanto executado (arquivo com +x) quanto "sourced" pela imagem gvenzl.
# =============================================================================

atomix_criar_objetos() {
  local conexao="${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/FREEPDB1"
  local script log resultado tabelas invalidos

  for script in /opt/atomix/sql/*.sql; do
    [ -e "$script" ] || { echo ">>> ATOMIX: ERRO - nenhum .sql em /opt/atomix/sql (confira o volume no docker-compose)"; return 1; }
    log="/tmp/$(basename "$script").log"
    echo ">>> ATOMIX: executando $(basename "$script")"
    sqlplus -s "$conexao" @"$script" <<< "exit" > "$log" 2>&1
    if grep -q "SP2-0310" "$log"; then
      echo ">>> ATOMIX: ERRO - não foi possível ler $script (rode: chmod 644 database/sql/*.sql)"
      return 1
    fi
    grep -E "Warning|PLS-" "$log"
  done

  resultado=$(sqlplus -s "$conexao" <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT (SELECT COUNT(*) FROM user_tables WHERE table_name LIKE 'TB_ATX%') || ' ' ||
       (SELECT COUNT(*) FROM user_objects WHERE status = 'INVALID') FROM dual;
EXIT
SQL
)
  read -r tabelas invalidos <<< "$resultado"
  echo ">>> ATOMIX: tabelas TB_ATX_* = $tabelas | objetos inválidos = $invalidos"
  [ "$tabelas" = "6" ] || { echo ">>> ATOMIX: ERRO - as 6 tabelas TB_ATX_* não foram criadas"; return 1; }
  [ "$invalidos" = "0" ] || { echo ">>> ATOMIX: ERRO - há objetos PL/SQL inválidos"; return 1; }
}

if ! atomix_criar_objetos; then
  # Executado como processo: sai com erro. "Sourced": só registra o erro no log.
  [ "${BASH_SOURCE[0]}" = "$0" ] && exit 1
fi
