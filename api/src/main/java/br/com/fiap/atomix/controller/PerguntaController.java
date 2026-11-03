package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.*;
import br.com.fiap.atomix.service.PerguntaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;

@RestController
@RequestMapping("/api/perguntas")
@Tag(name = "Perguntas do Quiz", description = "Perguntas sobre as aplicações. Gravação via PRC_ATX_INS/UPD/DEL_PERGUNTA")
public class PerguntaController {

    private final PerguntaService service;

    public PerguntaController(PerguntaService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar perguntas (com gabarito)", description = "Filtre por aplicação com `idAplicacao`.")
    public List<PerguntaResponse> listar(@Parameter(description = "Filtra pela aplicação", example = "1") @RequestParam(required = false) Long idAplicacao) {
        return service.listar(idAplicacao);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalhar pergunta")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Pergunta encontrada"),
            @ApiResponse(responseCode = "404", description = "Pergunta não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public PerguntaResponse buscar(@Parameter(description = "ID da pergunta", example = "1") @PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @PostMapping
    @Operation(summary = "Cadastrar pergunta",
            description = "Chama PRC_ATX_INS_PERGUNTA. As 4 alternativas precisam ser diferentes (@AlternativasDistintas).")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Pergunta criada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos (ex.: resposta fora de A-D)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Aplicação não existe (ORA-20003)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<PerguntaResponse> criar(@RequestBody @Valid PerguntaRequest request) {
        PerguntaResponse criada = service.criar(request);
        var uri = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}").buildAndExpand(criada.idPergunta()).toUri();
        return ResponseEntity.created(uri).body(criada);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar pergunta", description = "Chama PRC_ATX_UPD_PERGUNTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Pergunta atualizada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Pergunta ou aplicação inexistente",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public PerguntaResponse atualizar(@Parameter(description = "ID da pergunta", example = "1") @PathVariable Long id,
                                      @RequestBody @Valid PerguntaRequest request) {
        return service.atualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir pergunta", description = "Chama PRC_ATX_DEL_PERGUNTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Pergunta excluída"),
            @ApiResponse(responseCode = "404", description = "Pergunta não encontrada (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> excluir(@Parameter(description = "ID da pergunta", example = "11") @PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/responder")
    @Operation(summary = "Responder pergunta", description = "Corrige a resposta e devolve os pontos ganhos.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Resultado da resposta"),
            @ApiResponse(responseCode = "400", description = "Alternativa inválida",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Pergunta não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResultadoRespostaResponse responder(@Parameter(description = "ID da pergunta", example = "1") @PathVariable Long id,
                                               @RequestBody @Valid RespostaRequest request) {
        return service.responder(id, request);
    }
}
