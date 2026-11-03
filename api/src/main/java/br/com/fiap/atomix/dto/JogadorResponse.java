package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.Jogador;

import java.time.LocalDateTime;

/** Nunca devolve a senha. */
@Schema(description = "Jogador (sem a senha) com a quantidade de conquistas desbloqueadas")
public record JogadorResponse(Long idJogador, String nome, String email, Integer pontuacao,
                              LocalDateTime dtCadastro, long qtdConquistas) {

    public static JogadorResponse from(Jogador j, long qtdConquistas) {
        return new JogadorResponse(j.getIdJogador(), j.getNome(), j.getEmail(), j.getPontuacao(),
                j.getDtCadastro(), qtdConquistas);
    }
}
