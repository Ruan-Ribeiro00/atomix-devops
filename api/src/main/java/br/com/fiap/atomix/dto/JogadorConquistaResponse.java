package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.JogadorConquista;

import java.time.LocalDateTime;

@Schema(description = "Conquista desbloqueada por um jogador e a data do desbloqueio")
public record JogadorConquistaResponse(Long idJogador, Long idConquista, String conquista,
                                       Integer pontosNecessarios, LocalDateTime dtDesbloqueio) {

    public static JogadorConquistaResponse from(JogadorConquista jc) {
        return new JogadorConquistaResponse(jc.getId().getIdJogador(), jc.getId().getIdConquista(),
                jc.getConquista().getNome(), jc.getConquista().getPontosNecessarios(), jc.getDtDesbloqueio());
    }
}
