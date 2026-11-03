package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Atualização de jogador. Senha nula mantém a senha atual.")
public record JogadorAtualizacaoRequest(
        @Schema(example = "João Pedro Cardoso")
        @NotBlank(message = "O nome é obrigatório")
        @Size(min = 1, max = 100, message = "O nome deve ter no máximo 100 caracteres")
        String nome,

        @Schema(example = "joao.cardoso@email.com")
        @NotBlank(message = "O e-mail é obrigatório")
        @Email(message = "E-mail em formato inválido")
        @Size(max = 120)
        String email,

        @Schema(description = "Nova senha (opcional). Envie null para manter a senha atual.",
                example = "Atomix@2026", nullable = true)
        @Size(min = 6, max = 50, message = "A senha deve ter entre 6 e 50 caracteres")
        String senha,

        @Schema(example = "120")
        @NotNull(message = "A pontuação é obrigatória")
        @PositiveOrZero(message = "A pontuação não pode ser negativa")
        Integer pontuacao
) {
}
