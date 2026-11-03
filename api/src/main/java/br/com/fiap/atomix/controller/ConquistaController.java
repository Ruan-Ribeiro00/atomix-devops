package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.ConquistaRequest;
import br.com.fiap.atomix.dto.ConquistaResponse;
import br.com.fiap.atomix.dto.ErroResponse;
import br.com.fiap.atomix.service.ConquistaService;
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
@RequestMapping("/api/conquistas")
@Tag(name = "Conquistas", description = "Medalhas desbloqueadas por pontuação. Gravação via PRC_ATX_INS/UPD/DEL_CONQUISTA")
public class ConquistaController {

    private final ConquistaService service;

    public ConquistaController(ConquistaService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar conquistas", description = "Ordenadas pelos pontos necessários.")
    public List<ConquistaResponse> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalhar conquista")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Conquista encontrada"),
            @ApiResponse(responseCode = "404", description = "Conquista não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ConquistaResponse buscar(@Parameter(description = "ID da conquista", example = "1") @PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @PostMapping
    @Operation(summary = "Cadastrar conquista", description = "Chama PRC_ATX_INS_CONQUISTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Conquista criada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Área não existe (ORA-20003)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Nome já usado (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<ConquistaResponse> criar(@RequestBody @Valid ConquistaRequest request) {
        ConquistaResponse criada = service.criar(request);
        var uri = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}").buildAndExpand(criada.idConquista()).toUri();
        return ResponseEntity.created(uri).body(criada);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar conquista", description = "Chama PRC_ATX_UPD_CONQUISTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Conquista atualizada"),
            @ApiResponse(responseCode = "404", description = "Conquista (ORA-20004) ou área (ORA-20003) inexistente",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Nome já usado (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ConquistaResponse atualizar(@Parameter(description = "ID da conquista", example = "7") @PathVariable Long id,
                                       @RequestBody @Valid ConquistaRequest request) {
        return service.atualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir conquista", description = "Chama PRC_ATX_DEL_CONQUISTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Conquista excluída"),
            @ApiResponse(responseCode = "404", description = "Conquista não encontrada (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> excluir(@Parameter(description = "ID da conquista", example = "11") @PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}
