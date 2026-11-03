# Roteiro do vídeo — ATOMIX · DevOps Tools & Cloud Computing (~3 min)

**O que o enunciado pede:** vídeo de uns 3 minutos mostrando a **VM criada no Azure via CLI** e o **container
funcionando com o Dockerfile**, com os detalhes de criação, implementação e testes, e a **exclusão do grupo de
recursos** no final. Resolução mínima 720p, telas legíveis, narração (ou legendas) explicando cada passo,
publicado no YouTube como **Não listado**.

Tudo roda na **VM do Azure**: nada de `localhost` no navegador ou no Postman (localhost zera a nota).

| # | Tempo | O que mostrar | O que falar |
|---|---|---|---|
| 1 | 0:00–0:15 | README com nomes e RMs + diagrama de arquitetura | Quem somos, o que é o ATOMIX e o que o vídeo vai mostrar |
| 2 | 0:15–0:50 | `az login` e `bash infra/provision-azure.sh` rodando, até a saída final com o IP público | O script cria grupo de recursos, rede, NSG com as portas 22 e 8080, IP público, NIC e a VM, tudo pelo Azure CLI |
| 3 | 0:50–1:05 | Portal do Azure → grupo `rg-atomix` | Recursos provisionados e a VM em execução |
| 4 | 1:05–1:30 | `ssh azureuser@<IP>`, `git clone` e `bash infra/install-docker.sh` | Instalação do Docker na VM |
| 5 | 1:30–1:50 | `api/Dockerfile` aberto | Build em dois estágios, imagem Alpine, usuário sem privilégios, diretório `/app`, porta 8080 |
| 6 | 1:50–2:20 | `docker compose build atomix-api` → `docker images` → `docker compose up -d` → `docker compose ps` | Imagem gerada pelo Dockerfile e containers rodando em background (API e banco) |
| 7 | 2:20–2:45 | Swagger em `http://<IP>:8080/swagger-ui/index.html` e `bash scripts/test-crud.sh <IP>` | A API funcionando pelo IP público da VM: cadastra, consulta, altera e exclui |
| 8 | 2:45–3:00 | `bash infra/destroy-azure.sh` mostrando `false` + portal sem o `rg-atomix` | Grupo de recursos excluído ao final dos testes |

**Dicas**
- Grave em 1080p e aumente a fonte do terminal antes de começar.
- O provisionamento, a instalação do Docker, o build da imagem e a 1ª subida do Oracle levam alguns minutos:
  corte a espera na edição, mas mantenha o início e o fim de cada comando.
- Os dois integrantes podem narrar partes diferentes.
