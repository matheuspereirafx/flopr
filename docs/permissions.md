# Permissões e Papéis

## 1. Objetivo

Este documento define os papéis dos usuários e as permissões de acesso dentro do Flopr.

Todas as permissões do clube e de seus torneios são controladas pelo model:

```ruby
ClubMembership
```

Não será utilizado um model separado chamado `TournamentStaff`.

O papel armazenado no `ClubMembership` determina o que o usuário pode fazer dentro do clube e nos torneios pertencentes a ele.

Toda permissão deve ser validada no backend.

Ocultar botões na interface não substitui a autorização no Controller.

---

## 2. Estrutura de participação

A relação entre usuário e clube é representada por:

```ruby
class ClubMembership < ApplicationRecord
  belongs_to :user
  belongs_to :club
end
```

Papéis disponíveis:

```ruby
enum :role, {
  player: 0,
  dealer: 1,
  admin: 2,
  owner: 3
}
```

Cada usuário possui um papel específico em cada clube.

Exemplo:

```text
Usuário A
├── Clube 1: owner
├── Clube 2: dealer
└── Clube 3: player
```

Ser owner em um clube não concede permissões em outro clube.

---

## 3. Princípios gerais

* Todo usuário deve estar autenticado para acessar áreas privadas.
* Um usuário somente pode acessar clubes dos quais participa.
* Um usuário não pode acessar outro clube alterando o ID da URL.
* Todas as permissões devem ser verificadas no backend.
* O papel deve ser atribuído pelo backend.
* O usuário não pode selecionar livremente seu próprio papel.
* As permissões devem ser cobertas por testes.
* Todo torneio deve pertencer a um clube.
* O acesso a um torneio depende da participação do usuário no clube correspondente.

---

## 4. Owner

O `owner` é o proprietário do clube.

Possui acesso completo à administração do clube, à administração dos torneios e também pode participar como jogador.

### Pode

* visualizar o clube;
* editar o clube;
* excluir o clube;
* administrar membros;
* convidar usuários;
* remover usuários;
* alterar papéis;
* promover usuários para admin;
* definir usuários como dealer;
* criar torneios;
* editar torneios;
* excluir torneios;
* configurar torneios;
* configurar estrutura de blinds;
* configurar premiações;
* iniciar torneios;
* pausar e retomar o timer;
* operar o clock;
* registrar rebuys;
* registrar add-ons;
* registrar eliminações;
* realizar check-in;
* participar dos torneios como jogador;
* aceitar convites;
* finalizar torneios;
* visualizar informações administrativas e operacionais.

### Não pode

* acessar clubes dos quais não participa;
* acessar dados de outros clubes;
* alterar registros de outros clubes;
* burlar regras de integridade do sistema.

---

## 5. Admin

O `admin` possui acesso administrativo limitado.

Ele auxilia o owner na administração e operação do clube, mas não possui controle completo sobre propriedade e ações críticas.

### Pode

* visualizar o clube;
* editar informações permitidas do clube;
* visualizar membros;
* convidar jogadores, quando autorizado;
* criar torneios;
* editar informações permitidas dos torneios;
* configurar torneios;
* visualizar o painel administrativo;
* operar o torneio;
* iniciar, pausar e retomar o timer;
* registrar rebuys;
* registrar add-ons;
* registrar eliminações;
* participar dos torneios como jogador;
* aceitar convites;
* realizar check-in.

### Não pode

* excluir o clube;
* remover o owner;
* alterar o papel do owner;
* transferir a propriedade do clube;
* promover outro usuário para owner;
* executar ações exclusivas do owner;
* acessar outros clubes sem participação;
* alterar configurações bloqueadas pela User Story correspondente.

As permissões específicas de edição do admin devem ser detalhadas nas User Stories.

Quando uma regra ainda não estiver definida, a IA deve apontar a dúvida antes de implementar.

---

## 6. Player

O `player` possui acesso às funcionalidades relacionadas à participação nos jogos.

Não possui acesso administrativo ao clube ou aos torneios.

### Pode

* visualizar o clube;
* visualizar torneios disponíveis;
* receber convites;
* aceitar ou recusar convites;
* realizar inscrição;
* realizar check-in;
* participar de torneios;
* visualizar blinds;
* visualizar mesas;
* visualizar premiações;
* visualizar o timer;
* visualizar seu status no torneio;
* visualizar seus resultados.

### Não pode

* editar o clube;
* excluir o clube;
* administrar membros;
* alterar papéis;
* criar torneios;
* editar torneios;
* excluir torneios;
* alterar configurações do torneio;
* iniciar ou pausar o timer;
* operar o clock;
* registrar eliminações;
* registrar rebuys de outros jogadores;
* acessar o painel administrativo.

---

## 7. Dealer

O `dealer` possui acesso operacional aos torneios do clube.

Seu foco é auxiliar na execução do torneio, principalmente nas funções relacionadas às mesas e ao clock.

### Pode

* visualizar o clube;
* visualizar os torneios do clube;
* acessar o painel operacional do torneio;
* visualizar jogadores e mesas;
* visualizar o nível atual de blinds;
* visualizar o estado do torneio;
* acessar a entidade responsável pelo clock;
* pausar o timer;
* retomar o timer, quando autorizado;
* registrar informações operacionais permitidas;
* informar ou registrar eliminações, quando definido;
* participar como jogador, quando também estiver inscrito no torneio.

### Não pode

* editar o clube;
* excluir o clube;
* administrar membros;
* alterar papéis;
* criar torneios;
* excluir torneios;
* alterar configurações principais do torneio;
* alterar estrutura de blinds sem autorização;
* alterar premiações;
* finalizar o torneio;
* executar ações exclusivas de owner ou admin.

As ações exatas do dealer devem ser detalhadas nas User Stories relacionadas à operação do torneio.

---

## 8. Relação entre papel e participação no torneio

O papel no clube não significa automaticamente que o usuário está inscrito como jogador em um torneio.

A participação em um torneio deve ser representada por:

```ruby
TournamentRegistration
```

Exemplo:

```text
Usuário
├── ClubMembership
│   └── role: owner
│
└── TournamentRegistration
    └── participação no Torneio 10
```

O `ClubMembership` define as permissões.

O `TournamentRegistration` define se o usuário está inscrito e participando daquele torneio.

Assim, um owner pode administrar o torneio e também jogar, desde que possua uma inscrição.

Um dealer pode operar o torneio e também jogar, caso essa combinação seja permitida e ele esteja inscrito.

---

## 9. Entidade de clock

O timer do torneio deve ser controlado por uma entidade própria.

Exemplo:

```ruby
TournamentClockState
```

Essa entidade pode armazenar informações como:

* estado do timer;
* horário de início;
* tempo restante;
* nível atual;
* momento da pausa;
* status do torneio.

A permissão para operar o clock depende do papel no `ClubMembership`.

### Pode operar completamente

* owner;
* admin.

### Pode operar de forma limitada

* dealer.

### Apenas visualiza

* player.

As ações específicas permitidas ao dealer devem ser definidas nas User Stories do clock.

---

## 10. Matriz de permissões do clube

| Ação                    | Owner |    Admin | Dealer | Player |
| ----------------------- | ----: | -------: | -----: | -----: |
| Visualizar clube        |   Sim |      Sim |    Sim |    Sim |
| Editar clube            |   Sim | Limitado |    Não |    Não |
| Excluir clube           |   Sim |      Não |    Não |    Não |
| Administrar membros     |   Sim | Limitado |    Não |    Não |
| Alterar papéis          |   Sim | Limitado |    Não |    Não |
| Criar torneio           |   Sim |      Sim |    Não |    Não |
| Editar torneio          |   Sim | Limitado |    Não |    Não |
| Excluir torneio         |   Sim | Limitado |    Não |    Não |
| Participar como jogador |   Sim |      Sim |    Sim |    Sim |
| Aceitar convites        |   Sim |      Sim |    Sim |    Sim |
| Realizar check-in       |   Sim |      Sim |    Sim |    Sim |

A participação como jogador depende de uma inscrição válida no torneio.

---

## 11. Matriz de permissões do torneio

| Ação                 | Owner |    Admin |   Dealer |        Player |
| -------------------- | ----: | -------: | -------: | ------------: |
| Visualizar torneio   |   Sim |      Sim |      Sim |           Sim |
| Criar torneio        |   Sim |      Sim |      Não |           Não |
| Editar torneio       |   Sim | Limitado |      Não |           Não |
| Excluir torneio      |   Sim | Limitado |      Não |           Não |
| Configurar blinds    |   Sim |      Sim | Limitado |           Não |
| Configurar premiação |   Sim | Limitado |      Não |           Não |
| Iniciar torneio      |   Sim |      Sim | Limitado |           Não |
| Pausar timer         |   Sim |      Sim |      Sim |           Não |
| Retomar timer        |   Sim |      Sim | Limitado |           Não |
| Registrar eliminação |   Sim |      Sim | Limitado |           Não |
| Registrar rebuy      |   Sim |      Sim | Limitado | Próprio fluxo |
| Registrar add-on     |   Sim |      Sim | Limitado | Próprio fluxo |
| Finalizar torneio    |   Sim |      Sim |      Não |           Não |
| Visualizar clock     |   Sim |      Sim |      Sim |           Sim |
| Operar clock         |   Sim |      Sim | Limitado |           Não |

As permissões marcadas como `Limitado` devem ser detalhadas pela User Story correspondente.

---

## 12. Consulta segura do clube

Evitar:

```ruby
@club = Club.find(params[:id])
```

Preferir:

```ruby
@club = current_user.clubs.find(params[:id])
```

Essa consulta garante que o usuário participe do clube.

Para localizar a participação atual:

```ruby
def current_membership
  @current_membership ||= @club.club_memberships.find_by!(
    user: current_user
  )
end
```

---

## 13. Consulta segura do torneio

Um torneio deve ser buscado por meio do clube autorizado.

Evitar:

```ruby
@tournament = Tournament.find(params[:id])
```

Preferir:

```ruby
@tournament = @club.tournaments.find(params[:id])
```

Fluxo esperado:

```text
current_user
    ↓
club_memberships
    ↓
club autorizado
    ↓
tournament pertencente ao clube
```

---

## 14. Verificação de papéis

Exemplo para autorizar owner:

```ruby
def authorize_owner!
  return if current_membership.owner?

  redirect_to club_path(@club),
              alert: "Você não possui permissão para realizar esta ação."
end
```

Exemplo para owner ou admin:

```ruby
def authorize_management!
  return if current_membership.owner? ||
            current_membership.admin?

  redirect_to club_path(@club),
              alert: "Você não possui permissão para realizar esta ação."
end
```

Exemplo para operação do clock:

```ruby
def authorize_clock_operation!
  return if current_membership.owner? ||
            current_membership.admin? ||
            current_membership.dealer?

  redirect_to club_tournament_path(@club, @tournament),
              alert: "Você não possui permissão para operar o timer."
end
```

Esses códigos são exemplos.

Antes de implementar, deve-se analisar o padrão atual do projeto.

---

## 15. Permissões nas Views

A View pode esconder ações não permitidas.

Exemplo:

```erb
<% if current_membership.owner? || current_membership.admin? %>
  <%= link_to "Criar torneio",
      new_club_tournament_path(@club) %>
<% end %>
```

Exemplo para dealer:

```erb
<% if current_membership.owner? ||
      current_membership.admin? ||
      current_membership.dealer? %>

  <%= button_to "Pausar timer",
      pause_club_tournament_clock_path(@club, @tournament) %>
<% end %>
```

A proteção também deve existir no backend.

---

## 16. Strong Parameters

O papel não deve ser alterado livremente por meio de um formulário comum.

Evitar:

```ruby
params.require(:club_membership).permit(
  :user_id,
  :club_id,
  :role
)
```

Mudanças de papel devem possuir uma ação própria, protegida por autorização.

O backend deve definir:

* usuário;
* clube;
* papel permitido;
* responsável pela alteração.

---

## 17. Proteção do owner

O sistema não deve permitir que um clube fique sem owner.

Até existir um fluxo de transferência de propriedade:

* owner não pode remover a si mesmo;
* admin não pode remover o owner;
* dealer não pode alterar papéis;
* player não pode alterar papéis;
* o papel do owner não pode ser alterado diretamente;
* nenhum usuário pode se promover para owner.

---

## 18. Testes de autorização

Toda User Story com acesso restrito deve testar os papéis relevantes.

Exemplo:

```ruby
context "quando o usuário é owner" do
  it "permite executar a ação"
end

context "quando o usuário é admin" do
  it "permite ou limita a ação conforme a regra"
end

context "quando o usuário é dealer" do
  it "permite apenas as ações operacionais autorizadas"
end

context "quando o usuário é player" do
  it "não permite ações administrativas"
end

context "quando o usuário não pertence ao clube" do
  it "não permite acessar o recurso"
end
```

Também devem ser testados:

* usuário não autenticado;
* alteração do ID do clube na URL;
* alteração do ID do torneio na URL;
* torneio pertencente a outro clube;
* envio de papel pelo formulário;
* tentativa de acessar diretamente uma rota protegida.

---

## 19. Regras ainda não definidas

As seguintes regras devem ser detalhadas em User Stories:

* quais campos do clube o admin pode editar;
* se o admin pode excluir torneios;
* quais configurações o admin pode alterar;
* se o dealer pode iniciar o torneio;
* se o dealer pode retomar o timer;
* se o dealer pode alterar o nível de blinds;
* se o dealer pode registrar eliminações;
* se o dealer pode registrar rebuy e add-on;
* se um dealer pode operar e jogar simultaneamente;
* transferência de propriedade do clube;
* bloqueio de alterações após a finalização do torneio.

Enquanto uma regra não estiver definida, a IA não deve inventar a permissão.

Ela deve apresentar a dúvida durante o planejamento da User Story.

---

## 20. Resumo dos papéis

### Owner

Possui acesso completo ao clube e aos torneios. Pode administrar, configurar, operar e também participar como jogador.

### Admin

Possui acesso administrativo e operacional limitado. As limitações devem ser definidas pelas User Stories.

### Dealer

Possui acesso operacional ao torneio, principalmente às mesas e ao clock. Não possui acesso administrativo ao clube.

### Player

Possui acesso somente às funcionalidades relacionadas à participação nos jogos, como convites, inscrição, check-in e visualização do torneio.

---

## 21. Regra final

Antes de implementar qualquer funcionalidade protegida:

1. identificar o clube;
2. confirmar que o usuário participa do clube;
3. localizar o `ClubMembership`;
4. identificar o papel atual;
5. verificar a permissão exigida;
6. proteger a ação no backend;
7. ajustar a interface;
8. criar testes para os papéis;
9. verificar acesso indevido entre clubes;
10. não criar `TournamentStaff`.
