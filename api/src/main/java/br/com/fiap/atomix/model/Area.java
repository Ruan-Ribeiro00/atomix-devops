package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

/**
 * Área da "cidade nuclear" (Saúde, Agro, Indústria, Energia, Pesquisa...). Tabela TB_ATX_AREA.
 * <p>
 * Entidade somente leitura no JPA: toda gravação passa pelas procedures PRC_ATX_*_AREA
 * (métodos {@code @Procedure} de {@link br.com.fiap.atomix.repository.AreaRepository}).
 */
@Entity
@Immutable
@Table(name = "TB_ATX_AREA")
public class Area {

    @Id
    @Column(name = "id_area")
    private Long idArea;

    @Column(name = "nome", nullable = false, length = 50)
    private String nome;

    @Column(name = "descricao", nullable = false, length = 400)
    private String descricao;

    /** S = aparece na cidade do app; N = área futura ("em breve"). */
    @Column(name = "ativa", nullable = false, length = 1)
    private String ativa;

    protected Area() {
    }

    public Long getIdArea() { return idArea; }
    public String getNome() { return nome; }
    public String getDescricao() { return descricao; }
    public String getAtiva() { return ativa; }
}
