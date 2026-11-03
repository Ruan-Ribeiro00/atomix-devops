package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

@Schema(description = "Dados para cadastrar ou atualizar uma aplicação nuclear")
public record AplicacaoRequest(
        @Schema(description = "ID da área à qual a aplicação pertence", example = "1")
        @NotNull(message = "A área é obrigatória")
        @Positive(message = "O ID da área deve ser positivo")
        Long idArea,

        @Schema(description = "Título (único dentro da área)", example = "Radioterapia")
        @NotBlank(message = "O título é obrigatório")
        @Size(min = 3, max = 120, message = "O título deve ter entre 3 e 120 caracteres")
        String titulo,

        @Schema(description = "Como a tecnologia nuclear é usada",
                example = "Feixes de radiação ionizante são direcionados ao tumor para danificar o DNA das células cancerígenas.")
        @NotBlank(message = "A descrição é obrigatória")
        @Size(min = 5, max = 1000, message = "A descrição deve ter entre 5 e 1000 caracteres")
        String descricao,

        @Schema(description = "Benefício para a sociedade",
                example = "Tratamento de câncer com maior chance de cura e preservação de órgãos.")
        @NotBlank(message = "O benefício é obrigatório")
        @Size(min = 5, max = 500, message = "O benefício deve ter entre 5 e 500 caracteres")
        String beneficio
) {
}
