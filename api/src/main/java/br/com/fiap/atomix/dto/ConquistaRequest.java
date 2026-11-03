package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Dados para cadastrar ou atualizar uma conquista")
public record ConquistaRequest(
        @Schema(description = "Área temática (nula = conquista geral)", example = "1", nullable = true)
        @Positive(message = "O ID da área deve ser positivo")
        Long idArea,

        @Schema(example = "Primeiro Átomo")
        @NotBlank(message = "O nome é obrigatório")
        @Size(max = 60, message = "O nome deve ter no máximo 60 caracteres")
        String nome,

        @Schema(example = "Fez os primeiros pontos na cidade nuclear.")
        @NotBlank(message = "A descrição é obrigatória")
        @Size(max = 300, message = "A descrição deve ter no máximo 300 caracteres")
        String descricao,

        @Schema(description = "Pontuação mínima para desbloquear", example = "10")
        @NotNull(message = "Os pontos necessários são obrigatórios")
        @PositiveOrZero(message = "Os pontos necessários não podem ser negativos")
        Integer pontosNecessarios
) {
}
