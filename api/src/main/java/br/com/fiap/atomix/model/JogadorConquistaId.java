package br.com.fiap.atomix.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

/** Chave composta de TB_ATX_JOGADOR_CONQUISTA (id_jogador + id_conquista). */
@Embeddable
public class JogadorConquistaId implements Serializable {

    @Column(name = "id_jogador")
    private Long idJogador;

    @Column(name = "id_conquista")
    private Long idConquista;

    protected JogadorConquistaId() {
    }

    public JogadorConquistaId(Long idJogador, Long idConquista) {
        this.idJogador = idJogador;
        this.idConquista = idConquista;
    }

    public Long getIdJogador() { return idJogador; }
    public Long getIdConquista() { return idConquista; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof JogadorConquistaId that)) return false;
        return Objects.equals(idJogador, that.idJogador) && Objects.equals(idConquista, that.idConquista);
    }

    @Override
    public int hashCode() {
        return Objects.hash(idJogador, idConquista);
    }
}
