package br.com.fiap.atomix.database;

import org.junit.jupiter.api.Test;
import org.springframework.orm.jpa.JpaSystemException;

import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.*;

class ProcedimentosTest {

    @Test
    void devolveOResultadoDaProcedure() {
        assertEquals(7L, Procedimentos.executar("PRC_ATX_INS_AREA", () -> 7L));
    }

    @Test
    void converteRaiseApplicationErrorEmErroBancoException() {
        var sql = new SQLException("ORA-20006: JOGADOR_CONQUISTA: pontuacao insuficiente.", "72000", 20006);
        var erroJpa = new JpaSystemException(new RuntimeException("could not execute procedure", sql));

        ErroBancoException erro = assertThrows(ErroBancoException.class,
                () -> Procedimentos.executar("PRC_ATX_INS_JOGADOR_CONQUISTA", () -> { throw erroJpa; }));

        assertEquals(-20006, erro.getCodigo());
        assertEquals("JOGADOR_CONQUISTA: pontuacao insuficiente.", erro.getMessage());
    }

    @Test
    void repassaErrosQueNaoSaoDaProcedure() {
        var outro = new IllegalStateException("falha de conexão");
        assertSame(outro, assertThrows(IllegalStateException.class,
                () -> Procedimentos.executar("PRC_ATX_DEL_AREA", (Runnable) () -> { throw outro; })));
    }
}
