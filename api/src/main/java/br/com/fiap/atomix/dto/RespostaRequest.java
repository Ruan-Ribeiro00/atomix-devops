package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

@Schema(description = "Alternativa escolhida pelo jogador")
public record RespostaRequest(
        @Schema(example = "A", allowableValues = {"A", "B", "C", "D"})
        @NotBlank(message = "Informe a alternativa escolhida")
        @Pattern(regexp = "[ABCD]", message = "A alternativa deve ser A, B, C ou D")
        String alternativa
) {
}
