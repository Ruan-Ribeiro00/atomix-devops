package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.Procedimentos;
import br.com.fiap.atomix.dto.ConquistaRequest;
import br.com.fiap.atomix.dto.ConquistaResponse;
import br.com.fiap.atomix.exception.RecursoNaoEncontradoException;
import br.com.fiap.atomix.repository.ConquistaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ConquistaService {

    private final ConquistaRepository repository;

    public ConquistaService(ConquistaRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<ConquistaResponse> listar() {
        return repository.findAllByOrderByPontosNecessariosAscNomeAsc().stream().map(ConquistaResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public ConquistaResponse buscarPorId(Long id) {
        return ConquistaResponse.from(repository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Conquista", id)));
    }

    /** INSERT via PRC_ATX_INS_CONQUISTA. */
    public ConquistaResponse criar(ConquistaRequest req) {
        Long id = Procedimentos.executar("PRC_ATX_INS_CONQUISTA", () -> repository.inserir(
                req.idArea(), req.nome().trim(), req.descricao().trim(), req.pontosNecessarios()));
        return buscarPorId(id);
    }

    /** UPDATE via PRC_ATX_UPD_CONQUISTA. */
    public ConquistaResponse atualizar(Long id, ConquistaRequest req) {
        Procedimentos.executar("PRC_ATX_UPD_CONQUISTA", () -> repository.atualizar(
                id, req.idArea(), req.nome().trim(), req.descricao().trim(), req.pontosNecessarios()));
        return buscarPorId(id);
    }

    /** DELETE via PRC_ATX_DEL_CONQUISTA. */
    public void excluir(Long id) {
        Procedimentos.executar("PRC_ATX_DEL_CONQUISTA", () -> repository.excluir(id));
    }
}
