package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.Pergunta;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/** Leitura com Query Methods; escrita com {@link Procedure} chamando PRC_ATX_*_PERGUNTA. */
public interface PerguntaRepository extends JpaRepository<Pergunta, Long> {

    @Override
    @EntityGraph(attributePaths = {"aplicacao", "aplicacao.area"})
    Optional<Pergunta> findById(Long id);

    @EntityGraph(attributePaths = {"aplicacao", "aplicacao.area"})
    List<Pergunta> findAllByOrderByIdPergunta();

    @EntityGraph(attributePaths = {"aplicacao", "aplicacao.area"})
    List<Pergunta> findByAplicacaoIdAplicacaoOrderByIdPergunta(Long idAplicacao);

    @EntityGraph(attributePaths = {"aplicacao", "aplicacao.area"})
    List<Pergunta> findByAplicacaoAreaIdArea(Long idArea);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_PERGUNTA", outputParameterName = "p_id_pergunta")
    Long inserir(@Param("p_id_aplicacao") Long idAplicacao,
                 @Param("p_enunciado") String enunciado,
                 @Param("p_alternativa_a") String alternativaA,
                 @Param("p_alternativa_b") String alternativaB,
                 @Param("p_alternativa_c") String alternativaC,
                 @Param("p_alternativa_d") String alternativaD,
                 @Param("p_resposta_correta") String respostaCorreta,
                 @Param("p_pontos") Integer pontos);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_PERGUNTA")
    void atualizar(@Param("p_id_pergunta") Long idPergunta,
                   @Param("p_id_aplicacao") Long idAplicacao,
                   @Param("p_enunciado") String enunciado,
                   @Param("p_alternativa_a") String alternativaA,
                   @Param("p_alternativa_b") String alternativaB,
                   @Param("p_alternativa_c") String alternativaC,
                   @Param("p_alternativa_d") String alternativaD,
                   @Param("p_resposta_correta") String respostaCorreta,
                   @Param("p_pontos") Integer pontos);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_PERGUNTA")
    void excluir(@Param("p_id_pergunta") Long idPergunta);
}
