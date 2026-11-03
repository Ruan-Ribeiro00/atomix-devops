package br.com.fiap.atomix.model;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;

/**
 * Pergunta do quiz sobre uma aplicação nuclear. Tabela TB_ATX_PERGUNTA.
 * A área da pergunta é obtida pela aplicação (Pergunta → Aplicação → Área), sem coluna redundante (3FN).
 */
@Entity
@Immutable
@Table(name = "TB_ATX_PERGUNTA")
public class Pergunta {

    @Id
    @Column(name = "id_pergunta")
    private Long idPergunta;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_aplicacao", nullable = false)
    private AplicacaoNuclear aplicacao;

    @Column(name = "enunciado", nullable = false, length = 500)
    private String enunciado;

    @Column(name = "alternativa_a", nullable = false, length = 200)
    private String alternativaA;

    @Column(name = "alternativa_b", nullable = false, length = 200)
    private String alternativaB;

    @Column(name = "alternativa_c", nullable = false, length = 200)
    private String alternativaC;

    @Column(name = "alternativa_d", nullable = false, length = 200)
    private String alternativaD;

    @Enumerated(EnumType.STRING)
    @Column(name = "resposta_correta", nullable = false, length = 1)
    private Alternativa respostaCorreta;

    @Column(name = "pontos", nullable = false)
    private Integer pontos;

    protected Pergunta() {
    }

    public boolean acertou(Alternativa resposta) {
        return respostaCorreta == resposta;
    }

    public Long getIdPergunta() { return idPergunta; }
    public AplicacaoNuclear getAplicacao() { return aplicacao; }
    public String getEnunciado() { return enunciado; }
    public String getAlternativaA() { return alternativaA; }
    public String getAlternativaB() { return alternativaB; }
    public String getAlternativaC() { return alternativaC; }
    public String getAlternativaD() { return alternativaD; }
    public Alternativa getRespostaCorreta() { return respostaCorreta; }
    public Integer getPontos() { return pontos; }
}
