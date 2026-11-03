package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.Conquista;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/** Leitura com Query Methods; escrita com {@link Procedure} chamando PRC_ATX_*_CONQUISTA. */
public interface ConquistaRepository extends JpaRepository<Conquista, Long> {

    @Override
    @EntityGraph(attributePaths = "area")
    Optional<Conquista> findById(Long id);

    @EntityGraph(attributePaths = "area")
    List<Conquista> findAllByOrderByPontosNecessariosAscNomeAsc();

    /** Área nula = conquista geral. */
    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_CONQUISTA", outputParameterName = "p_id_conquista")
    Long inserir(@Param("p_id_area") Long idArea,
                 @Param("p_nome") String nome,
                 @Param("p_descricao") String descricao,
                 @Param("p_pontos_necessarios") Integer pontosNecessarios);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_CONQUISTA")
    void atualizar(@Param("p_id_conquista") Long idConquista,
                   @Param("p_id_area") Long idArea,
                   @Param("p_nome") String nome,
                   @Param("p_descricao") String descricao,
                   @Param("p_pontos_necessarios") Integer pontosNecessarios);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_CONQUISTA")
    void excluir(@Param("p_id_conquista") Long idConquista);
}
