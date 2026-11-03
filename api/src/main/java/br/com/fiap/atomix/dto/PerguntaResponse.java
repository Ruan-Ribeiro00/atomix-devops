package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.Pergunta;

@Schema(description = "Pergunta do quiz com o gabarito (uso administrativo)")
public record PerguntaResponse(Long idPergunta, Long idAplicacao, String aplicacao, Long idArea, String area,
                               String enunciado, String alternativaA, String alternativaB, String alternativaC,
                               String alternativaD, String respostaCorreta, Integer pontos) {

    public static PerguntaResponse from(Pergunta p) {
        var ap = p.getAplicacao();
        return new PerguntaResponse(p.getIdPergunta(), ap.getIdAplicacao(), ap.getTitulo(),
                ap.getArea().getIdArea(), ap.getArea().getNome(), p.getEnunciado(),
                p.getAlternativaA(), p.getAlternativaB(), p.getAlternativaC(), p.getAlternativaD(),
                p.getRespostaCorreta().name(), p.getPontos());
    }
}
