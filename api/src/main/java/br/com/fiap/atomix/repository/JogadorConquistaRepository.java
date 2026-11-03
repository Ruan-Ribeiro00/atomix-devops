package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.JogadorConquista;
import br.com.fiap.atomix.model.JogadorConquistaId;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * Conquistas desbloqueadas (associativa JOGADOR x CONQUISTA).
 * Escrita com {@link Procedure}: PRC_ATX_*_JOGADOR_CONQUISTA e PRC_ATX_DESBLOQUEAR_CONQUISTAS.
 */
public interface JogadorConquistaRepository extends JpaRepository<JogadorConquista, JogadorConquistaId> {

    @EntityGraph(attributePaths = "conquista")
    List<JogadorConquista> findByIdIdJogadorOrderByDtDesbloqueioAscIdIdConquistaAsc(Long idJogador);

    long countByIdIdJogador(Long idJogador);

    /** Regra da procedure: pontuação do jogador >= pontos necessários (senão ORA-20006). Data nula = hoje. */
    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_JOGADOR_CONQUISTA")
    void inserir(@Param("p_id_jogador") Long idJogador,
                 @Param("p_id_conquista") Long idConquista,
                 @Param("p_dt_desbloqueio") LocalDate dtDesbloqueio);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_JOGADOR_CONQUISTA")
    void atualizar(@Param("p_id_jogador") Long idJogador,
                   @Param("p_id_conquista") Long idConquista,
                   @Param("p_dt_desbloqueio") LocalDate dtDesbloqueio);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_JOGADOR_CONQUISTA")
    void excluir(@Param("p_id_jogador") Long idJogador,
                 @Param("p_id_conquista") Long idConquista);

    /** Libera todas as conquistas que a pontuação já permite; devolve quantas foram desbloqueadas. */
    @Transactional
    @Procedure(procedureName = "PRC_ATX_DESBLOQUEAR_CONQUISTAS", outputParameterName = "p_qtd_desbloq")
    Integer desbloquearAutomaticamente(@Param("p_id_jogador") Long idJogador);
}
