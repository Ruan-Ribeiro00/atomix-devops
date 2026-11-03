package br.com.fiap.atomix.controller;

import br.com.fiap.atomix.dto.RankingJogadorResponse;
import br.com.fiap.atomix.dto.RelatorioAplicacaoResponse;
import br.com.fiap.atomix.service.RelatorioService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/relatorios")
@Tag(name = "Relatórios", description = "Functions PL/SQL com retorno TABLE")
public class RelatorioController {

    private final RelatorioService service;

    public RelatorioController(RelatorioService service) {
        this.service = service;
    }

    @GetMapping("/aplicacoes")
    @Operation(summary = "Relatório de aplicações por área",
            description = "SELECT * FROM TABLE(FN_ATX_RELATORIO_APLICACOES(:idArea)) — cursor com INNER JOIN e LEFT JOIN.")
    public List<RelatorioAplicacaoResponse> aplicacoes(
            @Parameter(description = "Área (vazio = todas)", example = "1") @RequestParam(required = false) @Positive Long idArea) {
        return service.relatorioAplicacoes(idArea);
    }

    @GetMapping("/ranking")
    @Operation(summary = "Ranking de jogadores",
            description = "SELECT * FROM TABLE(FN_ATX_RANKING_JOGADORES(:minConquistas)) — GROUP BY, COUNT/SUM e ORDER BY.")
    public List<RankingJogadorResponse> ranking(
            @Parameter(description = "Mínimo de conquistas", example = "2") @RequestParam(required = false) @Min(0) Integer minConquistas) {
        return service.ranking(minConquistas);
    }
}
