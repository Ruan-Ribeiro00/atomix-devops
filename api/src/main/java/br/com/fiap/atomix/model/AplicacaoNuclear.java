package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

import java.time.LocalDateTime;

/**
 * Aplicação real da tecnologia nuclear exibida em uma área (ex.: radioterapia em Saúde).
 * Tabela TB_ATX_APLICACAO. Gravação via PRC_ATX_*_APLICACAO.
 */
@Entity
@Immutable
@Table(name = "TB_ATX_APLICACAO")
public class AplicacaoNuclear {

    @Id
    @Column(name = "id_aplicacao")
    private Long idAplicacao;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_area", nullable = false)
    private Area area;

    @Column(name = "titulo", nullable = false, length = 120)
    private String titulo;

    @Column(name = "descricao", nullable = false, length = 1000)
    private String descricao;

    @Column(name = "beneficio", nullable = false, length = 500)
    private String beneficio;

    @Column(name = "dt_cadastro", nullable = false)
    private LocalDateTime dtCadastro;

    protected AplicacaoNuclear() {
    }

    public Long getIdAplicacao() { return idAplicacao; }
    public Area getArea() { return area; }
    public String getTitulo() { return titulo; }
    public String getDescricao() { return descricao; }
    public String getBeneficio() { return beneficio; }
    public LocalDateTime getDtCadastro() { return dtCadastro; }
}
