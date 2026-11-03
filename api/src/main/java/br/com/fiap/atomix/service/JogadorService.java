package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.Procedimentos;
import br.com.fiap.atomix.dto.*;
import br.com.fiap.atomix.exception.RecursoNaoEncontradoException;
import br.com.fiap.atomix.model.Jogador;
import br.com.fiap.atomix.repository.JogadorConquistaRepository;
import br.com.fiap.atomix.repository.JogadorRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class JogadorService {

    private final JogadorRepository jogadorRepository;
    private final JogadorConquistaRepository jogadorConquistaRepository;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public JogadorService(JogadorRepository jogadorRepository, JogadorConquistaRepository jogadorConquistaRepository) {
        this.jogadorRepository = jogadorRepository;
        this.jogadorConquistaRepository = jogadorConquistaRepository;
    }

    // ------------------------------------------------------------ Jogador

    @Transactional(readOnly = true)
    public List<JogadorResponse> listar(String nome) {
        List<Jogador> jogadores = (nome == null || nome.isBlank())
                ? jogadorRepository.findAllByOrderByPontuacaoDescNomeAsc()
                : jogadorRepository.findByNomeContainingIgnoreCaseOrderByNome(nome.trim());
        return jogadores.stream().map(this::paraResposta).toList();
    }

    @Transactional(readOnly = true)
    public JogadorResponse buscarPorId(Long id) {
        return paraResposta(buscarEntidade(id));
    }

    /** INSERT via PRC_ATX_INS_JOGADOR (a senha é gravada só como hash BCrypt). */
    public JogadorResponse criar(JogadorCriacaoRequest req) {
        Long id = Procedimentos.executar("PRC_ATX_INS_JOGADOR", () -> jogadorRepository.inserir(
                req.nome().trim(), req.email().trim(), encoder.encode(req.senha()),
                req.pontuacao() == null ? 0 : req.pontuacao()));
        return buscarPorId(id);
    }

    /** UPDATE via PRC_ATX_UPD_JOGADOR (senha nula mantém a atual). */
    public JogadorResponse atualizar(Long id, JogadorAtualizacaoRequest req) {
        String novoHash = req.senha() == null ? null : encoder.encode(req.senha());
        Procedimentos.executar("PRC_ATX_UPD_JOGADOR", () -> jogadorRepository.atualizar(
                id, req.nome().trim(), req.email().trim(), novoHash, req.pontuacao()));
        return buscarPorId(id);
    }

    /** DELETE via PRC_ATX_DEL_JOGADOR (as conquistas do jogador saem em cascata). */
    public void excluir(Long id) {
        Procedimentos.executar("PRC_ATX_DEL_JOGADOR", () -> jogadorRepository.excluir(id));
    }

    // ------------------------------------------------- Conquistas do jogador

    @Transactional(readOnly = true)
    public List<JogadorConquistaResponse> listarConquistas(Long idJogador) {
        buscarEntidade(idJogador);
        return jogadorConquistaRepository.findByIdIdJogadorOrderByDtDesbloqueioAscIdIdConquistaAsc(idJogador)
                .stream().map(JogadorConquistaResponse::from).toList();
    }

    /** INSERT via PRC_ATX_INS_JOGADOR_CONQUISTA (pontuação insuficiente: ORA-20006 → 422). */
    public List<JogadorConquistaResponse> desbloquear(Long idJogador, JogadorConquistaRequest req) {
        Procedimentos.executar("PRC_ATX_INS_JOGADOR_CONQUISTA", () ->
                jogadorConquistaRepository.inserir(idJogador, req.idConquista(), req.dtDesbloqueio()));
        return listarConquistas(idJogador);
    }

    /** UPDATE via PRC_ATX_UPD_JOGADOR_CONQUISTA (corrige a data do desbloqueio). */
    public List<JogadorConquistaResponse> atualizarData(Long idJogador, Long idConquista, DataDesbloqueioRequest req) {
        Procedimentos.executar("PRC_ATX_UPD_JOGADOR_CONQUISTA", () ->
                jogadorConquistaRepository.atualizar(idJogador, idConquista, req.dtDesbloqueio()));
        return listarConquistas(idJogador);
    }

    /** DELETE via PRC_ATX_DEL_JOGADOR_CONQUISTA. */
    public void removerConquista(Long idJogador, Long idConquista) {
        Procedimentos.executar("PRC_ATX_DEL_JOGADOR_CONQUISTA", () ->
                jogadorConquistaRepository.excluir(idJogador, idConquista));
    }

    /** Regra de negócio: PRC_ATX_DESBLOQUEAR_CONQUISTAS libera tudo o que a pontuação já permite. */
    public DesbloqueioResponse desbloquearAutomaticamente(Long idJogador) {
        Integer qtd = Procedimentos.executar("PRC_ATX_DESBLOQUEAR_CONQUISTAS", () ->
                jogadorConquistaRepository.desbloquearAutomaticamente(idJogador));
        return new DesbloqueioResponse(idJogador, qtd == null ? 0 : qtd, listarConquistas(idJogador));
    }

    private Jogador buscarEntidade(Long id) {
        return jogadorRepository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Jogador", id));
    }

    private JogadorResponse paraResposta(Jogador j) {
        return JogadorResponse.from(j, jogadorConquistaRepository.countByIdIdJogador(j.getIdJogador()));
    }
}
