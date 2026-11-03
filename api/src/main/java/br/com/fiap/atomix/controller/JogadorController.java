package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.*;
import br.com.fiap.atomix.service.JogadorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;

@RestController
@RequestMapping("/api/jogadores")
@Tag(name = "Jogadores", description = "Jogadores e suas conquistas. Gravação via PRC_ATX_INS/UPD/DEL_JOGADOR e PRC_ATX_INS/UPD/DEL_JOGADOR_CONQUISTA")
public class JogadorController {

    private final JogadorService service;

    public JogadorController(JogadorService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar jogadores", description = "Ordenado por pontuação. Filtre por parte do nome com `nome`.")
    public List<JogadorResponse> listar(@Parameter(description = "Parte do nome (sem diferenciar maiúsculas)", example = "ana") @RequestParam(required = false) String nome) {
        return service.listar(nome);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalhar jogador")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Jogador encontrado"),
            @ApiResponse(responseCode = "404", description = "Jogador não encontrado",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public JogadorResponse buscar(@Parameter(description = "ID do jogador", example = "1") @PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @PostMapping
    @Operation(summary = "Cadastrar jogador", description = "Chama PRC_ATX_INS_JOGADOR. A senha é gravada como hash BCrypt.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Jogador criado"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "E-mail já cadastrado (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<JogadorResponse> criar(@RequestBody @Valid JogadorCriacaoRequest request) {
        JogadorResponse criado = service.criar(request);
        var uri = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}").buildAndExpand(criado.idJogador()).toUri();
        return ResponseEntity.created(uri).body(criado);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar jogador", description = "Chama PRC_ATX_UPD_JOGADOR. `senha` nula mantém a atual.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Jogador atualizado"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "404", description = "Jogador não encontrado (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "E-mail de outro jogador (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public JogadorResponse atualizar(@Parameter(description = "ID do jogador", example = "10") @PathVariable Long id,
                                     @RequestBody @Valid JogadorAtualizacaoRequest request) {
        return service.atualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir jogador", description = "Chama PRC_ATX_DEL_JOGADOR.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Jogador excluído"),
            @ApiResponse(responseCode = "404", description = "Jogador não encontrado (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> excluir(@Parameter(description = "ID do jogador", example = "11") @PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }

    // ------------------------------------------------ conquistas do jogador

    @GetMapping("/{id}/conquistas")
    @Operation(summary = "Conquistas do jogador")
    public List<JogadorConquistaResponse> conquistas(@Parameter(description = "ID do jogador", example = "1") @PathVariable Long id) {
        return service.listarConquistas(id);
    }

    @PostMapping("/{id}/conquistas")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Desbloquear conquista", description = "Chama PRC_ATX_INS_JOGADOR_CONQUISTA. "
            + "Regra: a pontuação do jogador precisa ser maior ou igual aos pontos necessários.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Conquista desbloqueada; devolve todas as conquistas do jogador"),
            @ApiResponse(responseCode = "404", description = "Jogador ou conquista inexistente (ORA-20003)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "409", description = "Conquista já desbloqueada (ORA-20002)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class))),
            @ApiResponse(responseCode = "422", description = "Pontuação insuficiente (ORA-20006)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public List<JogadorConquistaResponse> desbloquear(@Parameter(description = "ID do jogador", example = "1") @PathVariable Long id,
                                                      @RequestBody @Valid JogadorConquistaRequest request) {
        return service.desbloquear(id, request);
    }

    @PutMapping("/{id}/conquistas/{idConquista}")
    @Operation(summary = "Corrigir data do desbloqueio", description = "Chama PRC_ATX_UPD_JOGADOR_CONQUISTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Data corrigida"),
            @ApiResponse(responseCode = "404", description = "Associação inexistente (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public List<JogadorConquistaResponse> atualizarData(@Parameter(description = "ID do jogador", example = "1") @PathVariable Long id,
                                                        @Parameter(description = "ID da conquista", example = "10") @PathVariable Long idConquista,
                                                        @RequestBody @Valid DataDesbloqueioRequest request) {
        return service.atualizarData(id, idConquista, request);
    }

    @DeleteMapping("/{id}/conquistas/{idConquista}")
    @Operation(summary = "Remover conquista do jogador", description = "Chama PRC_ATX_DEL_JOGADOR_CONQUISTA.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Removida"),
            @ApiResponse(responseCode = "404", description = "Associação inexistente (ORA-20004)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public ResponseEntity<Void> removerConquista(@Parameter(description = "ID do jogador", example = "10") @PathVariable Long id,
                                                 @Parameter(description = "ID da conquista", example = "3") @PathVariable Long idConquista) {
        service.removerConquista(id, idConquista);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/conquistas/desbloquear")
    @Operation(summary = "Desbloqueio automático",
            description = "Chama PRC_ATX_DESBLOQUEAR_CONQUISTAS: libera todas as conquistas que a pontuação já permite.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Quantidade desbloqueada e conquistas atuais"),
            @ApiResponse(responseCode = "404", description = "Jogador inexistente (ORA-20003)",
                    content = @Content(schema = @Schema(implementation = ErroResponse.class)))
    })
    public DesbloqueioResponse desbloquearAutomatico(@Parameter(description = "ID do jogador", example = "3") @PathVariable Long id) {
        return service.desbloquearAutomaticamente(id);
    }
}
