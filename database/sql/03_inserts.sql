-- =============================================================================
--  ATOMIX - Carga inicial de dados (INSERTs) - DevOps
--  Executado automaticamente pelo database/01-criar-objetos.sh na 1ª subida do
--  Oracle, depois de 01_ddl.sql e 02_plsql.sql, conectado como ATOMIX.
--  Tabelas e sequences: modelo do projeto de Banco de Dados (TB_ATX_*).
--  Senha dos jogadores de teste: Atomix@2026 (gravada como hash BCrypt, como a API faz).
-- =============================================================================
SET DEFINE OFF

-- ------------------------------------------------------------- TB_ATX_AREA ----
-- Mesmas 10 áreas do projeto de Banco de Dados: 5 ativas na cidade e 5 "em breve" (ativa = N)
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Saúde', 'Como a radiação ajuda a diagnosticar e tratar doenças, de exames de imagem ao tratamento do câncer.', 'S');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Agro', 'Técnicas nucleares que protegem lavouras, controlam pragas e criam variedades mais resistentes.', 'S');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Indústria', 'Inspeção de peças, esterilização e controle de qualidade com fontes radioativas.', 'S');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Energia', 'Geração de eletricidade em usinas nucleares e o ciclo do combustível nuclear.', 'S');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Pesquisa', 'Reatores de pesquisa, datação de materiais e produção de radioisótopos para a ciência.', 'S');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Meio Ambiente', 'Traçadores radioativos para estudar água, solo e poluição.', 'N');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Alimentação', 'Irradiação de alimentos para aumentar a durabilidade e a segurança alimentar.', 'N');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Patrimônio Cultural', 'Análises nucleares não destrutivas que ajudam a preservar obras de arte e fósseis.', 'N');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Propulsão Naval', 'A propulsão nuclear de submarinos desenvolvida pelo Programa Nuclear da Marinha.', 'N');
INSERT INTO TB_ATX_AREA (id_area, nome, descricao, ativa) VALUES (SQ_ATX_AREA.NEXTVAL, 'Espaço', 'Fontes nucleares de energia que alimentam sondas e missões espaciais.', 'N');

-- -------------------------------------------------------- TB_ATX_APLICACAO ----
INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Saúde'),
  'PET-CT com flúor-18',
  'O paciente recebe um radiofármaco com flúor-18 (FDG), que se concentra em células com metabolismo acelerado. O equipamento PET-CT detecta a radiação emitida e gera imagens do corpo.',
  'Permite detectar tumores e acompanhar a resposta ao tratamento de forma precoce e não invasiva.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Saúde'),
  'Radioterapia e braquiterapia',
  'Feixes de radiação ou pequenas fontes radioativas (como o irídio-192) colocadas junto ao tumor destroem células cancerígenas.',
  'Trata diversos tipos de câncer, muitas vezes evitando cirurgias e preservando órgãos.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Agro'),
  'Irradiação de alimentos',
  'Alimentos passam por uma dose controlada de radiação gama, que elimina fungos, bactérias e insetos sem deixar o alimento radioativo.',
  'Aumenta a vida útil de frutas, grãos e temperos e reduz perdas e doenças transmitidas por alimentos.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Agro'),
  'Melhoramento genético por mutação induzida',
  'Sementes são expostas à radiação para gerar variações genéticas; pesquisadores selecionam as plantas com características desejáveis.',
  'Cria variedades mais produtivas e resistentes a pragas e à seca, sem uso de transgenia.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Indústria'),
  'Gamagrafia de soldas',
  'Uma fonte radioativa atravessa tubulações e chapas metálicas e registra a imagem interna da peça, revelando trincas e falhas de solda.',
  'Garante a segurança de oleodutos, navios, pontes e plataformas de petróleo sem desmontar as estruturas.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Indústria'),
  'Esterilização de produtos médicos',
  'Seringas, luvas, cateteres e curativos já embalados são expostos à radiação gama, que elimina microrganismos.',
  'Esteriliza grandes lotes na embalagem final, sem calor nem resíduos químicos.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Energia'),
  'Usinas nucleares Angra 1 e 2',
  'Em Angra dos Reis (RJ), a fissão do urânio aquece água, gera vapor e movimenta turbinas que produzem eletricidade.',
  'Geração de energia contínua e de baixa emissão de gases de efeito estufa, complementando a matriz elétrica.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Energia'),
  'Propulsão nuclear naval - LABGENE',
  'O Laboratório de Geração Núcleo-Elétrica, da Marinha, em Iperó (SP), é o protótipo em terra do sistema de propulsão do submarino brasileiro com propulsão nuclear.',
  'Domínio tecnológico nacional e submarinos com grande autonomia para proteger a Amazônia Azul.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Pesquisa'),
  'Reator de pesquisa IEA-R1',
  'Reator do IPEN, em São Paulo, inaugurado em 1957, usado para pesquisa, formação de pessoal e produção de radioisótopos.',
  'Pioneiro no país, apoia décadas de ciência nuclear e a produção de insumos para a medicina.');

INSERT INTO TB_ATX_APLICACAO (id_aplicacao, id_area, titulo, descricao, beneficio) VALUES (
  SQ_ATX_APLICACAO.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Pesquisa'),
  'Reator Multipropósito Brasileiro (RMB)',
  'Projeto de reator de pesquisa em Iperó (SP) voltado à produção de radioisótopos, como o molibdênio-99, e a testes de materiais.',
  'Reduz a dependência de importação de radiofármacos usados em milhões de exames.');

-- --------------------------------------------------------- TB_ATX_PERGUNTA ----
INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, resposta_correta, pontos) VALUES (
  SQ_ATX_PERGUNTA.NEXTVAL, (SELECT id_aplicacao FROM TB_ATX_APLICACAO WHERE titulo = 'PET-CT com flúor-18'),
  'Qual exame usa um radiofármaco com flúor-18 para localizar tumores?',
  'Raio-X simples', 'PET-CT', 'Ultrassom', 'Eletrocardiograma', 'B', 10);

INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, resposta_correta, pontos) VALUES (
  SQ_ATX_PERGUNTA.NEXTVAL, (SELECT id_aplicacao FROM TB_ATX_APLICACAO WHERE titulo = 'Irradiação de alimentos'),
  'Um alimento irradiado fica radioativo?',
  'Sim, para sempre', 'Sim, por alguns dias', 'Não, a radiação não permanece no alimento', 'Só se for fruta', 'C', 10);

INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, resposta_correta, pontos) VALUES (
  SQ_ATX_PERGUNTA.NEXTVAL, (SELECT id_aplicacao FROM TB_ATX_APLICACAO WHERE titulo = 'Gamagrafia de soldas'),
  'Para que serve a gamagrafia na indústria?',
  'Pintar peças metálicas', 'Inspecionar soldas e falhas internas', 'Gerar energia', 'Resfriar máquinas', 'B', 10);

INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, resposta_correta, pontos) VALUES (
  SQ_ATX_PERGUNTA.NEXTVAL, (SELECT id_aplicacao FROM TB_ATX_APLICACAO WHERE titulo = 'Usinas nucleares Angra 1 e 2'),
  'Onde ficam as usinas nucleares brasileiras Angra 1 e 2?',
  'Angra dos Reis (RJ)', 'Iperó (SP)', 'Resende (RJ)', 'Recife (PE)', 'A', 10);

INSERT INTO TB_ATX_PERGUNTA (id_pergunta, id_aplicacao, enunciado, alternativa_a, alternativa_b, alternativa_c, alternativa_d, resposta_correta, pontos) VALUES (
  SQ_ATX_PERGUNTA.NEXTVAL, (SELECT id_aplicacao FROM TB_ATX_APLICACAO WHERE titulo = 'Reator de pesquisa IEA-R1'),
  'Qual instituição opera o reator de pesquisa IEA-R1, em São Paulo?',
  'NASA', 'IPEN', 'Petrobras', 'INPE', 'B', 10);

-- ---------------------------------------------------------- TB_ATX_JOGADOR ----
INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao) VALUES (SQ_ATX_JOGADOR.NEXTVAL, 'Ana Souza', 'ana.souza@example.com', '$2a$10$hpihQ.5pL0YmdiRT17D7xOLy4dZneDV1bs6q/0MWckGRkOy6sy4LG', 120);
INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao) VALUES (SQ_ATX_JOGADOR.NEXTVAL, 'Bruno Lima', 'bruno.lima@example.com', '$2a$10$hpihQ.5pL0YmdiRT17D7xOLy4dZneDV1bs6q/0MWckGRkOy6sy4LG', 40);
INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao) VALUES (SQ_ATX_JOGADOR.NEXTVAL, 'Carla Mendes', 'carla.mendes@example.com', '$2a$10$hpihQ.5pL0YmdiRT17D7xOLy4dZneDV1bs6q/0MWckGRkOy6sy4LG', 0);
INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao) VALUES (SQ_ATX_JOGADOR.NEXTVAL, 'Diego Alves', 'diego.alves@example.com', '$2a$10$hpihQ.5pL0YmdiRT17D7xOLy4dZneDV1bs6q/0MWckGRkOy6sy4LG', 260);
INSERT INTO TB_ATX_JOGADOR (id_jogador, nome, email, senha, pontuacao) VALUES (SQ_ATX_JOGADOR.NEXTVAL, 'Eduarda Nunes', 'eduarda.nunes@example.com', '$2a$10$hpihQ.5pL0YmdiRT17D7xOLy4dZneDV1bs6q/0MWckGRkOy6sy4LG', 610);

-- -------------------------------------------------------- TB_ATX_CONQUISTA ----
-- Mesmo catálogo do projeto de Banco de Dados, do console .NET e do app (id_area nulo = conquista geral)
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, NULL, 'Primeiro Átomo', 'Criou a conta e começou a explorar a cidade nuclear.', 0);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Saúde'), 'Explorador da Saúde', 'Descobriu como a radiação salva vidas na medicina.', 50);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Agro'), 'Guardião do Agro', 'Aprendeu como a tecnologia nuclear protege as lavouras.', 100);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Indústria'), 'Engenheiro da Indústria', 'Dominou as aplicações nucleares na indústria.', 150);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Energia'), 'Energia Limpa', 'Entendeu como a energia nuclear gera eletricidade com baixa emissão.', 200);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Pesquisa'), 'Mente Científica', 'Explorou os reatores de pesquisa e a datação de materiais.', 300);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, NULL, 'Mestre do Quiz', 'Acertou perguntas de todas as áreas da cidade nuclear.', 400);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, NULL, 'Cidadão Nuclear', 'Conhece as principais aplicações nucleares do dia a dia.', 500);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, (SELECT id_area FROM TB_ATX_AREA WHERE nome = 'Propulsão Naval'), 'Submarinista', 'Conheceu o Programa Nuclear da Marinha e a propulsão naval.', 750);
INSERT INTO TB_ATX_CONQUISTA (id_conquista, id_area, nome, descricao, pontos_necessarios) VALUES (SQ_ATX_CONQUISTA.NEXTVAL, NULL, 'Mestre Nuclear', 'Alcançou o nível máximo do ATOMIX.', 1000);

-- ------------------------------------------------ TB_ATX_JOGADOR_CONQUISTA ----
-- Regra: conquista desbloqueada quando pontuacao >= pontos_necessarios
INSERT INTO TB_ATX_JOGADOR_CONQUISTA (id_jogador, id_conquista)
SELECT j.id_jogador, c.id_conquista
  FROM TB_ATX_JOGADOR j
  JOIN TB_ATX_CONQUISTA c ON j.pontuacao >= c.pontos_necessarios;

COMMIT;

-- Conferência rápida
SELECT 'AREA' tabela, COUNT(*) qtd FROM TB_ATX_AREA
UNION ALL SELECT 'APLICACAO', COUNT(*) FROM TB_ATX_APLICACAO
UNION ALL SELECT 'PERGUNTA', COUNT(*) FROM TB_ATX_PERGUNTA
UNION ALL SELECT 'JOGADOR', COUNT(*) FROM TB_ATX_JOGADOR
UNION ALL SELECT 'CONQUISTA', COUNT(*) FROM TB_ATX_CONQUISTA
UNION ALL SELECT 'JOGADOR_CONQUISTA', COUNT(*) FROM TB_ATX_JOGADOR_CONQUISTA;
