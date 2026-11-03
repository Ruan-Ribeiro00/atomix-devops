package br.com.fiap.atomix.database;

import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Converte o ORA-200xx levantado pelas procedures em {@link ErroBancoException}. */
public final class TradutorErroOracle {

    private static final Pattern ORA_APLICACAO = Pattern.compile("ORA-(20\\d{3}):\\s*([^\\n]+)");

    private TradutorErroOracle() {
    }

    /** Devolve a exceção traduzida ou {@code null} se o erro não veio de RAISE_APPLICATION_ERROR. */
    public static ErroBancoException traduzir(Throwable erro) {
        for (Throwable t = erro; t != null; t = t.getCause()) {
            if (t instanceof SQLException sql) {
                int codigo = sql.getErrorCode();
                String texto = sql.getMessage() == null ? "" : sql.getMessage();
                Matcher m = ORA_APLICACAO.matcher(texto);
                if (m.find()) {
                    return new ErroBancoException(-Integer.parseInt(m.group(1)), m.group(2).trim(), erro);
                }
                if (codigo >= 20000 && codigo <= 20999) {
                    return new ErroBancoException(-codigo, texto.trim(), erro);
                }
            }
        }
        return null;
    }
}
