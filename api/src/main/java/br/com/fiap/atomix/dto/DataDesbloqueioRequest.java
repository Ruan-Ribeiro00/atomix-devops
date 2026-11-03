package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;

import java.time.LocalDate;

@Schema(description = "Correção da data em que a conquista foi desbloqueada")
public record DataDesbloqueioRequest(
        @Schema(example = "2026-10-01")
        @NotNull(message = "A data do desbloqueio é obrigatória")
        @PastOrPresent(message = "A data do desbloqueio não pode estar no futuro")
        LocalDate dtDesbloqueio
) {
}
