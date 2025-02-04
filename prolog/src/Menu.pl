:- module('Menu', [menuPrincipal/0]).
:- use_module('controller/MonitorController.pl', [vinculaMonitor/1, getMonitor/2, ehMonitor/1, desvinculaMonitor/1, listarMonitoresByDisciplina/1]).
:- use_module('controller/ChatController.pl', [exibeTicketsDisciplina/1, exibeTicketsAluno/2, responderTicket/2, getTicketsAluno/2,marcarTicketAlunoComoResolvido/1,adicionarMensagemTicketAluno/1, adicionaTicket/2, excluirTicket/1]).
:- use_module('controller/ProfessorController.pl', [getProfessor/2, ehProfessor/1]).
:- use_module('controller/AlunoController.pl', [getAluno/2, ehAluno/1, vinculaAlunoDisciplina/1, removeAluno/1, desvinculaAlunoDisciplina/1]).
:- use_module('util/jsonFunctions', [checaExistencia/2, atualizaAtributoAluno/3, atualizaAtributoProfessor/3, getObjetoByID/3, atualizaAtributoTicket/3]).
:- use_module('util/EncriptFunctions.pl', [encripta/3]).
:- use_module('util/input.pl',[input/1]).

menuPrincipal() :- writeln('\n\nBem vindo ao SAD: Sistema de Atendimento ao Discente! :):\n'), menuLogin().

menuLogin() :- 
    writeln("Insira seu ID para entrar. Para sair do sistema, digite 'sair': "), 
    input(Id),
    decideMenu(Id).

menuAutenticacao(Objeto):-
    writeln("\nInsira a sua Senha:"),
    input(Senha),
    encripta(Senha, Objeto.nome, SenhaEncriptada),
    SenhaEncriptada = Objeto.senha.

decideMenu('sair'):- halt(0).
decideMenu(Id) :- 
    atom_string(Id, IdString),
    (
      ehProfessor(IdString) -> 
        getProfessor(IdString, Professor), 
        (menuAutenticacao(Professor) -> exibeMenuProfessor(IdString); writeln("Senha incorreta\n"), menuLogin());
      ehMonitor(IdString) -> 
        getAluno(IdString, Monitor),
        (menuAutenticacao(Monitor) -> exibeMenuAlunoMonitor(IdString); writeln("Senha incorreta\n"), menuLogin());
      ehAluno(IdString) -> 
        getAluno(IdString, Aluno),
        (menuAutenticacao(Aluno) -> exibeMenuAluno(IdString); writeln("Senha incorreta\n"), menuLogin());
      writeln("ID nao encontrado!\n"),
      menuLogin()
    ).

trocarSenha(Entidade):-
    writeln('Digite sua nova senha:'),
    input(Senha),
    encripta(Senha, Entidade.nome, SenhaEncriptada),
    (   
        ehAluno(Entidade.id) ->atualizaAtributoAluno(Entidade.id, "senha", SenhaEncriptada);
        atualizaAtributoProfessor(Entidade.id, "senha", SenhaEncriptada)
    ), writeln("Senha alterada com sucesso").

perguntaDisciplina(Disciplinas, Disciplina):-
    length(Disciplinas, Size), Size > 1,
    writeln("Insira a disciplina:"),
    input(SiglaDisciplina), nl,
    atom_string(SiglaDisciplina, SiglaString),
    (
        member(SiglaString, Disciplinas) -> Disciplina = SiglaString;
        Disciplina = "INVALIDA"
    )
    ;
    [H|_] = Disciplinas,
    Disciplina = H.

msgInputInvalido():- writeln("Insira um valor valido\n").

%----------------------------------------------------- PROFESSOR -----------------------------------------------------%

exibeMenuProfessor(Id):-
    getProfessor(Id, Professor),
    writeln('\n== SAD: MENU PROFESSOR =='),
    swritef(Out, "\nID: %w | Nome: %w | Disciplinas: %w\n", [Professor.id, Professor.nome, Professor.disciplinas]), write(Out),
    writeln('Digite o numero da acao que deseja executar!\n'),
    writeln('1) Exibir tickets\n2) Responder Tickets em andamento\n3) Vincular aluno/monitor\n4) Desvincular aluno/monitor\n5) Alterar senha de acesso\n6) Listar monitores por disciplina\n7) Deslogar\n'),
    input(Opcao),
    decideMenuProfessor(Opcao, Professor),
    exibeMenuProfessor(Id).

decideMenuProfessor('1', Professor) :- 
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor(-1, Professor) ; exibeTicketsDisciplina(Disciplina)).

decideMenuProfessor('2', Professor):- 
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor(-1, Professor) ; responderTicket(Professor, Disciplina)).

decideMenuProfessor('3', Professor):- menuCadastroProfessor(Professor).

decideMenuProfessor('4', Professor):- menuRemocaoProfessor(Professor).

decideMenuProfessor('5', Professor):- trocarSenha(Professor).

decideMenuProfessor('6', Professor) :-
    perguntaDisciplina(Professor.disciplinas, Disciplina),
    (
        Disciplina = "INVALIDA" -> decideMenuProfessor(-1, Professor)
    ;
        listarMonitoresByDisciplina(Disciplina)
    ).

decideMenuProfessor('7', _) :- writeln('Deslogando...'), menuPrincipal().

decideMenuProfessor(_, Professor) :- 
    msgInputInvalido(),
    exibeMenuProfessor(Professor.id).

menuCadastroProfessor(Professor) :- 
    writeln('\nQuem voce deseja vincular?'),
    writeln('1) Vincular aluno\n2) Vincular monitor\n3) Voltar para o menu professor\n'),
    input(Opcao),
    decideMenuCadastro(Opcao, Professor),
    exibeMenuProfessor(Professor.id).

decideMenuCadastro('1', Professor):-
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor('-1', Professor); 
    vinculaAlunoDisciplina(Disciplina)).

decideMenuCadastro('2', Professor):-
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor('-1', Professor) ;  vinculaMonitor(Disciplina)).

decideMenuCadastro('3', _).

decideMenuCadastro(_, Professor):- msgInputInvalido(), menuCadastroProfessor(Professor).

menuRemocaoProfessor(Professor) :- 
    writeln('\nQuem voce deseja desvincular?'),
    writeln('1) Desvincular aluno\n2) Desvincular monitor\n3) Voltar para o menu professor\n'),
    input(Opcao),
    decideMenuRemocao(Opcao, Professor),
    exibeMenuProfessor(Professor.id).

decideMenuRemocao('1', Professor) :-
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor(-1, Professor) ;  desvinculaAlunoDisciplina(Disciplina)).

decideMenuRemocao('2', Professor) :- 
    perguntaDisciplina(Professor.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuProfessor(-1, Professor) ;  desvinculaMonitor(Disciplina)).

decideMenuRemocao('3', Professor):- exibeMenuProfessor(Professor.id).

decideMenuRemocao(_, Professor):- msgInputInvalido(), menuRemocao(Professor).

%----------------------------------------------------- MONITOR -----------------------------------------------------%

exibeMenuAlunoMonitor(Id) :- 
    getMonitor(Id, Monitor),
    write('\nFoi identificado que voce eh monitor da disciplina: '), write(Monitor.disciplina),
    write('\nComo deseja entrar no sistema?\n\n1) Entrar como Aluno\n2) Entrar como Monitor de '), write(Monitor.disciplina), nl,
    input(Opcao),
    decideMenuAlunoMonitor(Opcao, Id).

decideMenuAlunoMonitor('1', Id) :- exibeMenuAluno(Id).
decideMenuAlunoMonitor('2', Id) :- exibeMenuMonitor(Id).
decideMenuAlunoMonitor(_, _) :- msgInputInvalido(), exibeMenuAlunoMonitor().

exibeMenuMonitor(Id) :- 
    getMonitor(Id, Monitor),
    getAluno(Id, Aluno),
    writeln('\n== SAD: MENU MONITOR =='),
    swritef(Out, '\nID: %w | Nome: %w | Disciplina: %w\n', [Monitor.id, Aluno.nome, Monitor.disciplina]), write(Out),
    writeln('Digite o numero da ação que deseja executar!\n'),
    writeln('1) Exibir todos os tickets\n2) Responder tickets em andamento\n3) Deslogar\n'),
    input(Opcao),
    decideMenuMonitor(Opcao, Monitor),
    exibeMenuMonitor(Id).

decideMenuMonitor('1', Monitor) :- exibeTicketsDisciplina(Monitor.disciplina).

decideMenuMonitor('2', Monitor):- responderTicket(Monitor, Monitor.disciplina).

decideMenuMonitor('3', _) :- write('\nDeslogando...'), menuPrincipal().

decideMenuMonitor(_) :- msgInputInvalido().

%----------------------------------------------------- ALUNO -----------------------------------------------------%

exibeMenuAluno(Id):-
    getAluno(Id, Aluno),
    writeln('\n== SAD: MENU ALUNO =='),
    swritef(Out, '\nID: %w | Nome: %w | Disciplinas: %w\n', [Aluno.id, Aluno.nome, Aluno.disciplinas]), write(Out),
    writeln('Digite o numero da acao que deseja executar!\n'),
    writeln('1) Ler tickets de uma disciplina\n2) Ler meus tickets\n3) Criar Ticket\n4) Mandar mensagem em um ticket meu\n5) Marcar ticket como resolvido\n6) Excluir ticket\n7) Trocar senha de acesso\n8) Deslogar\n'),
    input(Opcao),
    decideMenuAluno(Opcao, Aluno),
    exibeMenuAluno(Id).

decideMenuAluno('1', Aluno):- 
    perguntaDisciplina(Aluno.disciplinas, Disciplina), 
    (Disciplina = "INVALIDA" -> decideMenuAluno(-1, Aluno) ; exibeTicketsDisciplina(Disciplina)).

decideMenuAluno('2', Aluno):- exibeTicketsAluno(Aluno.id, _).

decideMenuAluno('3', Aluno):-
    perguntaDisciplina(Aluno.disciplinas, Disciplina),
    (Disciplina = "INVALIDA" -> decideMenuAluno(-1, Aluno);
    adicionaTicket(Aluno, Disciplina)
    ).

decideMenuAluno('4', Aluno) :-
    adicionarMensagemTicketAluno(Aluno).

decideMenuAluno('5', Aluno) :-
    marcarTicketAlunoComoResolvido(Aluno).

decideMenuAluno('6', Aluno):- excluirTicket(Aluno.id).

decideMenuAluno('7', Aluno):- trocarSenha(Aluno).

decideMenuAluno('8', _) :- write('\nDeslogando...'), menuPrincipal().

decideMenuAluno(_, _) :- msgInputInvalido().
