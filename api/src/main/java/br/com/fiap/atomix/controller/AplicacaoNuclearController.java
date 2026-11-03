package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.AplicacaoRequest;
import br.com.fiap.atomix.dto.AplicacaoResponse;
import br.com.fiap.atomix.dto.ErroResponse;
import br.com.fiap.atomix.service.AplicacaoNuclearService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/aplicacoes")
@Tag(name = "Aplicações Nucleares",
        description = "CRUD principal: aplicações reais da tecnologia nuclear, com busca por texto. "
                + "Gravação via PRC_ATX_INS/UPD/DEL_APLICACAO")
public class AplicacaoNuclearController {

    private final AplicacaoNuclearService service;

    public AplicacaoNuclearController(AplicacaoNuclearService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar aplicações",
            description = "Lista paginada; filtre por área com `idArea`. Paginação: `page`, `size`, `sort=titulo,asc`.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Página de aplicações"),
            @ApiResponse(responseCode = "404", description = "Área informada não existe",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public Page<AplicacaoResponse> listar(
            @Parameter(description = "Filtra pela área", example = "1") @RequestParam(required = false) @Positive Long idArea,
            @ParameterObject @PageableDefault(size = 20, sort = "idAplicacao") Pageable pageable) {
        return service.listar(idArea, pageable);
    }

    @GetMapping("/busca")
    @Operation(summary = "Buscar aplicações por texto",
            description = "Procura o texto no título, na descrição e no benefício, sem diferenciar maiúsculas. "
                    + "Implementado com **Query Method** do Spring Data JPA.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Resultados (pode ser vazio)"),
            @ApiResponse(responseCode = "400", description = "Texto ausente ou com tamanho inválido",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public Page<AplicacaoResponse> buscar(
            @Parameter(description = "Texto a buscar (2 a 100 caracteres)", example = "urânio", required = true)
            @RequestParam @NotBlank(message = "Informe o texto da busca")
            @Size(min = 2, max = 100, message = "O texto deve ter entre 2 e 100 caracteres") String texto,
            @Parameter(description = "Restringe a uma área", example = "4") @RequestParam(required = false) @Positive Long idArea,
            @ParameterObject @PageableDefault(size = 20, sort = "titulo") Pageable pageable) {
        return service.buscarPorTexto(texto, idArea, pageable);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalhar aplicação")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Aplicação encontrada"),
            @ApiResponse(responseCode = "404", description = "Aplicação não encontrada",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public AplicacaoResponse buscarPorId(@Parameter(description = "ID da aplicação", example = "1") @PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @PostMapping
    @Operation(summary = "Cadastrar aplicação", description = "Chama PRC_ATX_INS_APLICACAO.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Aplicação criada (header Location)"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Área não existe (ORA-20003)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Título já existe na área (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<AplicacaoResponse> criar(@RequestBody @Valid AplicacaoRequest request) {
        AplicacaoResponse criada = service.criar(request);
        var uri = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}").buildAndExpand(criada.idAplicacao()).toUri();
        return ResponseEntity.created(uri).body(criada);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar aplicação", description = "Chama PRC_ATX_UPD_APLICACAO.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Aplicação atualizada"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Aplicação (ORA-20004) ou área (ORA-20003) inexistente",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Título já existe na área (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public AplicacaoResponse atualizar(@Parameter(description = "ID da aplicação", example = "7") @PathVariable Long id,
                                       @RequestBody @Valid AplicacaoRequest request) {
        return service.atualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir aplicação", description = "Chama PRC_ATX_DEL_APLICACAO. Bloqueado se houver perguntas.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Aplicação excluída"),
            @ApiResponse(responseCode = "404", description = "Aplicação não encontrada (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Aplicação possui perguntas (ORA-20005)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> excluir(@Parameter(description = "ID da aplicação", example = "11") @PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}
