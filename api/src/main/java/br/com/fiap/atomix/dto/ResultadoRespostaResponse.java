package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Resultado da correção de uma resposta do quiz")
public record ResultadoRespostaResponse(Long idPergunta, boolean acertou, String alternativaEscolhida,
                                        String respostaCorreta, int pontosGanhos) {
}
