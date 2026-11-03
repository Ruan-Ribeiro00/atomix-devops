package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

import java.time.LocalDateTime;

/**
 * Entidade associativa JOGADOR x CONQUISTA (N:N): conquistas já desbloqueadas e quando.
 * Tabela TB_ATX_JOGADOR_CONQUISTA. Gravação via PRC_ATX_*_JOGADOR_CONQUISTA.
 */
@Entity
@Immutable
@Table(name = "TB_ATX_JOGADOR_CONQUISTA")
public class JogadorConquista {

    @EmbeddedId
    private JogadorConquistaId id;

    @MapsId("idConquista")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_conquista")
    private Conquista conquista;

    @Column(name = "dt_desbloqueio", nullable = false)
    private LocalDateTime dtDesbloqueio;

    protected JogadorConquista() {
    }

    public JogadorConquistaId getId() { return id; }
    public Conquista getConquista() { return conquista; }
    public LocalDateTime getDtDesbloqueio() { return dtDesbloqueio; }
}
