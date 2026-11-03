package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

/**
 * Conquista (medalha) desbloqueada por pontuação. Tabela TB_ATX_CONQUISTA.
 * A área é opcional: conquistas gerais não pertencem a nenhuma área.
 */
@Entity
@Immutable
@Table(name = "TB_ATX_CONQUISTA")
public class Conquista {

    @Id
    @Column(name = "id_conquista")
    private Long idConquista;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_area")
    private Area area;

    @Column(name = "nome", nullable = false, length = 60)
    private String nome;

    @Column(name = "descricao", nullable = false, length = 300)
    private String descricao;

    @Column(name = "pontos_necessarios", nullable = false)
    private Integer pontosNecessarios;

    protected Conquista() {
    }

    public Long getIdConquista() { return idConquista; }
    public Area getArea() { return area; }
    public String getNome() { return nome; }
    public String getDescricao() { return descricao; }
    public Integer getPontosNecessarios() { return pontosNecessarios; }
}
