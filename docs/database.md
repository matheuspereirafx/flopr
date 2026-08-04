# Banco De Dados - Sistema De Torneios De Poker

Este documento descreve o banco de dados mostrado no diagrama.

O sistema e dividido em 8 partes principais:

1. usuarios;
2. clubes;
3. membros dos clubes;
4. torneios;
5. inscricoes dos jogadores;
6. niveis de blind;
7. relogio do torneio;
8. opcoes de cobranca e pagamentos.

---

## 1. Visao Geral Do Modelo

O banco foi pensado para um sistema onde:

- um usuario pode participar de clubes;
- as permissoes do usuario sao controladas pelo `role` em `club_memberships`;
- um clube pode ter varios torneios;
- um torneio tem jogadores inscritos;
- um torneio tem uma estrutura de blinds;
- um torneio tem um relogio persistido;
- um torneio pode ter cobrancas como buy-in, rebuy e add-on;
- cada pagamento fica associado a uma inscricao e a uma opcao de cobranca.

Fluxo principal:

```text
users
  -> club_memberships
  -> clubs
  -> tournaments
  -> tournament_registration
  -> registration_payments
```

Fluxo do relogio:

```text
tournaments
  -> blind_levels
  -> tournament_clock_states
```

---

## 2. Tabela `users`

Representa os usuarios do sistema.

Um usuario pode ser:

- jogador;
- membro de clube;
- admin de clube;
- participante inscrito em torneios.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do usuario |
| `name` | Nome do usuario |
| `email` | Email do usuario |

### Relacionamentos

| Relacionamento | Descricao |
|---|---|
| `users.id -> club_memberships.id_users` | Usuario participa de clubes |
| `users.id -> tournaments_registration.id_users` | Usuario se inscreve em torneios |

---

## 3. Tabela `clubs`

Representa um clube ou home game.

O clube agrupa torneios e membros.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do clube |
| `name` | Nome do clube |
| `description` | Descricao do clube |

### Relacionamentos

| Relacionamento | Descricao |
|---|---|
| `clubs.id -> club_memberships.id_clubs` | Clube possui membros |
| `clubs.id -> tournaments.id_clubs` | Clube possui torneios |

---

## 4. Tabela `club_memberships`

Representa o vinculo entre um usuario e um clube.

Ela existe porque um usuario pode participar de varios clubes, e um clube pode ter varios usuarios.

Essa tabela tambem centraliza permissoes. Nao existe uma tabela separada de staff do torneio. Quem pode criar, editar ou operar torneios e definido pelo `role` do usuario dentro do clube.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do vinculo |
| `id_clubs` | FK para `clubs.id` |
| `id_users` | FK para `users.id` |
| `role` | Papel do usuario dentro do clube |
| `status` | Status do membro dentro do clube |

### Possiveis valores de `role`

| Valor | Descricao |
|---|---|
| `owner` | Dono do clube |
| `admin` | Administrador do clube |
| `staff` | Pode ajudar na operacao dos torneios do clube |
| `member` | Membro/jogador comum |

### Possiveis valores de `status`

| Valor | Descricao |
|---|---|
| `active` | Membro ativo |
| `invited` | Membro convidado |
| `removed` | Membro removido do clube |

### Permissoes por `role`

| Role | Clube | Torneios |
|---|---|---|
| `owner` | Pode editar clube, membros, roles e configuracoes | Pode criar, editar, iniciar, pausar, finalizar e cancelar torneios |
| `admin` | Pode editar configuracoes do clube e gerenciar membros abaixo dele | Pode criar, editar e operar torneios |
| `staff` | Nao altera configuracoes sensiveis do clube | Pode operar check-in, pagamentos manuais, eliminacoes e relogio |
| `member` | Apenas visualiza/participa conforme regra do clube | Pode se inscrever e participar dos torneios |

### Exemplo

```text
Usuario Matheus e admin do clube Poker House.
Isso gera uma linha em club_memberships:

id_clubs = Poker House
id_users = Matheus
role = admin
```

### Ao criar um clube

Quando um usuario cria um clube, o sistema deve criar automaticamente uma linha em `club_memberships`.

Exemplo:

```text
clubs:
id = 1
name = Poker House

club_memberships:
id_clubs = 1
id_users = usuario que criou o clube
role = owner
status = active
```

Isso garante que o criador ja tenha permissao para configurar o clube e criar torneios.

---

## 5. Tabela `tournaments`

Representa um torneio criado dentro de um clube.

Cada torneio pertence a um clube.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do torneio |
| `id_clubs` | FK para `clubs.id` |
| `name` | Nome do torneio |
| `location` | Local onde o torneio acontece |
| `max_players` | Quantidade maxima de jogadores |
| `starts_at` | Data e hora de inicio do torneio |

### Relacionamentos

| Relacionamento | Descricao |
|---|---|
| `tournaments.id -> tournaments_registration.id_tournaments` | Torneio possui inscricoes |
| `tournaments.id -> blind_levels.id_tournaments` | Torneio possui niveis de blind |
| `tournaments.id -> tournament_clock_states.id_tournaments` | Torneio possui estado de relogio |
| `tournaments.id -> tournament_charge_options.id_tournaments` | Torneio possui opcoes de cobranca |

---

## 6. Tabela `tournaments_registration`

Representa a inscricao de um usuario em um torneio.

Cada linha representa um jogador inscrito em um torneio.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico da inscricao |
| `id_tournaments` | FK para `tournaments.id` |
| `id_users` | FK para `users.id` |
| `rsvp_status` | Resposta do jogador sobre participacao |
| `presence_status` | Status de presenca do jogador no torneio |
| `eliminated_at` | Data/hora em que o jogador foi eliminado |
| `finish_position` | Posicao final do jogador |

### Possiveis valores de `rsvp_status`

| Valor | Descricao |
|---|---|
| `pending` | Ainda nao respondeu |
| `confirmed` | Confirmou presenca |
| `declined` | Recusou participar |
| `cancelled` | Inscricao cancelada |

### Possiveis valores de `presence_status`

| Valor | Descricao |
|---|---|
| `not_arrived` | Jogador ainda nao chegou |
| `checked_in` | Jogador fez check-in |
| `playing` | Jogador esta ativo no torneio |
| `eliminated` | Jogador foi eliminado |
| `no_show` | Jogador nao apareceu |

### Regras importantes

- Um usuario nao deve ter duas inscricoes no mesmo torneio.
- `finish_position` so deve ser preenchido quando o jogador for eliminado ou quando o torneio finalizar.
- `eliminated_at` deve ser preenchido quando `presence_status = eliminated`.

---

## 7. Tabela `blind_levels`

Representa a estrutura de blinds do torneio.

Cada linha e um nivel.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do nivel |
| `id_tournaments` | FK para `tournaments.id` |
| `level` | Numero do nivel |
| `duration_minutes` | Duracao do nivel em minutos |
| `small_blind` | Valor do small blind |
| `big_blind` | Valor do big blind |
| `ante` | Valor do ante |

### Exemplo

| level | duration_minutes | small_blind | big_blind | ante |
|---:|---:|---:|---:|---:|
| 1 | 10 | 100 | 200 | 0 |
| 2 | 10 | 200 | 400 | 0 |
| 3 | 15 | 300 | 600 | 100 |

### Como o sistema usa essa tabela

O sistema sempre busca os niveis do torneio ordenando pelo campo `level`.

Exemplo:

```sql
SELECT *
FROM blind_levels
WHERE id_tournaments = 1
ORDER BY level ASC;
```

Quando o relogio inicia, ele pega o primeiro nivel.

Quando o tempo acaba, ele busca o proximo nivel:

```sql
SELECT *
FROM blind_levels
WHERE id_tournaments = 1
AND level > 1
ORDER BY level ASC
LIMIT 1;
```

---

## 8. Tabela `tournament_clock_states`

Representa o estado atual do relogio de um torneio.

Essa tabela nao guarda todos os niveis. Ela guarda somente em qual nivel o torneio esta agora e quanto tempo falta.

Os niveis ficam em `blind_levels`.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do estado do relogio |
| `id_tournaments` | FK para `tournaments.id` |
| `status` | Status atual do relogio |
| `current_blind_level_id` | FK para `blind_levels.id`, indicando o nivel atual |
| `remaining_seconds` | Tempo restante do nivel atual em segundos |
| `started_at` | Momento em que o nivel atual comecou ou foi retomado |
| `paused_at` | Momento em que o relogio foi pausado |

### Possiveis valores de `status`

| Valor | Descricao |
|---|---|
| `not_started` | Relogio ainda nao iniciou |
| `running` | Relogio esta rodando |
| `paused` | Relogio esta pausado |
| `finished` | Estrutura de blinds acabou ou torneio terminou |

### Como funciona o campo `current_blind_level_id`

O campo `current_blind_level_id` aponta para uma linha da tabela `blind_levels`.

Exemplo:

```text
tournament_clock_states.current_blind_level_id = 2
```

Isso significa:

```text
O nivel atual do torneio e o blind_levels.id = 2.
```

Entao o sistema busca essa linha em `blind_levels` para mostrar:

- numero do nivel;
- small blind;
- big blind;
- ante;
- duracao original do nivel.

### Passo a passo do relogio

#### 1. Antes de iniciar

```text
status = not_started
current_blind_level_id = null
remaining_seconds = 0
started_at = null
paused_at = null
```

#### 2. Ao iniciar

O sistema busca o primeiro nivel:

```sql
SELECT *
FROM blind_levels
WHERE id_tournaments = :tournament_id
ORDER BY level ASC
LIMIT 1;
```

Depois salva:

```text
status = running
current_blind_level_id = id do primeiro nivel
remaining_seconds = duration_minutes * 60
started_at = agora
paused_at = null
```

#### 3. Enquanto esta rodando

O tempo exibido pode ser calculado assim:

```text
tempo_passado = agora - started_at
tempo_restante = remaining_seconds - tempo_passado
```

#### 4. Ao pausar

O sistema calcula quanto tempo falta e salva:

```text
status = paused
remaining_seconds = tempo_restante_calculado
paused_at = agora
```

#### 5. Ao retomar

O sistema continua no mesmo nivel:

```text
status = running
started_at = agora
paused_at = null
remaining_seconds = tempo_que_estava_salvo
```

#### 6. Quando o tempo chega em zero

O sistema busca o proximo nivel:

```sql
SELECT *
FROM blind_levels
WHERE id_tournaments = :tournament_id
AND level > :level_atual
ORDER BY level ASC
LIMIT 1;
```

Se existir proximo nivel:

```text
current_blind_level_id = id do proximo nivel
remaining_seconds = duration_minutes * 60
started_at = agora
status = running
```

Se nao existir proximo nivel:

```text
status = finished
remaining_seconds = 0
```

---

## 9. Tabela `tournament_charge_options`

Representa as opcoes de cobranca de um torneio.

Exemplos:

- buy-in;
- rebuy;
- add-on;
- taxa extra;
- ajuste manual.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico da opcao de cobranca |
| `id_tournaments` | FK para `tournaments.id` |
| `kind` | Tipo da cobranca |
| `amount` | Valor em dinheiro |
| `chip_amount` | Quantidade de fichas recebidas nessa compra |
| `available_from_level_id` | Nivel a partir do qual essa cobranca esta disponivel |
| `available_until_level_id` | Nivel ate o qual essa cobranca esta disponivel |

### Possiveis valores de `kind`

| Valor | Descricao |
|---|---|
| `buy_in` | Entrada principal no torneio |
| `rebuy` | Recompra de fichas |
| `addon` | Compra adicional de fichas |
| `fee` | Taxa extra |
| `adjustment` | Ajuste manual |

### Exemplo

```text
Buy-in:
kind = buy_in
amount = 100
chip_amount = 20000

Rebuy disponivel ate o nivel 6:
kind = rebuy
amount = 100
chip_amount = 20000
available_until_level_id = blind_levels.id do nivel 6

Add-on disponivel no break:
kind = addon
amount = 150
chip_amount = 30000
available_from_level_id = blind_levels.id do nivel desejado
available_until_level_id = blind_levels.id do nivel desejado
```

### Relacionamentos

| Relacionamento | Descricao |
|---|---|
| `tournament_charge_options.id_tournaments -> tournaments.id` | Opcao pertence a um torneio |
| `tournament_charge_options.available_from_level_id -> blind_levels.id` | Inicio da disponibilidade |
| `tournament_charge_options.available_until_level_id -> blind_levels.id` | Fim da disponibilidade |

---

## 10. Tabela `registration_payments`

Representa os pagamentos feitos por uma inscricao.

Cada pagamento pertence a:

- uma inscricao;
- uma opcao de cobranca.

### Campos

| Campo | Descricao |
|---|---|
| `id` | Identificador unico do pagamento |
| `id_tournament_charge_options` | FK para `tournament_charge_options.id` |
| `id_tournaments_registration` | FK para `tournaments_registration.id` |
| `amount` | Valor pago |
| `status` | Status interno do pagamento |
| `provider` | Provedor do pagamento |
| `provider_payment_id` | ID do pagamento no provedor externo |
| `provider_status` | Status retornado pelo provedor externo |
| `payment_method` | Metodo de pagamento |
| `paid_at` | Data/hora em que o pagamento foi aprovado |

### Possiveis valores de `status`

| Valor | Descricao |
|---|---|
| `pending` | Pagamento criado, mas ainda nao pago |
| `paid` | Pagamento aprovado |
| `failed` | Pagamento falhou |
| `cancelled` | Pagamento cancelado |
| `refunded` | Pagamento estornado |

### Possiveis valores de `provider`

| Valor | Descricao |
|---|---|
| `manual` | Pagamento confirmado manualmente |
| `stripe` | Pagamento via Stripe |
| `mercado_pago` | Pagamento via Mercado Pago |
| `pix` | Pagamento via PIX direto/manual |

### Possiveis valores de `payment_method`

| Valor | Descricao |
|---|---|
| `pix` | PIX |
| `credit_card` | Cartao de credito |
| `debit_card` | Cartao de debito |
| `cash` | Dinheiro |
| `manual` | Confirmacao manual |

### Relacionamentos

| Relacionamento | Descricao |
|---|---|
| `registration_payments.id_tournament_charge_options -> tournament_charge_options.id` | Pagamento foi feito para uma opcao de cobranca |
| `registration_payments.id_tournaments_registration -> tournaments_registration.id` | Pagamento pertence a uma inscricao |

---

## 11. Relacionamentos Do Banco

### Usuarios e clubes

```text
users 1:N club_memberships
clubs 1:N club_memberships
```

Um usuario pode estar em varios clubes.
Um clube pode ter varios usuarios.

### Clubes e torneios

```text
clubs 1:N tournaments
```

Um clube pode criar varios torneios.
Um torneio pertence a um clube.

### Torneios e inscricoes

```text
tournaments 1:N tournaments_registration
users 1:N tournaments_registration
```

Um torneio pode ter varios inscritos.
Um usuario pode se inscrever em varios torneios.

### Torneios e blinds

```text
tournaments 1:N blind_levels
```

Um torneio tem varios niveis de blind.
Cada linha em `blind_levels` e um nivel.

### Torneios e relogio

```text
tournaments 1:1 tournament_clock_states
tournament_clock_states N:1 blind_levels
```

Um torneio deve ter apenas um estado de relogio ativo.
O relogio aponta para o nivel atual pelo campo `current_blind_level_id`.

### Torneios e cobrancas

```text
tournaments 1:N tournament_charge_options
```

Um torneio pode ter varias opcoes de cobranca.

### Inscricoes e pagamentos

```text
tournaments_registration 1:N registration_payments
tournament_charge_options 1:N registration_payments
```

Uma inscricao pode ter varios pagamentos.
Cada pagamento aponta para uma opcao de cobranca.

---

## 12. Fluxo De Criacao De Clube E Permissoes

### 1. Usuario cria o clube

Cria uma linha em `clubs`:

```text
name = nome do clube
description = descricao opcional
```

### 2. Sistema cria o membro automaticamente

Cria uma linha em `club_memberships`:

```text
id_clubs = clube criado
id_users = usuario criador
role = owner
status = active
```

### 3. Owner adiciona outros membros

Quando convidar outro usuario, cria outra linha em `club_memberships`:

```text
id_clubs = clube
id_users = usuario convidado
role = member, staff ou admin
status = invited ou active
```

### 4. Sistema valida permissao pelo role

Antes de permitir qualquer acao no clube ou torneio, o sistema verifica:

```text
Qual e o role desse usuario em club_memberships para esse clube?
```

Exemplo:

```text
Se role = owner ou admin:
  pode editar configuracoes do torneio.

Se role = staff:
  pode operar relogio, check-in e eliminacoes.

Se role = member:
  pode participar, mas nao gerenciar.
```

---

## 13. Fluxo De Inscricao E Pagamento

### 1. Jogador entra no torneio

Cria uma linha em `tournaments_registration`:

```text
id_tournaments = torneio escolhido
id_users = jogador
rsvp_status = pending ou confirmed
presence_status = not_arrived
```

### 2. Sistema gera o pagamento

Busca a opcao de cobranca `buy_in` em `tournament_charge_options`.

Depois cria uma linha em `registration_payments`:

```text
id_tournament_charge_options = buy-in do torneio
id_tournaments_registration = inscricao do jogador
amount = valor do buy-in
status = pending
provider = provedor escolhido
```

### 3. Pagamento aprovado

Atualiza:

```text
registration_payments.status = paid
registration_payments.paid_at = agora
```

E a inscricao pode ficar:

```text
tournaments_registration.rsvp_status = confirmed
```

### 4. Jogador chega no local

Atualiza:

```text
tournaments_registration.presence_status = checked_in
```

### 5. Jogador e eliminado

Atualiza:

```text
tournaments_registration.presence_status = eliminated
tournaments_registration.eliminated_at = agora
tournaments_registration.finish_position = posicao final
```

---

## 14. Fluxo Do Relogio Do Torneio

### 1. Criacao da estrutura

O admin cadastra os niveis em `blind_levels`.

Exemplo:

```text
Nivel 1: 100 / 200 / ante 0 / 10 minutos
Nivel 2: 200 / 400 / ante 0 / 10 minutos
Nivel 3: 300 / 600 / ante 100 / 15 minutos
```

### 2. Inicio do torneio

O sistema busca o primeiro nivel do torneio:

```text
menor valor de blind_levels.level
```

Depois cria ou atualiza `tournament_clock_states`:

```text
status = running
current_blind_level_id = primeiro nivel
remaining_seconds = duration_minutes * 60
started_at = agora
```

### 3. Pausa

Quando pausar:

```text
status = paused
remaining_seconds = tempo restante real
paused_at = agora
```

### 4. Retorno da pausa

Quando retomar:

```text
status = running
started_at = agora
paused_at = null
```

O `current_blind_level_id` continua o mesmo.

### 5. Proximo nivel

Quando `remaining_seconds` chegar a zero:

```text
buscar o proximo blind_levels.level
atualizar current_blind_level_id
reiniciar remaining_seconds com a duracao do novo nivel
```

### 6. Fim da estrutura

Se nao existir proximo nivel:

```text
status = finished
remaining_seconds = 0
```

---

## 15. Nomes Que Eu Recomendo Ajustar

Alguns nomes no diagrama funcionam, mas podem ficar mais consistentes.

| Nome atual | Nome recomendado | Motivo |
|---|---|---|
| `id_users` | `user_id` | Padrao mais comum em bancos relacionais e frameworks |
| `id_clubs` | `club_id` | Mais legivel e padronizado |
| `id_tournaments` | `tournament_id` | Mais legivel e padronizado |
| `tournaments_registration` | `tournament_registrations` | Nome plural igual ao restante das tabelas |
| `id_tournaments_registration` | `tournament_registration_id` | FK mais clara |
| `id_tournament_charge_options` | `tournament_charge_option_id` | FK mais clara |
| `smal` | `small_blind` | Corrige erro de escrita e deixa claro o significado |

Exemplo de padrao recomendado:

```text
users.id
clubs.id
club_memberships.user_id
club_memberships.club_id
tournaments.club_id
blind_levels.tournament_id
tournament_clock_states.tournament_id
tournament_clock_states.current_blind_level_id
```

---

## 16. Resumo Direto

- `users` guarda os usuarios.
- `clubs` guarda os clubes.
- `club_memberships` liga usuarios aos clubes e controla permissoes por `role`.
- `tournaments` guarda os torneios.
- `tournaments_registration` guarda os jogadores inscritos.
- `blind_levels` guarda um nivel de blind por linha.
- `tournament_clock_states` guarda o estado atual do relogio.
- `tournament_charge_options` guarda buy-in, rebuy, add-on e outras cobrancas.
- `registration_payments` guarda os pagamentos feitos por cada inscricao.

Ponto mais importante:

```text
blind_levels guarda a configuracao dos niveis.
tournament_clock_states guarda somente o nivel atual e o tempo restante.
```
