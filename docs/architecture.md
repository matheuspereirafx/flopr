como o Rails está estruturado;
onde cada tipo de código deve ficar;
quando criar Model, Controller, Service ou Stimulus;
quais padrões já existem no projeto;
quais decisoes aruiteturais devem ser respeitadas 

# Arquitetura do Projeto

## 1. Visão geral

O Flopr é uma aplicação web desenvolvida em Ruby on Rails.

O projeto segue principalmente o padrão MVC:

* Model: dados, relacionamentos, validações e regras de negócio.
* View: apresentação das informações ao usuário.
* Controller: coordenação das requisições entre View e Model.

A aplicação deve seguir as convenções do Rails sempre que possível, evitando abstrações desnecessárias.

---

## 2. Stack principal

* Ruby 3.3.5
* Ruby on Rails 8.1
* PostgreSQL
* Devise
* Simple Form
* Stimulus
* Importmap
* SCSS
* RSpec

Não adicionar novas bibliotecas ou gems sem justificar a necessidade e receber aprovação.

---

## 3. Estrutura MVC

### Models

Os Models são responsáveis por:

* relacionamentos entre entidades;
* validações;
* regras de negócio;
* consultas relacionadas ao próprio domínio;
* enums;
* callbacks simples, quando necessários.

Exemplos:

```ruby
class Tournament < ApplicationRecord
  belongs_to :club

  validates :name, presence: true
  validates :starts_at, presence: true
end
```

Os Models não devem ser usados para:

* renderizar HTML;
* controlar redirecionamentos;
* acessar parâmetros da requisição;
* definir comportamento visual;
* guardar regras específicas de interface.

---

### Controllers

Os Controllers são responsáveis por:

* receber a requisição;
* localizar os registros necessários;
* verificar autenticação e autorização;
* executar operações por meio dos Models;
* renderizar Views;
* redirecionar o usuário;
* definir mensagens de sucesso ou erro.

Exemplo de fluxo:

```ruby
def create
  @tournament = @club.tournaments.build(tournament_params)

  if @tournament.save
    redirect_to @tournament, notice: "Torneio criado com sucesso."
  else
    render :new, status: :unprocessable_entity
  end
end
```

Os Controllers devem ser pequenos e objetivos.

Controllers não devem conter:

* HTML;
* CSS;
* regras de negócio extensas;
* consultas inseguras;
* lógica duplicada;
* cálculos complexos.

Quando uma regra começar a crescer, avaliar se ela pertence ao Model ou a outro objeto de domínio.

---

### Views

As Views são responsáveis por:

* apresentar os dados;
* renderizar formulários;
* exibir mensagens;
* renderizar componentes e partials;
* disparar ações para rotas do backend.

As Views podem acessar variáveis preparadas pelo Controller:

```erb
<h1><%= @tournament.name %></h1>
```

As Views não devem:

* realizar regras de negócio;
* consultar diretamente grandes conjuntos de dados;
* decidir permissões complexas;
* modificar registros;
* conter consultas ActiveRecord extensas;
* executar cálculos importantes do domínio.

---

## 4. Fluxo de uma requisição

O fluxo padrão deve seguir:

```text
Usuário executa uma ação
        ↓
Router identifica a rota
        ↓
Controller recebe a requisição
        ↓
Controller busca ou cria os dados
        ↓
Model valida e executa regras
        ↓
Banco de dados salva ou consulta
        ↓
Controller renderiza ou redireciona
        ↓
View apresenta a resposta
```

Exemplo de criação de torneio:

```text
GET /clubs/:club_id/tournaments/new
        ↓
TournamentsController#new
        ↓
Cria @tournament em memória
        ↓
Renderiza new.html.erb
        ↓
Usuário envia o formulário
        ↓
POST /clubs/:club_id/tournaments
        ↓
TournamentsController#create
        ↓
Valida permissões e parâmetros
        ↓
Salva Tournament no banco
        ↓
Redireciona para a página do torneio
```

---

## 5. Rotas

As rotas devem representar a relação entre os recursos.

Quando um recurso pertence diretamente a outro, utilizar rotas aninhadas quando fizer sentido.

Exemplo:

```ruby
resources :clubs do
  resources :tournaments
end
```

Isso gera rotas como:

```text
GET    /clubs/:club_id/tournaments
GET    /clubs/:club_id/tournaments/new
POST   /clubs/:club_id/tournaments
GET    /clubs/:club_id/tournaments/:id
PATCH  /clubs/:club_id/tournaments/:id
DELETE /clubs/:club_id/tournaments/:id
```

Evitar níveis excessivos de aninhamento.

Preferencialmente, não utilizar mais de dois níveis de recursos aninhados.

---

## 6. Autenticação

A autenticação é realizada com Devise.

Controllers que exigem usuário autenticado devem utilizar:

```ruby
before_action :authenticate_user!
```

Nunca assumir que existe um usuário autenticado sem verificar.

O usuário autenticado deve ser acessado por:

```ruby
current_user
```

---

## 7. Autorização

A autorização deve garantir que o usuário somente acesse registros permitidos.

Evitar:

```ruby
@club = Club.find(params[:id])
```

Quando essa consulta permitir acesso a clubes de outros usuários.

Preferir consultas por associação:

```ruby
@club = current_user.clubs.find(params[:id])
```

Para recursos pertencentes a um clube:

```ruby
@tournament = @club.tournaments.find(params[:id])
```

Permissões de owner, admin, member, director e dealer devem seguir o documento:

```text
docs/permissions.md
```

A autorização deve ser validada no backend.

Ocultar um botão na View não é suficiente para proteger uma ação.

---

## 8. Strong Parameters

Todos os parâmetros recebidos por formulários devem passar por Strong Parameters.

Exemplo:

```ruby
def tournament_params
  params.require(:tournament).permit(
    :name,
    :starts_at,
    :buy_in
  )
end
```

Não utilizar:

```ruby
params.permit!
```

Não permitir atributos de segurança, como:

* owner_id;
* user_id;
* club_id;
* role;
* status de autorização.

Esses atributos devem ser definidos pelo backend quando necessário.

---

## 9. Relacionamentos

Os relacionamentos devem ser definidos nos Models.

Exemplo:

```ruby
class Club < ApplicationRecord
  has_many :tournaments, dependent: :destroy
end
```

```ruby
class Tournament < ApplicationRecord
  belongs_to :club
end
```

Preferir criar registros pelas associações:

```ruby
@club.tournaments.build(tournament_params)
```

em vez de receber o `club_id` diretamente do formulário.

Evitar:

```ruby
Tournament.new(
  tournament_params.merge(club_id: params[:club_id])
)
```

quando a associação já estiver disponível.

---

## 10. Services

Service Objects não devem ser criados automaticamente.

Criar um Service somente quando:

* a operação envolver vários Models;
* existir uma sequência complexa de etapas;
* houver integração externa;
* a regra não pertencer claramente a um único Model;
* o Controller estiver acumulando lógica de negócio extensa.

Exemplo de possível Service futuro:

```text
TournamentFinalizationService
```

Responsável por:

* finalizar o torneio;
* definir colocações;
* calcular premiações;
* salvar resultados;
* atualizar rankings.

Não criar Service apenas para envolver uma única chamada como:

```ruby
@tournament.save
```

---

## 11. Concerns

Concerns devem ser utilizados com cuidado.

Criar um Concern somente quando existir comportamento realmente compartilhado entre múltiplos Models ou Controllers.

Não utilizar Concerns para esconder código complexo ou evitar decidir corretamente a responsabilidade de uma regra.

---

## 12. Callbacks

Evitar callbacks complexos.

Callbacks simples podem ser usados quando o comportamento fizer parte diretamente do ciclo de vida do Model.

Exemplo aceitável:

```ruby
before_validation :normalize_name
```

Evitar usar callbacks para:

* criar vários registros;
* enviar múltiplas notificações;
* executar regras financeiras;
* alterar outros domínios;
* iniciar fluxos complexos.

Operações complexas devem ser explícitas.

---

## 13. Jobs

Background Jobs devem ser usados para operações que não precisam bloquear a resposta ao usuário.

Exemplos futuros:

* envio de convites;
* envio de notificações;
* geração de relatórios;
* atualização de rankings;
* processamento de arquivos.

Não criar Job para operações rápidas e simples sem necessidade.

---

## 14. Frontend

O frontend utiliza:

* ERB;
* SCSS;
* Stimulus;
* Simple Form;
* componentes compartilhados por partials.

A estrutura visual deve ser organizada em blocos claros.

Exemplo:

```text
tournament-page
├── tournament-header
├── tournament-information
├── tournament-actions
├── tournament-players
└── tournament-status
```

Os nomes das classes CSS devem representar a função do elemento.

---

## 15. Partials e componentes

Elementos reutilizados em mais de uma tela devem ser avaliados para criação de partial.

Exemplo:

```text
app/views/shared/components/buttons/_button_create.html.erb
```

Um componente deve possuir uma responsabilidade clara.

Evitar criar partials para trechos muito pequenos que não são reutilizados.

Preferir chamadas explícitas:

```erb
<%= render "shared/components/buttons/button_create",
  text: "Criar torneio",
  path: new_club_tournament_path(@club) %>
```

---

## 16. Stimulus

Stimulus deve ser usado para comportamentos interativos no navegador.

Exemplos:

* abrir e fechar menus;
* modais;
* tabs;
* filtros visuais;
* scroll horizontal;
* atualização dinâmica de campos;
* temporizadores;
* confirmação visual;
* exibição condicional de elementos.

Stimulus não deve ser utilizado para substituir regras do backend.

Toda regra de autorização ou validação importante deve continuar existindo no servidor.

---

## 17. SCSS

Os estilos devem seguir a organização já existente no projeto.

Exemplo:

```text
app/assets/stylesheets/
├── application.scss
├── components/
├── pages/
└── config/
```

Estilos específicos de uma página devem ficar em arquivos próprios.

Exemplo:

```text
pages/clubs/_show.scss
pages/tournaments/_new.scss
```

Componentes compartilhados devem ficar na pasta de componentes.

Evitar:

* estilos inline;
* duplicação de classes;
* seletores excessivamente específicos;
* uso desnecessário de `!important`;
* classes genéricas que afetem outras páginas.

---

## 18. Responsividade

As telas devem funcionar em:

* desktop;
* tablet;
* celular.

A implementação deve considerar:

* largura disponível;
* quebra de textos;
* tamanho de botões;
* espaçamentos;
* formulários;
* scroll horizontal;
* cards;
* imagens;
* menus.

Não considerar a tela pronta apenas por funcionar em desktop.

---

## 19. Banco de dados

Mudanças na estrutura do banco devem ser feitas com migrations.

Não alterar migrations antigas que já tenham sido executadas.

Criar uma nova migration para:

* adicionar coluna;
* remover coluna;
* adicionar relacionamento;
* criar índice;
* adicionar foreign key;
* alterar estrutura de tabela.

Relacionamentos devem possuir foreign keys e índices quando apropriado.

Exemplo:

```ruby
add_reference :tournaments,
              :club,
              null: false,
              foreign_key: true
```

---

## 20. Testes

Os testes devem seguir as regras de negócio e os critérios de aceitação das User Stories.

Utilizar:

* Model Specs para validações e associações;
* Request Specs para fluxo MVC, autenticação e autorização;
* System Specs para fluxos principais da interface;
* Service Specs quando existirem Services;
* Job Specs quando existirem Jobs.

Cada critério de aceitação deve estar coberto por pelo menos um teste quando possível.

---

## 21. Tratamento de erros

Erros de validação devem renderizar novamente o formulário:

```ruby
render :new, status: :unprocessable_entity
```

Exclusões devem utilizar:

```ruby
status: :see_other
```

Mensagens devem ser claras:

```ruby
redirect_to clubs_path,
            notice: "Clube atualizado com sucesso."
```

Não esconder erros importantes com `rescue` genérico.

Evitar:

```ruby
rescue StandardError
```

sem tratamento específico ou registro do erro.

---

## 22. Segurança

Toda funcionalidade deve verificar:

* usuário autenticado;
* acesso ao recurso;
* papel do usuário;
* strong parameters;
* associação correta entre registros;
* manipulação de IDs;
* ações destrutivas;
* acesso entre clubes diferentes.

Nunca confiar apenas nos dados enviados pelo formulário.

---

## 23. Princípios arquiteturais

O projeto deve seguir estes princípios:

* utilizar as convenções do Rails;
* manter Controllers pequenos;
* manter Views focadas na apresentação;
* colocar regras de negócio no domínio correto;
* evitar abstrações prematuras;
* evitar código duplicado;
* priorizar segurança;
* escrever código explícito;
* alterar somente o necessário;
* preservar os padrões existentes;
* testar regras de negócio;
* não refatorar fora do escopo da User Story.

---

## 24. Processo para novas funcionalidades

Antes de implementar uma User Story:

1. Ler o `AGENTS.md`.
2. Ler a User Story.
3. Consultar a documentação relacionada.
4. Analisar Models, Controllers, Views e rotas existentes.
5. Verificar o schema atual.
6. Apresentar o plano de implementação.
7. Informar os arquivos que serão criados ou alterados.
8. Aguardar aprovação.

Após a aprovação:

1. Implementar o backend.
2. Criar ou atualizar testes.
3. Executar os testes relacionados.
4. Mostrar as alterações.
5. Planejar a View.
6. Implementar o frontend após aprovação.
7. Fazer revisão final.
8. Sugerir commits.
