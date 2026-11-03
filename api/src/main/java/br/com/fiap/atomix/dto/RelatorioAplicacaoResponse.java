package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/** Linha da function FN_ATX_RELATORIO_APLICACOES (cursor + INNER/LEFT JOIN). */
@Schema(description = "Linha da function FN_ATX_RELATORIO_APLICACOES")
public record RelatorioAplicacaoResponse(String area, Long idAplicacao, String titulo, String beneficio,
                                         Integer qtdPerguntas, Integer pontosQuiz, String linhaRelatorio) {
}
