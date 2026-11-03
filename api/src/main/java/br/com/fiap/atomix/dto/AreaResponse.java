package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.Area;

@Schema(description = "Área da cidade nuclear, com o total de aplicações cadastradas")
public record AreaResponse(Long idArea, String nome, String descricao, String ativa, long qtdAplicacoes) {

    public static AreaResponse from(Area a, long qtdAplicacoes) {
        return new AreaResponse(a.getIdArea(), a.getNome(), a.getDescricao(), a.getAtiva(), qtdAplicacoes);
    }
}
