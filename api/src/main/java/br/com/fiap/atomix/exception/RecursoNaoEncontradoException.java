package br.com.fiap.atomix.exception;

/** Lançada quando um recurso buscado não existe (HTTP 404). */
public class RecursoNaoEncontradoException extends RuntimeException {

    public RecursoNaoEncontradoException(String mensagem) {
        super(mensagem);
    }

    public RecursoNaoEncontradoException(String recurso, Long id) {
        this(recurso + " com id " + id + " não encontrado(a)");
    }
}
