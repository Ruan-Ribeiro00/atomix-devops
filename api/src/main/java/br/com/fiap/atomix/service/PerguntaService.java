package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.Procedimentos;
import br.com.fiap.atomix.dto.*;
import br.com.fiap.atomix.exception.RecursoNaoEncontradoException;
import br.com.fiap.atomix.model.Alternativa;
import br.com.fiap.atomix.model.Pergunta;
import br.com.fiap.atomix.repository.PerguntaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
public class PerguntaService {

    private final PerguntaRepository repository;
    private final AreaService areaService;

    public PerguntaService(PerguntaRepository repository, AreaService areaService) {
        this.repository = repository;
        this.areaService = areaService;
    }

    @Transactional(readOnly = true)
    public List<PerguntaResponse> listar(Long idAplicacao) {
        List<Pergunta> perguntas = idAplicacao == null
                ? repository.findAllByOrderByIdPergunta()
                : repository.findByAplicacaoIdAplicacaoOrderByIdPergunta(idAplicacao);
        return perguntas.stream().map(PerguntaResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public PerguntaResponse buscarPorId(Long id) {
        return PerguntaResponse.from(buscarEntidade(id));
    }

    /** Sorteia até {@code quantidade} perguntas da área, sem revelar a resposta correta. */
    @Transactional(readOnly = true)
    public List<QuizPerguntaResponse> montarQuiz(Long idArea, int quantidade) {
        areaService.buscarEntidade(idArea);
        List<Pergunta> perguntas = new ArrayList<>(repository.findByAplicacaoAreaIdArea(idArea));
        Collections.shuffle(perguntas);
        return perguntas.stream().limit(quantidade).map(QuizPerguntaResponse::from).toList();
    }

    /** Corrige a resposta e devolve os pontos ganhos (o app soma na pontuação do jogador). */
    @Transactional(readOnly = true)
    public ResultadoRespostaResponse responder(Long idPergunta, RespostaRequest req) {
        Pergunta p = buscarEntidade(idPergunta);
        Alternativa escolhida = Alternativa.valueOf(req.alternativa());
        boolean acertou = p.acertou(escolhida);
        return new ResultadoRespostaResponse(idPergunta, acertou, escolhida.name(), p.getRespostaCorreta().name(),
                acertou ? p.getPontos() : 0);
    }

    /** INSERT via PRC_ATX_INS_PERGUNTA. */
    public PerguntaResponse criar(PerguntaRequest req) {
        Long id = Procedimentos.executar("PRC_ATX_INS_PERGUNTA", () -> repository.inserir(
                req.idAplicacao(), req.enunciado().trim(), req.alternativaA().trim(), req.alternativaB().trim(),
                req.alternativaC().trim(), req.alternativaD().trim(), req.respostaCorreta(), req.pontosOuPadrao()));
        return buscarPorId(id);
    }

    /** UPDATE via PRC_ATX_UPD_PERGUNTA. */
    public PerguntaResponse atualizar(Long id, PerguntaRequest req) {
        Procedimentos.executar("PRC_ATX_UPD_PERGUNTA", () -> repository.atualizar(
                id, req.idAplicacao(), req.enunciado().trim(), req.alternativaA().trim(), req.alternativaB().trim(),
                req.alternativaC().trim(), req.alternativaD().trim(), req.respostaCorreta(), req.pontosOuPadrao()));
        return buscarPorId(id);
    }

    /** DELETE via PRC_ATX_DEL_PERGUNTA. */
    public void excluir(Long id) {
        Procedimentos.executar("PRC_ATX_DEL_PERGUNTA", () -> repository.excluir(id));
    }

    private Pergunta buscarEntidade(Long id) {
        return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Pergunta", id));
    }
}
