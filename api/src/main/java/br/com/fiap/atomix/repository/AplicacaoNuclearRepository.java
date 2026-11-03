package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.AplicacaoNuclear;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * CRUD principal da API.
 * <ul>
 *   <li>Consultas: Query Methods (derivadas do nome do método, sem JPQL).</li>
 *   <li>Inclusão, alteração e exclusão: {@link Procedure} do Spring Data JPA chamando
 *       PRC_ATX_INS/UPD/DEL_APLICACAO (as validações e o COMMIT ficam na procedure).</li>
 * </ul>
 */
public interface AplicacaoNuclearRepository extends JpaRepository<AplicacaoNuclear, Long> {

    @Override
    @EntityGraph(attributePaths = "area")
    Optional<AplicacaoNuclear> findById(Long id);

    @Override
    @EntityGraph(attributePaths = "area")
    Page<AplicacaoNuclear> findAll(Pageable pageable);

    @EntityGraph(attributePaths = "area")
    Page<AplicacaoNuclear> findByAreaIdArea(Long idArea, Pageable pageable);

    /** Busca por texto em título, descrição ou benefício (sem distinguir maiúsculas/minúsculas). */
    @EntityGraph(attributePaths = "area")
    Page<AplicacaoNuclear> findByTituloContainingIgnoreCaseOrDescricaoContainingIgnoreCaseOrBeneficioContainingIgnoreCase(
            String titulo, String descricao, String beneficio, Pageable pageable);

    /**
     * Mesma busca restrita a uma área. No Spring Data o AND tem precedência sobre o OR:
     * (area = ? AND titulo LIKE ?) OR (area = ? AND descricao LIKE ?) OR (area = ? AND beneficio LIKE ?).
     */
    @EntityGraph(attributePaths = "area")
    Page<AplicacaoNuclear> findByAreaIdAreaAndTituloContainingIgnoreCaseOrAreaIdAreaAndDescricaoContainingIgnoreCaseOrAreaIdAreaAndBeneficioContainingIgnoreCase(
            Long idArea1, String titulo, Long idArea2, String descricao, Long idArea3, String beneficio,
            Pageable pageable);

    long countByAreaIdArea(Long idArea);

    default Page<AplicacaoNuclear> buscarPorTexto(String texto, Pageable pageable) {
        return findByTituloContainingIgnoreCaseOrDescricaoContainingIgnoreCaseOrBeneficioContainingIgnoreCase(
                texto, texto, texto, pageable);
    }

    default Page<AplicacaoNuclear> buscarPorTextoNaArea(Long idArea, String texto, Pageable pageable) {
        return findByAreaIdAreaAndTituloContainingIgnoreCaseOrAreaIdAreaAndDescricaoContainingIgnoreCaseOrAreaIdAreaAndBeneficioContainingIgnoreCase(
                idArea, texto, idArea, texto, idArea, texto, pageable);
    }

    // ------------------------------------------------ escrita via procedures

    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_APLICACAO", outputParameterName = "p_id_aplicacao")
    Long inserir(@Param("p_id_area") Long idArea,
                 @Param("p_titulo") String titulo,
                 @Param("p_descricao") String descricao,
                 @Param("p_beneficio") String beneficio);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_APLICACAO")
    void atualizar(@Param("p_id_aplicacao") Long idAplicacao,
                   @Param("p_id_area") Long idArea,
                   @Param("p_titulo") String titulo,
                   @Param("p_descricao") String descricao,
                   @Param("p_beneficio") String beneficio);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_APLICACAO")
    void excluir(@Param("p_id_aplicacao") Long idAplicacao);
}
