-- =====================================================================
--  ATOMIX - Challenge FIAP 2026 (2TDS) - Marinha do Brasil / CTMSP
--  Disciplina : Mastering Relational and Non-Relational Database
--  Arquivo    : ATOMIX_01_SQL_DDL.sql  (parte SQL - DDL)
--  Conteudo   : DROP (reexecucao), SEQUENCES, CREATE TABLE, CONSTRAINTS
--               (PK, FK, UK, CK), INDICES e COMMENTS
--  Grupo      : ATOMIX
--               Gianluca K. Araujo - RM 566765
--               Ruan Ribeiro       - RM 567693
--  SGBD       : Oracle Database 19c ou superior
--  Ordem de execucao: 1) este arquivo  2) ATOMIX_02_PLSQL.sql
--  Observacao : NAO ha INSERT neste script. Toda a carga de dados e feita
--               pela API Java, que chama as procedures do arquivo PL/SQL.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. LIMPEZA (permite reexecutar o script)
--    Na primeira execucao os DROPs retornam ORA-00942 / ORA-02289,
--    o que e esperado e pode ser ignorado.
-- ---------------------------------------------------------------------
DROP TABLE TB_ATX_JOGADOR_CONQUISTA CASCADE CONSTRAINTS PURGE;
DROP TABLE TB_ATX_CONQUISTA         CASCADE CONSTRAINTS PURGE;
DROP TABLE TB_ATX_JOGADOR           CASCADE CONSTRAINTS PURGE;
DROP TABLE TB_ATX_PERGUNTA          CASCADE CONSTRAINTS PURGE;
DROP TABLE TB_ATX_APLICACAO         CASCADE CONSTRAINTS PURGE;
DROP TABLE TB_ATX_AREA              CASCADE CONSTRAINTS PURGE;

DROP SEQUENCE SQ_ATX_AREA;
DROP SEQUENCE SQ_ATX_APLICACAO;
DROP SEQUENCE SQ_ATX_PERGUNTA;
DROP SEQUENCE SQ_ATX_JOGADOR;
DROP SEQUENCE SQ_ATX_CONQUISTA;


-- ---------------------------------------------------------------------
-- 1. SEQUENCES (geracao das chaves primarias substitutas)
--    NOCACHE garante IDs sequenciais sem saltos apos restart do banco,
--    o que deixa a demonstracao via API previsivel (IDs 1, 2, 3...).
-- ---------------------------------------------------------------------
CREATE SEQUENCE SQ_ATX_AREA      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SQ_ATX_APLICACAO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SQ_ATX_PERGUNTA  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SQ_ATX_JOGADOR   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SQ_ATX_CONQUISTA START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- ---------------------------------------------------------------------
-- 2. TABELAS
-- ---------------------------------------------------------------------

-- 2.1 AREA - as areas da "cidade nuclear" do app
CREATE TABLE TB_ATX_AREA (
    id_area      NUMBER(10)     NOT NULL,
    nome         VARCHAR2(50)   NOT NULL,
    descricao    VARCHAR2(400)  NOT NULL,
    ativa        CHAR(1)        DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_ATX_AREA        PRIMARY KEY (id_area),
    CONSTRAINT UK_ATX_AREA_NOME   UNIQUE (nome),
    CONSTRAINT CK_ATX_AREA_ATIVA  CHECK (ativa IN ('S', 'N'))
);

-- 2.2 APLICACAO - aplicacoes reais da tecnologia nuclear (CRUD da API Java)
CREATE TABLE TB_ATX_APLICACAO (
    id_aplicacao NUMBER(10)     NOT NULL,
    id_area      NUMBER(10)     NOT NULL,
    titulo       VARCHAR2(120)  NOT NULL,
    descricao    VARCHAR2(1000) NOT NULL,
    beneficio    VARCHAR2(500)  NOT NULL,
    dt_cadastro  DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_ATX_APLICACAO         PRIMARY KEY (id_aplicacao),
    CONSTRAINT UK_ATX_APLIC_AREA_TITULO UNIQUE (id_area, titulo),
    CONSTRAINT FK_ATX_APLIC_AREA        FOREIGN KEY (id_area)
        REFERENCES TB_ATX_AREA (id_area)
);

-- 2.3 PERGUNTA - perguntas do quiz, cada uma sobre uma aplicacao
CREATE TABLE TB_ATX_PERGUNTA (
    id_pergunta      NUMBER(10)    NOT NULL,
    id_aplicacao     NUMBER(10)    NOT NULL,
    enunciado        VARCHAR2(500) NOT NULL,
    alternativa_a    VARCHAR2(200) NOT NULL,
    alternativa_b    VARCHAR2(200) NOT NULL,
    alternativa_c    VARCHAR2(200) NOT NULL,
    alternativa_d    VARCHAR2(200) NOT NULL,
    resposta_correta CHAR(1)       NOT NULL,
    pontos           NUMBER(4)     DEFAULT 10 NOT NULL,
    CONSTRAINT PK_ATX_PERGUNTA          PRIMARY KEY (id_pergunta),
    CONSTRAINT CK_ATX_PERG_RESPOSTA     CHECK (resposta_correta IN ('A', 'B', 'C', 'D')),
    CONSTRAINT CK_ATX_PERG_PONTOS       CHECK (pontos BETWEEN 1 AND 1000),
    CONSTRAINT FK_ATX_PERG_APLICACAO    FOREIGN KEY (id_aplicacao)
        REFERENCES TB_ATX_APLICACAO (id_aplicacao)
);

-- 2.4 JOGADOR - usuario cadastrado no app (tela de cadastro / perfil)
CREATE TABLE TB_ATX_JOGADOR (
    id_jogador   NUMBER(10)    NOT NULL,
    nome         VARCHAR2(100) NOT NULL,
    email        VARCHAR2(120) NOT NULL,
    senha        VARCHAR2(100) NOT NULL,
    pontuacao    NUMBER(8)     DEFAULT 0 NOT NULL,
    dt_cadastro  DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_ATX_JOGADOR           PRIMARY KEY (id_jogador),
    CONSTRAINT UK_ATX_JOGADOR_EMAIL     UNIQUE (email),
    CONSTRAINT CK_ATX_JOG_EMAIL         CHECK (email LIKE '_%@_%._%'),
    CONSTRAINT CK_ATX_JOG_PONTUACAO     CHECK (pontuacao >= 0)
);

-- 2.5 CONQUISTA - medalhas desbloqueadas por pontuacao
--     id_area e opcional: conquistas gerais nao pertencem a uma area.
CREATE TABLE TB_ATX_CONQUISTA (
    id_conquista       NUMBER(10)    NOT NULL,
    id_area            NUMBER(10),
    nome               VARCHAR2(60)  NOT NULL,
    descricao          VARCHAR2(300) NOT NULL,
    pontos_necessarios NUMBER(8)     NOT NULL,
    CONSTRAINT PK_ATX_CONQUISTA         PRIMARY KEY (id_conquista),
    CONSTRAINT UK_ATX_CONQUISTA_NOME    UNIQUE (nome),
    CONSTRAINT CK_ATX_CONQ_PONTOS       CHECK (pontos_necessarios >= 0),
    CONSTRAINT FK_ATX_CONQ_AREA         FOREIGN KEY (id_area)
        REFERENCES TB_ATX_AREA (id_area) ON DELETE SET NULL
);

-- 2.6 JOGADOR_CONQUISTA - entidade associativa (resolve o N:N
--     entre JOGADOR e CONQUISTA) e registra quando houve o desbloqueio.
CREATE TABLE TB_ATX_JOGADOR_CONQUISTA (
    id_jogador     NUMBER(10) NOT NULL,
    id_conquista   NUMBER(10) NOT NULL,
    dt_desbloqueio DATE       DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_ATX_JOGADOR_CONQUISTA PRIMARY KEY (id_jogador, id_conquista),
    CONSTRAINT FK_ATX_JC_JOGADOR        FOREIGN KEY (id_jogador)
        REFERENCES TB_ATX_JOGADOR (id_jogador) ON DELETE CASCADE,
    CONSTRAINT FK_ATX_JC_CONQUISTA      FOREIGN KEY (id_conquista)
        REFERENCES TB_ATX_CONQUISTA (id_conquista) ON DELETE CASCADE
);


-- ---------------------------------------------------------------------
-- 3. INDICES nas chaves estrangeiras (evitam full scan nos JOINs e
--    lock de tabela filha ao excluir registros da tabela pai)
-- ---------------------------------------------------------------------
CREATE INDEX IX_ATX_APLIC_AREA      ON TB_ATX_APLICACAO (id_area);
CREATE INDEX IX_ATX_PERG_APLICACAO  ON TB_ATX_PERGUNTA (id_aplicacao);
CREATE INDEX IX_ATX_CONQ_AREA       ON TB_ATX_CONQUISTA (id_area);
CREATE INDEX IX_ATX_JC_CONQUISTA    ON TB_ATX_JOGADOR_CONQUISTA (id_conquista);


-- ---------------------------------------------------------------------
-- 4. DICIONARIO DE DADOS (COMMENTS)
-- ---------------------------------------------------------------------
COMMENT ON TABLE  TB_ATX_AREA                     IS 'Areas da cidade nuclear do app ATOMIX (Saude, Agro, Industria, Energia, Pesquisa...)';
COMMENT ON COLUMN TB_ATX_AREA.id_area             IS 'Chave primaria (SQ_ATX_AREA)';
COMMENT ON COLUMN TB_ATX_AREA.nome                IS 'Nome unico da area';
COMMENT ON COLUMN TB_ATX_AREA.descricao           IS 'Texto de apresentacao da area no app';
COMMENT ON COLUMN TB_ATX_AREA.ativa               IS 'S = visivel na cidade do app; N = area futura (em breve)';

COMMENT ON TABLE  TB_ATX_APLICACAO                IS 'Aplicacoes reais da tecnologia nuclear exibidas em cada area';
COMMENT ON COLUMN TB_ATX_APLICACAO.id_aplicacao   IS 'Chave primaria (SQ_ATX_APLICACAO)';
COMMENT ON COLUMN TB_ATX_APLICACAO.id_area        IS 'FK - area a que a aplicacao pertence';
COMMENT ON COLUMN TB_ATX_APLICACAO.titulo         IS 'Titulo da aplicacao (unico dentro da area)';
COMMENT ON COLUMN TB_ATX_APLICACAO.descricao      IS 'Explicacao de como a tecnologia nuclear e aplicada';
COMMENT ON COLUMN TB_ATX_APLICACAO.beneficio      IS 'Beneficio para a sociedade';
COMMENT ON COLUMN TB_ATX_APLICACAO.dt_cadastro    IS 'Data de cadastro do registro';

COMMENT ON TABLE  TB_ATX_PERGUNTA                 IS 'Perguntas do quiz; cada pergunta e sobre uma aplicacao';
COMMENT ON COLUMN TB_ATX_PERGUNTA.id_pergunta     IS 'Chave primaria (SQ_ATX_PERGUNTA)';
COMMENT ON COLUMN TB_ATX_PERGUNTA.id_aplicacao    IS 'FK - aplicacao sobre a qual a pergunta trata';
COMMENT ON COLUMN TB_ATX_PERGUNTA.enunciado       IS 'Texto da pergunta';
COMMENT ON COLUMN TB_ATX_PERGUNTA.alternativa_a   IS 'Texto da alternativa A';
COMMENT ON COLUMN TB_ATX_PERGUNTA.alternativa_b   IS 'Texto da alternativa B';
COMMENT ON COLUMN TB_ATX_PERGUNTA.alternativa_c   IS 'Texto da alternativa C';
COMMENT ON COLUMN TB_ATX_PERGUNTA.alternativa_d   IS 'Texto da alternativa D';
COMMENT ON COLUMN TB_ATX_PERGUNTA.resposta_correta IS 'Letra da alternativa correta (A, B, C ou D)';
COMMENT ON COLUMN TB_ATX_PERGUNTA.pontos          IS 'Pontos ganhos ao acertar a pergunta';

COMMENT ON TABLE  TB_ATX_JOGADOR                  IS 'Jogadores cadastrados no app';
COMMENT ON COLUMN TB_ATX_JOGADOR.id_jogador       IS 'Chave primaria (SQ_ATX_JOGADOR)';
COMMENT ON COLUMN TB_ATX_JOGADOR.nome             IS 'Nome do jogador';
COMMENT ON COLUMN TB_ATX_JOGADOR.email            IS 'E-mail unico, usado no login';
COMMENT ON COLUMN TB_ATX_JOGADOR.senha            IS 'Hash da senha (gerado pela API, ex.: BCrypt)';
COMMENT ON COLUMN TB_ATX_JOGADOR.pontuacao        IS 'Pontuacao acumulada no jogo';
COMMENT ON COLUMN TB_ATX_JOGADOR.dt_cadastro      IS 'Data de cadastro do jogador';

COMMENT ON TABLE  TB_ATX_CONQUISTA                IS 'Conquistas (medalhas) desbloqueaveis por pontuacao';
COMMENT ON COLUMN TB_ATX_CONQUISTA.id_conquista   IS 'Chave primaria (SQ_ATX_CONQUISTA)';
COMMENT ON COLUMN TB_ATX_CONQUISTA.id_area        IS 'FK opcional - area tematica da conquista (NULL = conquista geral)';
COMMENT ON COLUMN TB_ATX_CONQUISTA.nome           IS 'Nome unico da conquista';
COMMENT ON COLUMN TB_ATX_CONQUISTA.descricao      IS 'Descricao exibida no perfil';
COMMENT ON COLUMN TB_ATX_CONQUISTA.pontos_necessarios IS 'Pontuacao minima do jogador para desbloquear';

COMMENT ON TABLE  TB_ATX_JOGADOR_CONQUISTA        IS 'Associativa JOGADOR x CONQUISTA - conquistas desbloqueadas';
COMMENT ON COLUMN TB_ATX_JOGADOR_CONQUISTA.id_jogador     IS 'PK/FK - jogador';
COMMENT ON COLUMN TB_ATX_JOGADOR_CONQUISTA.id_conquista   IS 'PK/FK - conquista';
COMMENT ON COLUMN TB_ATX_JOGADOR_CONQUISTA.dt_desbloqueio IS 'Data em que a conquista foi desbloqueada';

-- Fim do arquivo SQL (DDL)
