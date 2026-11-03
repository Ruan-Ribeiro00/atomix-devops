package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.Area;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Leitura com Query Methods; escrita com {@link Procedure} do Spring Data JPA,
 * que chama as procedures PRC_ATX_*_AREA do projeto de Banco de Dados.
 */
public interface AreaRepository extends JpaRepository<Area, Long> {

    List<Area> findAllByOrderByIdArea();

    List<Area> findByAtivaOrderByIdArea(String ativa);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_AREA", outputParameterName = "p_id_area")
    Long inserir(@Param("p_nome") String nome,
                 @Param("p_descricao") String descricao,
                 @Param("p_ativa") String ativa);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_AREA")
    void atualizar(@Param("p_id_area") Long idArea,
                   @Param("p_nome") String nome,
                   @Param("p_descricao") String descricao,
                   @Param("p_ativa") String ativa);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_AREA")
    void excluir(@Param("p_id_area") Long idArea);
}
