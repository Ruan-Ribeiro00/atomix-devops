package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

import java.time.LocalDateTime;

/**
 * Jogador cadastrado no app. Tabela TB_ATX_JOGADOR. Gravação via PRC_ATX_*_JOGADOR.
 * A senha é guardada apenas como hash BCrypt e nunca sai da API.
 */
@Entity
@Immutable
@Table(name = "TB_ATX_JOGADOR")
public class Jogador {

    @Id
    @Column(name = "id_jogador")
    private Long idJogador;

    @Column(name = "nome", nullable = false, length = 100)
    private String nome;

    @Column(name = "email", nullable = false, length = 120)
    private String email;

    @Column(name = "senha", nullable = false, length = 100)
    private String senha;

    @Column(name = "pontuacao", nullable = false)
    private Integer pontuacao;

    @Column(name = "dt_cadastro", nullable = false)
    private LocalDateTime dtCadastro;

    protected Jogador() {
    }

    public Long getIdJogador() { return idJogador; }
    public String getNome() { return nome; }
    public String getEmail() { return email; }
    public String getSenha() { return senha; }
    public Integer getPontuacao() { return pontuacao; }
    public LocalDateTime getDtCadastro() { return dtCadastro; }
}
