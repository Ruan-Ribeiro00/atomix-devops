package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.AplicacaoNuclear;

import java.time.LocalDateTime;

@Schema(description = "Aplicação nuclear com o nome da área")
public record AplicacaoResponse(Long idAplicacao, Long idArea, String area, String titulo, String descricao,
                                String beneficio, LocalDateTime dtCadastro) {

    public static AplicacaoResponse from(AplicacaoNuclear a) {
        return new AplicacaoResponse(a.getIdAplicacao(), a.getArea().getIdArea(), a.getArea().getNome(),
                a.getTitulo(), a.getDescricao(), a.getBeneficio(), a.getDtCadastro());
    }
}
