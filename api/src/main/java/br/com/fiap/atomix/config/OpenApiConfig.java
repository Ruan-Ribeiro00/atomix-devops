package br.com.fiap.atomix.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI atomixOpenApi() {
        return new OpenAPI().info(new Info()
                .title("ATOMIX API")
                .version("1.0.0")
                .description("""
                        API RESTful do **ATOMIX**, app gamificado em que o usuário explora uma *cidade nuclear* \
                        com 5 áreas (Saúde, Agro, Indústria, Energia e Pesquisa), descobre aplicações reais \
                        da tecnologia nuclear, responde quizzes, ganha pontos e desbloqueia conquistas.

                        Challenge FIAP 2026 · Marinha do Brasil / CTMSP (Programa Nuclear da Marinha).

                        **Recursos:** Áreas · Aplicações Nucleares (CRUD + busca por texto) · Perguntas do quiz · \
                        Jogadores · Conquistas · Relatórios.

                        **Persistência:** leituras com Spring Data JPA; toda inclusão, alteração e exclusão chama \
                        as procedures PRC_ATX_INS/UPD/DEL do Oracle.

                        **Erros:** os erros das procedures (RAISE_APPLICATION_ERROR) e de validação voltam como \
                        status HTTP 400, 404, 409 ou 422, sempre no formato ErroResponse.""")
                .contact(new Contact()
                        .name("Grupo ATOMIX — Gianluca K. Araujo (RM 566765) · Ruan Ribeiro (RM 567693)")));
    }
}
