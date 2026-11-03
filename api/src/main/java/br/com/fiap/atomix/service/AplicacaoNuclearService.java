package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.Procedimentos;
import br.com.fiap.atomix.dto.AplicacaoRequest;
import br.com.fiap.atomix.dto.AplicacaoResponse;
import br.com.fiap.atomix.exception.RecursoNaoEncontradoException;
import br.com.fiap.atomix.model.AplicacaoNuclear;
import br.com.fiap.atomix.repository.AplicacaoNuclearRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AplicacaoNuclearService {

    private final AplicacaoNuclearRepository repository;
    private final AreaService areaService;

    public AplicacaoNuclearService(AplicacaoNuclearRepository repository, AreaService areaService) {
        this.repository = repository;
        this.areaService = areaService;
    }

    @Transactional(readOnly = true)
    public Page<AplicacaoResponse> listar(Long idArea, Pageable pageable) {
        if (idArea == null) {
            return repository.findAll(pageable).map(AplicacaoResponse::from);
        }
        areaService.buscarEntidade(idArea); // 404 se a área não existir
        return repository.findByAreaIdArea(idArea, pageable).map(AplicacaoResponse::from);
    }

    @Transactional(readOnly = true)
    public Page<AplicacaoResponse> buscarPorTexto(String texto, Long idArea, Pageable pageable) {
        String t = texto.trim();
        Page<AplicacaoNuclear> pagina = idArea == null
                ? repository.buscarPorTexto(t, pageable)
                : repository.buscarPorTextoNaArea(idArea, t, pageable);
        return pagina.map(AplicacaoResponse::from);
    }

    @Transactional(readOnly = true)
    public AplicacaoResponse buscarPorId(Long id) {
        return AplicacaoResponse.from(repository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Aplicação nuclear", id)));
    }

    /** INSERT via PRC_ATX_INS_APLICACAO. */
    public AplicacaoResponse criar(AplicacaoRequest req) {
        Long id = Procedimentos.executar("PRC_ATX_INS_APLICACAO", () -> repository.inserir(
                req.idArea(), req.titulo().trim(), req.descricao().trim(), req.beneficio().trim()));
        return buscarPorId(id);
    }

    /** UPDATE via PRC_ATX_UPD_APLICACAO. */
    public AplicacaoResponse atualizar(Long id, AplicacaoRequest req) {
        Procedimentos.executar("PRC_ATX_UPD_APLICACAO", () -> repository.atualizar(
                id, req.idArea(), req.titulo().trim(), req.descricao().trim(), req.beneficio().trim()));
        return buscarPorId(id);
    }

    /** DELETE via PRC_ATX_DEL_APLICACAO (bloqueado se houver perguntas: ORA-20005 → 409). */
    public void excluir(Long id) {
        Procedimentos.executar("PRC_ATX_DEL_APLICACAO", () -> repository.excluir(id));
    }
}
