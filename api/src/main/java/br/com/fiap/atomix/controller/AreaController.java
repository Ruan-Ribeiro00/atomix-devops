package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.AreaRequest;
import br.com.fiap.atomix.dto.AreaResponse;
import br.com.fiap.atomix.dto.ErroResponse;
import br.com.fiap.atomix.dto.QuizPerguntaResponse;
import br.com.fiap.atomix.service.AreaService;
import br.com.fiap.atomix.service.PerguntaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;

@RestController
@RequestMapping("/api/areas")
@Tag(name = "Áreas", description = "Áreas da cidade nuclear. Gravação via PRC_ATX_INS/UPD/DEL_AREA")
public class AreaController {

    private final AreaService service;
    private final PerguntaService perguntaService;

    public AreaController(AreaService service, PerguntaService perguntaService) {
        this.service = service;
        this.perguntaService = perguntaService;
    }

    @GetMapping
    @Operation(summary = "Listar áreas", description = "Com o total de aplicações de cada área. `ativas=true` mostra só as visíveis no app.")
    public List<AreaResponse> listar(@Parameter(description = "Somente áreas ativas (S)", example = "true")
                                     @RequestParam(required = false) Boolean ativas) {
        return service.listar(ativas);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalhar área")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Área encontrada"),
            @ApiResponse(responseCode = "404", description = "Área não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public AreaResponse buscar(@Parameter(description = "ID da área", example = "1") @PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @GetMapping("/{id}/quiz")
    @Operation(summary = "Montar quiz da área",
            description = "Sorteia perguntas das aplicações da área **sem revelar a resposta correta**.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Perguntas sorteadas"),
            @ApiResponse(responseCode = "404", description = "Área não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public List<QuizPerguntaResponse> quiz(@Parameter(description = "ID da área", example = "1") @PathVariable Long id,
                                           @Parameter(description = "Quantidade de perguntas (1 a 20)", example = "5")
                                           @RequestParam(defaultValue = "5") @Min(1) @Max(20) int quantidade) {
        return perguntaService.montarQuiz(id, quantidade);
    }

    @PostMapping
    @Operation(summary = "Cadastrar área", description = "Chama PRC_ATX_INS_AREA.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Área criada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos (Bean Validation ou ORA-20001/-20007)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Nome já usado (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<AreaResponse> criar(@RequestBody @Valid AreaRequest request) {
        AreaResponse criada = service.criar(request);
        var uri = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}").buildAndExpand(criada.idArea()).toUri();
        return ResponseEntity.created(uri).body(criada);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar área", description = "Chama PRC_ATX_UPD_AREA.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Área atualizada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Área não encontrada (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Nome já usado por outra área (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public AreaResponse atualizar(@Parameter(description = "ID da área", example = "6") @PathVariable Long id, @RequestBody @Valid AreaRequest request) {
        return service.atualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir área", description = "Chama PRC_ATX_DEL_AREA. Bloqueado se a área tiver aplicações.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Área excluída"),
            @ApiResponse(responseCode = "404", description = "Área não encontrada (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Área possui aplicações (ORA-20005)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> excluir(@Parameter(description = "ID da área", example = "11") @PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}
