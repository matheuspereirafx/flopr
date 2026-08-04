# AGENTS.md

## 1. Projeto

O Flopr é uma aplicação Ruby on Rails para gerenciamento de clubes de poker e torneios privados.

O sistema permite que usuários criem e participem de clubes, organizem torneios, aceitem convites, realizem inscrições, operem torneios e acompanhem o clock.

O projeto segue o padrão MVC do Ruby on Rails.

---

## 2. Stack

* Ruby 3.3.5
* Ruby on Rails 8.1
* PostgreSQL
* Devise
* Simple Form
* Stimulus
* Importmap
* SCSS
* RSpec

Não adicionar gems ou dependências sem autorização.

---

## 3. Documentação do projeto

Antes de analisar ou implementar uma funcionalidade, consulte os documentos relacionados:

* `docs/product.md`: visão do produto, usuários e funcionalidades;
* `docs/architecture.md`: arquitetura técnica e responsabilidades;
* `docs/database.md`: Models, tabelas e relacionamentos;
* `docs/permissions.md`: papéis e regras de autorização;
* `docs/coding-standards.md`: padrões de desenvolvimento;
* `docs/user-stories/`: requisitos e critérios de aceitação.

O arquivo da User Story atual deve ser considerado a principal fonte de escopo da funcionalidade.

Caso exista conflito entre documentos, informe o conflito antes de implementar.

Não invente regras de negócio que não estejam documentadas.

---

## 4. Processo de trabalho

Cada User Story deve ser trabalhada em:

* uma conversa própria;
* uma branch própria;
* um escopo definido;
* um conjunto de alterações relacionado.

Antes de alterar qualquer arquivo:

1. Leia este `AGENTS.md`.
2. Leia a User Story indicada.
3. Consulte os documentos relacionados.
4. Verifique a branch atual.
5. Analise o código existente.
6. Analise rotas, Models, Controllers, Views e schema relacionados.
7. Identifique regras de negócio e permissões.
8. Apresente um plano de implementação.
9. Liste os arquivos que serão criados ou alterados.
10. Aguarde aprovação quando isso for solicitado.

Não implemente durante a etapa de análise.

---

## 5. Branches

Cada funcionalidade deve utilizar uma branch própria.

Padrões:

```text
feature/create-tournament
feature/tournament-clock
feature/accept-invitation
fix/club-authorization
refactor/tournament-controller
```

Antes da primeira alteração:

1. verifique a branch atual;
2. crie a branch solicitada, quando necessário;
3. mude para a nova branch;
4. confirme a branch ativa.

Não realizar commit automaticamente.

Não enviar alterações para o repositório remoto sem autorização.

---

## 6. Planejamento da implementação

O planejamento deve ser objetivo, mas suficiente para explicar tecnicamente a solução.

Para funcionalidades de backend, apresente:

* fluxo da requisição;
* rotas necessárias;
* Models envolvidos;
* relacionamentos;
* validações;
* migration necessária;
* actions do Controller;
* strong parameters;
* regras de autenticação;
* regras de autorização;
* arquivos criados ou alterados;
* testes necessários;
* riscos e dúvidas.

Explique o fluxo esperado:

```text
Route
→ Controller
→ Model
→ Banco de dados
→ Controller
→ View ou redirecionamento
```

Não implementar até o plano ser aprovado quando o usuário solicitar aprovação.

---

## 7. Implementação do backend

Quando o plano for aprovado, implemente somente o escopo autorizado.

O backend pode envolver:

* migrations;
* Models;
* associações;
* validações;
* enums;
* rotas;
* Controllers;
* autenticação;
* autorização;
* strong parameters;
* testes.

Não implementar Views, SCSS ou Stimulus durante a etapa de backend, salvo autorização explícita.

Não realizar refatorações fora do escopo.

Não alterar regras existentes sem informar.

---

## 8. Arquitetura MVC

### Models

Models são responsáveis por:

* associações;
* validações;
* enums;
* regras de negócio;
* estados da entidade;
* consultas relacionadas ao domínio.

Models não devem controlar:

* renderização;
* redirecionamentos;
* parâmetros HTTP;
* comportamento visual.

### Controllers

Controllers são responsáveis por:

* receber requisições;
* autenticar o usuário;
* buscar registros;
* verificar autorização;
* executar operações;
* renderizar Views;
* redirecionar;
* apresentar mensagens.

Controllers devem ser pequenos e objetivos.

Não colocar HTML ou regras de negócio extensas nos Controllers.

### Views

Views são responsáveis por:

* apresentar informações;
* renderizar formulários;
* exibir mensagens;
* renderizar partials;
* disponibilizar ações ao usuário.

Não colocar consultas extensas, persistência ou regras de negócio importantes nas Views.

---

## 9. Permissões

Todas as permissões são controladas pelo `ClubMembership`.

Papéis atuais:

```text
owner
admin
dealer
player
```

Não criar o model `TournamentStaff`.

O papel de um usuário pode ser diferente em cada clube.

Exemplo:

```text
Usuário A
├── Clube 1: owner
├── Clube 2: dealer
└── Clube 3: player
```

### Owner

Possui acesso completo ao clube e aos torneios.

Pode administrar, editar, excluir, configurar, operar e também participar como jogador quando estiver inscrito.

### Admin

Possui acesso administrativo e operacional limitado.

As limitações devem ser definidas na User Story correspondente.

### Dealer

Possui acesso operacional aos torneios do clube.

Pode acessar funções relacionadas ao torneio e ao clock, incluindo pausar o timer conforme as regras da funcionalidade.

Não possui acesso administrativo ao clube.

### Player

Possui acesso às funcionalidades de jogo.

Pode receber e aceitar convites, realizar inscrição, check-in, participar e visualizar informações permitidas.

Não pode executar ações administrativas.

Consulte sempre:

```text
docs/permissions.md
```

---

## 10. Participação no torneio

O `ClubMembership` define as permissões do usuário no clube.

A participação do usuário como jogador em um torneio deve ser controlada por uma entidade própria, como:

```text
TournamentRegistration
```

Ter o papel de owner, admin ou dealer não significa automaticamente estar inscrito no torneio.

---

## 11. Clock do torneio

O estado do timer deve ser controlado por uma entidade própria, como:

```text
TournamentClockState
```

Essa entidade pode controlar:

* estado do timer;
* tempo restante;
* horário de início;
* momento da pausa;
* nível atual;
* status do clock.

As permissões para operar o clock continuam sendo verificadas pelo papel do usuário no `ClubMembership`.

---

## 12. Segurança e autorização

Toda funcionalidade privada deve verificar:

* usuário autenticado;
* participação no clube;
* papel do usuário;
* associação correta entre clube e recurso;
* acesso entre clubes diferentes;
* parâmetros sensíveis;
* permissões da ação.

Não confiar apenas no ID recebido pela URL.

Evitar:

```ruby
@club = Club.find(params[:id])
```

Quando for necessário validar a participação do usuário.

Preferir:

```ruby
@club = current_user.clubs.find(params[:id])
```

Para recursos do clube:

```ruby
@tournament = @club.tournaments.find(params[:id])
```

A autorização deve existir no backend.

Esconder um botão na View não protege uma rota.

---

## 13. Strong Parameters

Todos os parâmetros devem ser filtrados.

Não utilizar:

```ruby
params.permit!
```

Não permitir diretamente campos sensíveis, como:

```text
user_id
club_id
owner_id
role
```

Esses valores devem ser definidos pelo backend quando possível.

---

## 14. Banco de dados

Toda alteração estrutural deve ser feita por uma nova migration.

Não alterar migrations antigas já executadas.

Não remover:

* tabelas;
* colunas;
* índices;
* foreign keys;
* dados;

sem autorização explícita.

Relacionamentos devem utilizar foreign keys e índices quando apropriado.

Mudanças destrutivas devem ser informadas antes da execução.

---

## 15. Transações

Utilize transações quando várias operações precisarem ser concluídas juntas.

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

Se uma operação falhar, não devem permanecer registros parciais.

Não criar transações para uma única operação simples.

---

## 16. Services

Não criar Service Objects automaticamente.

Considere um Service apenas quando:

* vários Models participarem do fluxo;
* houver várias etapas dependentes;
* existir uma operação transacional complexa;
* houver integração externa;
* a regra não pertencer claramente a um Model;
* o Controller estiver acumulando lógica extensa.

Não criar Service para apenas executar:

```ruby
record.save
```

---

## 17. Frontend

Antes de implementar uma interface:

1. analise a imagem ou referência visual;
2. consulte os estilos existentes;
3. consulte os componentes existentes;
4. consulte `docs/coding-standards.md`;
5. apresente a composição da página;
6. mostre a hierarquia dos blocos;
7. explique a função de cada elemento;
8. explique a conexão com o backend;
9. informe quais arquivos serão alterados;
10. aguarde aprovação quando solicitado.

A análise deve mostrar uma estrutura semelhante a:

```text
tournament-page
├── tournament-header
├── tournament-information
├── tournament-actions
├── tournament-players
└── tournament-clock
```

Não implementar durante a etapa de análise da View.

---

## 18. Views e partials

Utilize ERB e Simple Form conforme os padrões existentes.

Crie partials quando:

* o elemento for reutilizado;
* representar um componente claro;
* melhorar a organização da View.

Não criar partial para cada pequena `div`.

Passe dados explicitamente por locals:

```erb
<%= render "shared/components/club_card",
           club: club %>
```

Evite depender de variáveis de instância escondidas dentro de componentes reutilizáveis.

---

## 19. HTML e organização visual

Utilize HTML semântico quando adequado:

```text
header
main
section
article
nav
footer
```

As classes CSS devem representar a função do elemento.

Preferir:

```text
tournament-card
tournament-card__header
tournament-card__title
tournament-card__actions
```

Evitar nomes genéricos como:

```text
box
content
left
big
blue
```

---

## 20. SCSS

Estilos específicos de páginas devem ficar em arquivos de páginas.

Estilos reutilizáveis devem ficar em componentes.

Evitar:

* estilos inline;
* `!important`;
* duplicação;
* seletores excessivamente profundos;
* alteração de estilos globais sem necessidade;
* modificar um componente compartilhado para corrigir apenas uma tela.

Toda interface deve ser responsiva para desktop, tablet e celular.

---

## 21. Stimulus

Utilize Stimulus para comportamentos interativos no navegador.

Exemplos:

* menus;
* modais;
* tabs;
* scroll horizontal;
* filtros visuais;
* campos condicionais;
* clock;
* pausa e retomada visual do timer.

Stimulus não substitui:

* autorização;
* validações;
* persistência;
* regras de negócio do backend.

Não utilizar JavaScript inline nas Views.

---

## 22. Testes

Os testes devem seguir:

* regras de negócio;
* critérios de aceitação;
* permissões;
* fluxos válidos;
* fluxos inválidos;
* segurança.

Cada critério de aceitação deve estar coberto por pelo menos um teste quando aplicável.

### Model Specs

Devem testar:

* associações;
* validações;
* enums;
* métodos de negócio;
* estados importantes.

### Request Specs

Devem testar:

* autenticação;
* autorização;
* criação;
* atualização;
* exclusão;
* parâmetros;
* status HTTP;
* redirecionamentos;
* acesso entre clubes;
* tentativa de manipulação de IDs.

### System Specs

Devem testar os principais fluxos pela interface.

Exemplos:

* criar clube;
* criar torneio;
* aceitar convite;
* realizar check-in;
* operar o clock.

Não criar System Specs desnecessários quando um Request Spec for suficiente.

---

## 23. Testes de permissão

Quando uma ação possuir acesso restrito, teste os papéis relacionados:

```text
owner
admin
dealer
player
usuário não autenticado
usuário que não pertence ao clube
```

Também devem ser considerados:

* clube de outro usuário;
* torneio de outro clube;
* alteração de IDs na URL;
* acesso direto à rota;
* envio de papel pelo formulário;
* parâmetros não permitidos.

---

## 24. Execução dos testes

Após implementar, execute primeiro os testes relacionados.

Exemplos:

```bash
bundle exec rspec spec/models/tournament_spec.rb
```

```bash
bundle exec rspec spec/requests/tournaments_spec.rb
```

Quando necessário:

```bash
bundle exec rspec
```

Nunca afirmar que os testes foram executados sem realmente executá-los.

Informe:

* comando executado;
* quantidade de testes;
* resultado;
* falhas encontradas;
* correções realizadas;
* critérios ainda não cobertos.

---

## 25. Revisão das alterações

Após implementar:

1. revise o diff completo;
2. verifique arquivos fora do escopo;
3. remova código de depuração;
4. verifique segurança;
5. verifique critérios de aceitação;
6. execute os testes relacionados;
7. informe pendências.

Não deixar no código:

```text
puts
p
pp
binding.irb
byebug
console.log
```

---

## 26. Apresentação da entrega

Ao concluir uma etapa, apresente:

### Arquivos criados

Liste os novos arquivos.

### Arquivos alterados

Liste os arquivos modificados.

### Resumo técnico

Explique objetivamente o que mudou em cada arquivo.

### Fluxo da funcionalidade

Explique:

```text
Route
→ Controller
→ Model
→ Banco
→ View ou redirecionamento
```

### Testes

Informe:

* arquivos de teste;
* critérios cobertos;
* comandos executados;
* resultado;
* critérios não cobertos.

### Pendências

Informe dúvidas, limitações ou riscos restantes.

---

## 27. Commits

Não realizar commit automaticamente.

Após aprovação da entrega:

1. analise o diff;
2. verifique os testes;
3. sugira uma ou mais mensagens de commit;
4. informe quais arquivos entrarão;
5. explique se deve ser um commit único ou dividido.

Utilize preferencialmente Conventional Commits.

Exemplos:

```text
feat(tournaments): add tournament creation flow
```

```text
fix(clubs): prevent unauthorized club editing
```

```text
test(tournaments): cover tournament permissions
```

Não utilizar mensagens genéricas como:

```text
ajustes
alterações
correções
novo código
```

Somente realize o commit após autorização explícita.

Não execute `git push` sem autorização explícita.

---

## 28. Restrições

A IA não deve:

* inventar regras de negócio;
* implementar antes da aprovação quando ela for exigida;
* alterar arquitetura sem informar;
* adicionar gems sem autorização;
* remover dados sem autorização;
* alterar arquivos fora do escopo;
* fazer commits automaticamente;
* executar push automaticamente;
* esconder falhas de testes;
* afirmar que executou algo sem executar;
* criar `TournamentStaff`;
* realizar grandes refatorações durante uma User Story;
* modificar documentação sem relação com a alteração.

---

## 29. Regra final

Toda User Story deve seguir este fluxo:

```text
Ler AGENTS.md
        ↓
Ler a User Story
        ↓
Consultar documentação
        ↓
Analisar código existente
        ↓
Verificar branch
        ↓
Planejar Routes, Models e Controllers
        ↓
Apresentar arquivos envolvidos
        ↓
Aguardar aprovação
        ↓
Implementar backend
        ↓
Criar e executar testes
        ↓
Apresentar alterações
        ↓
Planejar a View
        ↓
Explicar a conexão com o backend
        ↓
Aguardar aprovação
        ↓
Implementar frontend
        ↓
Revisar critérios e diff
        ↓
Executar testes finais
        ↓
Sugerir commits
        ↓
Realizar commit somente após autorização
```
