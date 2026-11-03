package br.com.fiap.atomix.database;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.function.Supplier;

/**
 * Envolve as chamadas às procedures PRC_ATX_* (métodos {@code @Procedure} dos repositórios):
 * registra no log qual procedure foi executada e converte o erro levantado por
 * RAISE_APPLICATION_ERROR (ORA-200xx) em {@link ErroBancoException}, que o
 * GlobalExceptionHandler transforma no status HTTP correspondente.
 */
public final class Procedimentos {

    private static final Logger log = LoggerFactory.getLogger(Procedimentos.class);

    private Procedimentos() {
    }

    public static <T> T executar(String procedure, Supplier<T> chamada) {
        log.info("CALL {}", procedure);
        try {
            return chamada.get();
        } catch (RuntimeException ex) {
            ErroBancoException traduzido = TradutorErroOracle.traduzir(ex);
            if (traduzido != null) {
                log.info("{} -> ORA{}: {}", procedure, traduzido.getCodigo(), traduzido.getMessage());
                throw traduzido;
            }
            throw ex;
        }
    }

    public static void executar(String procedure, Runnable chamada) {
        executar(procedure, () -> {
            chamada.run();
            return null;
        });
    }
}
