package br.com.fiap.atomix.database;

/**
 * Erro de negócio levantado por uma procedure com RAISE_APPLICATION_ERROR.
 * O {@link #getCodigo()} é o código Oracle (ex.: -20002) e define o status HTTP
 * no {@link br.com.fiap.atomix.exception.GlobalExceptionHandler}:
 * <pre>
 *  -20001 campo obrigatório/valor inválido  → 400
 *  -20002 registro duplicado                → 409
 *  -20003 registro pai inexistente (FK)     → 404
 *  -20004 registro não encontrado           → 404
 *  -20005 exclusão bloqueada por filhos     → 409
 *  -20006 regra de negócio violada          → 422
 *  -20007 violação de CHECK                 → 400
 *  -20099 erro inesperado                   → 500
 * </pre>
 */
public class ErroBancoException extends RuntimeException {

    private final int codigo;

    public ErroBancoException(int codigo, String mensagem, Throwable causa) {
        super(mensagem, causa);
        this.codigo = codigo;
    }

    public int getCodigo() {
        return codigo;
    }
}
