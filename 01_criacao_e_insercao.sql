-- =====================================================================
-- Projecto de Base de Dados: VetCare (Clínica Veterinária)
-- Disciplina: Tecnologias de Base de Dados | Licenciatura em Informática, 2º ano
-- Universidade Licungo
-- Autor: Eduardo Luís Gemusse
-- SGBD: MySQL 8.0+ (compatível com MariaDB 10.5+)
-- Ficheiro 1/2: criação da base de dados, tabelas, índices e inserção de dados
-- Execução (de raiz, sem erros):  mysql -u root -p < 01_criacao_e_insercao.sql
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS vetcare;
SET FOREIGN_KEY_CHECKS = 1;

CREATE DATABASE vetcare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vetcare;

-- ---------------------------------------------------------------------
-- ETAPA 2.1: CRIAÇÃO DAS TABELAS (ordem imposta pelas chaves estrangeiras:
-- primeiro as tabelas "pai", depois as tabelas que as referenciam)
-- ---------------------------------------------------------------------

-- Contas de acesso ao sistema (administrador, veterinário, recepcionista).
CREATE TABLE utilizador (
  id_utilizador      INT NOT NULL AUTO_INCREMENT,
  nome_completo      VARCHAR(100) NOT NULL,
  email              VARCHAR(100) NOT NULL UNIQUE,
  palavra_passe      CHAR(64) NOT NULL,
  perfil             ENUM('administrador','veterinario','recepcionista') NOT NULL,
  ativo              BOOLEAN NOT NULL DEFAULT TRUE,
  data_criacao       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_utilizador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dados profissionais dos médicos veterinários (1:1 com utilizador).
CREATE TABLE veterinario (
  id_veterinario     INT NOT NULL AUTO_INCREMENT,
  id_utilizador      INT NOT NULL UNIQUE,
  n_cedula           VARCHAR(20) NOT NULL UNIQUE,
  especialidade      VARCHAR(60) NOT NULL,
  telefone           VARCHAR(20) NOT NULL,
  PRIMARY KEY (id_veterinario),
  CONSTRAINT fk_veterinario_utilizador FOREIGN KEY (id_utilizador) REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Donos dos animais (clientes da clínica).
CREATE TABLE proprietario (
  id_proprietario    INT NOT NULL AUTO_INCREMENT,
  nome_completo      VARCHAR(100) NOT NULL,
  bi                 VARCHAR(20) NOT NULL UNIQUE,
  telefone           VARCHAR(20) NOT NULL,
  email              VARCHAR(100),
  endereco           VARCHAR(150) NOT NULL,
  bairro             VARCHAR(60) NOT NULL,
  cidade             VARCHAR(60) NOT NULL,
  PRIMARY KEY (id_proprietario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Espécies animais atendidas na clínica.
CREATE TABLE especie (
  id_especie         INT NOT NULL AUTO_INCREMENT,
  nome_comum         VARCHAR(50) NOT NULL UNIQUE,
  grupo              ENUM('Mamífero','Ave','Réptil') NOT NULL,
  PRIMARY KEY (id_especie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Raças de cada espécie (inclui 'Sem raça definida').
CREATE TABLE raca (
  id_raca            INT NOT NULL AUTO_INCREMENT,
  id_especie         INT NOT NULL,
  nome               VARCHAR(60) NOT NULL,
  PRIMARY KEY (id_raca),
  CONSTRAINT uq_raca_especie_nome UNIQUE (id_especie, nome),
  CONSTRAINT fk_raca_especie FOREIGN KEY (id_especie) REFERENCES especie (id_especie) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Animais registados na clínica.
CREATE TABLE animal (
  id_animal          INT NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(50) NOT NULL,
  sexo               ENUM('M','F') NOT NULL,
  data_nascimento    DATE NOT NULL,
  peso_kg            DECIMAL(6,2) NOT NULL,
  cor                VARCHAR(40) NOT NULL,
  microchip          VARCHAR(20) UNIQUE,
  id_proprietario    INT NOT NULL,
  id_raca            INT NOT NULL,
  PRIMARY KEY (id_animal),
  CONSTRAINT ck_animal_peso_kg CHECK (peso_kg > 0),
  CONSTRAINT fk_animal_proprietario FOREIGN KEY (id_proprietario) REFERENCES proprietario (id_proprietario) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_animal_raca FOREIGN KEY (id_raca) REFERENCES raca (id_raca) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo de serviços prestados (consultas, vacinas, cirurgias, ...).
CREATE TABLE servico (
  id_servico         INT NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(80) NOT NULL UNIQUE,
  descricao          VARCHAR(200) NOT NULL,
  preco_mzn          DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_servico),
  CONSTRAINT ck_servico_preco_mzn CHECK (preco_mzn >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Medicamentos em stock na farmácia da clínica.
CREATE TABLE medicamento (
  id_medicamento     INT NOT NULL AUTO_INCREMENT,
  nome_comercial     VARCHAR(80) NOT NULL UNIQUE,
  principio_ativo    VARCHAR(100) NOT NULL,
  forma              VARCHAR(40) NOT NULL,
  stock_unidades     INT NOT NULL DEFAULT 0,
  preco_unitario     DECIMAL(10,2) NOT NULL,
  validade           DATE NOT NULL,
  PRIMARY KEY (id_medicamento),
  CONSTRAINT ck_medicamento_stock_unidades CHECK (stock_unidades >= 0),
  CONSTRAINT ck_medicamento_preco_unitario CHECK (preco_unitario >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Consultas (agendadas, realizadas ou canceladas) de um animal com um veterinário.
CREATE TABLE consulta (
  id_consulta        INT NOT NULL AUTO_INCREMENT,
  data_hora          DATETIME NOT NULL,
  motivo             VARCHAR(150) NOT NULL,
  diagnostico        VARCHAR(250),
  estado             ENUM('agendada','realizada','cancelada') NOT NULL DEFAULT 'agendada',
  id_animal          INT NOT NULL,
  id_veterinario     INT NOT NULL,
  PRIMARY KEY (id_consulta),
  CONSTRAINT uq_consulta_vet_data UNIQUE (id_veterinario, data_hora),
  CONSTRAINT fk_consulta_animal FOREIGN KEY (id_animal) REFERENCES animal (id_animal) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_consulta_veterinario FOREIGN KEY (id_veterinario) REFERENCES veterinario (id_veterinario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela associativa N:M entre consulta e serviço (com quantidade e preço aplicado).
CREATE TABLE consulta_servico (
  id_consulta        INT NOT NULL,
  id_servico         INT NOT NULL,
  quantidade         INT NOT NULL DEFAULT 1,
  preco_aplicado     DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_consulta, id_servico),
  CONSTRAINT ck_consulta_servico_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_consulta_servico_preco_aplicado CHECK (preco_aplicado >= 0),
  CONSTRAINT fk_consulta_servico_consulta FOREIGN KEY (id_consulta) REFERENCES consulta (id_consulta) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_consulta_servico_servico FOREIGN KEY (id_servico) REFERENCES servico (id_servico) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ENTIDADE FRACA: linhas da receita de uma consulta (identificada por id_consulta + num_item).
CREATE TABLE item_receita (
  id_consulta        INT NOT NULL,
  num_item           INT NOT NULL,
  id_medicamento     INT NOT NULL,
  posologia          VARCHAR(150) NOT NULL,
  duracao_dias       INT NOT NULL,
  PRIMARY KEY (id_consulta, num_item),
  CONSTRAINT ck_item_receita_num_item CHECK (num_item > 0),
  CONSTRAINT ck_item_receita_duracao_dias CHECK (duracao_dias > 0),
  CONSTRAINT fk_item_receita_consulta FOREIGN KEY (id_consulta) REFERENCES consulta (id_consulta) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_item_receita_medicamento FOREIGN KEY (id_medicamento) REFERENCES medicamento (id_medicamento) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fatura emitida por cada consulta realizada (relação 1:1).
CREATE TABLE fatura (
  id_fatura          INT NOT NULL AUTO_INCREMENT,
  numero             VARCHAR(20) NOT NULL UNIQUE,
  id_consulta        INT NOT NULL UNIQUE,
  data_emissao       DATE NOT NULL,
  total_mzn          DECIMAL(10,2) NOT NULL,
  metodo_pagamento   ENUM('Numerário','M-Pesa','e-Mola','Cartão'),
  estado             ENUM('pendente','paga') NOT NULL DEFAULT 'pendente',
  PRIMARY KEY (id_fatura),
  CONSTRAINT ck_fatura_total_mzn CHECK (total_mzn >= 0),
  CONSTRAINT fk_fatura_consulta FOREIGN KEY (id_consulta) REFERENCES consulta (id_consulta) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Índices para acelerar pesquisas e listagens do futuro sistema web
-- (as chaves estrangeiras e as colunas UNIQUE já têm índice automático)
-- ---------------------------------------------------------------------
CREATE INDEX idx_proprietario_nome ON proprietario (nome_completo);
CREATE INDEX idx_animal_nome ON animal (nome);
CREATE INDEX idx_animal_proprietario ON animal (id_proprietario);
CREATE INDEX idx_consulta_data ON consulta (data_hora);
CREATE INDEX idx_consulta_animal ON consulta (id_animal);
CREATE INDEX idx_fatura_estado ON fatura (estado);

-- ---------------------------------------------------------------------
-- ETAPA 2.2: INSERÇÃO DOS REGISTOS (>= 20 por tabela), pela ordem das FK
-- Nota: as palavras-passe estão guardadas como hash SHA-256 (dados de demonstração).
-- ---------------------------------------------------------------------

-- utilizador: 25 registos
INSERT INTO utilizador (id_utilizador, nome_completo, email, palavra_passe, perfil, ativo, data_criacao) VALUES
  (1, 'Amélia Cumbane', 'amelia.cumbane@vetcare.co.mz', 'a36aef5a11c4073fbe60314fc9df530a9d5f986533594d1f5190742ff9e0e408', 'administrador', 1, '2026-01-05 08:00:00'),
  (2, 'Rui Manjate', 'rui.manjate@vetcare.co.mz', 'a36aef5a11c4073fbe60314fc9df530a9d5f986533594d1f5190742ff9e0e408', 'administrador', 1, '2026-01-05 08:00:00'),
  (3, 'Lúcia Sitoe', 'lucia.sitoe@vetcare.co.mz', '5d8a2ac2a9dea6b5f65b1cd02675ed9a153bb990e0e589407cd56fb566627565', 'recepcionista', 1, '2026-01-05 08:10:00'),
  (4, 'Domingos Bila', 'domingos.bila@vetcare.co.mz', '5d8a2ac2a9dea6b5f65b1cd02675ed9a153bb990e0e589407cd56fb566627565', 'recepcionista', 1, '2026-01-05 08:10:00'),
  (5, 'Carla Matusse', 'carla.matusse@vetcare.co.mz', '5d8a2ac2a9dea6b5f65b1cd02675ed9a153bb990e0e589407cd56fb566627565', 'recepcionista', 1, '2026-01-05 08:10:00'),
  (6, 'Armando Tembe', 'armando.tembe@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (7, 'Beatriz Nhantumbo', 'beatriz.nhantumbo@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (8, 'Cândido Macamo', 'candido.macamo@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (9, 'Dulce Mabjaia', 'dulce.mabjaia@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (10, 'Ernesto Langa', 'ernesto.langa@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (11, 'Filipa Mucavele', 'filipa.mucavele@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (12, 'Gilberto Mavie', 'gilberto.mavie@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (13, 'Helena Zandamela', 'helena.zandamela@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (14, 'Inácio Chongo', 'inacio.chongo@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (15, 'Joana Maculuve', 'joana.maculuve@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (16, 'Kátia Nhaca', 'katia.nhaca@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (17, 'Leopoldo Chirindza', 'leopoldo.chirindza@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (18, 'Marta Uamusse', 'marta.uamusse@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (19, 'Nelson Cossa', 'nelson.cossa@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (20, 'Olívia Mabunda', 'olivia.mabunda@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (21, 'Patrício Muianga', 'patricio.muianga@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (22, 'Quitéria Machava', 'quiteria.machava@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (23, 'Rodrigo Fernandes', 'rodrigo.fernandes@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (24, 'Sandra Pereira', 'sandra.pereira@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00'),
  (25, 'Tomás Guambe', 'tomas.guambe@vetcare.co.mz', '2902812495c2d65bf271c7a6b8eb9ae708988e17b1e512668a8160ec4cf65cb0', 'veterinario', 1, '2026-01-05 08:20:00');

-- veterinario: 20 registos
INSERT INTO veterinario (id_veterinario, id_utilizador, n_cedula, especialidade, telefone) VALUES
  (1, 6, 'MV-0001', 'Clínica Geral', '+258 87 497 5298'),
  (2, 7, 'MV-0002', 'Cirurgia de Pequenos Animais', '+258 85 588 8875'),
  (3, 8, 'MV-0003', 'Medicina Interna', '+258 84 680 2452'),
  (4, 9, 'MV-0004', 'Dermatologia', '+258 82 771 6029'),
  (5, 10, 'MV-0005', 'Emergência e Cuidados Intensivos', '+258 86 862 9606'),
  (6, 11, 'MV-0006', 'Animais de Grande Porte', '+258 87 954 3183'),
  (7, 12, 'MV-0007', 'Aves e Animais Exóticos', '+258 85 145 6760'),
  (8, 13, 'MV-0008', 'Oftalmologia', '+258 84 237 0337'),
  (9, 14, 'MV-0009', 'Odontologia', '+258 82 328 3914'),
  (10, 15, 'MV-0010', 'Ortopedia', '+258 86 419 7491'),
  (11, 16, 'MV-0011', 'Cardiologia', '+258 87 511 1068'),
  (12, 17, 'MV-0012', 'Neurologia', '+258 85 602 4645'),
  (13, 18, 'MV-0013', 'Oncologia', '+258 84 693 8222'),
  (14, 19, 'MV-0014', 'Reprodução', '+258 82 785 1799'),
  (15, 20, 'MV-0015', 'Anestesiologia', '+258 86 876 5376'),
  (16, 21, 'MV-0016', 'Imagiologia', '+258 87 967 8953'),
  (17, 22, 'MV-0017', 'Patologia Clínica', '+258 85 159 2530'),
  (18, 23, 'MV-0018', 'Nutrição Animal', '+258 84 250 6107'),
  (19, 24, 'MV-0019', 'Comportamento Animal', '+258 82 341 9684'),
  (20, 25, 'MV-0020', 'Medicina Felina', '+258 86 433 3261');

-- proprietario: 22 registos
INSERT INTO proprietario (id_proprietario, nome_completo, bi, telefone, email, endereco, bairro, cidade) VALUES
  (1, 'Fernando Cuna', '110100083717B', '+258 82 314 8144', 'fernando.cuna@exemplo.co.mz', 'Av. Julius Nyerere, 345', 'Polana Cimento', 'Maputo'),
  (2, 'Graça Nhamitambo', '110100167434C', '+258 86 406 1721', 'graca.nhamitambo@exemplo.co.mz', 'Rua da Resistência, 120', 'Sommerschield', 'Maputo'),
  (3, 'Hortência Matavele', '110100251151D', '+258 87 497 5298', 'hortencia.matavele@exemplo.co.mz', 'Av. 24 de Julho, 2210', 'Malhangalene', 'Maputo'),
  (4, 'Ismael Jossefa', '110100334868E', '+258 84 588 8875', 'ismael.jossefa@exemplo.co.mz', 'Av. Eduardo Mondlane, 880', 'Alto-Maé', 'Maputo'),
  (5, 'Júlio Bambo', '110100418585A', '+258 82 680 2452', NULL, 'Rua de Mukumbura, 45', 'Machava', 'Matola'),
  (6, 'Lídia Mulungo', '110100502302B', '+258 86 771 6029', 'lidia.mulungo@exemplo.co.mz', 'Av. de Moçambique, 1502', 'Zimpeto', 'Maputo'),
  (7, 'Mussá Macie', '110100586019C', '+258 87 862 9606', 'mussa.macie@exemplo.co.mz', 'Rua do Rio Save, 17', 'Fomento', 'Matola'),
  (8, 'Noémia Tivane', '110100669736D', '+258 84 954 3183', 'noemia.tivane@exemplo.co.mz', 'Av. Marginal, 3300', 'Costa do Sol', 'Maputo'),
  (9, 'Orlando Guambe', '110100753453E', '+258 82 145 6760', 'orlando.guambe@exemplo.co.mz', 'Rua dos Desportistas, 210', 'Polana Caniço', 'Maputo'),
  (10, 'Palmira Ngovene', '110100837170A', '+258 86 237 0337', NULL, 'Av. Vladimir Lenine, 1180', 'Maxaquene', 'Maputo'),
  (11, 'Quim Sigauque', '110100920887B', '+258 87 328 3914', 'quim.sigauque@exemplo.co.mz', 'Rua da Liberdade, 63', 'Liberdade', 'Matola'),
  (12, 'Raquel Xavier', '110101004604C', '+258 84 419 7491', 'raquel.xavier@exemplo.co.mz', 'Estrada Nacional 4, km 16', 'Boane Sede', 'Boane'),
  (13, 'Samuel Salimo', '110101088321D', '+258 82 511 1068', 'samuel.salimo@exemplo.co.mz', 'Av. Mao Tsé-Tung, 740', 'Sommerschield', 'Maputo'),
  (14, 'Telma Cumbe', '110101172038E', '+258 86 602 4645', 'telma.cumbe@exemplo.co.mz', 'Rua de Inhambane, 29', 'Matola-Gare', 'Matola'),
  (15, 'Ulisses Nhamuave', '110101255755A', '+258 87 693 8222', NULL, 'Av. Kenneth Kaunda, 415', 'Triunfo', 'Maputo'),
  (16, 'Vera Massingue', '110101339472B', '+258 84 785 1799', 'vera.massingue@exemplo.co.mz', 'Rua da Mafalala, 88', 'Mafalala', 'Maputo'),
  (17, 'Wilson Mavume', '110101423189C', '+258 82 876 5376', 'wilson.mavume@exemplo.co.mz', 'Av. das Indústrias, 902', 'Machava', 'Matola'),
  (18, 'Yara Zimba', '110101506906D', '+258 86 967 8953', 'yara.zimba@exemplo.co.mz', 'Rua do Jardim, 12', 'Coop', 'Maputo'),
  (19, 'Zeferino Dimande', '110101590623E', '+258 87 159 2530', 'zeferino.dimande@exemplo.co.mz', 'Estrada de Boane, km 9', 'Boane Sede', 'Boane'),
  (20, 'Adelaide Cossa', '110101674340A', '+258 84 250 6107', NULL, 'Av. Acordos de Lusaka, 2750', 'Zimpeto', 'Maputo'),
  (21, 'Bernardo Honwana', '110101758057B', '+258 82 341 9684', 'bernardo.honwana@exemplo.co.mz', 'Rua Joaquim Chissano, 506', 'Malhangalene', 'Maputo'),
  (22, 'Cecília Mazive', '110101841774C', '+258 86 433 3261', 'cecilia.mazive@exemplo.co.mz', 'Av. do Trabalho, 1320', 'Fomento', 'Matola');

-- especie: 20 registos
INSERT INTO especie (id_especie, nome_comum, grupo) VALUES
  (1, 'Cão', 'Mamífero'),
  (2, 'Gato', 'Mamífero'),
  (3, 'Coelho', 'Mamífero'),
  (4, 'Cavalo', 'Mamífero'),
  (5, 'Bovino', 'Mamífero'),
  (6, 'Caprino', 'Mamífero'),
  (7, 'Suíno', 'Mamífero'),
  (8, 'Galinha', 'Ave'),
  (9, 'Papagaio', 'Ave'),
  (10, 'Tartaruga', 'Réptil'),
  (11, 'Hamster', 'Mamífero'),
  (12, 'Porquinho-da-Índia', 'Mamífero'),
  (13, 'Ovino', 'Mamífero'),
  (14, 'Pato', 'Ave'),
  (15, 'Peru', 'Ave'),
  (16, 'Burro', 'Mamífero'),
  (17, 'Furão', 'Mamífero'),
  (18, 'Periquito', 'Ave'),
  (19, 'Canário', 'Ave'),
  (20, 'Pombo', 'Ave');

-- raca: 24 registos
INSERT INTO raca (id_raca, id_especie, nome) VALUES
  (1, 1, 'Pastor Alemão'),
  (2, 1, 'Labrador Retriever'),
  (3, 1, 'Rottweiler'),
  (4, 1, 'Boerboel'),
  (5, 1, 'Rhodesian Ridgeback'),
  (6, 1, 'Sem raça definida'),
  (7, 2, 'Siamês'),
  (8, 2, 'Persa'),
  (9, 2, 'Sem raça definida'),
  (10, 3, 'Anão Holandês'),
  (11, 3, 'Angorá'),
  (12, 4, 'Lusitano'),
  (13, 5, 'Nguni'),
  (14, 5, 'Brahman'),
  (15, 6, 'Boer'),
  (16, 7, 'Landrace'),
  (17, 8, 'Rhode Island Red'),
  (18, 9, 'Cinzento-africano'),
  (19, 11, 'Sírio'),
  (20, 13, 'Dorper'),
  (21, 14, 'Pequim'),
  (22, 10, 'Tartaruga-leopardo'),
  (23, 18, 'Periquito comum'),
  (24, 19, 'Canário-do-reino');

-- animal: 26 registos
INSERT INTO animal (id_animal, nome, sexo, data_nascimento, peso_kg, cor, microchip, id_proprietario, id_raca) VALUES
  (1, 'Rex', 'M', '2021-03-14', 34.50, 'Preto e castanho', 'MZ900100000001', 1, 1),
  (2, 'Luna', 'F', '2022-07-02', 27.00, 'Dourada', 'MZ900100000002', 2, 2),
  (3, 'Mimi', 'F', '2023-01-20', 3.80, 'Creme e castanho', NULL, 3, 7),
  (4, 'Simba', 'M', '2020-11-05', 5.20, 'Laranja', 'MZ900100000004', 4, 9),
  (5, 'Thor', 'M', '2019-05-30', 52.00, 'Preto e castanho', 'MZ900100000005', 5, 3),
  (6, 'Nala', 'F', '2021-09-09', 31.00, 'Castanha', 'MZ900100000006', 6, 5),
  (7, 'Bobi', 'M', '2018-08-18', 14.00, 'Branco e preto', NULL, 7, 6),
  (8, 'Nikita', 'F', '2023-06-25', 4.10, 'Cinzenta', NULL, 8, 8),
  (9, 'Max', 'M', '2020-04-12', 41.00, 'Preto', 'MZ900100000009', 9, 4),
  (10, 'Estrela', 'F', '2024-01-08', 2.30, 'Branca', NULL, 10, 10),
  (11, 'Fofo', 'M', '2023-10-30', 2.40, 'Cinzento', NULL, 11, 11),
  (12, 'Zeca', 'M', '2017-03-03', 480.00, 'Castanho', 'MZ900100000012', 12, 12),
  (13, 'Mimosa', 'F', '2019-09-15', 410.00, 'Malhada', NULL, 13, 13),
  (14, 'Bambi', 'F', '2022-05-21', 38.00, 'Castanha e branca', NULL, 14, 15),
  (15, 'Jaco', 'M', '2015-12-12', 0.45, 'Cinzento', NULL, 15, 18),
  (16, 'Dora', 'F', '2012-04-04', 9.80, 'Amarela e preta', NULL, 16, 22),
  (17, 'Toby', 'M', '2025-02-14', 0.12, 'Dourado', NULL, 17, 19),
  (18, 'Neve', 'F', '2023-08-08', 2.10, 'Branca', NULL, 18, 10),
  (19, 'Bolt', 'M', '2024-03-17', 24.50, 'Preto e branco', 'MZ900100000019', 19, 2),
  (20, 'Trovão', 'M', '2020-06-06', 520.00, 'Preto', 'MZ900100000020', 20, 12),
  (21, 'Dolly', 'F', '2023-04-01', 55.00, 'Branca', NULL, 21, 20),
  (22, 'Patolino', 'M', '2025-04-20', 3.00, 'Branco', NULL, 22, 21),
  (23, 'Tigre', 'M', '2021-12-01', 4.90, 'Rajado', 'MZ900100000023', 1, 9),
  (24, 'Pipoca', 'F', '2024-09-09', 11.00, 'Branca', 'MZ900100000024', 3, 6),
  (25, 'Duque', 'M', '2022-10-10', 36.00, 'Preto e castanho', 'MZ900100000025', 5, 1),
  (26, 'Mel', 'F', '2023-03-23', 4.40, 'Creme', NULL, 8, 7);

-- servico: 20 registos
INSERT INTO servico (id_servico, nome, descricao, preco_mzn) VALUES
  (1, 'Consulta geral', 'Exame clínico geral do animal', 500.00),
  (2, 'Consulta de urgência', 'Atendimento prioritário fora de marcação', 1200.00),
  (3, 'Vacina antirrábica', 'Vacinação contra a raiva', 450.00),
  (4, 'Vacina polivalente canina', 'Vacinação múltipla para cães', 800.00),
  (5, 'Vacina tripla felina', 'Vacinação múltipla para gatos', 750.00),
  (6, 'Desparasitação interna', 'Tratamento contra parasitas intestinais', 300.00),
  (7, 'Desparasitação externa', 'Tratamento contra pulgas e carraças', 350.00),
  (8, 'Esterilização', 'Ovariohisterectomia em fêmeas', 4500.00),
  (9, 'Castração', 'Orquiectomia em machos', 3000.00),
  (10, 'Ecografia', 'Exame ecográfico abdominal', 1500.00),
  (11, 'Raio-X', 'Radiografia digital', 1800.00),
  (12, 'Análises ao sangue', 'Hemograma e bioquímica', 1200.00),
  (13, 'Limpeza dentária', 'Destartarização sob anestesia', 2500.00),
  (14, 'Cirurgia ortopédica', 'Correcção cirúrgica de fracturas e lesões', 12000.00),
  (15, 'Sutura de ferida', 'Limpeza e sutura de lacerações', 1500.00),
  (16, 'Internamento diário', 'Diária de internamento com monitorização', 1000.00),
  (17, 'Colocação de microchip', 'Identificação electrónica do animal', 900.00),
  (18, 'Banho e tosquia', 'Higiene e tosquia do animal', 600.00),
  (19, 'Consulta domiciliária', 'Deslocação do veterinário ao domicílio', 1800.00),
  (20, 'Teste rápido de parvovirose', 'Teste rápido para diagnóstico em cães', 700.00);

-- medicamento: 20 registos
INSERT INTO medicamento (id_medicamento, nome_comercial, principio_ativo, forma, stock_unidades, preco_unitario, validade) VALUES
  (1, 'Amoxival 500', 'Amoxicilina', 'Comprimido', 180, 18.00, '2027-08-31'),
  (2, 'Meloxivet', 'Meloxicam', 'Suspensão oral', 45, 650.00, '2027-03-31'),
  (3, 'Ivermec Plus', 'Ivermectina', 'Injectável', 30, 820.00, '2027-05-31'),
  (4, 'Predniderm', 'Prednisolona', 'Comprimido', 220, 12.00, '2027-10-31'),
  (5, 'Metrovet', 'Metronidazol', 'Comprimido', 160, 10.00, '2027-06-30'),
  (6, 'Doxivet', 'Doxiciclina', 'Comprimido', 140, 14.00, '2027-09-30'),
  (7, 'Cefalexivet', 'Cefalexina', 'Cápsula', 95, 22.00, '2027-04-30'),
  (8, 'Furosevet', 'Furosemida', 'Comprimido', 120, 9.00, '2028-01-31'),
  (9, 'Vermifugo Pet', 'Pirantel + Praziquantel', 'Comprimido', 75, 85.00, '2027-12-31'),
  (10, 'Omeprazvet', 'Omeprazol', 'Cápsula', 60, 25.00, '2027-07-31'),
  (11, 'Cetirivet', 'Cetirizina', 'Comprimido', 90, 15.00, '2027-11-30'),
  (12, 'Enrofloxvet', 'Enrofloxacina', 'Comprimido', 110, 28.00, '2027-02-28'),
  (13, 'Carprovet', 'Carprofeno', 'Comprimido', 85, 40.00, '2027-08-31'),
  (14, 'Sulfaderm', 'Sulfadiazina de prata', 'Pomada', 25, 380.00, '2027-01-31'),
  (15, 'Gentacolírio', 'Gentamicina', 'Colírio', 38, 210.00, '2027-03-31'),
  (16, 'Soro Vet', 'Cloreto de sódio 0,9%', 'Solução injectável', 55, 160.00, '2028-02-29'),
  (17, 'Complexo B Vet', 'Vitaminas do complexo B', 'Injectável', 48, 140.00, '2027-05-31'),
  (18, 'Fenbenvet', 'Fenbendazol', 'Suspensão oral', 33, 310.00, '2027-09-30'),
  (19, 'Oxitetra LA', 'Oxitetraciclina', 'Injectável', 20, 950.00, '2027-04-30'),
  (20, 'Dermacalm', 'Hidrocortisona', 'Pomada', 70, 260.00, '2027-10-31');

-- consulta: 30 registos
INSERT INTO consulta (id_consulta, data_hora, motivo, diagnostico, estado, id_animal, id_veterinario) VALUES
  (1, '2026-06-03 09:00:00', 'Vacinação anual', 'Animal saudável, vacinação em dia', 'realizada', 1, 1),
  (2, '2026-06-05 10:30:00', 'Perda de apetite e vómitos', 'Gastrite aguda', 'realizada', 4, 20),
  (3, '2026-06-10 08:30:00', 'Dificuldade em apoiar a pata traseira', 'Entorse ligeira do joelho', 'realizada', 2, 10),
  (4, '2026-06-12 14:00:00', 'Ferida profunda na pata dianteira', 'Laceração com início de infecção', 'realizada', 5, 5),
  (5, '2026-06-17 09:15:00', 'Comichão intensa e queda de pelo', 'Dermatite alérgica', 'realizada', 3, 4),
  (6, '2026-06-20 11:00:00', 'Vacinação e desparasitação', 'Animal saudável', 'realizada', 8, 20),
  (7, '2026-06-24 15:30:00', 'Dentes incisivos demasiado compridos', 'Sobrecrescimento dentário', 'realizada', 10, 7),
  (8, '2026-07-01 09:00:00', 'Castração', 'Procedimento sem complicações', 'realizada', 9, 2),
  (9, '2026-07-03 10:00:00', 'Diarreia há três dias', 'Parasitose gastrointestinal', 'realizada', 14, 6),
  (10, '2026-07-08 08:00:00', 'Inquietação e sinais de cólica', 'Cólica ligeira', 'realizada', 12, 6),
  (11, '2026-07-10 13:30:00', 'Vacinação e desparasitação', 'Animal saudável', 'realizada', 13, 6),
  (12, '2026-07-15 09:30:00', 'Letargia e mucosas pálidas', 'Anemia ligeira', 'realizada', 6, 3),
  (13, '2026-07-22 11:15:00', 'Olho esquerdo vermelho e com secreção', 'Conjuntivite bacteriana', 'realizada', 7, 8),
  (14, '2026-07-29 16:00:00', 'Penas arrepiadas e espirros', 'Infecção respiratória', 'realizada', 15, 7),
  (15, '2026-08-04 09:45:00', 'Carapaça amolecida', 'Deficiência nutricional de cálcio', 'realizada', 16, 7),
  (16, '2026-08-07 10:20:00', 'Mau hálito e gengivas inflamadas', 'Tártaro dentário grau 2', 'realizada', 19, 9),
  (17, '2026-08-12 14:45:00', 'Claudicação do membro anterior', 'Tendinite', 'realizada', 20, 6),
  (18, '2026-08-19 08:40:00', 'Dificuldade em levantar-se', 'Suspeita de displasia da anca', 'realizada', 25, 10),
  (19, '2026-08-26 09:10:00', 'Colocação de microchip', 'Sem alterações', 'realizada', 23, 20),
  (20, '2026-09-02 10:00:00', 'Esterilização', 'Procedimento sem complicações', 'realizada', 24, 2),
  (21, '2026-09-09 11:30:00', 'Esterilização', 'Procedimento sem complicações', 'realizada', 26, 2),
  (22, '2026-09-16 15:00:00', 'Perda de peso', 'Parasitose gastrointestinal', 'realizada', 21, 6),
  (23, '2026-09-23 09:00:00', 'Feridas na pele', 'Dermatite por fricção', 'realizada', 17, 7),
  (24, '2026-10-06 10:30:00', 'Febre e prostração', 'Suspeita de erliquiose', 'realizada', 1, 3),
  (25, '2026-10-14 09:00:00', 'Vacinação anual', NULL, 'agendada', 2, 1),
  (26, '2026-10-15 10:30:00', 'Revisão da ferida', NULL, 'agendada', 5, 5),
  (27, '2026-10-16 14:00:00', 'Consulta de rotina', NULL, 'agendada', 22, 7),
  (28, '2026-10-19 09:30:00', 'Vacinação', NULL, 'agendada', 18, 7),
  (29, '2026-10-07 11:00:00', 'Consulta de rotina', NULL, 'cancelada', 9, 1),
  (30, '2026-10-09 15:30:00', 'Controlo de peso', NULL, 'cancelada', 11, 7);

-- consulta_servico: 47 registos
INSERT INTO consulta_servico (id_consulta, id_servico, quantidade, preco_aplicado) VALUES
  (1, 4, 1, 800.00),
  (1, 3, 1, 450.00),
  (2, 1, 1, 450.00),
  (2, 12, 1, 1200.00),
  (3, 1, 1, 450.00),
  (3, 11, 1, 1800.00),
  (4, 2, 1, 1200.00),
  (4, 15, 1, 1500.00),
  (5, 1, 1, 450.00),
  (5, 7, 1, 350.00),
  (6, 5, 1, 750.00),
  (6, 6, 1, 300.00),
  (7, 1, 1, 450.00),
  (7, 12, 1, 1200.00),
  (8, 1, 1, 500.00),
  (8, 9, 1, 3000.00),
  (9, 19, 1, 1800.00),
  (9, 6, 1, 300.00),
  (10, 2, 1, 1200.00),
  (10, 19, 1, 1800.00),
  (11, 3, 1, 450.00),
  (11, 6, 1, 300.00),
  (12, 1, 1, 500.00),
  (12, 12, 1, 1200.00),
  (12, 10, 1, 1500.00),
  (13, 1, 1, 500.00),
  (14, 1, 1, 500.00),
  (14, 11, 1, 1800.00),
  (15, 1, 1, 500.00),
  (15, 11, 1, 1800.00),
  (16, 1, 1, 500.00),
  (16, 13, 1, 2500.00),
  (17, 19, 1, 1800.00),
  (17, 10, 1, 1500.00),
  (18, 1, 1, 500.00),
  (18, 11, 2, 1800.00),
  (19, 17, 1, 900.00),
  (19, 3, 1, 450.00),
  (20, 8, 1, 4500.00),
  (20, 16, 2, 1000.00),
  (21, 8, 1, 4500.00),
  (21, 16, 1, 1000.00),
  (22, 1, 1, 500.00),
  (22, 6, 1, 300.00),
  (23, 1, 1, 500.00),
  (24, 2, 1, 1200.00),
  (24, 12, 1, 1200.00);

-- item_receita: 23 registos
INSERT INTO item_receita (id_consulta, num_item, id_medicamento, posologia, duracao_dias) VALUES
  (2, 1, 10, '1 cápsula por dia, em jejum', 7),
  (3, 1, 2, '1 dose por dia, com a refeição', 5),
  (4, 1, 7, '1 cápsula de 12 em 12 horas', 8),
  (4, 2, 14, 'Aplicar sobre a ferida 2 vezes ao dia', 10),
  (5, 1, 11, '1 comprimido por dia', 10),
  (5, 2, 4, '1 comprimido por dia, de manhã', 5),
  (7, 1, 17, '1 dose por semana', 21),
  (8, 1, 13, '1 comprimido por dia, com comida', 5),
  (9, 1, 18, '1 dose única, repetir ao fim de 14 dias', 14),
  (10, 1, 16, 'Fluidoterapia durante a observação', 1),
  (12, 1, 17, '1 dose por semana', 28),
  (13, 1, 15, '1 gota em cada olho, 3 vezes ao dia', 7),
  (14, 1, 12, '1 comprimido por dia', 7),
  (16, 1, 1, '1 comprimido de 12 em 12 horas', 7),
  (17, 1, 2, '1 dose por dia, com a refeição', 7),
  (18, 1, 13, '1 comprimido por dia, com comida', 14),
  (20, 1, 2, '1 dose por dia, com a refeição', 5),
  (20, 2, 1, '1 comprimido de 12 em 12 horas', 7),
  (21, 1, 1, '1 comprimido de 12 em 12 horas', 7),
  (22, 1, 18, '1 dose única, repetir ao fim de 14 dias', 14),
  (23, 1, 14, 'Aplicar na pele afectada 2 vezes ao dia', 10),
  (24, 1, 6, '1 comprimido de 12 em 12 horas', 21),
  (24, 2, 10, '1 cápsula por dia, em jejum', 14);

-- fatura: 24 registos
INSERT INTO fatura (id_fatura, numero, id_consulta, data_emissao, total_mzn, metodo_pagamento, estado) VALUES
  (1, 'FT-2026/0001', 1, '2026-06-03', 1250.00, 'M-Pesa', 'paga'),
  (2, 'FT-2026/0002', 2, '2026-06-05', 1650.00, 'e-Mola', 'paga'),
  (3, 'FT-2026/0003', 3, '2026-06-10', 2250.00, 'Cartão', 'paga'),
  (4, 'FT-2026/0004', 4, '2026-06-12', 2700.00, 'Numerário', 'paga'),
  (5, 'FT-2026/0005', 5, '2026-06-17', 800.00, 'M-Pesa', 'paga'),
  (6, 'FT-2026/0006', 6, '2026-06-20', 1050.00, 'e-Mola', 'paga'),
  (7, 'FT-2026/0007', 7, '2026-06-24', 1650.00, 'Cartão', 'paga'),
  (8, 'FT-2026/0008', 8, '2026-07-01', 3500.00, 'Numerário', 'paga'),
  (9, 'FT-2026/0009', 9, '2026-07-03', 2100.00, 'M-Pesa', 'paga'),
  (10, 'FT-2026/0010', 10, '2026-07-08', 3000.00, 'e-Mola', 'paga'),
  (11, 'FT-2026/0011', 11, '2026-07-10', 750.00, 'Cartão', 'paga'),
  (12, 'FT-2026/0012', 12, '2026-07-15', 3200.00, 'Numerário', 'paga'),
  (13, 'FT-2026/0013', 13, '2026-07-22', 500.00, 'M-Pesa', 'paga'),
  (14, 'FT-2026/0014', 14, '2026-07-29', 2300.00, 'e-Mola', 'paga'),
  (15, 'FT-2026/0015', 15, '2026-08-04', 2300.00, 'Cartão', 'paga'),
  (16, 'FT-2026/0016', 16, '2026-08-07', 3000.00, 'Numerário', 'paga'),
  (17, 'FT-2026/0017', 17, '2026-08-12', 3300.00, 'M-Pesa', 'paga'),
  (18, 'FT-2026/0018', 18, '2026-08-19', 4100.00, NULL, 'pendente'),
  (19, 'FT-2026/0019', 19, '2026-08-26', 1350.00, 'Cartão', 'paga'),
  (20, 'FT-2026/0020', 20, '2026-09-02', 6500.00, 'Numerário', 'paga'),
  (21, 'FT-2026/0021', 21, '2026-09-09', 5500.00, 'M-Pesa', 'paga'),
  (22, 'FT-2026/0022', 22, '2026-09-16', 800.00, NULL, 'pendente'),
  (23, 'FT-2026/0023', 23, '2026-09-23', 500.00, NULL, 'pendente'),
  (24, 'FT-2026/0024', 24, '2026-10-06', 2400.00, NULL, 'pendente');

-- Verificação rápida: número de registos por tabela
SELECT 'utilizador' AS tabela, COUNT(*) AS registos FROM utilizador
UNION ALL SELECT 'veterinario', COUNT(*) FROM veterinario
UNION ALL SELECT 'proprietario', COUNT(*) FROM proprietario
UNION ALL SELECT 'especie', COUNT(*) FROM especie
UNION ALL SELECT 'raca', COUNT(*) FROM raca
UNION ALL SELECT 'animal', COUNT(*) FROM animal
UNION ALL SELECT 'servico', COUNT(*) FROM servico
UNION ALL SELECT 'medicamento', COUNT(*) FROM medicamento
UNION ALL SELECT 'consulta', COUNT(*) FROM consulta
UNION ALL SELECT 'consulta_servico', COUNT(*) FROM consulta_servico
UNION ALL SELECT 'item_receita', COUNT(*) FROM item_receita
UNION ALL SELECT 'fatura', COUNT(*) FROM fatura;
