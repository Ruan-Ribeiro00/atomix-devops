# ATOMIX ⚛️ — Docker + Azure (prova de conceito)

> \*\*Challenge FIAP 2026 · 2TDSPA · Marinha do Brasil / CTMSP (Programa Nuclear da Marinha)\*\*
> Disciplina: \*\*DevOps Tools \& Cloud Computing\*\* — Sprint 1

## 👥 Integrantes

|Nome|RM|Turma|
|-|-|-|
|Gianluca K. Araujo|RM 566765|2TDSPA|
|Ruan Ribeiro|RM 567693|2TDSPA|

## 💡 Como Docker e Cloud Computing podem ser utilizados na solução proposta pelo grupo?

O **ATOMIX** é um app gamificado em que o usuário explora uma "cidade nuclear" e descobre as aplicações da
tecnologia nuclear em saúde, agro, indústria, energia e pesquisa. O app e os totens que propomos para museus e
escolas dependem de uma **API sempre disponível pela internet**, com o conteúdo educativo e a pontuação dos jogadores.

O **Docker** empacota essa API com tudo de que ela precisa (Java 21, dependências e configuração) numa imagem que roda
igual no computador de qualquer integrante e no servidor. O deploy vira um comando, cada parte da solução (API e banco
Oracle) fica isolada no seu container, a aplicação roda com um usuário sem privilégios e as senhas ficam fora do código.

A **nuvem (Microsoft Azure)** fornece essa infraestrutura sob demanda: a VM, a rede e as regras de firewall são criadas
por script com o Azure CLI em poucos minutos, podem ser recriadas iguais quando necessário e são apagadas ao fim dos
testes para não gerar custo. Quando o número de jogadores crescer — uma escola inteira jogando durante uma visita ao
museu, por exemplo — a mesma imagem Docker pode rodar em mais VMs ou em serviços gerenciados do Azure, sem reescrever a aplicação.

## 📌 O que esta prova de conceito demonstra

* A **API REST do ATOMIX** empacotada numa imagem Docker pelo [`api/Dockerfile`](api/Dockerfile). É a mesma API da
disciplina de Java Advanced, reaproveitada como o enunciado permite: CRUD de Aplicações Nucleares e busca por texto;
* Uma **VM Linux no Microsoft Azure criada por script Azure CLI** ([`infra/provision-azure.sh`](infra/provision-azure.sh)),
com rede virtual e regras de acesso liberando só as portas necessárias;
* A **API rodando em container dentro da VM**, ao lado do banco **Oracle** em outro container, respondendo pelo IP público;
* A **exclusão do grupo de recursos** ao final dos testes ([`infra/destroy-azure.sh`](infra/destroy-azure.sh)).

## 🏗️ Arquitetura

!\[Arquitetura ATOMIX no Azure](docs/arquitetura-atomix-azure.png)

|Camada|Recurso|Detalhe|
|-|-|-|
|Azure|Grupo de recursos `rg-atomix`|Agrupa todos os recursos (excluído ao final)|
|Rede|VNet `vnet-atomix` (10.10.0.0/16) + Subnet `snet-atomix` (10.10.1.0/24)|Rede privada da VM|
|Segurança|NSG `nsg-atomix`|Entrada liberada só em **22/TCP** (SSH) e **8080/TCP** (API); a porta 1521 do banco **não** é exposta|
|Acesso|IP público estático `pip-atomix` + NIC `nic-atomix`|Endereço usado nos testes|
|Computação|VM `vm-atomix` — Ubuntu 24.04 LTS, Standard\_B2s|Docker Engine + Docker Compose|
|Container|`atomix-api` — imagem `atomix-api:1.0` (gerada pelo Dockerfile)|Java 21 + Spring Boot, usuário sem privilégios `atomix`, diretório `/app`, porta 8080|
|Container|`atomix-oracle` — `gvenzl/oracle-free:23-slim`|Oracle Database 23ai Free com o modelo da disciplina de Banco de Dados|
|Rede Docker|`atomix-net` (bridge)|A API acessa o banco pelo nome `oracle-db`|
|Volume|`atomix-oracle-data`|Os dados do banco não se perdem ao recriar os containers|

## 🐳 Dockerfile

O [`api/Dockerfile`](api/Dockerfile) gera a imagem da API em dois estágios:

|Estágio|Imagem base|O que faz|
|-|-|-|
|1 · build|`maven:3.9-eclipse-temurin-21-alpine`|Baixa as dependências e compila o `.jar` com o Maven|
|2 · runtime|`eclipse-temurin:21-jre-alpine`|Copia só o `.jar` para uma imagem Alpine com JRE (leve), cria o usuário sem privilégios `atomix`, usa o diretório padrão `/app` e expõe a porta 8080|

Gerar a imagem, executar o container e comprovar que a aplicação funciona (na VM):

```bash
docker compose build atomix-api          # gera a imagem atomix-api:1.0 a partir do api/Dockerfile
docker images | grep atomix-api          # a imagem criada
docker compose up -d                     # sobe o banco e a API em background
docker compose ps                        # atomix-oracle (healthy) e atomix-api (Up)
docker exec atomix-api sh -c 'id \&\& pwd' # uid=100(atomix) ... /app  → sem root
curl -s http://localhost:8080/api/areas  # a API responde
```

## ☁️ Comandos Azure CLI utilizados

Todos estão nos scripts [`infra/provision-azure.sh`](infra/provision-azure.sh) (criação) e
[`infra/destroy-azure.sh`](infra/destroy-azure.sh) (exclusão). Com os valores padrão, eles executam:

```bash
az login
az group create --name rg-atomix --location eastus2
az network vnet create --resource-group rg-atomix --name vnet-atomix --address-prefixes 10.10.0.0/16 \\
  --subnet-name snet-atomix --subnet-prefixes 10.10.1.0/24
az network nsg create --resource-group rg-atomix --name nsg-atomix
az network nsg rule create --resource-group rg-atomix --nsg-name nsg-atomix --name Allow-SSH \\
  --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22
az network nsg rule create --resource-group rg-atomix --nsg-name nsg-atomix --name Allow-API-ATOMIX \\
  --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8080
az network vnet subnet update --resource-group rg-atomix --vnet-name vnet-atomix --name snet-atomix \\
  --network-security-group nsg-atomix
az network public-ip create --resource-group rg-atomix --name pip-atomix --sku Standard --allocation-method Static
az network nic create --resource-group rg-atomix --name nic-atomix --vnet-name vnet-atomix --subnet snet-atomix \\
  --network-security-group nsg-atomix --public-ip-address pip-atomix
az vm create --resource-group rg-atomix --name vm-atomix --image Ubuntu2404 --size Standard\_B2s \\
  --nics nic-atomix --admin-username azureuser --generate-ssh-keys --os-disk-size-gb 64 --storage-sku StandardSSD\_LRS

# ao final dos testes
az group delete --name rg-atomix --yes
az group exists --name rg-atomix         # false = grupo de recursos excluído
```

## 🚀 Como executar

### 1\. Pré-requisitos (no seu computador)

* Conta Azure (Azure for Students) e **Azure CLI**

  * macOS (Homebrew): `brew install azure-cli`
  * Windows: `winget install -e --id Microsoft.AzureCLI`
  * Linux: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`
* Opcional, para o script de testes: `jq` (macOS: `brew install jq`)

### 2\. Criar a VM no Azure

```bash
az login
bash infra/provision-azure.sh
```

O script cria o grupo de recursos, a VNet/Subnet, o NSG com as regras (22 e 8080), o IP público, a NIC e a VM,
e no final mostra os recursos criados, as regras do NSG e o **IP público da VM**.

> Se a assinatura recusar a região (`RequestDisallowedByAzure`), rode com outra:
> `LOCATION=brazilsouth bash infra/provision-azure.sh` (outras opções comuns: `eastus`, `centralus`, `westus2`).

### 3\. Instalar o Docker na VM

```bash
ssh azureuser@<IP\_PUBLICO>
git clone <https://github.com/Ruan-Ribeiro00/atomix-devops.git> atomix \&\& cd atomix
bash infra/install-docker.sh
newgrp docker
```

### 4\. Gerar a imagem e subir os containers

```bash
cp .env.example .env
nano .env                                # troque as senhas (mantenha DB\_USER=ATOMIX)
docker compose build atomix-api
docker compose up -d
docker compose ps
```

Na primeira subida o Oracle cria o schema `ATOMIX` e roda os scripts de `database/sql/` (tabelas, procedures e dados
de teste). A API só inicia quando o banco fica `healthy` (acompanhe com `docker compose logs -f`).

### 5\. Comprovar que a aplicação funciona (do seu computador, pelo IP público)

* Swagger: `http://<IP\_PUBLICO>:8080/swagger-ui/index.html`
* Listagem: `curl http://<IP\_PUBLICO>:8080/api/aplicacoes`
* Teste completo (cadastra, consulta, altera e exclui aplicações): `bash scripts/test-crud.sh <IP\_PUBLICO>`

### 6\. Apagar o grupo de recursos

```bash
bash infra/destroy-azure.sh
```

O script exclui o grupo de recursos e mostra `az group exists` = `false` e a lista de grupos restantes.
Tire print dessa saída (e do portal do Azure sem o `rg-atomix`) como comprovação.

## 📁 Estrutura do repositório

```
.
├── api/                         # Código-fonte da API Java (Spring Boot) - mesmo projeto de Java Advanced
│   ├── src/ · pom.xml · mvnw
│   ├── Dockerfile               # Multi-stage, Alpine, usuário sem privilégios, WORKDIR /app
│   └── .dockerignore
├── database/                    # Usada pelo container do Oracle na 1ª subida
│   ├── 01-criar-objetos.sh
│   └── sql/                     # 01\_ddl.sql · 02\_plsql.sql · 03\_inserts.sql
├── docs/
│   ├── arquitetura-atomix-azure.png / .svg
│   ├── contrato-api-banco.md
│   └── roteiro-video.md         # Roteiro do vídeo (\~3 min)
├── infra/
│   ├── provision-azure.sh       # Azure CLI: grupo de recursos, rede, NSG, IP, NIC e VM
│   ├── install-docker.sh        # Instala Docker Engine + Compose na VM
│   └── destroy-azure.sh         # Exclui o grupo de recursos e comprova a exclusão
├── scripts/
│   └── test-crud.sh             # Testa a API pelo IP público (cadastro, consulta, alteração e exclusão)
├── docker-compose.yml
├── .env.example
└── README.md
```

## 🧰 Tecnologias

|Ferramenta|Versão|Onde|
|-|-|-|
|Azure CLI|2.x|Computador do desenvolvedor|
|Ubuntu Server|24.04 LTS|VM Azure (Standard\_B2s)|
|Docker Engine + Docker Compose|versão estável do repositório oficial da Docker|VM Azure (instalados pelo `install-docker.sh`)|
|Java|Eclipse Temurin 21 (JRE Alpine)|Container da API|
|Spring Boot|3.5.16|API|
|Oracle Database|23ai Free (`gvenzl/oracle-free:23-slim`)|Container do banco|

## 🎥 Vídeo

Link (YouTube, não listado): **⚠️ inserir link**

Roteiro: [`docs/roteiro-video.md`](docs/roteiro-video.md)

## 🔐 Boas práticas aplicadas

* Imagens enxutas (`\*-alpine` e `\*-slim`) e build multi-stage: o Maven e o JDK não vão para a imagem final
* Aplicação roda com usuário sem privilégios (`atomix`) no diretório padrão `/app`
* Senhas fora do código, em `.env` (não versionado)
* Banco sem porta pública; só a API (8080) e o SSH (22) liberados no NSG
* Infraestrutura criada e apagada por script (Azure CLI), sem cliques no portal

