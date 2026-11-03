package br.com.fiap.atomix.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;

public class AlternativasDistintasValidator implements ConstraintValidator<AlternativasDistintas, ComAlternativas> {

    @Override
    public boolean isValid(ComAlternativas valor, ConstraintValidatorContext context) {
        if (valor == null) {
            return true;
        }
        List<String> normalizadas = valor.alternativas().stream()
                .filter(Objects::nonNull)
                .map(a -> a.trim().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT))
                .filter(a -> !a.isEmpty())
                .toList();
        // Alternativas nulas/vazias já são barradas pelo @NotBlank de cada campo.
        Set<String> unicas = new HashSet<>(normalizadas);
        return unicas.size() == normalizadas.size();
    }
}
