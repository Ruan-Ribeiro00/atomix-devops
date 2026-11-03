package br.com.fiap.atomix.database;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.UncategorizedSQLException;

import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.*;

class TradutorErroOracleTest {

    @Test
    void traduzRaiseApplicationErrorDaProcedure() {
        var sql = new SQLException("ORA-20002: AREA: ja existe uma area com o nome \"Saúde\".\n"
                + "ORA-06512: em \"ATOMIX.PRC_ATX_INS_AREA\", line 40", "72000", 20002);
        var erro = new UncategorizedSQLException("CallableStatementCallback", "{call PRC_ATX_INS_AREA}", sql);

        ErroBancoException traduzido = TradutorErroOracle.traduzir(erro);

        assertNotNull(traduzido);
        assertEquals(-20002, traduzido.getCodigo());
        assertEquals("AREA: ja existe uma area com o nome \"Saúde\".", traduzido.getMessage());
    }

    @Test
    void ignoraErrosQueNaoVieramDeRaiseApplicationError() {
        var sql = new SQLException("ORA-00942: tabela ou view não existe", "42000", 942);
        assertNull(TradutorErroOracle.traduzir(new UncategorizedSQLException("x", "select", sql)));
        assertNull(TradutorErroOracle.traduzir(new RuntimeException("sem SQLException")));
    }
}
