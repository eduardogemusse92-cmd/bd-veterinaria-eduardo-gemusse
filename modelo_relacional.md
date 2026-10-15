# Modelo relacional — VetCare (Clínica Veterinária)

Projecto de Base de Dados · Tecnologias de Base de Dados · Universidade Licungo  
Autor: Eduardo Luís Gemusse

> Notação: **negrito** = chave primária (PK); *itálico* = chave estrangeira (FK); `UQ` = valor único.

## 1. Relações (tabelas), chaves primárias e estrangeiras

- **utilizador**(**id_utilizador**, nome_completo, email, palavra_passe, perfil, ativo, data_criacao)
- **veterinario**(**id_veterinario**, *id_utilizador*, n_cedula, especialidade, telefone)
- **proprietario**(**id_proprietario**, nome_completo, bi, telefone, email, endereco, bairro, cidade)
- **especie**(**id_especie**, nome_comum, grupo)
- **raca**(**id_raca**, *id_especie*, nome)
- **animal**(**id_animal**, nome, sexo, data_nascimento, peso_kg, cor, microchip, *id_proprietario*, *id_raca*)
- **servico**(**id_servico**, nome, descricao, preco_mzn)
- **medicamento**(**id_medicamento**, nome_comercial, principio_ativo, forma, stock_unidades, preco_unitario, validade)
- **consulta**(**id_consulta**, data_hora, motivo, diagnostico, estado, *id_animal*, *id_veterinario*)
- **consulta_servico**(**id_consulta** *(FK)*, **id_servico** *(FK)*, quantidade, preco_aplicado)
- **item_receita**(**id_consulta** *(FK)*, **num_item**, *id_medicamento*, posologia, duracao_dias)
- **fatura**(**id_fatura**, numero, *id_consulta*, data_emissao, total_mzn, metodo_pagamento, estado)

### Chaves estrangeiras

| Tabela (filha) | FK | Referencia (pai) | ON DELETE | Significado |
|---|---|---|---|---|
| veterinario | id_utilizador | utilizador(id_utilizador) | RESTRICT | cada veterinário tem uma (e só uma) conta de utilizador |
| raca | id_especie | especie(id_especie) | RESTRICT | cada raça pertence a uma espécie |
| animal | id_proprietario | proprietario(id_proprietario) | RESTRICT | cada animal tem um proprietário |
| animal | id_raca | raca(id_raca) | RESTRICT | cada animal tem uma raça |
| consulta | id_animal | animal(id_animal) | RESTRICT | a consulta é feita a um animal |
| consulta | id_veterinario | veterinario(id_veterinario) | RESTRICT | a consulta é feita por um veterinário |
| consulta_servico | id_consulta | consulta(id_consulta) | CASCADE | serviços prestados numa consulta |
| consulta_servico | id_servico | servico(id_servico) | RESTRICT | serviço do catálogo |
| item_receita | id_consulta | consulta(id_consulta) | CASCADE | a receita pertence a uma consulta (entidade fraca) |
| item_receita | id_medicamento | medicamento(id_medicamento) | RESTRICT | medicamento prescrito |
| fatura | id_consulta | consulta(id_consulta) | RESTRICT | cada fatura corresponde a uma consulta realizada |

`ON DELETE RESTRICT` impede apagar um registo “pai” que ainda tenha “filhos” (ex.: não se apaga um animal com consultas). `ON DELETE CASCADE` apaga também os dependentes (ao apagar uma consulta, apagam-se as suas linhas de serviços e de receita).

## 2. Passagem do diagrama ER ao modelo relacional

| Relacionamento | Cardinalidade | Participação | Como foi convertido |
|---|---|---|---|
| especie — agrupa — raca | 1:N | especie (0,N) · raca (1,1) total | FK `raca.id_especie` |
| raca — classifica — animal | 1:N | raca (0,N) · animal (1,1) total | FK `animal.id_raca` |
| animal — pertence a — proprietario | N:1 | animal (1,1) total · proprietario (0,N) | FK `animal.id_proprietario` |
| animal — tem — consulta | 1:N | animal (0,N) · consulta (1,1) total | FK `consulta.id_animal` |
| veterinario — atende — consulta | 1:N | veterinario (0,N) · consulta (1,1) total | FK `consulta.id_veterinario` |
| utilizador — tem conta — veterinario | 1:1 | utilizador (0,1) · veterinario (1,1) total | FK `veterinario.id_utilizador` com UNIQUE |
| consulta — inclui — servico | N:M | consulta (0,N) · servico (0,N) | tabela associativa `consulta_servico` (PK composta) + atributos `quantidade`, `preco_aplicado` |
| consulta — prescreve — item_receita | 1:N identificadora | consulta (0,N) · item_receita (1,1) total | entidade fraca: PK composta (`id_consulta`, `num_item`); `id_consulta` é também FK |
| item_receita — refere-se a — medicamento | N:1 | item_receita (1,1) total · medicamento (0,N) | FK `item_receita.id_medicamento` |
| consulta — gera — fatura | 1:1 | consulta (0,1) · fatura (1,1) total | FK `fatura.id_consulta` com UNIQUE |

**Entidade fraca:** `item_receita` não existe sem a sua consulta e só se distingue dentro dela pelo número da linha (`num_item`). Por isso a sua chave primária é composta por `id_consulta` (chave da entidade forte) + `num_item` (chave parcial).

## 3. Dicionário de dados

### utilizador
Contas de acesso ao sistema (administrador, veterinário, recepcionista).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_utilizador | INT | PK; AUTO_INCREMENT |
| nome_completo | VARCHAR(100) | NOT NULL |
| email | VARCHAR(100) | NOT NULL; UNIQUE |
| palavra_passe | CHAR(64) | NOT NULL |
| perfil | ENUM('administrador','veterinario','recepcionista') | NOT NULL |
| ativo | BOOLEAN | NOT NULL; DEFAULT TRUE |
| data_criacao | DATETIME | NOT NULL; DEFAULT CURRENT_TIMESTAMP |

### veterinario
Dados profissionais dos médicos veterinários (1:1 com utilizador).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_veterinario | INT | PK; AUTO_INCREMENT |
| id_utilizador | INT | NOT NULL; UNIQUE; FK → utilizador.id_utilizador (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| n_cedula | VARCHAR(20) | NOT NULL; UNIQUE |
| especialidade | VARCHAR(60) | NOT NULL |
| telefone | VARCHAR(20) | NOT NULL |

### proprietario
Donos dos animais (clientes da clínica).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_proprietario | INT | PK; AUTO_INCREMENT |
| nome_completo | VARCHAR(100) | NOT NULL |
| bi | VARCHAR(20) | NOT NULL; UNIQUE |
| telefone | VARCHAR(20) | NOT NULL |
| email | VARCHAR(100) | NULL permitido |
| endereco | VARCHAR(150) | NOT NULL |
| bairro | VARCHAR(60) | NOT NULL |
| cidade | VARCHAR(60) | NOT NULL |

### especie
Espécies animais atendidas na clínica.

| Atributo | Tipo | Restrições |
|---|---|---|
| id_especie | INT | PK; AUTO_INCREMENT |
| nome_comum | VARCHAR(50) | NOT NULL; UNIQUE |
| grupo | ENUM('Mamífero','Ave','Réptil') | NOT NULL |

### raca
Raças de cada espécie (inclui 'Sem raça definida').

| Atributo | Tipo | Restrições |
|---|---|---|
| id_raca | INT | PK; AUTO_INCREMENT |
| id_especie | INT | NOT NULL; FK → especie.id_especie (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| nome | VARCHAR(60) | NOT NULL |

Restrição adicional `uq_raca_especie_nome`: UNIQUE (id_especie, nome)

### animal
Animais registados na clínica.

| Atributo | Tipo | Restrições |
|---|---|---|
| id_animal | INT | PK; AUTO_INCREMENT |
| nome | VARCHAR(50) | NOT NULL |
| sexo | ENUM('M','F') | NOT NULL |
| data_nascimento | DATE | NOT NULL |
| peso_kg | DECIMAL(6,2) | NOT NULL; CHECK (peso_kg > 0) |
| cor | VARCHAR(40) | NOT NULL |
| microchip | VARCHAR(20) | NULL permitido; UNIQUE |
| id_proprietario | INT | NOT NULL; FK → proprietario.id_proprietario (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| id_raca | INT | NOT NULL; FK → raca.id_raca (ON DELETE RESTRICT, ON UPDATE CASCADE) |

### servico
Catálogo de serviços prestados (consultas, vacinas, cirurgias, ...).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_servico | INT | PK; AUTO_INCREMENT |
| nome | VARCHAR(80) | NOT NULL; UNIQUE |
| descricao | VARCHAR(200) | NOT NULL |
| preco_mzn | DECIMAL(10,2) | NOT NULL; CHECK (preco_mzn >= 0) |

### medicamento
Medicamentos em stock na farmácia da clínica.

| Atributo | Tipo | Restrições |
|---|---|---|
| id_medicamento | INT | PK; AUTO_INCREMENT |
| nome_comercial | VARCHAR(80) | NOT NULL; UNIQUE |
| principio_ativo | VARCHAR(100) | NOT NULL |
| forma | VARCHAR(40) | NOT NULL |
| stock_unidades | INT | NOT NULL; DEFAULT 0; CHECK (stock_unidades >= 0) |
| preco_unitario | DECIMAL(10,2) | NOT NULL; CHECK (preco_unitario >= 0) |
| validade | DATE | NOT NULL |

### consulta
Consultas (agendadas, realizadas ou canceladas) de um animal com um veterinário.

| Atributo | Tipo | Restrições |
|---|---|---|
| id_consulta | INT | PK; AUTO_INCREMENT |
| data_hora | DATETIME | NOT NULL |
| motivo | VARCHAR(150) | NOT NULL |
| diagnostico | VARCHAR(250) | NULL permitido |
| estado | ENUM('agendada','realizada','cancelada') | NOT NULL; DEFAULT 'agendada' |
| id_animal | INT | NOT NULL; FK → animal.id_animal (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| id_veterinario | INT | NOT NULL; FK → veterinario.id_veterinario (ON DELETE RESTRICT, ON UPDATE CASCADE) |

Restrição adicional `uq_consulta_vet_data`: UNIQUE (id_veterinario, data_hora)

### consulta_servico
Tabela associativa N:M entre consulta e serviço (com quantidade e preço aplicado).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_consulta | INT | PK; FK → consulta.id_consulta (ON DELETE CASCADE, ON UPDATE CASCADE) |
| id_servico | INT | PK; FK → servico.id_servico (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| quantidade | INT | NOT NULL; DEFAULT 1; CHECK (quantidade > 0) |
| preco_aplicado | DECIMAL(10,2) | NOT NULL; CHECK (preco_aplicado >= 0) |

### item_receita
ENTIDADE FRACA: linhas da receita de uma consulta (identificada por id_consulta + num_item).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_consulta | INT | PK; FK → consulta.id_consulta (ON DELETE CASCADE, ON UPDATE CASCADE) |
| num_item | INT | PK; CHECK (num_item > 0) |
| id_medicamento | INT | NOT NULL; FK → medicamento.id_medicamento (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| posologia | VARCHAR(150) | NOT NULL |
| duracao_dias | INT | NOT NULL; CHECK (duracao_dias > 0) |

### fatura
Fatura emitida por cada consulta realizada (relação 1:1).

| Atributo | Tipo | Restrições |
|---|---|---|
| id_fatura | INT | PK; AUTO_INCREMENT |
| numero | VARCHAR(20) | NOT NULL; UNIQUE |
| id_consulta | INT | NOT NULL; UNIQUE; FK → consulta.id_consulta (ON DELETE RESTRICT, ON UPDATE CASCADE) |
| data_emissao | DATE | NOT NULL |
| total_mzn | DECIMAL(10,2) | NOT NULL; CHECK (total_mzn >= 0) |
| metodo_pagamento | ENUM('Numerário','M-Pesa','e-Mola','Cartão') | NULL permitido |
| estado | ENUM('pendente','paga') | NOT NULL; DEFAULT 'pendente' |

## 4. Normalização

- **1FN:** todos os atributos são atómicos (não há listas dentro de uma coluna); os serviços de uma consulta e as linhas de receita estão em tabelas próprias.
- **2FN:** em `consulta_servico` e `item_receita` (chaves compostas) todos os atributos dependem da chave inteira (ex.: `quantidade` depende de consulta + serviço).
- **3FN:** não há dependências transitivas: o nome do veterinário está em `utilizador`, a espécie está em `especie` (e não repetida em `animal`), o preço actual está em `servico`.
- `consulta_servico.preco_aplicado` e `fatura.total_mzn` guardam valores históricos de propósito: o preço de um serviço pode mudar, mas a fatura antiga não pode mudar.
