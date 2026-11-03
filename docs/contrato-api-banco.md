# Contrato entre DevOps, API Java e Banco (igual em todas as matérias)

A API da pasta `api/` é o **mesmo projeto** da matéria de Java Advanced, e os scripts de `database/sql/01_ddl.sql`
e `02_plsql.sql` são **os mesmos** da matéria de Banco de Dados. Se algo mudar em uma matéria, copie para cá.

## API Java (pasta `api/`)

- Maven, **Java 21**, Spring Boot 3.5, driver `ojdbc11`
- Conexão **só por variáveis de ambiente** (o Compose define): `DB_URL`, `DB_USER`, `DB_PASSWORD`
- Leituras com Spring Data JPA; **toda escrita chama uma procedure `PRC_ATX_*`** (não usa `save()` do JPA)
- Erros `RAISE_APPLICATION_ERROR` das procedures viram HTTP 400 / 404 / 409 / 422

### Endpoints usados no vídeo e em `scripts/test-crud.sh`

| Método | Rota | Resposta |
|---|---|---|
| POST | `/api/aplicacoes` | 201 + objeto com `idAplicacao` (procedure `PRC_ATX_INS_APLICACAO`) |
| GET | `/api/aplicacoes` | 200 + página (`content`) |
| GET | `/api/aplicacoes/{id}` | 200 ou 404 |
| PUT | `/api/aplicacoes/{id}` | 200 ou 404 (`PRC_ATX_UPD_APLICACAO`) |
| DELETE | `/api/aplicacoes/{id}` | 204 ou 404 (`PRC_ATX_DEL_APLICACAO`) |
| GET | `/api/aplicacoes/busca?texto=` | 200 + página (Query Method) |

JSON de entrada: `idArea`, `titulo`, `descricao`, `beneficio`. Saída: `idAplicacao`, `idArea`, `area`, `titulo`, `descricao`, `beneficio`, `dtCadastro`.
A lista completa de endpoints está no Swagger: `http://<IP>:8080/swagger-ui.html`.

## Banco Oracle (schema `ATOMIX`, PDB `FREEPDB1`)

| Tabela | Colunas |
|---|---|
| `TB_ATX_AREA` | `id_area` PK, `nome` (único), `descricao`, `ativa` (S/N) |
| `TB_ATX_APLICACAO` | `id_aplicacao` PK, `id_area` FK, `titulo` (único na área), `descricao`, `beneficio`, `dt_cadastro` |
| `TB_ATX_PERGUNTA` | `id_pergunta` PK, `id_aplicacao` FK, `enunciado`, `alternativa_a..d`, `resposta_correta` (A–D), `pontos` |
| `TB_ATX_JOGADOR` | `id_jogador` PK, `nome`, `email` (único), `senha` (hash), `pontuacao`, `dt_cadastro` |
| `TB_ATX_CONQUISTA` | `id_conquista` PK, `id_area` FK opcional, `nome` (único), `descricao`, `pontos_necessarios` |
| `TB_ATX_JOGADOR_CONQUISTA` | `id_jogador` + `id_conquista` PK, `dt_desbloqueio` |

IDs gerados pelas sequences `SQ_ATX_*`. Regra de desbloqueio: `pontuacao >= pontos_necessarios`.
Catálogo de conquistas (igual no banco, no .NET e no app): Primeiro Átomo (0), Explorador da Saúde (50),
Guardião do Agro (100), Engenheiro da Indústria (150), Energia Limpa (200), Mente Científica (300),
Mestre do Quiz (400), Cidadão Nuclear (500), Submarinista (750) e Mestre Nuclear (1000).
Níveis do jogador: Aprendiz Atômico (0–99), Explorador Nuclear (100–299), Cientista do Átomo (300–599),
Especialista CTMSP (600–999) e Mestre Nuclear (1000+).
