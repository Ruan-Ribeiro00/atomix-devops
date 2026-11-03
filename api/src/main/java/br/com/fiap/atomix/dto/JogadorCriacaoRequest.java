package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Cadastro de jogador (tela de cadastro do app)")
public record JogadorCriacaoRequest(
        @Schema(example = "Ana Beatriz Souza")
        @NotBlank(message = "O nome é obrigatório")
        @Size(min = 2, max = 100, message = "O nome deve ter entre 2 e 100 caracteres")
        String nome,

        @Schema(example = "ana.souza@email.com")
        @NotBlank(message = "O e-mail é obrigatório")
        @Email(message = "E-mail em formato inválido")
        @Size(max = 120, message = "O e-mail deve ter no máximo 120 caracteres")
        String email,

        @Schema(description = "Senha em texto; a API grava apenas o hash BCrypt", example = "Atomix@2026")
        @NotBlank(message = "A senha é obrigatória")
        @Size(min = 6, max = 50, message = "A senha deve ter entre 6 e 50 caracteres")
        String senha,

        @Schema(description = "Pontuação inicial (padrão 0)", example = "0")
        @PositiveOrZero(message = "A pontuação não pode ser negativa")
        Integer pontuacao
) {
}
