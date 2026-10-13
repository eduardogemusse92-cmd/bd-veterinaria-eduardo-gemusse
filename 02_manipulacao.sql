-- =====================================================================
-- Projecto de Base de Dados: VetCare (Clínica Veterinária)
-- Autor: Eduardo Luís Gemusse | Tecnologias de Base de Dados | Universidade Licungo
-- Ficheiro 2/2: ETAPA 3 - Manipulação dos dados
-- Pré-requisito: executar primeiro 01_criacao_e_insercao.sql
-- Nota: o último comando (teste de integridade) FALHA DE PROPÓSITO.
--       Execute-o em separado (ou com "mysql --force") para ver a mensagem de erro.
-- =====================================================================

USE vetcare;

-- =====================================================================
-- 1. SELECT SIMPLES (3) - com WHERE e ORDER BY
-- =====================================================================

-- 1.1 Animais com mais de 30 kg, do mais pesado para o mais leve.
SELECT id_animal, nome, sexo, peso_kg
FROM animal
WHERE peso_kg > 30
ORDER BY peso_kg DESC;

-- 1.2 Proprietários que moram na Matola, por ordem alfabética.
SELECT nome_completo, telefone, bairro
FROM proprietario
WHERE cidade = 'Matola'
ORDER BY nome_completo ASC;

-- 1.3 Medicamentos com stock baixo (menos de 50 unidades), do mais crítico ao menos crítico.
SELECT nome_comercial, forma, stock_unidades, validade
FROM medicamento
WHERE stock_unidades < 50
ORDER BY stock_unidades ASC;

-- =====================================================================
-- 2. SELECT COM JOIN (3) - informação completa a partir de várias tabelas
-- =====================================================================

-- 2.1 Consultas realizadas desde 1 de Setembro de 2026, com animal, espécie,
--     proprietário e veterinário (junta 6 tabelas).
SELECT c.id_consulta,
       c.data_hora,
       a.nome            AS animal,
       e.nome_comum      AS especie,
       p.nome_completo   AS proprietario,
       u.nome_completo   AS veterinario,
       c.diagnostico
FROM consulta c
JOIN animal       a ON a.id_animal       = c.id_animal
JOIN raca         r ON r.id_raca         = a.id_raca
JOIN especie      e ON e.id_especie      = r.id_especie
JOIN proprietario p ON p.id_proprietario = a.id_proprietario
JOIN veterinario  v ON v.id_veterinario  = c.id_veterinario
JOIN utilizador   u ON u.id_utilizador   = v.id_utilizador
WHERE c.estado = 'realizada'
  AND c.data_hora >= '2026-09-01 00:00:00'
ORDER BY c.data_hora;

-- 2.2 Faturas pendentes, com o cliente a contactar (do maior para o menor valor).
SELECT f.numero,
       f.data_emissao,
       f.total_mzn,
       a.nome            AS animal,
       p.nome_completo   AS proprietario,
       p.telefone
FROM fatura f
JOIN consulta     c ON c.id_consulta     = f.id_consulta
JOIN animal       a ON a.id_animal       = c.id_animal
JOIN proprietario p ON p.id_proprietario = a.id_proprietario
WHERE f.estado = 'pendente'
ORDER BY f.total_mzn DESC;

-- 2.3 Receitas das consultas de Setembro e Outubro: cada linha da receita
--     (entidade fraca) com o medicamento e o animal tratado.
SELECT i.id_consulta,
       i.num_item,
       a.nome            AS animal,
       m.nome_comercial  AS medicamento,
       i.posologia,
       i.duracao_dias
FROM item_receita i
JOIN medicamento m ON m.id_medicamento = i.id_medicamento
JOIN consulta    c ON c.id_consulta    = i.id_consulta
JOIN animal      a ON a.id_animal      = c.id_animal
WHERE c.data_hora >= '2026-09-01 00:00:00'
ORDER BY i.id_consulta, i.num_item;

-- 2.4 (EXTRA) Faturação por veterinário (JOIN + GROUP BY).
SELECT u.nome_completo AS veterinario,
       COUNT(f.id_fatura) AS faturas,
       SUM(f.total_mzn)   AS total_faturado_mzn
FROM fatura f
JOIN consulta    c ON c.id_consulta    = f.id_consulta
JOIN veterinario v ON v.id_veterinario = c.id_veterinario
JOIN utilizador  u ON u.id_utilizador  = v.id_utilizador
GROUP BY u.nome_completo
ORDER BY total_faturado_mzn DESC;

-- =====================================================================
-- 3. UPDATE (3)
-- =====================================================================

-- 3.1 Reagendar a consulta 26 (revisão da ferida do Thor) para o dia 17/10 às 11:00.
UPDATE consulta
SET data_hora = '2026-10-17 11:00:00'
WHERE id_consulta = 26;
SELECT id_consulta, data_hora, motivo, estado FROM consulta WHERE id_consulta = 26;

-- 3.2 O cliente da fatura FT-2026/0024 pagou por M-Pesa: marcar como paga.
UPDATE fatura
SET estado = 'paga', metodo_pagamento = 'M-Pesa'
WHERE numero = 'FT-2026/0024';
SELECT numero, total_mzn, estado, metodo_pagamento FROM fatura WHERE numero = 'FT-2026/0024';

-- 3.3 Dar baixa de 10 unidades no stock do Omeprazvet (medicamento 10) após dispensa.
UPDATE medicamento
SET stock_unidades = stock_unidades - 10
WHERE id_medicamento = 10;
SELECT id_medicamento, nome_comercial, stock_unidades FROM medicamento WHERE id_medicamento = 10;

-- =====================================================================
-- 4. DELETE (1) - respeitando as chaves estrangeiras
-- =====================================================================

-- A consulta 29 está CANCELADA: não tem fatura (RESTRICT), pelo que pode ser eliminada.
-- Se tivesse linhas em consulta_servico ou item_receita, seriam apagadas automaticamente
-- (ON DELETE CASCADE). Eliminar uma consulta que já tem fatura seria impedido.
SELECT COUNT(*) AS consultas_antes FROM consulta;
DELETE FROM consulta
WHERE id_consulta = 29 AND estado = 'cancelada';
SELECT COUNT(*) AS consultas_depois FROM consulta;

-- =====================================================================
-- 5. TESTE DE INTEGRIDADE (1) - FALHA DE PROPÓSITO
-- =====================================================================
-- Tentativa de registar uma consulta para o animal 999, que NÃO existe.
-- Resultado esperado: o MySQL recusa o INSERT com o erro
--   ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
--   (`vetcare`.`consulta`, CONSTRAINT `fk_consulta_animal` FOREIGN KEY (`id_animal`)
--    REFERENCES `animal` (`id_animal`) ON UPDATE CASCADE)
-- Explicação: consulta.id_animal é chave estrangeira de animal.id_animal. Como não existe
-- nenhum animal com id 999, a integridade referencial é violada e a BD protege-se,
-- evitando uma consulta "órfã" (sem animal).
INSERT INTO consulta (id_consulta, data_hora, motivo, estado, id_animal, id_veterinario)
VALUES (31, '2026-10-21 09:00:00', 'Teste de integridade referencial', 'agendada', 999, 1);
