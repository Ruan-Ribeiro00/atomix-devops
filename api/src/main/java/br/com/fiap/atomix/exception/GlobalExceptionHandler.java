package br.com.fiap.atomix.exception;

import br.com.fiap.atomix.database.ErroBancoException;
import br.com.fiap.atomix.dto.ErroResponse;
import br.com.fiap.atomix.dto.ErroResponse.CampoErro;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.InvalidDataAccessApiUsageException;
import org.springframework.data.mapping.PropertyReferenceException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Tratamento global de exceções: toda falha da API é convertida em um {@link ErroResponse}
 * com status HTTP adequado, sem expor stack trace ao cliente.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // ---------- 400 Bad Request ----------

    /** Falhas de @Valid no corpo da requisição (inclui validações de classe, como @AlternativasDistintas). */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErroResponse> validacaoCorpo(MethodArgumentNotValidException ex, HttpServletRequest req) {
        List<CampoErro> campos = new ArrayList<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(fe -> campos.add(new CampoErro(fe.getField(), mensagemDoCampo(fe))));
        ex.getBindingResult().getGlobalErrors()
                .forEach(ge -> campos.add(new CampoErro(ge.getObjectName(), ge.getDefaultMessage())));
        return resposta(HttpStatus.BAD_REQUEST, "Dados inválidos na requisição", req, campos);
    }

    /** Falhas de validação em parâmetros de query/path (ex.: @Size no termo de busca). */
    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ErroResponse> validacaoParametros(HandlerMethodValidationException ex, HttpServletRequest req) {
        List<CampoErro> campos = ex.getParameterValidationResults().stream()
                .flatMap(r -> r.getResolvableErrors().stream()
                        .map(e -> new CampoErro(r.getMethodParameter().getParameterName(), e.getDefaultMessage())))
                .toList();
        return resposta(HttpStatus.BAD_REQUEST, "Parâmetros inválidos na requisição", req, campos);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErroResponse> violacaoRestricao(ConstraintViolationException ex, HttpServletRequest req) {
        List<CampoErro> campos = ex.getConstraintViolations().stream()
                .map(v -> new CampoErro(v.getPropertyPath().toString(), v.getMessage()))
                .toList();
        return resposta(HttpStatus.BAD_REQUEST, "Dados inválidos na requisição", req, campos);
    }

    /** JSON malformado ou valor que não pode ser convertido (ex.: respostaCorreta = "E"). */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErroResponse> corpoIlegivel(HttpMessageNotReadableException ex, HttpServletRequest req) {
        return resposta(HttpStatus.BAD_REQUEST,
                "Corpo da requisição inválido. Verifique o formato do JSON e os valores enviados "
                        + "(datas no formato AAAA-MM-DD).", req, null);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErroResponse> tipoInvalido(MethodArgumentTypeMismatchException ex, HttpServletRequest req) {
        String msg = "O parâmetro '%s' recebeu um valor inválido: '%s'".formatted(ex.getName(), ex.getValue());
        return resposta(HttpStatus.BAD_REQUEST, msg, req, null);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErroResponse> parametroAusente(MissingServletRequestParameterException ex, HttpServletRequest req) {
        return resposta(HttpStatus.BAD_REQUEST,
                "O parâmetro obrigatório '%s' não foi informado".formatted(ex.getParameterName()), req, null);
    }

    /** Campo de ordenação inexistente em ?sort=... */
    @ExceptionHandler({PropertyReferenceException.class, InvalidDataAccessApiUsageException.class})
    public ResponseEntity<ErroResponse> ordenacaoInvalida(RuntimeException ex, HttpServletRequest req) {
        return resposta(HttpStatus.BAD_REQUEST,
                "Parâmetro de ordenação ou consulta inválido: " + ex.getMessage(), req, null);
    }

    // ---------- 404 / 405 / 415 ----------

    @ExceptionHandler(RecursoNaoEncontradoException.class)
    public ResponseEntity<ErroResponse> naoEncontrado(RecursoNaoEncontradoException ex, HttpServletRequest req) {
        return resposta(HttpStatus.NOT_FOUND, ex.getMessage(), req, null);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErroResponse> rotaInexistente(NoResourceFoundException ex, HttpServletRequest req) {
        return resposta(HttpStatus.NOT_FOUND, "Endpoint não encontrado. Consulte a documentação em /swagger-ui.html", req, null);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErroResponse> metodoNaoSuportado(HttpRequestMethodNotSupportedException ex, HttpServletRequest req) {
        return resposta(HttpStatus.METHOD_NOT_ALLOWED,
                "Método %s não é suportado neste endpoint".formatted(ex.getMethod()), req, null);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErroResponse> midiaNaoSuportada(HttpMediaTypeNotSupportedException ex, HttpServletRequest req) {
        return resposta(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Envie o corpo como application/json", req, null);
    }

    // ---------- Erros levantados pelas procedures (RAISE_APPLICATION_ERROR) ----------

    /** Traduz o código ORA-200xx da procedure no status HTTP correspondente. */
    @ExceptionHandler(ErroBancoException.class)
    public ResponseEntity<ErroResponse> erroProcedure(ErroBancoException ex, HttpServletRequest req) {
        HttpStatus status = switch (ex.getCodigo()) {
            case -20001, -20007 -> HttpStatus.BAD_REQUEST;
            case -20002, -20005 -> HttpStatus.CONFLICT;
            case -20003, -20004 -> HttpStatus.NOT_FOUND;
            case -20006 -> HttpStatus.UNPROCESSABLE_ENTITY;
            default -> HttpStatus.INTERNAL_SERVER_ERROR;
        };
        if (status.is5xxServerError()) {
            log.error("Erro inesperado na procedure: {}", ex.getMessage(), ex);
        }
        var corpo = new ErroResponse(LocalDateTime.now(), status.value(), status.getReasonPhrase(),
                ex.getMessage(), req.getRequestURI(), ex.getCodigo(), null);
        return ResponseEntity.status(status).body(corpo);
    }

    // ---------- 409 Conflict ----------

    /** Rede de segurança caso uma constraint do banco (UNIQUE/FK) seja violada. */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErroResponse> integridade(DataIntegrityViolationException ex, HttpServletRequest req) {
        log.warn("Violação de integridade: {}", ex.getMostSpecificCause().getMessage());
        return resposta(HttpStatus.CONFLICT,
                "A operação viola uma regra de integridade do banco (registro duplicado ou em uso)", req, null);
    }

    // ---------- 500 ----------

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErroResponse> erroInesperado(Exception ex, HttpServletRequest req) {
        log.error("Erro inesperado em {} {}", req.getMethod(), req.getRequestURI(), ex);
        return resposta(HttpStatus.INTERNAL_SERVER_ERROR, "Erro interno inesperado. Tente novamente mais tarde.", req, null);
    }

    // ---------- utilitários ----------

    private static String mensagemDoCampo(FieldError fe) {
        if (fe.isBindingFailure()) {
            return "Valor inválido para o campo '%s'".formatted(fe.getField());
        }
        return fe.getDefaultMessage();
    }

    private static ResponseEntity<ErroResponse> resposta(HttpStatus status, String mensagem,
                                                         HttpServletRequest req, List<CampoErro> campos) {
        var corpo = new ErroResponse(LocalDateTime.now(), status.value(), status.getReasonPhrase(),
                mensagem, req.getRequestURI(), null, campos);
        return ResponseEntity.status(status).body(corpo);
    }
}
