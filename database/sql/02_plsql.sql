-- =====================================================================
--  ATOMIX - Challenge FIAP 2026 (2TDS) - Marinha do Brasil / CTMSP
--  Disciplina : Mastering Relational and Non-Relational Database
--  Arquivo    : ATOMIX_02_PLSQL.sql  (parte PL/SQL)
--  Conteudo   : 1) Procedures de INSERT / UPDATE / DELETE de cada tabela
--               2) Procedure de regra de negocio (desbloqueio automatico)
--               3) Tipos (OBJECT / TABLE) usados pelas functions
--               4) Function 1 - relatorio com CURSOR + INNER/LEFT JOIN
--               5) Function 2 - ranking com INNER JOIN, GROUP BY,
--                  agregacoes (COUNT, SUM, MAX) e ORDER BY
--  Grupo      : ATOMIX
--               Gianluca K. Araujo - RM 566765
--               Ruan Ribeiro       - RM 567693
--  Pre-requisito: executar antes o ATOMIX_01_SQL_DDL.sql
--
--  PADRAO DE ERROS (RAISE_APPLICATION_ERROR) - usado pela API Java para
--  traduzir o erro em HTTP status:
--    -20001  campo obrigatorio ausente ou valor invalido   -> 400
--    -20002  registro duplicado (UNIQUE)                    -> 409
--    -20003  registro pai (FK) inexistente                  -> 404/422
--    -20004  registro nao encontrado (UPDATE/DELETE)        -> 404
--    -20005  exclusao bloqueada: existem registros filhos   -> 409
--    -20006  regra de negocio violada                       -> 422
--    -20007  violacao de CHECK constraint                   -> 400
--    -20099  erro inesperado                                -> 500
--
--  Todas as procedures confirmam a transacao (COMMIT) em caso de sucesso
--  e desfazem (ROLLBACK) em caso de erro. As de INSERT devolvem o ID
--  gerado pela sequence no parametro OUT.
-- =====================================================================

SET SERVEROUTPUT ON;


-- =====================================================================
-- 1. TB_ATX_AREA
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_AREA (
    p_nome      IN  TB_ATX_AREA.nome%TYPE,
    p_descricao IN  TB_ATX_AREA.descricao%TYPE,
    p_ativa     IN  TB_ATX_AREA.ativa%TYPE DEFAULT 'S',
    p_id_area   OUT TB_ATX_AREA.id_area%TYPE
) IS
    v_ativa        TB_ATX_AREA.ativa%TYPE;
    v_campo        VARCHAR2(30);
    e_obrigatorio  EXCEPTION;
    e_check        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
BEGIN
    IF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    END IF;

    v_ativa := UPPER(NVL(p_ativa, 'S'));

    INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa)
    VALUES (SQ_ATX_AREA.NEXTVAL, TRIM(p_nome), TRIM(p_descricao), v_ativa)
    RETURNING id_area INTO p_id_area;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'AREA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'AREA: ja existe uma area com o nome "' || p_nome || '".');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'AREA: o campo "ativa" aceita apenas S ou N.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'AREA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'AREA: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_AREA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_AREA (
    p_id_area   IN TB_ATX_AREA.id_area%TYPE,
    p_nome      IN TB_ATX_AREA.nome%TYPE,
    p_descricao IN TB_ATX_AREA.descricao%TYPE,
    p_ativa     IN TB_ATX_AREA.ativa%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_linhas         PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_check          EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
BEGIN
    IF p_id_area IS NULL THEN
        v_campo := 'id_area';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    END IF;

    UPDATE TB_ATX_AREA
       SET nome      = TRIM(p_nome),
           descricao = TRIM(p_descricao),
           ativa     = UPPER(NVL(p_ativa, ativa))
     WHERE id_area   = p_id_area;

    v_linhas := SQL%ROWCOUNT;
    IF v_linhas = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'AREA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'AREA: id ' || p_id_area || ' nao encontrado.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'AREA: ja existe outra area com o nome "' || p_nome || '".');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'AREA: o campo "ativa" aceita apenas S ou N.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'AREA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'AREA: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_AREA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_AREA (
    p_id_area IN TB_ATX_AREA.id_area%TYPE
) IS
    v_qtd_aplicacoes  PLS_INTEGER;
    e_obrigatorio     EXCEPTION;
    e_nao_encontrado  EXCEPTION;
    e_possui_filhos   EXCEPTION;
    e_fk_filho        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_filho, -2292);
BEGIN
    IF p_id_area IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    -- Regra: area com aplicacoes cadastradas nao pode ser excluida
    SELECT COUNT(*) INTO v_qtd_aplicacoes
      FROM TB_ATX_APLICACAO
     WHERE id_area = p_id_area;

    IF v_qtd_aplicacoes > 0 THEN
        RAISE e_possui_filhos;
    END IF;

    -- Conquistas da area ficam como gerais (FK ON DELETE SET NULL)
    DELETE FROM TB_ATX_AREA WHERE id_area = p_id_area;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'AREA: o campo "id_area" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'AREA: id ' || p_id_area || ' nao encontrado.');
    WHEN e_possui_filhos THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'AREA: id ' || p_id_area || ' possui ' || v_qtd_aplicacoes
            || ' aplicacao(oes) vinculada(s) e nao pode ser excluida.');
    WHEN e_fk_filho THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'AREA: existem registros dependentes desta area.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'AREA: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_AREA;
/


-- =====================================================================
-- 2. TB_ATX_APLICACAO
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_APLICACAO (
    p_id_area      IN  TB_ATX_APLICACAO.id_area%TYPE,
    p_titulo       IN  TB_ATX_APLICACAO.titulo%TYPE,
    p_descricao    IN  TB_ATX_APLICACAO.descricao%TYPE,
    p_beneficio    IN  TB_ATX_APLICACAO.beneficio%TYPE,
    p_id_aplicacao OUT TB_ATX_APLICACAO.id_aplicacao%TYPE
) IS
    v_campo         VARCHAR2(30);
    v_existe_area   PLS_INTEGER;
    e_obrigatorio   EXCEPTION;
    e_area_inexist  EXCEPTION;
    e_fk_pai        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_area IS NULL THEN
        v_campo := 'id_area';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_titulo) IS NULL THEN
        v_campo := 'titulo';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_beneficio) IS NULL THEN
        v_campo := 'beneficio';
        RAISE e_obrigatorio;
    END IF;

    SELECT COUNT(*) INTO v_existe_area FROM TB_ATX_AREA WHERE id_area = p_id_area;
    IF v_existe_area = 0 THEN
        RAISE e_area_inexist;
    END IF;

    INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio, dt_cadastro)
    VALUES (SQ_ATX_APLICACAO.NEXTVAL, p_id_area, TRIM(p_titulo), TRIM(p_descricao), TRIM(p_beneficio), SYSDATE)
    RETURNING id_aplicacao INTO p_id_aplicacao;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'APLICACAO: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_area_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'APLICACAO: a area ' || p_id_area || ' nao existe.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'APLICACAO: ja existe a aplicacao "' || p_titulo || '" nesta area.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'APLICACAO: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'APLICACAO: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_APLICACAO;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_APLICACAO (
    p_id_aplicacao IN TB_ATX_APLICACAO.id_aplicacao%TYPE,
    p_id_area      IN TB_ATX_APLICACAO.id_area%TYPE,
    p_titulo       IN TB_ATX_APLICACAO.titulo%TYPE,
    p_descricao    IN TB_ATX_APLICACAO.descricao%TYPE,
    p_beneficio    IN TB_ATX_APLICACAO.beneficio%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_existe_area    PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_area_inexist   EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_fk_pai         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_aplicacao IS NULL THEN
        v_campo := 'id_aplicacao';
        RAISE e_obrigatorio;
    ELSIF p_id_area IS NULL THEN
        v_campo := 'id_area';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_titulo) IS NULL THEN
        v_campo := 'titulo';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_beneficio) IS NULL THEN
        v_campo := 'beneficio';
        RAISE e_obrigatorio;
    END IF;

    SELECT COUNT(*) INTO v_existe_area FROM TB_ATX_AREA WHERE id_area = p_id_area;
    IF v_existe_area = 0 THEN
        RAISE e_area_inexist;
    END IF;

    UPDATE TB_ATX_APLICACAO
       SET id_area   = p_id_area,
           titulo    = TRIM(p_titulo),
           descricao = TRIM(p_descricao),
           beneficio = TRIM(p_beneficio)
     WHERE id_aplicacao = p_id_aplicacao;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'APLICACAO: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_area_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'APLICACAO: a area ' || p_id_area || ' nao existe.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'APLICACAO: id ' || p_id_aplicacao || ' nao encontrado.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'APLICACAO: ja existe a aplicacao "' || p_titulo || '" nesta area.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'APLICACAO: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'APLICACAO: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_APLICACAO;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_APLICACAO (
    p_id_aplicacao IN TB_ATX_APLICACAO.id_aplicacao%TYPE
) IS
    v_qtd_perguntas  PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_possui_filhos  EXCEPTION;
    e_fk_filho       EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_filho, -2292);
BEGIN
    IF p_id_aplicacao IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    -- Regra: aplicacao com perguntas de quiz nao pode ser excluida
    SELECT COUNT(*) INTO v_qtd_perguntas
      FROM TB_ATX_PERGUNTA
     WHERE id_aplicacao = p_id_aplicacao;

    IF v_qtd_perguntas > 0 THEN
        RAISE e_possui_filhos;
    END IF;

    DELETE FROM TB_ATX_APLICACAO WHERE id_aplicacao = p_id_aplicacao;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'APLICACAO: o campo "id_aplicacao" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'APLICACAO: id ' || p_id_aplicacao || ' nao encontrado.');
    WHEN e_possui_filhos THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'APLICACAO: id ' || p_id_aplicacao || ' possui ' || v_qtd_perguntas
            || ' pergunta(s) de quiz e nao pode ser excluida.');
    WHEN e_fk_filho THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'APLICACAO: existem registros dependentes desta aplicacao.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'APLICACAO: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_APLICACAO;
/


-- =====================================================================
-- 3. TB_ATX_PERGUNTA
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_PERGUNTA (
    p_id_aplicacao     IN  TB_ATX_PERGUNTA.id_aplicacao%TYPE,
    p_enunciado        IN  TB_ATX_PERGUNTA.enunciado%TYPE,
    p_alternativa_a    IN  TB_ATX_PERGUNTA.alternativa_a%TYPE,
    p_alternativa_b    IN  TB_ATX_PERGUNTA.alternativa_b%TYPE,
    p_alternativa_c    IN  TB_ATX_PERGUNTA.alternativa_c%TYPE,
    p_alternativa_d    IN  TB_ATX_PERGUNTA.alternativa_d%TYPE,
    p_resposta_correta IN  TB_ATX_PERGUNTA.resposta_correta%TYPE,
    p_pontos           IN  TB_ATX_PERGUNTA.pontos%TYPE DEFAULT 10,
    p_id_pergunta      OUT TB_ATX_PERGUNTA.id_pergunta%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_resposta       TB_ATX_PERGUNTA.resposta_correta%TYPE;
    v_existe_aplic   PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_aplic_inexist  EXCEPTION;
    e_resposta_inv   EXCEPTION;
    e_check          EXCEPTION;
    e_fk_pai         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_aplicacao IS NULL THEN
        v_campo := 'id_aplicacao';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_enunciado) IS NULL THEN
        v_campo := 'enunciado';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_alternativa_a) IS NULL OR TRIM(p_alternativa_b) IS NULL
       OR TRIM(p_alternativa_c) IS NULL OR TRIM(p_alternativa_d) IS NULL THEN
        v_campo := 'alternativas A, B, C e D';
        RAISE e_obrigatorio;
    END IF;

    v_resposta := UPPER(TRIM(p_resposta_correta));
    IF v_resposta IS NULL OR v_resposta NOT IN ('A', 'B', 'C', 'D') THEN
        RAISE e_resposta_inv;
    END IF;

    SELECT COUNT(*) INTO v_existe_aplic FROM TB_ATX_APLICACAO WHERE id_aplicacao = p_id_aplicacao;
    IF v_existe_aplic = 0 THEN
        RAISE e_aplic_inexist;
    END IF;

    INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado,
                                 alternativa_a, alternativa_b, alternativa_c, alternativa_d,
                                 resposta_correta, pontos)
    VALUES (SQ_ATX_PERGUNTA.NEXTVAL, p_id_aplicacao, TRIM(p_enunciado),
            TRIM(p_alternativa_a), TRIM(p_alternativa_b), TRIM(p_alternativa_c), TRIM(p_alternativa_d),
            v_resposta, NVL(p_pontos, 10))
    RETURNING id_pergunta INTO p_id_pergunta;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_resposta_inv THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: resposta_correta deve ser A, B, C ou D.');
    WHEN e_aplic_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'PERGUNTA: a aplicacao ' || p_id_aplicacao || ' nao existe.');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'PERGUNTA: pontos deve estar entre 1 e 1000.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'PERGUNTA: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_PERGUNTA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_PERGUNTA (
    p_id_pergunta      IN TB_ATX_PERGUNTA.id_pergunta%TYPE,
    p_id_aplicacao     IN TB_ATX_PERGUNTA.id_aplicacao%TYPE,
    p_enunciado        IN TB_ATX_PERGUNTA.enunciado%TYPE,
    p_alternativa_a    IN TB_ATX_PERGUNTA.alternativa_a%TYPE,
    p_alternativa_b    IN TB_ATX_PERGUNTA.alternativa_b%TYPE,
    p_alternativa_c    IN TB_ATX_PERGUNTA.alternativa_c%TYPE,
    p_alternativa_d    IN TB_ATX_PERGUNTA.alternativa_d%TYPE,
    p_resposta_correta IN TB_ATX_PERGUNTA.resposta_correta%TYPE,
    p_pontos           IN TB_ATX_PERGUNTA.pontos%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_resposta       TB_ATX_PERGUNTA.resposta_correta%TYPE;
    v_existe_aplic   PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_aplic_inexist  EXCEPTION;
    e_resposta_inv   EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_check          EXCEPTION;
    e_fk_pai         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_pergunta IS NULL THEN
        v_campo := 'id_pergunta';
        RAISE e_obrigatorio;
    ELSIF p_id_aplicacao IS NULL THEN
        v_campo := 'id_aplicacao';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_enunciado) IS NULL THEN
        v_campo := 'enunciado';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_alternativa_a) IS NULL OR TRIM(p_alternativa_b) IS NULL
       OR TRIM(p_alternativa_c) IS NULL OR TRIM(p_alternativa_d) IS NULL THEN
        v_campo := 'alternativas A, B, C e D';
        RAISE e_obrigatorio;
    ELSIF p_pontos IS NULL THEN
        v_campo := 'pontos';
        RAISE e_obrigatorio;
    END IF;

    v_resposta := UPPER(TRIM(p_resposta_correta));
    IF v_resposta IS NULL OR v_resposta NOT IN ('A', 'B', 'C', 'D') THEN
        RAISE e_resposta_inv;
    END IF;

    SELECT COUNT(*) INTO v_existe_aplic FROM TB_ATX_APLICACAO WHERE id_aplicacao = p_id_aplicacao;
    IF v_existe_aplic = 0 THEN
        RAISE e_aplic_inexist;
    END IF;

    UPDATE TB_ATX_PERGUNTA
       SET id_aplicacao     = p_id_aplicacao,
           enunciado        = TRIM(p_enunciado),
           alternativa_a    = TRIM(p_alternativa_a),
           alternativa_b    = TRIM(p_alternativa_b),
           alternativa_c    = TRIM(p_alternativa_c),
           alternativa_d    = TRIM(p_alternativa_d),
           resposta_correta = v_resposta,
           pontos           = p_pontos
     WHERE id_pergunta = p_id_pergunta;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_resposta_inv THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: resposta_correta deve ser A, B, C ou D.');
    WHEN e_aplic_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'PERGUNTA: a aplicacao ' || p_id_aplicacao || ' nao existe.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'PERGUNTA: id ' || p_id_pergunta || ' nao encontrado.');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'PERGUNTA: pontos deve estar entre 1 e 1000.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'PERGUNTA: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_PERGUNTA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_PERGUNTA (
    p_id_pergunta IN TB_ATX_PERGUNTA.id_pergunta%TYPE
) IS
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
BEGIN
    IF p_id_pergunta IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    DELETE FROM TB_ATX_PERGUNTA WHERE id_pergunta = p_id_pergunta;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PERGUNTA: o campo "id_pergunta" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'PERGUNTA: id ' || p_id_pergunta || ' nao encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'PERGUNTA: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_PERGUNTA;
/


-- =====================================================================
-- 4. TB_ATX_JOGADOR
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_JOGADOR (
    p_nome       IN  TB_ATX_JOGADOR.nome%TYPE,
    p_email      IN  TB_ATX_JOGADOR.email%TYPE,
    p_senha      IN  TB_ATX_JOGADOR.senha%TYPE,
    p_pontuacao  IN  TB_ATX_JOGADOR.pontuacao%TYPE DEFAULT 0,
    p_id_jogador OUT TB_ATX_JOGADOR.id_jogador%TYPE
) IS
    v_campo        VARCHAR2(30);
    v_email        TB_ATX_JOGADOR.email%TYPE;
    e_obrigatorio  EXCEPTION;
    e_email_inv    EXCEPTION;
    e_check        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
BEGIN
    IF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_email) IS NULL THEN
        v_campo := 'email';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_senha) IS NULL THEN
        v_campo := 'senha';
        RAISE e_obrigatorio;
    END IF;

    -- E-mail sempre gravado em minusculas para garantir unicidade real
    v_email := LOWER(TRIM(p_email));
    IF NOT REGEXP_LIKE(v_email, '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$') THEN
        RAISE e_email_inv;
    END IF;

    INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao, dt_cadastro)
    VALUES (SQ_ATX_JOGADOR.NEXTVAL, TRIM(p_nome), v_email, p_senha, NVL(p_pontuacao, 0), SYSDATE)
    RETURNING id_jogador INTO p_id_jogador;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_email_inv THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: e-mail "' || p_email || '" em formato invalido.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'JOGADOR: o e-mail "' || v_email || '" ja esta cadastrado.');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'JOGADOR: a pontuacao nao pode ser negativa.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_JOGADOR;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_JOGADOR (
    p_id_jogador IN TB_ATX_JOGADOR.id_jogador%TYPE,
    p_nome       IN TB_ATX_JOGADOR.nome%TYPE,
    p_email      IN TB_ATX_JOGADOR.email%TYPE,
    p_senha      IN TB_ATX_JOGADOR.senha%TYPE,
    p_pontuacao  IN TB_ATX_JOGADOR.pontuacao%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_email          TB_ATX_JOGADOR.email%TYPE;
    e_obrigatorio    EXCEPTION;
    e_email_inv      EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_check          EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
BEGIN
    IF p_id_jogador IS NULL THEN
        v_campo := 'id_jogador';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_email) IS NULL THEN
        v_campo := 'email';
        RAISE e_obrigatorio;
    ELSIF p_pontuacao IS NULL THEN
        v_campo := 'pontuacao';
        RAISE e_obrigatorio;
    END IF;

    v_email := LOWER(TRIM(p_email));
    IF NOT REGEXP_LIKE(v_email, '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$') THEN
        RAISE e_email_inv;
    END IF;

    -- Senha nula = mantem a atual (a API so envia quando o usuario troca)
    UPDATE TB_ATX_JOGADOR
       SET nome      = TRIM(p_nome),
           email     = v_email,
           senha     = NVL(p_senha, senha),
           pontuacao = p_pontuacao
     WHERE id_jogador = p_id_jogador;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_email_inv THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: e-mail "' || p_email || '" em formato invalido.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'JOGADOR: id ' || p_id_jogador || ' nao encontrado.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'JOGADOR: o e-mail "' || v_email || '" ja pertence a outro jogador.');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'JOGADOR: a pontuacao nao pode ser negativa.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_JOGADOR;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_JOGADOR (
    p_id_jogador IN TB_ATX_JOGADOR.id_jogador%TYPE
) IS
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
BEGIN
    IF p_id_jogador IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    -- As conquistas desbloqueadas do jogador sao removidas em cascata
    -- (FK_ATX_JC_JOGADOR ON DELETE CASCADE)
    DELETE FROM TB_ATX_JOGADOR WHERE id_jogador = p_id_jogador;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR: o campo "id_jogador" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'JOGADOR: id ' || p_id_jogador || ' nao encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_JOGADOR;
/


-- =====================================================================
-- 5. TB_ATX_CONQUISTA
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_CONQUISTA (
    p_id_area            IN  TB_ATX_CONQUISTA.id_area%TYPE,
    p_nome               IN  TB_ATX_CONQUISTA.nome%TYPE,
    p_descricao          IN  TB_ATX_CONQUISTA.descricao%TYPE,
    p_pontos_necessarios IN  TB_ATX_CONQUISTA.pontos_necessarios%TYPE,
    p_id_conquista       OUT TB_ATX_CONQUISTA.id_conquista%TYPE
) IS
    v_campo        VARCHAR2(30);
    v_existe_area  PLS_INTEGER;
    e_obrigatorio  EXCEPTION;
    e_area_inexist EXCEPTION;
    e_check        EXCEPTION;
    e_fk_pai       EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    ELSIF p_pontos_necessarios IS NULL THEN
        v_campo := 'pontos_necessarios';
        RAISE e_obrigatorio;
    END IF;

    -- id_area e opcional (conquista geral); se informado, precisa existir
    IF p_id_area IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_area FROM TB_ATX_AREA WHERE id_area = p_id_area;
        IF v_existe_area = 0 THEN
            RAISE e_area_inexist;
        END IF;
    END IF;

    INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios)
    VALUES (SQ_ATX_CONQUISTA.NEXTVAL, p_id_area, TRIM(p_nome), TRIM(p_descricao), p_pontos_necessarios)
    RETURNING id_conquista INTO p_id_conquista;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'CONQUISTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_area_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'CONQUISTA: a area ' || p_id_area || ' nao existe.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'CONQUISTA: ja existe a conquista "' || p_nome || '".');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'CONQUISTA: pontos_necessarios nao pode ser negativo.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'CONQUISTA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'CONQUISTA: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_CONQUISTA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_CONQUISTA (
    p_id_conquista       IN TB_ATX_CONQUISTA.id_conquista%TYPE,
    p_id_area            IN TB_ATX_CONQUISTA.id_area%TYPE,
    p_nome               IN TB_ATX_CONQUISTA.nome%TYPE,
    p_descricao          IN TB_ATX_CONQUISTA.descricao%TYPE,
    p_pontos_necessarios IN TB_ATX_CONQUISTA.pontos_necessarios%TYPE
) IS
    v_campo          VARCHAR2(30);
    v_existe_area    PLS_INTEGER;
    e_obrigatorio    EXCEPTION;
    e_area_inexist   EXCEPTION;
    e_nao_encontrado EXCEPTION;
    e_check          EXCEPTION;
    e_fk_pai         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check, -2290);
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_conquista IS NULL THEN
        v_campo := 'id_conquista';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_nome) IS NULL THEN
        v_campo := 'nome';
        RAISE e_obrigatorio;
    ELSIF TRIM(p_descricao) IS NULL THEN
        v_campo := 'descricao';
        RAISE e_obrigatorio;
    ELSIF p_pontos_necessarios IS NULL THEN
        v_campo := 'pontos_necessarios';
        RAISE e_obrigatorio;
    END IF;

    IF p_id_area IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_area FROM TB_ATX_AREA WHERE id_area = p_id_area;
        IF v_existe_area = 0 THEN
            RAISE e_area_inexist;
        END IF;
    END IF;

    UPDATE TB_ATX_CONQUISTA
       SET id_area            = p_id_area,
           nome               = TRIM(p_nome),
           descricao          = TRIM(p_descricao),
           pontos_necessarios = p_pontos_necessarios
     WHERE id_conquista = p_id_conquista;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'CONQUISTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_area_inexist OR e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'CONQUISTA: a area ' || p_id_area || ' nao existe.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'CONQUISTA: id ' || p_id_conquista || ' nao encontrado.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'CONQUISTA: ja existe a conquista "' || p_nome || '".');
    WHEN e_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'CONQUISTA: pontos_necessarios nao pode ser negativo.');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'CONQUISTA: valor maior que o tamanho permitido para a coluna.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'CONQUISTA: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_CONQUISTA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_CONQUISTA (
    p_id_conquista IN TB_ATX_CONQUISTA.id_conquista%TYPE
) IS
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
BEGIN
    IF p_id_conquista IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    -- Os desbloqueios desta conquista sao removidos em cascata
    -- (FK_ATX_JC_CONQUISTA ON DELETE CASCADE)
    DELETE FROM TB_ATX_CONQUISTA WHERE id_conquista = p_id_conquista;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'CONQUISTA: o campo "id_conquista" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'CONQUISTA: id ' || p_id_conquista || ' nao encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'CONQUISTA: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_CONQUISTA;
/


-- =====================================================================
-- 6. TB_ATX_JOGADOR_CONQUISTA
--    REGRA DE NEGOCIO (mesma do console .NET): o jogador so desbloqueia
--    a conquista se pontuacao >= pontos_necessarios.
-- =====================================================================

CREATE OR REPLACE PROCEDURE PRC_ATX_INS_JOGADOR_CONQUISTA (
    p_id_jogador     IN TB_ATX_JOGADOR_CONQUISTA.id_jogador%TYPE,
    p_id_conquista   IN TB_ATX_JOGADOR_CONQUISTA.id_conquista%TYPE,
    p_dt_desbloqueio IN TB_ATX_JOGADOR_CONQUISTA.dt_desbloqueio%TYPE DEFAULT NULL
) IS
    v_campo               VARCHAR2(30);
    v_pontuacao           TB_ATX_JOGADOR.pontuacao%TYPE;
    v_pontos_necessarios  TB_ATX_CONQUISTA.pontos_necessarios%TYPE;
    e_obrigatorio         EXCEPTION;
    e_jogador_inexist     EXCEPTION;
    e_conquista_inexist   EXCEPTION;
    e_pontos_insuf        EXCEPTION;
    e_fk_pai              EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fk_pai, -2291);
BEGIN
    IF p_id_jogador IS NULL THEN
        v_campo := 'id_jogador';
        RAISE e_obrigatorio;
    ELSIF p_id_conquista IS NULL THEN
        v_campo := 'id_conquista';
        RAISE e_obrigatorio;
    END IF;

    BEGIN
        SELECT pontuacao INTO v_pontuacao
          FROM TB_ATX_JOGADOR WHERE id_jogador = p_id_jogador;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_jogador_inexist;
    END;

    BEGIN
        SELECT pontos_necessarios INTO v_pontos_necessarios
          FROM TB_ATX_CONQUISTA WHERE id_conquista = p_id_conquista;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_conquista_inexist;
    END;

    IF v_pontuacao < v_pontos_necessarios THEN
        RAISE e_pontos_insuf;
    END IF;

    INSERT INTO TB_ATX_JOGADOR_CONQUISTA (id_jogador, id_conquista, dt_desbloqueio)
    VALUES (p_id_jogador, p_id_conquista, NVL(p_dt_desbloqueio, SYSDATE));

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR_CONQUISTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_jogador_inexist THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'JOGADOR_CONQUISTA: o jogador ' || p_id_jogador || ' nao existe.');
    WHEN e_conquista_inexist THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'JOGADOR_CONQUISTA: a conquista ' || p_id_conquista || ' nao existe.');
    WHEN e_fk_pai THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'JOGADOR_CONQUISTA: jogador ou conquista inexistente.');
    WHEN e_pontos_insuf THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'JOGADOR_CONQUISTA: pontuacao insuficiente - o jogador tem '
            || v_pontuacao || ' ponto(s) e a conquista exige ' || v_pontos_necessarios || '.');
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'JOGADOR_CONQUISTA: o jogador ' || p_id_jogador
            || ' ja desbloqueou a conquista ' || p_id_conquista || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR_CONQUISTA: erro inesperado ao inserir - ' || SQLERRM);
END PRC_ATX_INS_JOGADOR_CONQUISTA;
/

-- A PK e composta (id_jogador, id_conquista); o unico atributo nao-chave
-- e dt_desbloqueio, que e o que o UPDATE altera (ex.: corrigir data).
CREATE OR REPLACE PROCEDURE PRC_ATX_UPD_JOGADOR_CONQUISTA (
    p_id_jogador     IN TB_ATX_JOGADOR_CONQUISTA.id_jogador%TYPE,
    p_id_conquista   IN TB_ATX_JOGADOR_CONQUISTA.id_conquista%TYPE,
    p_dt_desbloqueio IN TB_ATX_JOGADOR_CONQUISTA.dt_desbloqueio%TYPE
) IS
    v_campo          VARCHAR2(30);
    e_obrigatorio    EXCEPTION;
    e_data_futura    EXCEPTION;
    e_nao_encontrado EXCEPTION;
BEGIN
    IF p_id_jogador IS NULL THEN
        v_campo := 'id_jogador';
        RAISE e_obrigatorio;
    ELSIF p_id_conquista IS NULL THEN
        v_campo := 'id_conquista';
        RAISE e_obrigatorio;
    ELSIF p_dt_desbloqueio IS NULL THEN
        v_campo := 'dt_desbloqueio';
        RAISE e_obrigatorio;
    END IF;

    IF p_dt_desbloqueio > SYSDATE THEN
        RAISE e_data_futura;
    END IF;

    UPDATE TB_ATX_JOGADOR_CONQUISTA
       SET dt_desbloqueio = p_dt_desbloqueio
     WHERE id_jogador   = p_id_jogador
       AND id_conquista = p_id_conquista;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR_CONQUISTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_data_futura THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'JOGADOR_CONQUISTA: a data de desbloqueio nao pode estar no futuro.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'JOGADOR_CONQUISTA: o jogador ' || p_id_jogador
            || ' nao possui a conquista ' || p_id_conquista || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR_CONQUISTA: erro inesperado ao atualizar - ' || SQLERRM);
END PRC_ATX_UPD_JOGADOR_CONQUISTA;
/

CREATE OR REPLACE PROCEDURE PRC_ATX_DEL_JOGADOR_CONQUISTA (
    p_id_jogador   IN TB_ATX_JOGADOR_CONQUISTA.id_jogador%TYPE,
    p_id_conquista IN TB_ATX_JOGADOR_CONQUISTA.id_conquista%TYPE
) IS
    v_campo          VARCHAR2(30);
    e_obrigatorio    EXCEPTION;
    e_nao_encontrado EXCEPTION;
BEGIN
    IF p_id_jogador IS NULL THEN
        v_campo := 'id_jogador';
        RAISE e_obrigatorio;
    ELSIF p_id_conquista IS NULL THEN
        v_campo := 'id_conquista';
        RAISE e_obrigatorio;
    END IF;

    DELETE FROM TB_ATX_JOGADOR_CONQUISTA
     WHERE id_jogador   = p_id_jogador
       AND id_conquista = p_id_conquista;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE e_nao_encontrado;
    END IF;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'JOGADOR_CONQUISTA: o campo "' || v_campo || '" e obrigatorio.');
    WHEN e_nao_encontrado THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'JOGADOR_CONQUISTA: o jogador ' || p_id_jogador
            || ' nao possui a conquista ' || p_id_conquista || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'JOGADOR_CONQUISTA: erro inesperado ao excluir - ' || SQLERRM);
END PRC_ATX_DEL_JOGADOR_CONQUISTA;
/


-- =====================================================================
-- 7. REGRA DE NEGOCIO - desbloqueio automatico de conquistas
--    Percorre (cursor) todas as conquistas que o jogador ja atingiu pela
--    pontuacao e ainda nao possui, registrando o desbloqueio.
--    Usada pela API depois que o jogador termina um quiz.
-- =====================================================================
CREATE OR REPLACE PROCEDURE PRC_ATX_DESBLOQUEAR_CONQUISTAS (
    p_id_jogador     IN  TB_ATX_JOGADOR.id_jogador%TYPE,
    p_qtd_desbloq    OUT NUMBER
) IS
    v_pontuacao       TB_ATX_JOGADOR.pontuacao%TYPE;
    e_obrigatorio     EXCEPTION;
    e_jogador_inexist EXCEPTION;

    CURSOR c_conquistas_disponiveis (pc_pontuacao NUMBER, pc_id_jogador NUMBER) IS
        SELECT c.id_conquista
          FROM TB_ATX_CONQUISTA c
         WHERE c.pontos_necessarios <= pc_pontuacao
           AND NOT EXISTS (SELECT 1
                             FROM TB_ATX_JOGADOR_CONQUISTA jc
                            WHERE jc.id_jogador   = pc_id_jogador
                              AND jc.id_conquista = c.id_conquista)
         ORDER BY c.pontos_necessarios;
BEGIN
    p_qtd_desbloq := 0;

    IF p_id_jogador IS NULL THEN
        RAISE e_obrigatorio;
    END IF;

    BEGIN
        SELECT pontuacao INTO v_pontuacao
          FROM TB_ATX_JOGADOR WHERE id_jogador = p_id_jogador;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_jogador_inexist;
    END;

    FOR r IN c_conquistas_disponiveis(v_pontuacao, p_id_jogador) LOOP
        INSERT INTO TB_ATX_JOGADOR_CONQUISTA (id_jogador, id_conquista, dt_desbloqueio)
        VALUES (p_id_jogador, r.id_conquista, SYSDATE);
        p_qtd_desbloq := p_qtd_desbloq + 1;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN e_obrigatorio THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'DESBLOQUEIO: o campo "id_jogador" e obrigatorio.');
    WHEN e_jogador_inexist THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'DESBLOQUEIO: o jogador ' || p_id_jogador || ' nao existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20099, 'DESBLOQUEIO: erro inesperado - ' || SQLERRM);
END PRC_ATX_DESBLOQUEAR_CONQUISTAS;
/


-- =====================================================================
-- 8. TIPOS USADOS PELAS FUNCTIONS (retorno do tipo TABLE)
--    (DROP FORCE permite reexecutar o script; ignore o ORA-04043 na
--    primeira execucao)
-- =====================================================================
BEGIN
    FOR t IN (SELECT type_name FROM user_types
               WHERE type_name IN ('T_ATX_REL_APLICACAO_TAB', 'T_ATX_REL_APLICACAO_OBJ',
                                   'T_ATX_RANKING_TAB', 'T_ATX_RANKING_OBJ')
               ORDER BY CASE WHEN type_name LIKE '%_TAB' THEN 1 ELSE 2 END) LOOP
        EXECUTE IMMEDIATE 'DROP TYPE ' || t.type_name || ' FORCE';
    END LOOP;
END;
/

CREATE OR REPLACE TYPE T_ATX_REL_APLICACAO_OBJ AS OBJECT (
    area             VARCHAR2(50),
    id_aplicacao     NUMBER(10),
    titulo           VARCHAR2(120),
    beneficio        VARCHAR2(500),
    qtd_perguntas    NUMBER,
    pontos_quiz      NUMBER,
    linha_relatorio  VARCHAR2(400)
);
/

CREATE OR REPLACE TYPE T_ATX_REL_APLICACAO_TAB AS TABLE OF T_ATX_REL_APLICACAO_OBJ;
/

CREATE OR REPLACE TYPE T_ATX_RANKING_OBJ AS OBJECT (
    posicao            NUMBER,
    id_jogador         NUMBER(10),
    jogador            VARCHAR2(100),
    pontuacao          NUMBER(8),
    nivel              VARCHAR2(30),
    qtd_conquistas     NUMBER,
    perc_conquistas    NUMBER(5,1),
    soma_pontos_conq   NUMBER,
    ultima_conquista   DATE
);
/

CREATE OR REPLACE TYPE T_ATX_RANKING_TAB AS TABLE OF T_ATX_RANKING_OBJ;
/


-- =====================================================================
-- 9. FUNCTION 1 - RELATORIO DE APLICACOES POR AREA
--    * Retorno do tipo TABLE (T_ATX_REL_APLICACAO_TAB)
--    * CURSOR explicito (OPEN / FETCH / CLOSE)
--    * INNER JOIN AREA x APLICACAO  e  LEFT JOIN com PERGUNTA
--      (aplicacoes ainda sem quiz aparecem com 0 perguntas)
--    * Gera uma linha de relatorio formatada para cada aplicacao
--    Parametro opcional p_id_area: NULL = todas as areas.
--    Uso: SELECT * FROM TABLE(FN_ATX_RELATORIO_APLICACOES());
--         SELECT * FROM TABLE(FN_ATX_RELATORIO_APLICACOES(1));
-- =====================================================================
CREATE OR REPLACE FUNCTION FN_ATX_RELATORIO_APLICACOES (
    p_id_area IN TB_ATX_AREA.id_area%TYPE DEFAULT NULL
) RETURN T_ATX_REL_APLICACAO_TAB
IS
    CURSOR c_relatorio IS
        SELECT ar.nome                         AS area,
               ap.id_aplicacao,
               ap.titulo,
               ap.beneficio,
               COUNT(pe.id_pergunta)           AS qtd_perguntas,
               NVL(SUM(pe.pontos), 0)          AS pontos_quiz
          FROM TB_ATX_AREA ar
         INNER JOIN TB_ATX_APLICACAO ap ON ap.id_area      = ar.id_area
          LEFT JOIN TB_ATX_PERGUNTA  pe ON pe.id_aplicacao = ap.id_aplicacao
         WHERE (p_id_area IS NULL OR ar.id_area = p_id_area)
         GROUP BY ar.nome, ap.id_aplicacao, ap.titulo, ap.beneficio
         ORDER BY ar.nome, ap.titulo;

    v_reg        c_relatorio%ROWTYPE;
    v_resultado  T_ATX_REL_APLICACAO_TAB := T_ATX_REL_APLICACAO_TAB();
    v_linha      VARCHAR2(400);
    v_situacao   VARCHAR2(20);
BEGIN
    OPEN c_relatorio;
    LOOP
        FETCH c_relatorio INTO v_reg;
        EXIT WHEN c_relatorio%NOTFOUND;

        -- Indica se a aplicacao ja esta pronta para o quiz do app
        IF v_reg.qtd_perguntas = 0 THEN
            v_situacao := 'SEM QUIZ';
        ELSE
            v_situacao := 'QUIZ ATIVO';
        END IF;

        v_linha := RPAD(UPPER(v_reg.area), 20, '.') || ' '
                || RPAD(SUBSTR(v_reg.titulo, 1, 45), 45, ' ') || ' | '
                || LPAD(v_reg.qtd_perguntas, 2, ' ') || ' pergunta(s) | '
                || LPAD(v_reg.pontos_quiz, 4, ' ') || ' pts | '
                || v_situacao;

        v_resultado.EXTEND;
        v_resultado(v_resultado.LAST) := T_ATX_REL_APLICACAO_OBJ(
            v_reg.area, v_reg.id_aplicacao, v_reg.titulo, v_reg.beneficio,
            v_reg.qtd_perguntas, v_reg.pontos_quiz, v_linha);
    END LOOP;
    CLOSE c_relatorio;

    RETURN v_resultado;
EXCEPTION
    WHEN OTHERS THEN
        IF c_relatorio%ISOPEN THEN
            CLOSE c_relatorio;
        END IF;
        RAISE_APPLICATION_ERROR(-20099, 'RELATORIO APLICACOES: erro ao gerar - ' || SQLERRM);
END FN_ATX_RELATORIO_APLICACOES;
/


-- =====================================================================
-- 10. FUNCTION 2 - RANKING DE JOGADORES (regra de negocio de nivel)
--    * Retorno do tipo TABLE (T_ATX_RANKING_TAB)
--    * INNER JOIN JOGADOR x JOGADOR_CONQUISTA x CONQUISTA
--    * GROUP BY por jogador com COUNT, SUM e MAX
--    * ORDER BY pontuacao DESC, qtd de conquistas DESC, nome
--    REGRAS DE NEGOCIO:
--      - Nivel do jogador pela pontuacao:
--          0-99 Aprendiz Atomico | 100-299 Explorador Nuclear
--          300-599 Cientista do Atomo | 600-999 Especialista CTMSP
--          1000+ Mestre Nuclear
--      - Percentual de conquistas = desbloqueadas / total cadastradas
--      - Posicao no ranking (empate de pontuacao = mesma posicao)
--    Parametro p_min_conquistas: so lista quem tem pelo menos N conquistas.
--    Uso: SELECT * FROM TABLE(FN_ATX_RANKING_JOGADORES());
--         SELECT * FROM TABLE(FN_ATX_RANKING_JOGADORES(2));
-- =====================================================================
CREATE OR REPLACE FUNCTION FN_ATX_RANKING_JOGADORES (
    p_min_conquistas IN NUMBER DEFAULT 1
) RETURN T_ATX_RANKING_TAB
IS
    v_resultado       T_ATX_RANKING_TAB := T_ATX_RANKING_TAB();
    v_total_conq      NUMBER;
    v_posicao         NUMBER := 0;
    v_contador        NUMBER := 0;
    v_pontuacao_ant   NUMBER := -1;
    v_nivel           VARCHAR2(30);
    v_percentual      NUMBER(5,1);
BEGIN
    SELECT COUNT(*) INTO v_total_conq FROM TB_ATX_CONQUISTA;

    FOR r IN (
        SELECT j.id_jogador,
               j.nome,
               j.pontuacao,
               COUNT(jc.id_conquista)    AS qtd_conquistas,
               SUM(c.pontos_necessarios) AS soma_pontos_conq,
               MAX(jc.dt_desbloqueio)    AS ultima_conquista
          FROM TB_ATX_JOGADOR j
         INNER JOIN TB_ATX_JOGADOR_CONQUISTA jc ON jc.id_jogador   = j.id_jogador
         INNER JOIN TB_ATX_CONQUISTA         c  ON c.id_conquista  = jc.id_conquista
         GROUP BY j.id_jogador, j.nome, j.pontuacao
        HAVING COUNT(jc.id_conquista) >= NVL(p_min_conquistas, 1)
         ORDER BY j.pontuacao DESC, COUNT(jc.id_conquista) DESC, j.nome
    ) LOOP
        v_contador := v_contador + 1;
        IF r.pontuacao <> v_pontuacao_ant THEN
            v_posicao := v_contador;
        END IF;
        v_pontuacao_ant := r.pontuacao;

        v_nivel := CASE
                       WHEN r.pontuacao >= 1000 THEN 'Mestre Nuclear'
                       WHEN r.pontuacao >= 600  THEN 'Especialista CTMSP'
                       WHEN r.pontuacao >= 300  THEN TO_CHAR(UNISTR('Cientista do \00C1tomo'))
                       WHEN r.pontuacao >= 100  THEN 'Explorador Nuclear'
                       ELSE TO_CHAR(UNISTR('Aprendiz At\00F4mico'))
                   END;

        IF v_total_conq > 0 THEN
            v_percentual := ROUND(r.qtd_conquistas * 100 / v_total_conq, 1);
        ELSE
            v_percentual := 0;
        END IF;

        v_resultado.EXTEND;
        v_resultado(v_resultado.LAST) := T_ATX_RANKING_OBJ(
            v_posicao, r.id_jogador, r.nome, r.pontuacao, v_nivel,
            r.qtd_conquistas, v_percentual, r.soma_pontos_conq, r.ultima_conquista);
    END LOOP;

    RETURN v_resultado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'RANKING JOGADORES: erro ao gerar - ' || SQLERRM);
END FN_ATX_RANKING_JOGADORES;
/


-- =====================================================================
-- 11. CONSULTAS DE DEMONSTRACAO (executar depois da carga via API)
-- =====================================================================
-- Relatorio formatado (todas as areas)
-- SELECT linha_relatorio FROM TABLE(FN_ATX_RELATORIO_APLICACOES());

-- Relatorio completo de uma area
-- SELECT * FROM TABLE(FN_ATX_RELATORIO_APLICACOES(1));

-- Ranking de jogadores
-- SELECT posicao, jogador, pontuacao, nivel, qtd_conquistas, perc_conquistas
--   FROM TABLE(FN_ATX_RANKING_JOGADORES());

-- Conferencia: quantidade de registros por tabela (minimo 10 via API)
-- SELECT 'AREA' tabela, COUNT(*) qtd FROM TB_ATX_AREA UNION ALL
-- SELECT 'APLICACAO', COUNT(*) FROM TB_ATX_APLICACAO UNION ALL
-- SELECT 'PERGUNTA', COUNT(*) FROM TB_ATX_PERGUNTA UNION ALL
-- SELECT 'JOGADOR', COUNT(*) FROM TB_ATX_JOGADOR UNION ALL
-- SELECT 'CONQUISTA', COUNT(*) FROM TB_ATX_CONQUISTA UNION ALL
-- SELECT 'JOGADOR_CONQUISTA', COUNT(*) FROM TB_ATX_JOGADOR_CONQUISTA;

-- Fim do arquivo PL/SQL
