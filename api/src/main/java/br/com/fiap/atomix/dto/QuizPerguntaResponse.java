package br.com.fiap.atomix.dto;

import br.com.fiap.atomix.model.Pergunta;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Pergunta para o jogador responder: não revela a alternativa correta")
public record QuizPerguntaResponse(Long idPergunta, String aplicacao, String enunciado, String alternativaA,
                                   String alternativaB, String alternativaC, String alternativaD, Integer pontos) {

    public static QuizPerguntaResponse from(Pergunta p) {
        return new QuizPerguntaResponse(p.getIdPergunta(), p.getAplicacao().getTitulo(), p.getEnunciado(),
                p.getAlternativaA(), p.getAlternativaB(), p.getAlternativaC(), p.getAlternativaD(), p.getPontos());
    }
}
