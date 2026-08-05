# Backlog e Critérios de Aceite — Flopr

## Regras gerais

* Todas as áreas privadas exigem autenticação.
* As permissões são determinadas pelo `ClubMembership`.
* Os papéis do clube são `owner`, `admin`, `dealer` e `player`.
* Não será criado o model `TournamentStaff`.
* O acesso aos recursos deve respeitar o clube atual.
* O usuário não pode acessar dados de outro clube alterando IDs na URL.
* Participar de um clube não significa estar inscrito em um torneio.
* A participação em torneios será controlada pelo `TournamentRegistration`.
* Os critérios específicos da User Story prevalecem sobre regras genéricas.

---

# Épico 1 — Autenticação e conta

## US-001 — Criar conta

**Como visitante, quero criar uma conta para acessar o Flopr.**

### Critérios de aceite

* O visitante deve conseguir acessar a página de cadastro.
* Nome, e-mail e senha devem ser informados conforme as validações do sistema.
* O e-mail não pode estar cadastrado em outra conta.
* A senha deve atender aos requisitos mínimos definidos pelo Devise.
* Dados inválidos devem manter o formulário preenchido e exibir os erros.
* Após o cadastro válido, a conta deve ser criada.
* O usuário deve ser direcionado ao fluxo inicial do sistema.

---

## US-002 — Fazer login

**Como usuário cadastrado, quero entrar na minha conta.**

### Critérios de aceite

* O usuário deve conseguir acessar a tela de login.
* O login deve aceitar credenciais válidas.
* Credenciais inválidas não devem autenticar o usuário.
* Uma mensagem de erro deve ser apresentada quando o login falhar.
* Após autenticar, o usuário deve ser direcionado à área privada.
* Um usuário autenticado não deve precisar fazer login novamente durante a sessão válida.

---

## US-003 — Recuperar senha

**Como usuário, quero recuperar minha senha caso a esqueça.**

### Critérios de aceite

* O usuário deve conseguir solicitar recuperação informando seu e-mail.
* O sistema não deve revelar publicamente se determinado e-mail existe.
* Um token de recuperação deve possuir validade limitada.
* O link válido deve permitir definir uma nova senha.
* A nova senha deve respeitar as validações da conta.
* Após a alteração, a senha antiga não deve mais autenticar o usuário.

---

## US-004 — Editar conta

**Como usuário autenticado, quero editar meus dados de conta.**

### Critérios de aceite

* Somente o próprio usuário pode editar sua conta.
* Os dados atuais devem aparecer preenchidos no formulário.
* Alterações válidas devem ser salvas.
* Alterações inválidas devem exibir mensagens de erro.
* A troca de e-mail deve respeitar a exclusividade do endereço.
* A troca de senha deve seguir as regras de segurança do Devise.
* Após salvar, o usuário deve visualizar uma confirmação.

---

## US-005 — Encerrar sessão

**Como usuário autenticado, quero sair da minha conta.**

### Critérios de aceite

* O usuário autenticado deve visualizar a opção de sair.
* Ao sair, a sessão deve ser encerrada.
* Após encerrar a sessão, páginas privadas não devem continuar acessíveis.
* O usuário deve ser direcionado para uma página pública ou para o login.

---

# Épico 2 — Gestão de clubes

## US-006 — Visualizar meus clubes

**Como usuário, quero visualizar os clubes dos quais participo.**

### Critérios de aceite

* A página deve exibir apenas clubes relacionados ao usuário atual.
* O papel do usuário em cada clube deve ser respeitado.
* Clubes de outros usuários não devem aparecer.
* Cada clube deve possuir uma ação para acessar sua página.
* Quando não houver clubes, deve ser exibido um estado vazio.
* O owner deve visualizar também os clubes que criou.

---

## US-007 — Criar clube

**Como usuário, quero criar um clube.**

### Critérios de aceite

* Um usuário autenticado deve conseguir acessar o formulário.
* O nome do clube deve ser obrigatório.
* Dados inválidos não devem criar o clube.
* O clube e o `ClubMembership` do owner devem ser criados na mesma transação.
* O usuário que criou o clube deve receber o papel `owner`.
* Não deve existir clube salvo sem o membership inicial.
* Após criar, o usuário deve ser redirecionado para a página definida no fluxo.
* Uma mensagem de sucesso deve ser exibida.

---

## US-008 — Visualizar clube

**Como membro, quero acessar a página de um clube.**

### Critérios de aceite

* Apenas usuários relacionados ao clube podem acessar sua página privada.
* A página deve exibir nome e informações principais do clube.
* A página deve apresentar os torneios permitidos ao usuário.
* As ações administrativas devem aparecer somente para papéis autorizados.
* Alterar o ID da URL não deve permitir acesso a outro clube.
* Um usuário sem membership deve receber uma resposta segura.

---

## US-009 — Editar clube

**Como owner, quero editar o clube.**

### Critérios de aceite

* Apenas o owner deve possuir acesso completo à edição.
* O admin poderá editar somente campos definidos nas histórias específicas.
* Dealer e player não podem editar o clube.
* Os dados atuais devem aparecer preenchidos.
* Alterações válidas devem ser salvas.
* Dados inválidos devem renderizar novamente o formulário.
* O `owner_id`, o papel e outros campos sensíveis não podem ser alterados pelo formulário.
* Uma mensagem de sucesso deve ser apresentada.

---

## US-010 — Excluir clube

**Como owner, quero excluir um clube.**

### Critérios de aceite

* Apenas o owner pode excluir o clube.
* Admin, dealer e player não podem excluir.
* A exclusão deve exigir confirmação.
* Recursos dependentes devem seguir a estratégia definida no banco.
* O usuário não pode excluir clubes de terceiros.
* Após excluir, o usuário deve ser redirecionado para seus clubes.
* Uma mensagem de confirmação deve ser exibida.

---

# Épico 3 — Membros e papéis do clube

## US-011 — Convidar usuário para o clube

**Como owner ou admin autorizado, quero convidar um usuário.**

### Critérios de aceite

* Owner deve poder enviar convites.
* Admin só poderá convidar quando essa permissão estiver habilitada.
* Dealer e player não podem convidar membros.
* O convite deve ser associado ao clube correto.
* Não deve ser criado membership definitivo antes da aceitação.
* Um usuário já participante não deve receber convite duplicado ativo.
* O convite deve possuir status pendente.
* O convidado deve conseguir identificar o clube que enviou o convite.

---

## US-012 — Aceitar convite do clube

**Como usuário convidado, quero aceitar o convite.**

### Critérios de aceite

* Apenas o usuário destinatário pode aceitar.
* O convite deve estar pendente e válido.
* A aceitação deve criar um `ClubMembership`.
* O papel inicial deve ser definido pelo backend.
* O convite deve mudar para aceito.
* Aceitar novamente não deve criar membership duplicado.
* Após aceitar, o usuário deve acessar o clube conforme seu papel.

---

## US-013 — Recusar convite do clube

**Como usuário convidado, quero recusar um convite.**

### Critérios de aceite

* Apenas o destinatário pode recusar.
* Somente convites pendentes podem ser recusados.
* A recusa não deve criar `ClubMembership`.
* O status deve mudar para recusado.
* Um convite recusado não pode ser aceito sem uma nova ação permitida.
* O usuário deve receber confirmação da recusa.

---

## US-014 — Visualizar membros do clube

**Como owner ou admin, quero visualizar os membros.**

### Critérios de aceite

* Owner deve visualizar todos os membros e seus papéis.
* Admin deve visualizar as informações permitidas.
* Dealer e player não devem visualizar informações administrativas restritas.
* A lista deve exibir apenas membros do clube atual.
* Deve ser possível identificar owner, admin, dealer e player.
* Convites pendentes devem ser separados de memberships ativos.
* Usuários de outros clubes não devem aparecer.

---

## US-015 — Alterar papel de um membro

**Como owner, quero alterar o papel de um membro.**

### Critérios de aceite

* Apenas owner pode alterar papéis administrativos.
* O usuário não pode alterar o próprio papel de owner pelo fluxo comum.
* Nenhum clube pode ficar sem owner.
* Um membro não pode se promover.
* O papel deve aceitar apenas valores válidos.
* A alteração deve ocorrer somente no clube atual.
* A mudança deve ser registrada e confirmada.
* A permissão atualizada deve valer nas próximas requisições.

---

## US-016 — Remover membro do clube

**Como owner ou admin autorizado, quero remover um membro.**

### Critérios de aceite

* Owner pode remover admin, dealer ou player.
* Admin somente pode remover papéis permitidos.
* Admin não pode remover owner.
* Dealer e player não podem remover membros.
* O último owner não pode ser removido.
* O membership deve pertencer ao clube atual.
* A remoção deve exigir confirmação.
* O usuário removido não deve continuar acessando o clube.

---

## US-017 — Sair de um clube

**Como membro, quero sair de um clube.**

### Critérios de aceite

* Admin, dealer e player podem solicitar saída.
* O último owner não pode sair sem transferir a propriedade.
* A saída deve exigir confirmação.
* O `ClubMembership` deve ser encerrado ou removido conforme a regra definida.
* Após sair, o usuário não deve acessar áreas privadas do clube.
* Inscrições e histórico anteriores não devem ser apagados indevidamente.

---

# Épico 4 — Gestão básica de torneios

## US-018 — Visualizar torneios do clube

**Como membro, quero visualizar os torneios do clube.**

### Critérios de aceite

* Apenas membros autorizados podem acessar a lista privada.
* A lista deve exibir somente torneios do clube atual.
* Os torneios devem apresentar status e informações básicas.
* As ações devem respeitar o papel do usuário.
* Torneios públicos podem seguir uma visualização específica.
* Quando não houver torneios, deve existir um estado vazio.

---

## US-019 — Criar torneio

**Como owner ou admin, quero criar um torneio.**

### Critérios de aceite

* Owner e admin autorizados podem acessar a criação.
* Dealer e player não podem criar torneios.
* O torneio deve ser criado por associação com o clube.
* O `club_id` não deve ser escolhido livremente no formulário.
* Nome, data e campos obrigatórios devem ser validados.
* O torneio deve iniciar com um status válido, como rascunho.
* Dados inválidos não devem criar o registro.
* Após criar, o usuário deve ser direcionado para a próxima etapa ou overview.

---

## US-020 — Visualizar overview do torneio

**Como usuário autorizado, quero visualizar o resumo do torneio.**

### Critérios de aceite

* O torneio deve ser localizado por meio do clube autorizado.
* A página deve apresentar informações gerais, status, data e local.
* Valores e regras relevantes devem ser apresentados conforme a permissão.
* A página deve mostrar atalhos para as áreas disponíveis.
* Ações administrativas devem aparecer somente para papéis autorizados.
* O player deve visualizar apenas informações permitidas.

---

## US-021 — Editar torneio

**Como owner ou admin, quero editar um torneio.**

### Critérios de aceite

* Owner possui acesso completo à edição permitida.
* Admin possui acesso limitado conforme a configuração.
* Dealer e player não podem editar dados principais.
* O torneio deve pertencer ao clube atual.
* Dados válidos devem ser atualizados.
* Dados inválidos devem manter o formulário com erros.
* Campos protegidos não devem ser modificados por parâmetros indevidos.
* Alterações bloqueadas pelo status do torneio não devem ser aceitas.

---

## US-022 — Excluir torneio

**Como owner autorizado, quero excluir um torneio.**

### Critérios de aceite

* Owner pode excluir conforme as regras do status.
* A permissão do admin deve ser explicitamente definida.
* Dealer e player e outros role fora o Owner não podem excluir.
* A exclusão deve exigir confirmação.
* O torneio deve pertencer ao clube atual.
* Após excluir, o usuário deve retornar para a lista do clube.

---

## US-023 — Alterar status do torneio

**Como owner ou admin, quero controlar o ciclo de vida do torneio.**

### Critérios de aceite

* O status deve aceitar somente valores definidos.
* Transições inválidas não devem ser permitidas.
* Owner e admin autorizados podem realizar transições.
* Dealer poderá alterar apenas estados operacionais expressamente permitidos.
* Player não pode alterar status.
* Cada mudança deve manter a integridade das inscrições e do clock.
* O sistema deve informar o status atual.
* Mudanças críticas devem ser registradas.

---

## US-024 — Navegar pelas áreas do torneio

**Como usuário autorizado, quero navegar pelas áreas do torneio.**

### Critérios de aceite

* A navegação deve conter overview, jogadores, transações, relógio e configurações.
* A área ativa deve estar identificada.
* Links devem preservar o clube e o torneio corretos.
* Opções não permitidas devem ser ocultadas.
* Rotas protegidas devem bloquear acesso direto.
* A navegação deve funcionar em desktop e mobile.
* O player deve visualizar somente as áreas permitidas.

---

# Épico 5 — Configurações financeiras

## US-025 — Configurar buy-in

**Como owner ou admin, quero definir o buy-in.**

### Critérios de aceite

* O valor deve aceitar somente números válidos.
* Valores negativos não devem ser permitidos.
* A moeda deve seguir o padrão do sistema.
* Owner e admin autorizados podem configurar.
* Dealer e player não podem configurar.
* O buy-in deve ficar associado ao torneio.
* Alterações devem respeitar o status do torneio.
* O valor deve aparecer no overview permitido.

---

## US-026 — Configurar rebuy

**Como owner ou admin, quero configurar o rebuy.**

### Critérios de aceite

* Deve ser possível habilitar ou desabilitar rebuy.
* Quando habilitado, valor e regras obrigatórias devem ser informados.
* Deve ser possível definir limite por jogador, quando aplicável.
* Deve ser possível definir até qual nível o rebuy é permitido.
* Valores negativos não devem ser aceitos.
* A configuração deve pertencer ao torneio.
* Player e dealer não podem alterar a configuração.

---

## US-027 — Configurar add-on

**Como owner ou admin, quero configurar o add-on.**

### Critérios de aceite

* Deve ser possível habilitar ou desabilitar add-on.
* Quando habilitado, valor e momento permitido devem ser definidos.
* Deve ser possível informar a quantidade de fichas correspondente.
* Valores negativos não devem ser aceitos.
* O add-on deve estar associado ao torneio.
* A solicitação só pode ocorrer no período permitido.
* Player e dealer não podem alterar a configuração.

---

## US-028 — Configurar taxa extra

**Como owner ou admin, quero configurar taxas extras.**

### Critérios de aceite

* Deve ser possível informar nome e valor da taxa.
* O nome da taxa deve ser obrigatório.
* O valor não pode ser negativo.
* A taxa deve pertencer ao torneio.
* Deve ser possível definir se a taxa é obrigatória ou opcional.
* Taxas inválidas não devem ser salvas.
* Apenas papéis administrativos autorizados podem configurar.

---

## US-029 — Criar cobrança personalizada

**Como owner ou admin, quero criar outros tipos de cobrança.**

### Critérios de aceite

* O tipo deve possuir nome, valor e descrição opcional.
* O valor deve seguir as regras monetárias.
* A cobrança deve pertencer ao torneio.
* Tipos duplicados devem seguir a regra definida.
* Deve ser possível ativar ou desativar a cobrança.
* Apenas owner ou admin autorizado pode criar.
* O tipo criado deve ficar disponível no lançamento de transações.

---

## US-030 — Editar configurações financeiras

**Como owner ou admin, quero corrigir os valores do torneio.**

### Critérios de aceite

* Somente configurações do torneio atual podem ser editadas.
* Owner possui acesso completo.
* Admin possui acesso conforme as limitações.
* Alterações após transações existentes devem seguir regra de segurança.
* Valores inválidos não devem ser salvos.
* O histórico financeiro já registrado não deve ser alterado automaticamente.
* O usuário deve receber confirmação da atualização.

---

# Épico 6 — Estrutura de blinds

## US-031 — Criar estrutura de blinds

**Como owner ou admin, quero criar a estrutura do torneio.**

### Critérios de aceite

* A estrutura deve pertencer ao torneio.
* O torneio deve possuir apenas a quantidade de estruturas ativas definida.
* Owner e admin autorizados podem criar.
* Dealer e player não podem criar.
* A estrutura deve possuir ao menos um nível antes da publicação.
* Dados inválidos não devem ser salvos.
* A estrutura deve poder ser consultada pelo clock.

---

## US-032 — Adicionar nível de blind

**Como owner ou admin, quero adicionar níveis.**

### Critérios de aceite

* Cada nível deve possuir ordem e duração válidas.
* Small blind e big blind devem aceitar valores válidos.
* O big blind não deve ser menor que o small blind.
* O nível deve pertencer à estrutura atual.
* A ordem não deve gerar duplicidade inconsistente.
* O nível deve ser exibido na sequência correta.
* Apenas papéis autorizados podem adicionar.

---

## US-033 — Editar nível de blind

**Como owner ou admin, quero editar um nível.**

### Critérios de aceite

* O nível deve pertencer ao torneio atual.
* Valores e duração devem continuar válidos.
* Alterações durante torneio ativo devem seguir restrições próprias.
* A ordem deve permanecer consistente.
* Dealer só poderá alterar quando uma história específica permitir.
* Player não pode editar.
* O clock deve refletir alterações permitidas.

---

## US-034 — Excluir nível de blind

**Como owner ou admin, quero excluir um nível.**

### Critérios de aceite

* O nível deve pertencer à estrutura atual.
* A exclusão não pode deixar uma estrutura publicada inválida.
* Nível em execução não deve ser excluído sem regra específica.
* A ordem dos níveis restantes deve permanecer consistente.
* A exclusão deve exigir confirmação.
* Dealer e player não podem excluir.

---

## US-035 — Reordenar níveis de blinds

**Como owner ou admin, quero alterar a ordem dos níveis.**

### Critérios de aceite

* Todos os níveis devem permanecer com uma posição única.
* A nova ordem deve ser salva.
* Não pode haver níveis ausentes ou duplicados na sequência.
* A reordenação deve pertencer à mesma estrutura.
* Torneios em andamento devem possuir restrições.
* O clock deve utilizar a nova ordem válida.
* Apenas papéis autorizados podem reordenar.

---

## US-036 — Configurar intervalos

**Como owner ou admin, quero adicionar intervalos.**

### Critérios de aceite

* O intervalo deve possuir duração válida.
* Deve ser possível posicioná-lo entre níveis.
* Intervalos não devem exigir blinds.
* O clock deve identificar que o item atual é um intervalo.
* O próximo nível deve ser definido corretamente.
* Apenas owner ou admin autorizado pode configurar.
* O player deve conseguir visualizar o intervalo atual.

---

## US-037 — Configurar ante

**Como owner ou admin, quero definir o ante.**

### Critérios de aceite

* O ante pode ser opcional por nível.
* O valor não pode ser negativo.
* Deve ser possível representar o tipo de ante suportado.
* O ante deve aparecer no clock e no overview do nível.
* Alterações devem respeitar o status do torneio.
* Apenas owner e admin autorizado podem configurar.

---

## US-038 — Duplicar estrutura de blinds

**Como owner ou admin, quero reutilizar uma estrutura.**

### Critérios de aceite

* Deve ser possível selecionar uma estrutura autorizada.
* Todos os níveis e intervalos devem ser copiados.
* Os registros copiados devem possuir IDs próprios.
* Alterar a cópia não deve modificar a origem.
* A cópia deve ser associada ao novo torneio ou estrutura.
* Estruturas de clubes não autorizados não podem ser copiadas.
* O usuário deve revisar a estrutura antes da publicação.

---

# Épico 7 — Convites e inscrições

## US-039 — Convidar jogador para o torneio

### Critérios de aceite

* Owner e admin autorizado podem convidar.
* O jogador deve possuir relação permitida com o clube ou seguir o fluxo definido.
* O convite deve pertencer ao torneio.
* Convites duplicados ativos não devem ser criados.
* O convite deve iniciar como pendente.
* O jogador deve conseguir visualizar o convite.
* Dealer e player não podem convidar sem permissão.

---

## US-040 — Aceitar convite do torneio

### Critérios de aceite

* Apenas o convidado pode aceitar.
* O convite deve estar pendente e dentro da validade.
* A aceitação deve criar ou atualizar o `TournamentRegistration`.
* O status deve mudar para aceito ou confirmado.
* A aceitação duplicada não deve gerar inscrições duplicadas.
* O jogador deve passar a visualizar o torneio em sua área.

---

## US-041 — Recusar convite do torneio

### Critérios de aceite

* Apenas o destinatário pode recusar.
* O convite deve estar pendente.
* A recusa não deve confirmar a inscrição.
* O status deve mudar para recusado.
* O organizador deve conseguir visualizar a resposta.
* A nova participação exigirá um novo convite ou reabertura autorizada.

---

## US-042 — Inscrever-se em torneio público

### Critérios de aceite

* O torneio deve estar público e com inscrições abertas.
* O usuário deve estar autenticado.
* A capacidade máxima deve ser respeitada.
* Inscrições duplicadas não devem ser criadas.
* O status inicial deve seguir a regra do torneio.
* Quando houver aprovação, a inscrição deve ficar pendente.
* O jogador deve receber confirmação da solicitação.

---

## US-043 — Cancelar inscrição

### Critérios de aceite

* Apenas o próprio jogador ou administrador autorizado pode cancelar.
* O cancelamento deve respeitar o prazo configurado.
* Inscrições com transações devem seguir a política financeira.
* O status deve ser atualizado sem apagar o histórico necessário.
* A vaga deve ser liberada quando aplicável.
* Torneio iniciado pode bloquear o cancelamento.

---

## US-044 — Visualizar status da inscrição

### Critérios de aceite

* O jogador deve visualizar apenas sua própria inscrição.
* O status deve indicar convite, confirmação, pagamento e check-in.
* Mudanças devem aparecer de forma atualizada.
* O status deve pertencer ao torneio correto.
* Informações administrativas restritas não devem ser expostas.

---

## US-045 — Visualizar inscritos

### Critérios de aceite

* Owner e admin visualizam a lista completa permitida.
* Dealer visualiza informações operacionais necessárias.
* Player visualiza apenas a lista pública permitida.
* Cada participante deve apresentar status relevante.
* A lista deve pertencer ao torneio atual.
* Deve ser possível diferenciar pendentes, confirmados e presentes.

---

## US-046 — Aprovar inscrição

### Critérios de aceite

* Owner e admin autorizado podem aprovar.
* A inscrição deve estar pendente.
* A capacidade máxima deve ser respeitada.
* A aprovação deve atualizar o status.
* Inscrições de outro torneio não podem ser alteradas.
* O jogador deve visualizar a aprovação.
* Aprovação duplicada não deve causar efeitos extras.

---

# Épico 8 — Check-in e presença

## US-047 — Realizar check-in como player

### Critérios de aceite

* O jogador deve possuir inscrição válida.
* O período de check-in deve estar aberto.
* O jogador só pode fazer check-in para si mesmo.
* O check-in duplicado não deve criar registros extras.
* O status da inscrição deve mudar para presente.
* O horário do check-in deve ser registrado.

---

## US-048 — Realizar check-in de um jogador

### Critérios de aceite

* Owner e admin autorizado podem registrar.
* Dealer poderá registrar se permitido.
* O jogador deve estar inscrito.
* O torneio deve aceitar check-in.
* O responsável pela ação deve ser registrado.
* Check-in duplicado deve ser tratado.
* O status deve ser atualizado imediatamente.

---

## US-049 — Visualizar jogadores presentes

### Critérios de aceite

* A lista deve exibir apenas check-ins do torneio atual.
* Owner, admin e dealer autorizado podem visualizar.
* Deve ser possível diferenciar presentes e ausentes.
* A quantidade total deve ser apresentada.
* As informações devem estar atualizadas.
* Players não devem acessar dados administrativos restritos.

---

## US-050 — Remover check-in

### Critérios de aceite

* Apenas owner ou admin autorizado pode remover.
* O check-in deve pertencer ao torneio atual.
* O status do jogador deve voltar ao estado correto.
* A remoção deve registrar o responsável.
* Torneio iniciado pode bloquear ou limitar a ação.
* O histórico não deve ser perdido quando auditoria for necessária.

---

## US-051 — Encerrar check-in

### Critérios de aceite

* Owner ou admin pode encerrar.
* Após o encerramento, players não podem realizar novo check-in.
* A equipe pode possuir uma ação excepcional, se definida.
* O estado do torneio deve refletir o encerramento.
* A ação deve exigir confirmação.
* Jogadores ausentes devem permanecer identificados.

---

# Épico 9 — Transações

## US-052 — Registrar pagamento do buy-in

### Critérios de aceite

* A transação deve estar associada ao jogador e torneio.
* O valor deve usar a configuração válida do buy-in.
* Owner ou admin autorizado pode confirmar.
* Dealer só pode confirmar se expressamente permitido.
* O responsável e horário devem ser registrados.
* Pagamento duplicado deve ser impedido ou sinalizado.
* A inscrição deve refletir a situação de pagamento.

---

## US-053 — Confirmar pagamento como player

### Critérios de aceite

* O player deve agir apenas sobre sua própria inscrição.
* O valor apresentado deve corresponder ao torneio.
* O sistema deve diferenciar pagamento informado de pagamento aprovado.
* A confirmação não deve aprovar automaticamente sem regra definida.
* A solicitação deve ficar visível para a administração.
* Não deve ser possível confirmar cobrança inexistente.

---

## US-054 — Solicitar rebuy

### Critérios de aceite

* O jogador deve estar inscrito no torneio.
* O rebuy deve estar habilitado.
* A solicitação deve ocorrer dentro do nível permitido.
* O limite por jogador deve ser respeitado.
* O valor deve seguir a configuração vigente.
* A solicitação deve ficar pendente até aprovação, quando necessário.
* Solicitações inválidas devem ser rejeitadas com motivo.

---

## US-055 — Aprovar rebuy

### Critérios de aceite

* Owner e admin autorizado podem aprovar.
* Dealer pode aprovar somente se permitido.
* A solicitação deve estar pendente.
* Limite e período permitido devem ser revalidados.
* A transação deve registrar valor, jogador e responsável.
* A quantidade de rebuys deve ser atualizada.
* Aprovação duplicada não deve gerar outra cobrança.

---

## US-056 — Solicitar add-on

### Critérios de aceite

* O add-on deve estar habilitado.
* O jogador deve possuir inscrição válida.
* A solicitação deve ocorrer no momento permitido.
* O limite configurado deve ser respeitado.
* O valor deve seguir a configuração do torneio.
* A solicitação deve possuir status rastreável.
* Solicitações fora do período devem ser recusadas.

---

## US-057 — Aprovar add-on

### Critérios de aceite

* Apenas papéis autorizados podem aprovar.
* A solicitação deve estar pendente.
* O período e limite devem ser revalidados.
* A transação deve ser criada uma única vez.
* O responsável pela aprovação deve ser registrado.
* O total financeiro deve ser atualizado.
* O jogador deve visualizar o novo status.

---

## US-058 — Registrar taxa extra

### Critérios de aceite

* A taxa deve utilizar um tipo válido do torneio.
* O jogador deve pertencer ao torneio.
* O valor deve ser válido.
* Apenas owner ou admin autorizado pode registrar.
* O responsável deve ser armazenado.
* A transação deve aparecer no histórico.
* Não deve ser possível vincular a outro clube.

---

## US-059 — Visualizar transações

### Critérios de aceite

* Owner e admin autorizado visualizam as transações permitidas.
* A lista deve conter tipo, jogador, valor, status e responsável.
* As transações devem pertencer ao torneio atual.
* Deve ser possível diferenciar pendente, aprovada e cancelada.
* Totais devem considerar apenas estados definidos.
* Player não deve acessar transações de outros jogadores.

---

## US-060 — Visualizar minhas transações

### Critérios de aceite

* O player deve visualizar apenas suas transações.
* A lista deve indicar tipo, valor, data e status.
* Transações de outros jogadores não devem ser acessíveis.
* O total deve seguir a regra financeira definida.
* Cancelamentos devem permanecer identificáveis.
* O usuário deve acessar apenas torneios dos quais participa.

---

## US-061 — Cancelar transação incorreta

### Critérios de aceite

* Apenas owner ou admin autorizado pode cancelar.
* A transação deve pertencer ao torneio atual.
* O registro não deve ser apagado definitivamente.
* O status deve mudar para cancelado.
* O responsável, motivo e data devem ser registrados.
* Totais devem ser recalculados corretamente.
* Uma transação cancelada não deve ser cancelada novamente.

---

# Épico 10 — Clock

## US-062 — Criar estado inicial do clock

### Critérios de aceite

* Cada torneio deve possuir o estado de clock previsto.
* O clock deve iniciar parado.
* O primeiro nível válido deve ser associado.
* O tempo restante deve usar a duração configurada.
* A criação duplicada deve ser evitada.
* O estado deve pertencer ao torneio correto.

---

## US-063 — Iniciar o clock

### Critérios de aceite

* Owner e admin podem iniciar.
* Dealer só poderá iniciar se autorizado.
* Player não pode iniciar.
* O torneio deve possuir estrutura válida.
* O clock não pode iniciar se já estiver rodando.
* O horário de início deve ser registrado.
* O tempo deve avançar de forma consistente.

---

## US-064 — Pausar o clock

### Critérios de aceite

* Owner, admin e dealer podem pausar.
* Player não pode pausar.
* O clock deve estar rodando.
* O tempo restante deve ser preservado.
* O momento da pausa deve ser registrado.
* Pausas repetidas não devem alterar indevidamente o estado.
* A interface deve refletir o status pausado.

---

## US-065 — Retomar o clock

### Critérios de aceite

* O clock deve estar pausado.
* Owner e admin podem retomar.
* Dealer pode retomar quando autorizado.
* Player não pode retomar.
* O tempo deve continuar do ponto preservado.
* O momento da retomada deve ser registrado.
* O clock não deve reiniciar o nível indevidamente.

---

## US-066 — Avançar nível

### Critérios de aceite

* Owner e admin podem avançar.
* Dealer poderá avançar somente se permitido.
* O próximo nível deve existir.
* O clock deve carregar duração e valores do próximo item.
* O nível anterior deve permanecer no histórico operacional.
* Player não pode alterar o nível.
* No último nível, o sistema deve seguir o comportamento definido.

---

## US-067 — Voltar nível

### Critérios de aceite

* Apenas owner ou admin autorizado pode voltar.
* O nível anterior deve existir.
* A ação deve exigir confirmação.
* O clock deve carregar o nível correto.
* O tempo restante deve seguir a escolha definida.
* A alteração deve ser registrada.
* Player e dealer não podem executar sem permissão.

---

## US-068 — Ajustar tempo restante

### Critérios de aceite

* Apenas owner ou admin autorizado pode ajustar.
* O novo tempo deve ser válido.
* Valores negativos não devem ser aceitos.
* A alteração deve registrar valor anterior, novo valor e responsável.
* O ajuste deve refletir imediatamente no clock.
* Player e dealer não podem ajustar sem permissão.

---

## US-069 — Visualizar clock como player

### Critérios de aceite

* O player inscrito deve acessar o clock permitido.
* A tela deve mostrar tempo, nível, blinds, ante e estado.
* O player não deve visualizar controles administrativos.
* Atualizações devem aparecer de forma consistente.
* O clock deve pertencer ao torneio acessado.
* Torneios não autorizados não devem ser acessíveis.

---

## US-070 — Exibir clock em modo telão

### Critérios de aceite

* Deve existir uma visualização dedicada.
* O modo telão deve destacar tempo, nível e blinds.
* Controles administrativos não devem aparecer.
* A tela deve funcionar em resolução ampla.
* O estado deve acompanhar o clock oficial.
* A rota deve respeitar a política de acesso definida.
* Logo e identidade configurados devem ser exibidos quando disponíveis.

---

# Épico 11 — Operação de jogadores

## US-071 — Visualizar jogadores do torneio

### Critérios de aceite

* A lista deve apresentar jogadores do torneio atual.
* Estados como convidado, confirmado, presente, ativo e eliminado devem ser identificáveis.
* Owner e admin visualizam informações administrativas.
* Dealer visualiza informações operacionais.
* Player visualiza somente informações públicas.
* Jogadores de outros torneios não devem aparecer.

---

## US-072 — Registrar eliminação

### Critérios de aceite

* O jogador deve estar ativo.
* Owner e admin podem registrar.
* Dealer pode registrar quando autorizado.
* Player não pode registrar.
* Horário, nível e responsável devem ser armazenados.
* O jogador deve mudar para eliminado.
* Uma eliminação duplicada deve ser impedida.

---

## US-073 — Corrigir eliminação

### Critérios de aceite

* Apenas owner ou admin autorizado pode corrigir.
* O jogador deve estar eliminado.
* A correção deve exigir confirmação.
* O status anterior deve ser restaurado corretamente.
* O histórico deve registrar a correção.
* Resultados dependentes devem ser recalculados quando necessário.

---

## US-074 — Definir mesa e posição

### Critérios de aceite

* O jogador deve estar confirmado ou presente.
* A mesa e posição devem pertencer ao torneio.
* Não deve existir ocupação duplicada da mesma posição.
* Owner, admin ou dealer autorizado podem atribuir.
* A atribuição deve aparecer para o jogador.
* Alterações devem ser registradas.

---

## US-075 — Movimentar jogador entre mesas

### Critérios de aceite

* O jogador deve estar ativo.
* A nova mesa deve possuir vaga.
* A posição não pode estar ocupada.
* A movimentação deve ser feita por papel autorizado.
* Mesa e posição anteriores devem ser atualizadas.
* O jogador deve visualizar a nova localização.
* O histórico operacional deve ser preservado.

---

## US-076 — Visualizar minha mesa

### Critérios de aceite

* O player deve visualizar apenas sua atribuição.
* A tela deve informar mesa e posição atuais.
* Alterações devem aparecer de forma atualizada.
* Usuários sem atribuição devem visualizar mensagem adequada.
* O jogador não deve alterar sua própria mesa.

---

## US-077 — Marcar jogador como ativo

### Critérios de aceite

* Apenas inscrições válidas podem ser ativadas.
* O jogador deve atender às condições de presença e pagamento definidas.
* Papéis autorizados podem mudar o estado.
* O estado ativo deve aparecer na operação.
* Jogador eliminado não deve voltar a ativo sem correção autorizada.
* A mudança deve ser registrada.

---

# Épico 12 — Finalização e resultados

## US-078 — Finalizar torneio

### Critérios de aceite

* Apenas owner ou admin autorizado pode finalizar.
* O torneio deve estar em estado compatível.
* O clock deve ser encerrado ou bloqueado.
* Pendências críticas devem ser apresentadas.
* A finalização deve exigir confirmação.
* O status deve mudar para finalizado.
* Alterações operacionais posteriores devem ser bloqueadas.

---

## US-079 — Definir classificação final

### Critérios de aceite

* A classificação deve utilizar participantes válidos.
* Não pode haver posições duplicadas.
* As posições devem formar uma sequência válida.
* Owner ou admin autorizado pode definir.
* Eliminações existentes podem apoiar a sugestão de ordem.
* A classificação deve pertencer ao torneio.
* O resultado deve ser revisável antes da publicação.

---

## US-080 — Configurar distribuição da premiação

### Critérios de aceite

* Deve ser possível definir a quantidade de premiados.
* Os percentuais devem totalizar 100%.
* Percentuais negativos não devem ser permitidos.
* A quantidade de posições não pode exceder participantes elegíveis.
* Apenas owner ou admin autorizado pode configurar.
* A configuração deve pertencer ao torneio.
* Alterações após finalização devem ser bloqueadas ou auditadas.

---

## US-081 — Calcular premiação

### Critérios de aceite

* O cálculo deve usar o valor base definido.
* Custos e taxas devem seguir as regras do torneio.
* Os percentuais configurados devem ser aplicados corretamente.
* Arredondamentos devem seguir padrão monetário.
* A soma distribuída deve corresponder ao total permitido.
* O cálculo deve ser reproduzível.
* Valores devem ser revisados antes da confirmação.

---

## US-082 — Confirmar vencedor

### Critérios de aceite

* O vencedor deve ser participante válido.
* A primeira colocação deve ser única.
* Apenas owner ou admin autorizado pode confirmar.
* A confirmação deve exigir revisão dos resultados.
* O vencedor deve aparecer no resultado final.
* Alterações posteriores devem exigir reabertura ou correção autorizada.

---

## US-083 — Visualizar resultado do torneio

### Critérios de aceite

* O torneio deve possuir resultado publicado.
* A página deve mostrar classificação permitida.
* Premiações devem ser apresentadas conforme regra.
* Players devem visualizar o próprio resultado.
* Informações financeiras restritas não devem ser expostas.
* O resultado deve pertencer ao torneio correto.

---

## US-084 — Visualizar torneios antigos

### Critérios de aceite

* Devem aparecer torneios finalizados ou cancelados conforme filtro.
* O usuário deve visualizar apenas torneios permitidos.
* A lista deve apresentar data, clube e resultado disponível.
* Deve ser possível acessar o overview histórico.
* Operações bloqueadas não devem aparecer.
* Torneios públicos antigos podem seguir política própria.

---

## US-085 — Bloquear alterações após finalização

### Critérios de aceite

* Torneios finalizados não devem aceitar novas transações comuns.
* Clock e inscrições devem ficar bloqueados.
* Configurações principais não devem ser editadas.
* Tentativas diretas pelas rotas devem ser rejeitadas.
* Visualizações e relatórios devem continuar disponíveis.
* Apenas um fluxo explícito de reabertura pode liberar alterações.

---

## US-086 — Reabrir torneio finalizado

### Critérios de aceite

* Apenas owner pode reabrir, salvo regra diferente.
* A ação deve exigir justificativa.
* A reabertura deve ser registrada.
* O status deve mudar para o estado definido.
* Alterações liberadas devem seguir limites claros.
* Resultados publicados devem ser sinalizados como em revisão.
* Dealer e player não podem reabrir.

---

# Épico 13 — Navegação do player

## US-087 — Visualizar meus próximos torneios

### Critérios de aceite

* A lista deve mostrar torneios futuros relacionados ao usuário.
* Convites recusados não devem aparecer como confirmados.
* Status da participação deve estar visível.
* A ordenação deve considerar a data mais próxima.
* O usuário deve acessar o overview permitido.
* Torneios de outros usuários não devem aparecer.

---

## US-088 — Visualizar torneios aguardando resposta

### Critérios de aceite

* A lista deve conter apenas convites pendentes do usuário.
* Cada item deve apresentar torneio, clube e data.
* Deve existir ação para aceitar ou recusar.
* Convites respondidos devem sair da lista.
* Convites expirados devem ser identificados.
* O usuário não pode responder pelo convite de outra pessoa.

---

## US-089 — Visualizar torneios em andamento

### Critérios de aceite

* Devem aparecer torneios ativos relacionados ao player.
* O usuário deve acessar rapidamente overview e clock.
* O status deve indicar que o torneio está em andamento.
* Torneios finalizados não devem permanecer nessa área.
* A participação do usuário deve ser validada.

---

## US-090 — Visualizar histórico de torneios

### Critérios de aceite

* A lista deve mostrar torneios finalizados dos quais o usuário participou.
* Deve ser possível consultar data, clube e colocação.
* Resultados disponíveis devem possuir acesso.
* O histórico de outro usuário não deve ser exibido.
* A ordenação deve priorizar os eventos mais recentes.

---

## US-091 — Visualizar torneios públicos

### Critérios de aceite

* A página deve mostrar apenas torneios classificados como públicos.
* Torneios cancelados ou não publicados não devem aparecer.
* Informações básicas devem estar disponíveis.
* O usuário deve conseguir acessar detalhes públicos.
* Funcionalidades privadas devem continuar protegidas.
* A lista deve possuir estado vazio quando necessário.

---

## US-092 — Filtrar torneios públicos

### Critérios de aceite

* Deve ser possível filtrar pelos critérios definidos.
* Os filtros devem afetar somente torneios públicos.
* Deve ser possível limpar os filtros.
* Resultados devem manter ordenação consistente.
* Filtros inválidos não devem quebrar a página.
* A interface deve funcionar em mobile.

---

## US-093 — Acessar overview como player

### Critérios de aceite

* O player deve visualizar informações necessárias para decidir ou participar.
* Data, local, valores e status devem estar claros.
* Ações devem considerar o status da inscrição.
* Controles administrativos não devem aparecer.
* Informações restritas devem permanecer protegidas.
* O torneio acessado deve ser público ou relacionado ao usuário.

---

## US-094 — Acompanhar participantes

### Critérios de aceite

* O player deve visualizar apenas informações autorizadas.
* A lista deve pertencer ao torneio atual.
* Participantes ocultos por regra de privacidade não devem aparecer.
* Estados administrativos restritos não devem ser exibidos.
* A quantidade total permitida pode ser apresentada.
* O player não deve alterar participantes.

---

# Épico 14 — Configurações e identidade

## US-095 — Configurar informações gerais

### Critérios de aceite

* Deve ser possível definir nome, data, horário, local e descrição.
* Campos obrigatórios devem ser validados.
* Datas inválidas não devem ser aceitas.
* Owner e admin autorizado podem configurar.
* Dealer e player não podem editar.
* As informações devem aparecer no overview.
* Alterações devem respeitar o status do torneio.

---

## US-096 — Configurar capacidade de jogadores

### Critérios de aceite

* A capacidade deve ser um número inteiro válido.
* Valores negativos ou zero devem seguir a regra definida.
* A capacidade não pode ser reduzida abaixo das inscrições confirmadas sem tratamento.
* Owner e admin autorizado podem alterar.
* O limite deve ser respeitado em novas inscrições.
* A ocupação atual deve ser apresentada.

---

## US-097 — Configurar privacidade

### Critérios de aceite

* O torneio deve aceitar os estados público ou privado definidos.
* Owner e admin autorizado podem alterar.
* Torneios privados não devem aparecer na listagem pública.
* Torneios públicos devem exibir apenas informações permitidas.
* Mudanças com inscrições existentes devem preservar os participantes.
* A alteração deve refletir imediatamente nas listagens.

---

## US-098 — Configurar período de inscrições

### Critérios de aceite

* Deve ser possível definir abertura e encerramento.
* A data de encerramento não pode ser anterior à abertura.
* Inscrições fora do período devem ser bloqueadas.
* Owner e admin autorizado podem configurar.
* O período deve aparecer para o player.
* Mudanças devem respeitar inscrições existentes.

---

## US-099 — Configurar regras de recarga

### Critérios de aceite

* Deve ser possível definir limite e período de rebuy.
* Deve ser possível definir limite e momento do add-on.
* As regras devem ser associadas ao torneio.
* Solicitações devem validar essas regras no backend.
* Owner e admin autorizado podem editar.
* Dealer e player não podem modificar.
* O overview deve apresentar as regras permitidas.

---

## US-100 — Personalizar visual do clock

### Critérios de aceite

* Owner deve poder configurar elementos visuais permitidos.
* Admin poderá configurar quando autorizado.
* Deve ser possível utilizar a identidade do clube.
* Formatos de arquivos devem ser validados.
* Arquivos inválidos não devem ser aceitos.
* A personalização deve aparecer no modo telão.
* A legibilidade do clock deve ser preservada.

---

# Épico 15 — Segurança e auditoria

## US-101 — Restringir acesso por papel

### Critérios de aceite

* Cada ação protegida deve consultar o `ClubMembership`.
* Owner, admin, dealer e player devem possuir acessos distintos.
* A autorização deve acontecer no backend.
* Ocultar botões não deve ser a única proteção.
* Acesso direto à rota deve ser testado.
* Papéis de outro clube não devem conceder acesso.
* Não deve ser criado `TournamentStaff`.

---

## US-102 — Impedir acesso entre clubes

### Critérios de aceite

* Clubes devem ser encontrados pelas associações autorizadas.
* Torneios devem ser encontrados a partir do clube autorizado.
* Alterar IDs na URL não deve conceder acesso.
* Um usuário pode possuir papéis diferentes em clubes diferentes.
* O papel de um clube não deve valer em outro.
* Acesso indevido não deve expor dados sensíveis.
* Request Specs devem cobrir os cenários.

---

## US-103 — Registrar responsável por transação

### Critérios de aceite

* Toda transação administrativa deve registrar quem executou a ação.
* O responsável deve ser um usuário autorizado.
* Data e horário devem ser armazenados.
* Cancelamentos devem registrar o responsável específico.
* O histórico não deve ser alterado pelo player.
* Transações antigas devem preservar o responsável original.

---

## US-104 — Registrar alterações críticas

### Critérios de aceite

* Alterações críticas devem possuir responsável, data e ação.
* Papéis, clock, resultados e cancelamentos devem ser considerados.
* O histórico deve pertencer ao clube ou torneio correto.
* Registros de auditoria não devem ser editáveis por usuários comuns.
* Owner deve acessar as informações permitidas.
* Dados sensíveis devem possuir acesso restrito.

---

## US-105 — Impedir alteração de papel pelo formulário

### Critérios de aceite

* Formulários comuns não devem aceitar `role`.
* O papel deve ser definido pelo backend.
* O usuário não pode alterar o próprio papel.
* Parâmetros extras devem ser ignorados ou rejeitados.
* Mudanças de papel devem usar uma ação protegida.
* Apenas owner autorizado pode executar mudanças administrativas.
* Request Specs devem testar tentativa de elevação de privilégio.

---

# Definição de concluído

Uma User Story só pode ser marcada como `Concluída` quando:

* todos os critérios aplicáveis estiverem atendidos;
* as regras de permissão estiverem implementadas;
* os testes relacionados estiverem aprovados;
* o fluxo válido estiver funcionando;
* os fluxos inválidos estiverem protegidos;
* não houver arquivos alterados fora do escopo;
* o diff tiver sido revisado;
* a interface estiver responsiva, quando aplicável;
* a documentação necessária estiver atualizada;
* o commit tiver sido realizado;
* não existirem pendências bloqueadoras.
