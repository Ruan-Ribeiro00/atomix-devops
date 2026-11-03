package br.com.fiap.atomix.dto;

import br.com.fiap.atomix.validation.AlternativasDistintas;
import br.com.fiap.atomix.validation.ComAlternativas;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

import java.util.List;

@AlternativasDistintas
@Schema(description = "Dados para cadastrar ou atualizar uma pergunta do quiz")
public record PerguntaRequest(
        @Schema(description = "Aplicação sobre a qual a pergunta trata", example = "1")
        @NotNull(message = "A aplicação é obrigatória")
        @Positive(message = "O ID da aplicação deve ser positivo")
        Long idAplicacao,

        @Schema(example = "Qual é o principal objetivo da radioterapia?")
        @NotBlank(message = "O enunciado é obrigatório")
        @Size(min = 5, max = 500, message = "O enunciado deve ter entre 5 e 500 caracteres")
        String enunciado,

        @Schema(example = "Destruir ou controlar células de tumores")
        @NotBlank(message = "A alternativa A é obrigatória") @Size(max = 200) String alternativaA,
        @Schema(example = "Aquecer o corpo do paciente")
        @NotBlank(message = "A alternativa B é obrigatória") @Size(max = 200) String alternativaB,
        @Schema(example = "Gerar energia elétrica no hospital")
        @NotBlank(message = "A alternativa C é obrigatória") @Size(max = 200) String alternativaC,
        @Schema(example = "Esterilizar instrumentos cirúrgicos")
        @NotBlank(message = "A alternativa D é obrigatória") @Size(max = 200) String alternativaD,

        @Schema(description = "Letra da alternativa correta", example = "A", allowableValues = {"A", "B", "C", "D"})
        @NotBlank(message = "A resposta correta é obrigatória")
        @Pattern(regexp = "[ABCD]", message = "A resposta correta deve ser A, B, C ou D")
        String respostaCorreta,

        @Schema(description = "Pontos ganhos ao acertar (padrão 10)", example = "10")
        @Min(value = 1, message = "Os pontos devem ser no mínimo 1")
        @Max(value = 1000, message = "Os pontos devem ser no máximo 1000")
        Integer pontos
) implements ComAlternativas {

    @Override
    public List<String> alternativas() {
        return java.util.Arrays.asList(alternativaA, alternativaB, alternativaC, alternativaD);
    }

    public int pontosOuPadrao() {
        return pontos == null ? 10 : pontos;
    }
}
