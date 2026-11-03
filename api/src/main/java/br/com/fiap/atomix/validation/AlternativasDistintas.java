package br.com.fiap.atomix.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

/**
 * Validação customizada (nível de classe): as quatro alternativas de uma pergunta
 * do quiz precisam ser diferentes entre si, ignorando maiúsculas e espaços.
 */
@Documented
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = AlternativasDistintasValidator.class)
public @interface AlternativasDistintas {

    String message() default "As alternativas A, B, C e D devem ser diferentes entre si";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
