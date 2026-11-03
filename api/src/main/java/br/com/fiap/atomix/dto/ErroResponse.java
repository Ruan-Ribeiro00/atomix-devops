package br.com.fiap.atomix.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
@Schema(description = "Formato padrão de erro devolvido por toda a API")
public record ErroResponse(
        LocalDateTime timestamp,
        @Schema(example = "409") int status,
        @Schema(example = "Conflict") String erro,
        @Schema(example = "AREA: ja existe uma area com o nome \"Saúde\".") String mensagem,
        @Schema(example = "/api/areas") String caminho,
        @Schema(description = "Código do RAISE_APPLICATION_ERROR da procedure, quando o erro veio do banco",
                example = "-20002") Integer codigoOracle,
        @Schema(description = "Erros por campo (apenas em erros de validação)") List<CampoErro> campos
) {
    @Schema(description = "Erro de validação de um campo")
    public record CampoErro(
            @Schema(example = "nome") String campo,
            @Schema(example = "O nome é obrigatório") String mensagem) {
    }
}
