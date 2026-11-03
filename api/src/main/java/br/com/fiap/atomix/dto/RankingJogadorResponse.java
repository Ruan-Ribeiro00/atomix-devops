package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Linha da function FN_ATX_RANKING_JOGADORES (INNER JOIN + GROUP BY + COUNT/SUM/MAX + ORDER BY). */
@Schema(description = "Linha da function FN_ATX_RANKING_JOGADORES")
public record RankingJogadorResponse(Integer posicao, Long idJogador, String jogador, Integer pontuacao,
                                     String nivel, Integer qtdConquistas, BigDecimal percConquistas,
                                     Integer somaPontosConquistas, LocalDateTime ultimaConquista) {
}
