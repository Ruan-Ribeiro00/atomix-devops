package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(description = "Dados para cadastrar ou atualizar uma área da cidade nuclear")
public record AreaRequest(
        @Schema(example = "Saúde")
        @NotBlank(message = "O nome é obrigatório")
        @Size(max = 50, message = "O nome deve ter no máximo 50 caracteres")
        String nome,

        @Schema(example = "Como a radiação ajuda a diagnosticar e tratar doenças.")
        @NotBlank(message = "A descrição é obrigatória")
        @Size(max = 400, message = "A descrição deve ter no máximo 400 caracteres")
        String descricao,

        @Schema(description = "S = visível na cidade do app; N = área futura. Padrão: S", example = "S")
        @Pattern(regexp = "[SN]", message = "O campo ativa aceita apenas S ou N")
        String ativa
) {
    public String ativaOuPadrao() {
        return ativa == null ? "S" : ativa;
    }
}
