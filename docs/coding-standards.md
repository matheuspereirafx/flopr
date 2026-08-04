# Padrões de Desenvolvimento

## 1. Objetivo

Este documento define os padrões de desenvolvimento do projeto Flopr.

Todas as implementações devem priorizar:

* clareza;
* simplicidade;
* segurança;
* legibilidade;
* manutenção;
* consistência com o código existente;
* respeito às convenções do Ruby on Rails.

A IA deve consultar este documento antes de criar ou alterar código.

---

## 2. Princípios gerais

O código deve ser simples, explícito e fácil de entender.

Preferir soluções diretas antes de criar abstrações complexas.

Toda alteração deve:

* atender à User Story;
* respeitar os critérios de aceitação;
* alterar apenas os arquivos necessários;
* preservar o comportamento existente;
* seguir os padrões atuais do projeto;
* possuir testes quando houver regra de negócio;
* evitar refatorações fora do escopo.

Não criar funcionalidades adicionais sem solicitação.

---

## 3. Escopo das alterações

Antes de implementar, identificar:

* qual problema será resolvido;
* quais arquivos estão relacionados;
* quais regras de negócio serão afetadas;
* quais permissões precisam ser verificadas;
* quais testes serão necessários.

Não alterar arquivos que não estejam relacionados à funcionalidade.

Evitar:

* renomear classes sem necessidade;
* reorganizar pastas fora do escopo;
* formatar arquivos inteiros sem motivo;
* modificar estilos de outras páginas;
* alterar regras de negócio não mencionadas;
* atualizar gems sem necessidade.

Caso uma alteração fora do escopo seja necessária, ela deve ser informada antes da implementação.

---

## 4. Convenções do Ruby

Utilizar sintaxe clara e convencional.

Preferir:

```ruby
return if membership.owner?
```

em vez de:

```ruby
if membership.owner?
  return
end
```

Quando a condição for simples.

Utilizar nomes claros:

```ruby
current_membership
authorized_club
tournament_params
```

Evitar nomes genéricos:

```ruby
data
item
object
temp
value
```

quando houver um nome mais específico.

---

## 5. Nomes de métodos

Métodos devem representar uma ação ou intenção clara.

Exemplos:

```ruby
authorize_club_management!
set_member_club
create_owner_membership
tournament_params
```

Métodos booleanos devem terminar com `?`:

```ruby
owner?
admin?
clock_operator?
```

Métodos que podem interromper o fluxo ou lançar erro podem terminar com `!` quando apropriado:

```ruby
authorize_owner!
create_membership!
```

Não utilizar `!` apenas para dar destaque ao método.

---

## 6. Tamanho dos métodos

Métodos devem ser pequenos e possuir uma responsabilidade principal.

Evitar métodos que:

* busquem dados;
* validem permissões;
* criem vários registros;
* enviem notificações;
* façam redirecionamentos;
* executem cálculos;

tudo ao mesmo tempo.

Quando um método estiver difícil de explicar em uma frase, avaliar a separação de responsabilidades.

Não dividir métodos excessivamente apenas para reduzir quantidade de linhas.

A clareza é mais importante do que um limite fixo.

---

## 7. Controllers

Controllers devem coordenar a requisição.

Exemplo recomendado:

```ruby
def create
  @tournament = @club.tournaments.build(tournament_params)

  if @tournament.save
    redirect_to @tournament,
                notice: "Torneio criado com sucesso."
  else
    render :new,
           status: :unprocessable_entity
  end
end
```

Controllers devem:

* autenticar o usuário;
* localizar registros;
* verificar autorização;
* receber parâmetros;
* chamar Models ou serviços;
* renderizar ou redirecionar.

Controllers não devem:

* conter HTML;
* executar cálculos complexos;
* concentrar regras extensas;
* montar consultas inseguras;
* acessar registros sem considerar o usuário;
* possuir lógica repetida em várias actions.

---

## 8. Before actions

Utilizar `before_action` para tarefas repetidas entre actions relacionadas.

Exemplo:

```ruby
before_action :authenticate_user!
before_action :set_member_club
before_action :set_tournament, only: %i[show edit update destroy]
```

Evitar muitos `before_action` que tornem o fluxo difícil de acompanhar.

O nome do método deve indicar claramente o que ele faz.

Preferir:

```ruby
set_owned_club
```

em vez de:

```ruby
load_data
```

---

## 9. Models

Models devem concentrar:

* validações;
* associações;
* enums;
* regras de negócio;
* consultas próprias do domínio;
* estados da entidade.

Exemplo:

```ruby
class Tournament < ApplicationRecord
  belongs_to :club

  validates :name, presence: true
  validates :starts_at, presence: true
end
```

Evitar Models que apenas armazenem dados sem representar corretamente o domínio.

Também evitar transformar Models em arquivos muito grandes com responsabilidades diferentes.

---

## 10. Validações

Regras obrigatórias devem ser validadas no backend.

Exemplo:

```ruby
validates :name, presence: true
```

A validação HTML no formulário pode melhorar a experiência, mas não substitui a validação no Model.

Mensagens de erro devem ser compreensíveis para o usuário.

Não criar validações baseadas apenas em necessidades visuais.

---

## 11. Associações

Utilizar associações do Rails sempre que possível.

Preferir:

```ruby
@club.tournaments.build(tournament_params)
```

em vez de:

```ruby
Tournament.new(
  tournament_params.merge(club_id: @club.id)
)
```

Preferir:

```ruby
current_user.clubs.find(params[:id])
```

em vez de:

```ruby
Club.find(params[:id])
```

quando for necessário verificar acesso.

Associações devem possuir:

* nomes claros;
* `dependent` quando necessário;
* foreign keys;
* índices apropriados;
* validações de integridade.

---

## 12. Consultas Active Record

Preferir consultas claras e encadeadas.

Exemplo:

```ruby
@clubs = current_user.clubs.order(created_at: :desc)
```

Evitar carregar registros desnecessários.

Evitar:

```ruby
Club.all.select do |club|
  club.members.include?(current_user)
end
```

Preferir uma associação ou consulta ao banco.

Utilizar `includes` quando houver risco real de N+1.

Não adicionar `includes` preventivamente em todas as consultas.

---

## 13. Segurança nas consultas

Nunca confiar apenas no ID enviado pela URL.

Evitar:

```ruby
@tournament = Tournament.find(params[:id])
```

Preferir:

```ruby
@tournament = @club.tournaments.find(params[:id])
```

O acesso deve seguir a cadeia autorizada:

```text
current_user
    ↓
ClubMembership
    ↓
Club
    ↓
Tournament
```

---

## 14. Strong Parameters

Todos os parâmetros recebidos devem ser filtrados.

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

Não permitir campos sensíveis sem necessidade:

```ruby
:user_id
:club_id
:owner_id
:role
```

Esses valores devem ser definidos pelo backend.

---

## 15. Tratamento de sucesso e erro

Em caso de sucesso:

```ruby
redirect_to @tournament,
            notice: "Torneio criado com sucesso."
```

Em caso de erro de validação:

```ruby
render :new,
       status: :unprocessable_entity
```

Para exclusões:

```ruby
redirect_to clubs_path,
            notice: "Clube excluído com sucesso.",
            status: :see_other
```

Mensagens devem ser:

* diretas;
* consistentes;
* compreensíveis;
* escritas em português.

---

## 16. Exceções

Não utilizar `rescue` genérico para esconder erros.

Evitar:

```ruby
rescue StandardError
  redirect_to root_path
end
```

Caso uma exceção precise ser tratada:

* utilizar uma exceção específica;
* registrar o problema;
* definir uma resposta adequada;
* não esconder falhas inesperadas.

Métodos com `save!`, `create!` ou `update!` devem ser utilizados quando a falha deve interromper o fluxo.

Métodos sem `!` devem ser usados quando o erro será tratado por condição.

---

## 17. Transações

Utilizar transação quando várias operações precisam ser concluídas juntas.

Exemplo:

```ruby
ApplicationRecord.transaction do
  @club.save!

  @club.club_memberships.create!(
    user: current_user,
    role: :owner
  )
end
```

Se uma operação falhar, nenhuma alteração parcial deve permanecer no banco.

Não utilizar transação para uma única operação simples.

---

## 18. Callbacks

Evitar callbacks para fluxos importantes.

Callbacks podem ser usados para comportamentos simples e diretamente ligados ao Model.

Evitar callbacks para:

* criar vários registros;
* alterar permissões;
* enviar notificações importantes;
* finalizar torneios;
* calcular premiações;
* executar ações em vários Models.

Fluxos importantes devem ser explícitos no código.

---

## 19. Services

Não criar Service Object automaticamente.

Um Service pode ser considerado quando:

* vários Models participam da operação;
* existe uma sequência complexa;
* há necessidade de transação;
* existe integração externa;
* a regra não pertence claramente a um Model;
* o Controller está acumulando regra de negócio.

Exemplo de operação que pode justificar um Service:

```text
Finalizar torneio
├── definir posições
├── calcular premiação
├── atualizar jogadores
├── salvar resultados
└── atualizar ranking
```

Não criar Service apenas para chamar:

```ruby
record.save
```

---

## 20. Views ERB

Views devem conter apenas lógica simples de apresentação.

Aceitável:

```erb
<% if @tournament.active? %>
  <span>Torneio em andamento</span>
<% end %>
```

Evitar:

* consultas Active Record extensas;
* cálculos complexos;
* criação de registros;
* regras de autorização completas;
* lógica duplicada;
* grandes blocos Ruby.

Dados necessários devem ser preparados pelo Controller ou pelo Model adequado.

---

## 21. Partials

Criar partial quando:

* o bloco for reutilizado;
* a View estiver ficando difícil de ler;
* o elemento representar um componente claro;
* houver responsabilidade visual própria.

Exemplo:

```text
app/views/shared/components/buttons/_button_create.html.erb
```

Não criar partial para cada pequena `div`.

O nome do partial deve representar sua função.

---

## 22. Locals em partials

Passar dados explicitamente.

Preferir:

```erb
<%= render "shared/components/club_card",
           club: club %>
```

Dentro do partial:

```erb
<h3><%= club.name %></h3>
```

Evitar depender de variáveis de instância escondidas quando o componente pode receber um local.

Isso torna o partial mais previsível e reutilizável.

---

## 23. Formulários

Utilizar Simple Form conforme o padrão do projeto.

O formulário deve:

* exibir erros;
* usar labels claros;
* utilizar a variável preparada pelo Controller;
* enviar dados apenas para a rota correta;
* não enviar IDs ou papéis sensíveis;
* funcionar em criação e edição quando apropriado.

Exemplo:

```erb
<%= simple_form_for [@club, @tournament] do |form| %>
  <%= form.input :name %>
  <%= form.input :starts_at %>
  <%= form.submit "Criar torneio" %>
<% end %>
```

---

## 24. HTML

Utilizar HTML semântico quando fizer sentido.

Exemplos:

```html
<header>
<main>
<section>
<article>
<nav>
<footer>
```

Evitar utilizar apenas `div` quando existe uma tag semântica adequada.

A estrutura deve representar claramente os blocos da página.

---

## 25. Classes CSS

As classes devem possuir nomes claros e relacionados ao componente.

Exemplo:

```scss
.tournament-card
.tournament-card__header
.tournament-card__title
.tournament-card__actions
```

Evitar nomes genéricos:

```scss
.box
.content
.left
.blue
.big
```

Não utilizar IDs para estilização.

Preferir classes.

---

## 26. Organização do SCSS

Estilos de páginas devem ficar em arquivos de páginas.

Exemplo:

```text
app/assets/stylesheets/pages/tournaments/_new.scss
```

Estilos reutilizáveis devem ficar em componentes.

Exemplo:

```text
app/assets/stylesheets/components/_tournament_card.scss
```

Evitar:

* estilos inline;
* duplicação;
* `!important`;
* seletores muito profundos;
* regras globais sem necessidade;
* alterar componentes compartilhados para corrigir apenas uma página.

---

## 27. Responsividade

Toda View deve ser verificada em:

* desktop;
* tablet;
* celular.

Deve-se observar:

* largura dos componentes;
* overflow;
* quebra de texto;
* tamanho dos botões;
* espaçamento;
* imagens;
* formulários;
* grids;
* scroll horizontal.

Evitar larguras fixas que causem quebra em telas pequenas.

Preferir:

```scss
width: 277px;
max-width: 100%;
box-sizing: border-box;
```

Quando o componente precisar respeitar o container.

---

## 28. Stimulus

Utilizar Stimulus apenas para comportamento interativo no frontend.

Exemplos:

* abrir menu;
* fechar modal;
* mover carrossel;
* alternar tabs;
* atualizar campos visuais;
* controlar elementos do timer.

Estrutura recomendada:

```html
<div data-controller="dropdown">
  <button data-action="click->dropdown#toggle">
    Abrir
  </button>

  <div data-dropdown-target="menu">
  </div>
</div>
```

Stimulus não deve substituir regras do backend.

Autorização, persistência e validação devem continuar no Rails.

---

## 29. JavaScript

O JavaScript deve:

* possuir responsabilidade clara;
* evitar manipulação global desnecessária;
* usar targets e actions do Stimulus;
* possuir nomes descritivos;
* não duplicar regras do backend;
* limpar timers ou listeners quando necessário.

Evitar JavaScript inline nas Views.

---

## 30. Rotas

Criar apenas as rotas necessárias.

Preferir rotas RESTful:

```ruby
resources :clubs do
  resources :tournaments
end
```

Para ações específicas, utilizar `member` ou `collection` quando adequado:

```ruby
resources :tournaments do
  member do
    patch :pause_clock
  end
end
```

Não criar rotas genéricas sem relação clara com uma action.

---

## 31. Migrations

Toda mudança no banco deve utilizar uma nova migration.

Não alterar migration antiga já executada.

As migrations devem:

* possuir nome descritivo;
* utilizar tipos corretos;
* adicionar foreign keys;
* adicionar índices;
* definir `null: false` quando necessário;
* evitar dados inconsistentes.

Exemplo:

```ruby
add_reference :tournaments,
              :club,
              null: false,
              foreign_key: true
```

Mudanças destrutivas devem ser informadas antes da execução.

---

## 32. Banco de dados

Não remover:

* tabelas;
* colunas;
* índices;
* foreign keys;

sem autorização explícita.

Antes de criar uma coluna, verificar se a informação já existe em outra entidade.

Não duplicar dados sem justificativa.

---

## 33. Testes

Os testes devem representar regras reais do produto.

Criar testes com base em:

* critérios de aceitação;
* regras de negócio;
* permissões;
* fluxos válidos;
* fluxos inválidos;
* segurança;
* falhas esperadas.

Não criar testes apenas para aumentar cobertura.

---

## 34. Model Specs

Model Specs devem testar:

* associações;
* validações;
* enums;
* métodos de negócio;
* estados importantes.

Exemplo:

```ruby
RSpec.describe Tournament, type: :model do
  it { should belong_to(:club) }
  it { should validate_presence_of(:name) }
end
```

---

## 35. Request Specs

Request Specs devem testar:

* autenticação;
* autorização;
* parâmetros;
* criação;
* atualização;
* exclusão;
* redirecionamentos;
* status HTTP;
* acesso entre clubes.

Exemplo de cenários:

```text
owner pode executar
admin possui acesso limitado
dealer possui acesso operacional
player não possui acesso administrativo
usuário externo não acessa
```

---

## 36. System Specs

System Specs devem ser usados para fluxos principais da interface.

Exemplos:

* criar clube;
* criar torneio;
* aceitar convite;
* realizar check-in;
* operar o clock.

Não criar System Specs para cada pequena variação quando Request Specs forem suficientes.

---

## 37. Organização dos testes

Os testes devem seguir a estrutura do projeto.

Exemplo:

```text
spec/
├── models/
├── requests/
├── system/
├── factories/
└── services/
```

O nome do teste deve explicar o comportamento esperado.

Preferir:

```ruby
it "não permite que player crie um torneio"
```

em vez de:

```ruby
it "funciona corretamente"
```

---

## 38. Factories

Factories devem criar apenas os dados necessários.

Evitar factories com muitos dados automáticos e relacionamentos escondidos.

Utilizar traits para estados específicos.

Exemplo:

```ruby
factory :club_membership do
  user
  club
  role { :player }

  trait :owner do
    role { :owner }
  end
end
```

---

## 39. Qualidade dos testes

Um bom teste deve possuir:

* contexto claro;
* preparação mínima;
* uma expectativa principal;
* nome explicativo;
* independência de outros testes.

Evitar testes que dependam da ordem de execução.

Evitar múltiplos comportamentos diferentes dentro do mesmo teste.

---

## 40. Comandos de teste

Antes de finalizar uma alteração, executar os testes relacionados.

Exemplo:

```bash
bundle exec rspec spec/models/tournament_spec.rb
```

```bash
bundle exec rspec spec/requests/tournaments_spec.rb
```

Quando necessário, executar toda a suíte:

```bash
bundle exec rspec
```

A IA deve informar:

* comando executado;
* quantidade de testes;
* falhas encontradas;
* correções realizadas;
* resultado final.

---

## 41. RuboCop e formatação

Caso o projeto utilize RuboCop, executar nos arquivos alterados.

Exemplo:

```bash
bundle exec rubocop app/models/tournament.rb
```

Não alterar automaticamente arquivos fora do escopo.

Não adicionar RuboCop ao projeto sem aprovação.

---

## 42. Comentários no código

Comentários devem explicar o motivo, não repetir o código.

Evitar:

```ruby
# Salva o torneio
@tournament.save
```

Aceitável:

```ruby
# Mantém a criação do clube e do membership na mesma transação
ApplicationRecord.transaction do
```

Não utilizar comentários para compensar nomes ruins.

---

## 43. Documentação

Atualizar documentação quando a alteração mudar:

* arquitetura;
* models;
* relacionamentos;
* permissões;
* regras de negócio;
* fluxo principal;
* decisão técnica importante.

Não atualizar documentos sem relação com a User Story.

---

## 44. Logs e depuração

Não deixar no código:

```ruby
puts
p
pp
binding.irb
byebug
console.log
```

Esses recursos podem ser utilizados durante a investigação, mas devem ser removidos antes da conclusão.

---

## 45. Gems

Não adicionar gem sem:

* explicar o problema;
* justificar a necessidade;
* verificar se o Rails já oferece solução;
* informar impacto;
* receber aprovação.

Evitar dependências para resolver problemas simples.

---

## 46. Git

Cada User Story deve ser desenvolvida em uma branch própria.

Padrões sugeridos:

```text
feature/create-tournament
feature/tournament-clock
fix/club-authorization
refactor/tournament-controller
```

Não fazer commit automaticamente sem autorização.

Antes de sugerir o commit:

* revisar o diff;
* executar testes;
* verificar arquivos não relacionados;
* confirmar ausência de código de depuração.

---

## 47. Commits

As mensagens devem ser claras e objetivas.

Utilizar preferencialmente Conventional Commits.

Exemplos:

```text
feat(tournaments): add tournament creation flow
```

```text
fix(clubs): prevent unauthorized club editing
```

```text
test(tournaments): cover tournament creation permissions
```

```text
refactor(clubs): simplify membership authorization
```

Não utilizar mensagens genéricas:

```text
ajustes
alterações
correção
novo código
```

---

## 48. Separação de commits

Uma funcionalidade pequena pode utilizar um único commit.

Uma funcionalidade maior pode ser separada em:

```text
feat(tournaments): add tournament backend
feat(tournaments): add tournament creation interface
test(tournaments): cover creation flow
```

Não separar commits apenas por arquivo.

Separar por mudança lógica.

---

## 49. Revisão antes da entrega

Antes de considerar uma User Story pronta, verificar:

* critérios de aceitação;
* regras de negócio;
* permissões;
* fluxo MVC;
* validações;
* strong parameters;
* consultas seguras;
* tratamentos de erro;
* responsividade;
* testes;
* código de depuração;
* arquivos fora do escopo;
* documentação necessária.

---

## 50. Apresentação das alterações

Após implementar, a IA deve apresentar:

### Arquivos criados

Lista de novos arquivos.

### Arquivos alterados

Lista de arquivos modificados.

### Resumo técnico

Explicação objetiva do que foi implementado em cada arquivo.

### Fluxo da funcionalidade

Explicação da conexão entre:

```text
Route
→ Controller
→ Model
→ Banco
→ View
```

### Testes

Informar:

* arquivos de teste;
* critérios cobertos;
* comandos executados;
* resultado obtido;
* critérios não cobertos.

### Pendências

Informar dúvidas, limitações ou riscos restantes.

---

## 51. Uso da IA

A IA deve:

* analisar antes de alterar;
* consultar os documentos do projeto;
* entender o código existente;
* apresentar um plano;
* aguardar aprovação quando solicitado;
* implementar somente o escopo aprovado;
* mostrar o diff;
* executar testes;
* explicar o fluxo técnico;
* sugerir commits.

A IA não deve:

* inventar regras de negócio;
* alterar arquitetura sem informar;
* adicionar gems sem aprovação;
* remover dados;
* modificar arquivos fora do escopo;
* fazer commit sem autorização;
* esconder falhas de teste;
* afirmar que testou sem executar os testes.

---

## 52. Regra final

Toda implementação deve seguir esta ordem:

1. Ler a User Story.
2. Ler os documentos relacionados.
3. Analisar o código existente.
4. Identificar o fluxo MVC.
5. Identificar regras e permissões.
6. Apresentar o plano.
7. Implementar após aprovação.
8. Criar ou atualizar testes.
9. Executar os testes.
10. Revisar o diff.
11. Explicar as alterações.
12. Sugerir os commits.
