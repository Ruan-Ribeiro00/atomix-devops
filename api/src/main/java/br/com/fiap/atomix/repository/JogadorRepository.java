package br.com.fiap.atomix.repository;

import br.com.fiap.atomix.model.Jogador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Leitura com Query Methods; escrita com {@link Procedure} chamando PRC_ATX_*_JOGADOR. */
public interface JogadorRepository extends JpaRepository<Jogador, Long> {

    List<Jogador> findAllByOrderByPontuacaoDescNomeAsc();

    List<Jogador> findByNomeContainingIgnoreCaseOrderByNome(String nome);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_INS_JOGADOR", outputParameterName = "p_id_jogador")
    Long inserir(@Param("p_nome") String nome,
                 @Param("p_email") String email,
                 @Param("p_senha") String senhaHash,
                 @Param("p_pontuacao") Integer pontuacao);

    /** Senha nula mantém a senha atual (regra da procedure). */
    @Transactional
    @Procedure(procedureName = "PRC_ATX_UPD_JOGADOR")
    void atualizar(@Param("p_id_jogador") Long idJogador,
                   @Param("p_nome") String nome,
                   @Param("p_email") String email,
                   @Param("p_senha") String senhaHash,
                   @Param("p_pontuacao") Integer pontuacao);

    @Transactional
    @Procedure(procedureName = "PRC_ATX_DEL_JOGADOR")
    void excluir(@Param("p_id_jogador") Long idJogador);
}
