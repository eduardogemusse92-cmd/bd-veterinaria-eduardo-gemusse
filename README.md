# VetCare — Base de Dados de uma Clínica Veterinária

**Autor:** Eduardo Luís Gemusse  
**Curso:** Licenciatura em Informática, 2º ano — Universidade Licungo (Moçambique)  
**Disciplina:** Tecnologias de Base de Dados — Trabalho II (Projecto de uma Base de Dados)  
**Tema:** gestão de uma clínica veterinária (proprietários, animais, consultas, serviços, receitas e faturação)  
**SGBD:** MySQL 8.0+ (compatível com MariaDB 10.5+)  
**Vídeo de apresentação (YouTube):** _[colar aqui o link do vídeo]_

---

## 1. Descrição do problema

Numa clínica veterinária, o trabalho diário gira à volta de animais e dos seus donos. Quando um cliente chega, a recepcionista precisa de saber se o proprietário e o animal já estão registados; se não estiverem, regista-os (nome, BI, contacto, morada, e do animal: nome, espécie, raça, sexo, data de nascimento, peso, microchip). Hoje, muitas clínicas guardam esta informação em cadernos ou folhas soltas, o que torna difícil encontrar o historial clínico de um animal, evitar marcações sobrepostas, saber que medicamentos ainda há em stock ou quanto cada cliente deve.

O sistema que se pretende informatizar resolve esses problemas. A recepcionista marca **consultas** para um animal com um veterinário numa data e hora; um veterinário não pode ter duas consultas à mesma hora. Durante a consulta, o veterinário regista o diagnóstico e os **serviços** prestados (consulta geral, vacina, raio-X, esterilização, etc.), cada um com a sua quantidade e o preço aplicado nesse dia. Se for necessário tratamento, emite uma **receita**, composta por várias linhas (medicamento, posologia e duração); essas linhas só existem dentro da consulta a que pertencem, por isso são uma **entidade fraca**. No fim, é emitida uma **fatura** por cada consulta realizada, cujo total é a soma dos serviços, e que pode ser paga em numerário, M-Pesa, e-Mola ou cartão, ou ficar pendente. A clínica mantém ainda o catálogo de **medicamentos** com stock e validade. O acesso ao sistema é feito por **utilizadores** com perfis diferentes (administrador, veterinário e recepcionista), e cada veterinário está ligado a uma conta de utilizador.

Com esta base de dados é possível consultar o historial de cada animal, listar as consultas do dia, controlar o stock, saber quais as faturas pendentes e medir a faturação por veterinário.

## 2. Regras de negócio

| N.º | Regra |
|---|---|
| RN01 | Cada utilizador tem um email único e um perfil: administrador, veterinário ou recepcionista. As palavras-passe são guardadas como hash, nunca em texto simples. |
| RN02 | Cada veterinário tem exactamente uma conta de utilizador (relação 1:1) e uma cédula profissional única. |
| RN03 | Um proprietário é identificado pelo BI (único) e pode ter vários animais. |
| RN04 | Cada animal pertence a um único proprietário e tem uma raça; cada raça pertence a uma espécie. |
| RN05 | Quando a raça é desconhecida, usa-se a raça “Sem raça definida” da respectiva espécie. |
| RN06 | O número de microchip, quando existe, é único por animal. O peso tem de ser maior que zero e o sexo é M ou F. |
| RN07 | Uma consulta é feita a um animal por um veterinário e tem um estado: agendada, realizada ou cancelada. O diagnóstico só é preenchido quando a consulta é realizada. |
| RN08 | Um veterinário não pode ter duas consultas na mesma data e hora (restrição UNIQUE). |
| RN09 | Numa consulta podem ser prestados vários serviços, cada um com quantidade (> 0) e o preço aplicado, guardado como histórico mesmo que o preço do serviço mude depois. |
| RN10 | Uma receita é formada por linhas numeradas (1, 2, 3, ...) dentro da consulta; cada linha refere um medicamento, a posologia e a duração em dias (> 0). A linha não existe sem a consulta (entidade fraca). |
| RN11 | Só as consultas realizadas são faturadas, com uma única fatura por consulta. O total é a soma de quantidade × preço aplicado dos serviços (em MZN). |
| RN12 | Uma fatura está pendente ou paga; o método de pagamento (numerário, M-Pesa, e-Mola ou cartão) só é preenchido quando a fatura é paga. |
| RN13 | O stock de medicamentos nunca pode ser negativo e cada medicamento tem prazo de validade. |
| RN14 | Não se pode apagar um animal, veterinário, serviço ou medicamento que já tenha histórico (RESTRICT). Ao apagar uma consulta sem fatura, apagam-se também os seus serviços e as linhas da receita (CASCADE). |

## 3. Diagrama Entidade-Relacionamento

![Diagrama ER](diagrama_er.png)

São 12 entidades/tabelas, com 1 entidade fraca (`item_receita`), 1 relacionamento N:M (consulta–serviço, que origina a tabela associativa `consulta_servico`) e 1 relacionamento 1:1 (utilizador–veterinário, e consulta–fatura). A participação e a cardinalidade estão indicadas em notação (mín,máx) junto a cada entidade; a linha dupla indica participação total.

## 4. Modelo relacional

O modelo completo (relações, chaves primárias e estrangeiras, regras de conversão, dicionário de dados e normalização) está em [`modelo_relacional.md`](modelo_relacional.md).

Resumo (**PK** em negrito, *FK* em itálico):

- utilizador(**id_utilizador**, nome_completo, email, palavra_passe, perfil, ativo, data_criacao)
- veterinario(**id_veterinario**, *id_utilizador*, n_cedula, especialidade, telefone)
- proprietario(**id_proprietario**, nome_completo, bi, telefone, email, endereco, bairro, cidade)
- especie(**id_especie**, nome_comum, grupo)
- raca(**id_raca**, *id_especie*, nome)
- animal(**id_animal**, nome, sexo, data_nascimento, peso_kg, cor, microchip, *id_proprietario*, *id_raca*)
- servico(**id_servico**, nome, descricao, preco_mzn)
- medicamento(**id_medicamento**, nome_comercial, principio_ativo, forma, stock_unidades, preco_unitario, validade)
- consulta(**id_consulta**, data_hora, motivo, diagnostico, estado, *id_animal*, *id_veterinario*)
- consulta_servico(**id_consulta**, **id_servico**, quantidade, preco_aplicado)
- item_receita(**id_consulta**, **num_item**, *id_medicamento*, posologia, duracao_dias)
- fatura(**id_fatura**, numero, *id_consulta*, data_emissao, total_mzn, metodo_pagamento, estado)

## 5. Sistema web previsto (Programação Web)

Sobre esta mesma base de dados será desenvolvido o sistema web **VetCare**, com início de sessão e três perfis:

- **Recepcionista:** registar, listar, pesquisar e alterar proprietários e animais; marcar, reagendar e cancelar consultas; emitir e marcar faturas como pagas.
- **Veterinário:** ver a sua agenda do dia, registar diagnóstico e serviços prestados, e emitir receitas.
- **Administrador:** gerir utilizadores, serviços e preços, medicamentos e stock, e consultar relatórios (faturação por veterinário, faturas pendentes, medicamentos com stock baixo).

Formulários: registo de proprietário, de animal, de consulta, de serviços e de receita. Listagens e pesquisas: animais por nome ou proprietário, consultas por data ou veterinário, historial clínico de um animal, faturas pendentes.

## 6. Conteúdo do repositório

```
bd-veterinaria-eduardo-gemusse/
 README.md                    (este ficheiro)
 diagrama_er.png              (diagrama Entidade-Relacionamento)
 modelo_relacional.md         (modelo relacional e dicionário de dados)
 01_criacao_e_insercao.sql    (cria a BD vetcare, as tabelas e insere os dados)
 02_manipulacao.sql           (SELECT, JOIN, UPDATE, DELETE e teste de integridade)
```

## 7. Como executar

1. Instalar o MySQL 8.0+ (ou MariaDB 10.5+) e abrir um cliente (linha de comandos ou MySQL Workbench).
2. Executar o script de criação e inserção (cria a base de dados `vetcare` de raiz):
   ```
   mysql -u root -p < 01_criacao_e_insercao.sql
   ```
3. Executar o script de manipulação (o último comando é o teste de integridade e **falha de propósito**):
   ```
   mysql -u root -p --force < 02_manipulacao.sql
   ```
   No MySQL Workbench, executar o último `INSERT` em separado para ver o erro 1452.

### Dados de demonstração

| Tabela | Registos | Tabela | Registos |
|---|---|---|---|
| utilizador | 25 | consulta | 30 |
| veterinario | 20 | consulta_servico | 47 |
| proprietario | 22 | item_receita | 23 |
| especie | 20 | servico | 20 |
| raca | 24 | medicamento | 20 |
| animal | 26 | fatura | 24 |

Todos os dados são fictícios. Palavras-passe de demonstração (guardadas como hash SHA-256): `Admin@2026`, `Recep@2026` e `Vet@2026`.

## 8. Comandos de manipulação (resumo)

| Tipo | Quantidade | Onde |
|---|---|---|
| SELECT simples (WHERE + ORDER BY) | 3 | 02_manipulacao.sql, secção 1 |
| SELECT com JOIN | 3 (+1 extra com GROUP BY) | secção 2 |
| UPDATE | 3 | secção 3 |
| DELETE | 1 (respeita as FK) | secção 4 |
| Teste de integridade (FK inexistente) | 1 | secção 5 |
