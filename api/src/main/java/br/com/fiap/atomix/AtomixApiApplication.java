package br.com.fiap.atomix;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.web.config.EnableSpringDataWebSupport;

import static org.springframework.data.web.config.EnableSpringDataWebSupport.PageSerializationMode.VIA_DTO;

/**
 * ATOMIX API — backend educativo da "cidade nuclear" do app ATOMIX.
 * Challenge FIAP 2026 · Marinha do Brasil / CTMSP.
 */
@SpringBootApplication
@EnableSpringDataWebSupport(pageSerializationMode = VIA_DTO)
public class AtomixApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(AtomixApiApplication.class, args);
    }
}
