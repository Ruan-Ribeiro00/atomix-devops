package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;

@Schema(description = "Desbloqueio manual de uma conquista para o jogador")
public record JogadorConquistaRequest(
        @Schema(example = "1")
        @NotNull(message = "A conquista é obrigatória")
        @Positive(message = "O ID da conquista deve ser positivo")
        Long idConquista,

        @Schema(description = "Data do desbloqueio (padrão: hoje)", example = "2026-10-01", nullable = true)
        @PastOrPresent(message = "A data do desbloqueio não pode estar no futuro")
        LocalDate dtDesbloqueio
) {
}
