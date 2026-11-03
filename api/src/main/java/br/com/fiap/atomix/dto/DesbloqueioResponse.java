package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(description = "Resultado do desbloqueio automático (PRC_ATX_DESBLOQUEAR_CONQUISTAS)")
public record DesbloqueioResponse(Long idJogador, int qtdDesbloqueadas, List<JogadorConquistaResponse> conquistas) {
}
