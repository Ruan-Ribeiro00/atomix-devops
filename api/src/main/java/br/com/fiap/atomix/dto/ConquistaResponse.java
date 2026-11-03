package br.com.fiap.atomix.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import br.com.fiap.atomix.model.Conquista;

@Schema(description = "Conquista; idArea nulo indica conquista geral")
public record ConquistaResponse(Long idConquista, Long idArea, String area, String nome, String descricao,
                                Integer pontosNecessarios) {

    public static ConquistaResponse from(Conquista c) {
        var area = c.getArea();
        return new ConquistaResponse(c.getIdConquista(), area == null ? null : area.getIdArea(),
                area == null ? null : area.getNome(), c.getNome(), c.getDescricao(), c.getPontosNecessarios());
    }
}
