package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.TradutorErroOracle;
import br.com.fiap.atomix.dto.RankingJogadorResponse;
import br.com.fiap.atomix.dto.RelatorioAplicacaoResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;
import java.util.function.Supplier;

/** Consulta as functions com retorno TABLE do projeto de Banco de Dados. */
@Service
public class RelatorioService {

    private final JdbcTemplate jdbc;

    public RelatorioService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** FN_ATX_RELATORIO_APLICACOES: cursor + INNER JOIN (área) + LEFT JOIN (perguntas). */
    public List<RelatorioAplicacaoResponse> relatorioAplicacoes(Long idArea) {
        return traduzindo(() -> jdbc.query(
                "SELECT area, id_aplicacao, titulo, beneficio, qtd_perguntas, pontos_quiz, linha_relatorio "
                        + "FROM TABLE(FN_ATX_RELATORIO_APLICACOES(?))",
                (rs, i) -> new RelatorioAplicacaoResponse(rs.getString("area"), rs.getLong("id_aplicacao"),
                        rs.getString("titulo"), rs.getString("beneficio"), inteiro(rs, "qtd_perguntas"),
                        inteiro(rs, "pontos_quiz"), rs.getString("linha_relatorio")),
                idArea));
    }

    /** FN_ATX_RANKING_JOGADORES: INNER JOIN + GROUP BY + COUNT/SUM/MAX + ORDER BY. */
    public List<RankingJogadorResponse> ranking(Integer minConquistas) {
        return traduzindo(() -> jdbc.query(
                "SELECT posicao, id_jogador, jogador, pontuacao, nivel, qtd_conquistas, perc_conquistas, "
                        + "soma_pontos_conq, ultima_conquista FROM TABLE(FN_ATX_RANKING_JOGADORES(?))",
                (rs, i) -> {
                    Timestamp ultima = rs.getTimestamp("ultima_conquista");
                    return new RankingJogadorResponse(inteiro(rs, "posicao"), rs.getLong("id_jogador"),
                            rs.getString("jogador"), inteiro(rs, "pontuacao"), rs.getString("nivel"),
                            inteiro(rs, "qtd_conquistas"), rs.getBigDecimal("perc_conquistas"),
                            inteiro(rs, "soma_pontos_conq"), ultima == null ? null : ultima.toLocalDateTime());
                },
                minConquistas == null ? 1 : minConquistas));
    }

    private static Integer inteiro(ResultSet rs, String coluna) throws SQLException {
        int v = rs.getInt(coluna);
        return rs.wasNull() ? null : v;
    }

    private static <T> T traduzindo(Supplier<T> consulta) {
        try {
            return consulta.get();
        } catch (DataAccessException ex) {
            var traduzido = TradutorErroOracle.traduzir(ex);
            if (traduzido != null) throw traduzido;
            throw ex;
        }
    }
}
