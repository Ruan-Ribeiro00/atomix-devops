package br.com.fiap.atomix.service;

import br.com.fiap.atomix.database.Procedimentos;
import br.com.fiap.atomix.dto.AreaRequest;
import br.com.fiap.atomix.dto.AreaResponse;
import br.com.fiap.atomix.exception.RecursoNaoEncontradoException;
import br.com.fiap.atomix.model.Area;
import br.com.fiap.atomix.repository.AplicacaoNuclearRepository;
import br.com.fiap.atomix.repository.AreaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AreaService {

    private final AreaRepository areaRepository;
    private final AplicacaoNuclearRepository aplicacaoRepository;

    public AreaService(AreaRepository areaRepository, AplicacaoNuclearRepository aplicacaoRepository) {
        this.areaRepository = areaRepository;
        this.aplicacaoRepository = aplicacaoRepository;
    }

    @Transactional(readOnly = true)
    public List<AreaResponse> listar(Boolean somenteAtivas) {
        List<Area> areas = Boolean.TRUE.equals(somenteAtivas)
                ? areaRepository.findByAtivaOrderByIdArea("S")
                : areaRepository.findAllByOrderByIdArea();
        return areas.stream().map(this::paraResposta).toList();
    }

    @Transactional(readOnly = true)
    public AreaResponse buscarPorId(Long id) {
        return paraResposta(buscarEntidade(id));
    }

    /** INSERT via PRC_ATX_INS_AREA. */
    public AreaResponse criar(AreaRequest req) {
        Long id = Procedimentos.executar("PRC_ATX_INS_AREA", () ->
                areaRepository.inserir(req.nome().trim(), req.descricao().trim(), req.ativaOuPadrao()));
        return buscarPorId(id);
    }

    /** UPDATE via PRC_ATX_UPD_AREA. */
    public AreaResponse atualizar(Long id, AreaRequest req) {
        Procedimentos.executar("PRC_ATX_UPD_AREA", () ->
                areaRepository.atualizar(id, req.nome().trim(), req.descricao().trim(), req.ativaOuPadrao()));
        return buscarPorId(id);
    }

    /** DELETE via PRC_ATX_DEL_AREA (bloqueado se a área tiver aplicações: ORA-20005 → 409). */
    public void excluir(Long id) {
        Procedimentos.executar("PRC_ATX_DEL_AREA", () -> areaRepository.excluir(id));
    }

    Area buscarEntidade(Long id) {
        return areaRepository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Área", id));
    }

    private AreaResponse paraResposta(Area a) {
        return AreaResponse.from(a, aplicacaoRepository.countByAreaIdArea(a.getIdArea()));
    }
}
