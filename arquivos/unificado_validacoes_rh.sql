-- RH - Validação: RH - Validação - 1.sql

-- VALIDAÇÃO 1
-- Cadastro de locais de avaliação - O local de avaliação consta com bloco vazio

select i_locais_aval
  from bethadba.locais_aval
 where bloco is null;


-- CORREÇÃO



-- FIM DO ARQUIVO RH - Validação - 1.sql

-- RH - Validação: RH - Validação - 10.sql

-- VALIDAÇÃO 10
-- Tipo de diaria sem valor - É obrigatorio o valor para um tipo de diaria

select i_tipos_diarias,
       descricao
  from bethadba.tipos_diarias as td
 where vlr_diaria is null;


-- CORREÇÃO
-- Atualiza o valor nulo para 0 (zero)

update bethadba.tipos_diarias
   set vlr_diaria = 0
 where vlr_diaria is null;

-- FIM DO ARQUIVO RH - Validação - 10.sql

-- RH - Validação: RH - Validação - 11.sql

-- VALIDAÇÃO 11
-- Finalidade superior a 100 caracteres - A descrição da finalidade da diaria não pode possuir mais de 100 carcateres

select i_entidades,
       i_funcionarios,
       i_diarias,
       finalidade
  from bethadba.diarias
 where length(finalidade) > 100;


-- CORREÇÃO
-- Ajusta a finalidade para o máximo de 100 caracteres, eliminando o excesso

update bethadba.diarias
   set finalidade = substr(finalidade, 1, 100)
 where length(finalidade) > 100;

-- FIM DO ARQUIVO RH - Validação - 11.sql

-- RH - Validação: RH - Validação - 12.sql

-- VALIDAÇÃO 12
-- Cursos duplicados - Existem cursos com a mesma descrição e tipo

select c.i_cursos,
       c.nome,
       c.tipo
  from bethadba.cursos as c
 where exists (select first 1
                 from bethadba.cursos as c2
                where c2.nome = c.nome
                  and c2.tipo = c.tipo
                  and c2.i_cursos <> c.i_cursos);


-- CORREÇÃO
-- Atualiza a descrição do curso para evitar duplicidade

update bethadba.cursos
   set nome = i_cursos || ' - ' || nome
 where exists (select first 1
                 from bethadba.cursos as c2
                where c2.nome = bethadba.cursos.nome
                  and c2.tipo = bethadba.cursos.tipo
                  and c2.i_cursos <> bethadba.cursos.i_cursos);

-- FIM DO ARQUIVO RH - Validação - 12.sql

-- RH - Validação: RH - Validação - 13.sql

-- VALIDAÇÃO 13
-- Cursos concomitantes - Existem cursos concomitantes para a mesma pessoa

select pessoa = cp.i_pessoas,
       cursoPessoa = cp.i_cursos,
       dataInicial = cp.dt_inicial,
       dataFinal = cp.dt_final
  from bethadba.cursos_pessoas as cp
 where cp.participacao = 3
   and exists(select first 1
                from bethadba.cursos_pessoas as cp2
               where pessoa = cp2.i_pessoas
                 and cursoPessoa = cp2.i_cursos
                 and (cp2.dt_inicial between dataInicial and dataFinal
                  or cp2.dt_final between dataInicial and dataFinal));


-- CORREÇÃO
-- Verificar se os cursos são realmente concomitantes. Caso positivo, alterar a data final do curso de data inicial menor para um dia anterior a data incial do curso que possuir data inicial maior.

-- Exemplo de correção:
update bethadba.cursos_pessoas
   set dt_final = dateadd(day, -1, dt_inicial)
 where participacao = 3
   and exists(select first 1
                from bethadba.cursos_pessoas as cp2
               where i_pessoas = cp2.i_pessoas
                 and i_cursos = cp2.i_cursos
                 and (cp2.dt_inicial between dt_inicial and dt_final
                  or cp2.dt_final between dt_inicial and dt_final));

-- FIM DO ARQUIVO RH - Validação - 13.sql

-- RH - Validação: RH - Validação - 14.sql

-- VALIDAÇÃO 14
-- Descrição habilitação maior que o permitido - Descrição habilitação maior que o permitido, não é permitido possuir mais de 100 caracateres

select i_areas_atuacao,
       nome
  from bethadba.areas_atuacao
 where length(descr_habilitacao) > 100;


-- CORREÇÃO
-- A descrição da habilitação deve ser corrigida para que não ultrapasse o limite de 100 caracteres.

update bethadba.areas_atuacao
   set descr_habilitacao = substr(descr_habilitacao, 1, 100)
 where length(descr_habilitacao) > 100;

-- FIM DO ARQUIVO RH - Validação - 14.sql

-- RH - Validação: RH - Validação - 15.sql

-- VALIDAÇÃO 15
-- Ausência de membros em comissões - Ausência de membros em comissões, necessario um membro cadastrado para comissão

select i_comissoes_aval,
       nome
  from bethadba.comissoes_aval as ca
 where not exists(select first 1
                    from bethadba.comissoes_aval_membros as cam
                   where ca.i_comissoes_aval = cam.i_comissoes_aval);


-- CORREÇÃO
-- Excluir comissões que não possuem membros cadastrados

delete from bethadba.comissoes_aval
 where not exists (select first 1 
                     from bethadba.comissoes_aval_membros as cam
                    where comissoes_aval.i_comissoes_aval = cam.i_comissoes_aval);

-- FIM DO ARQUIVO RH - Validação - 15.sql

-- RH - Validação: RH - Validação - 16.sql

-- VALIDAÇÃO 16
-- Descrição maior que o numero permitido de caracteres - Descrição maior que o numero permitido de caracteres(500)

select i_fatores,
       nome
  from bethadba.fatores as f
 where length(f.descricao) > 500;


-- CORREÇÃO
-- Atualizando a descrição para que não exceda o limite de 500 caracteres

update bethadba.fatores
   set descricao = substr(descricao, 1, 500)
 where length(descricao) > 500;

-- FIM DO ARQUIVO RH - Validação - 16.sql

-- RH - Validação: RH - Validação - 17.sql

-- VALIDAÇÃO 17
-- Necessario possuir uma area de atuação

select i_entidades,
       i_concursos,
       i_candidatos
  from bethadba.candidatos as c
 where i_areas_atuacao is null;


-- CORREÇÃO
-- Atualiza os candidatos que não possuem área de atuação para a área de atuação padrão (1)

update bethadba.candidatos
   set i_areas_atuacao = 1
 where i_areas_atuacao is null;

-- FIM DO ARQUIVO RH - Validação - 17.sql

-- RH - Validação: RH - Validação - 18.sql

-- VALIDAÇÃO 18
-- Verifica se há registro na tabela planos_saude_tabelas_faixas - A tabela planos_saude_tabelas_faixas está vazia. É necessário ter os dados preenchidos

select case 
        when exists (select 1
                       from bethadba.planos_saude) 
        then (select count(*)
                from bethadba.planos_saude_tabelas_faixas)
       end as total_registros;


-- CORREÇÃO
-- Inserir os dados na tabela planos_saude_tabelas_faixas

INSERT INTO bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
VALUES (1, 1, 1, 1, 1, 0, 17, 100.00);

-- FIM DO ARQUIVO RH - Validação - 18.sql

-- RH - Validação: RH - Validação - 19.sql

-- VALIDAÇÃO 19
-- Verifica se idade_ini e idade_fin estão vazios - Faltam dados nas colunas idade_ini e idade_fin na tabela planos_saude_tabelas_faixas. É necessário ter os dados preenchidos

select case 
        when count(*) > 0
        then (select count(*)
                from bethadba.planos_saude_tabelas_faixas) 
       end total_registros
  from bethadba.planos_saude;


-- CORREÇÃO
-- Atualizar os registros na tabela planos_saude_tabelas_faixas para preencher idade_ini e idade_fin com valores padrão, se necessário.

update bethadba.planos_saude_tabelas_faixas
   set idade_ini = 0, idade_fin = 100
 where idade_ini is null
    or idade_fin is null;

-- FIM DO ARQUIVO RH - Validação - 19.sql

-- RH - Validação: RH - Validação - 2.sql

-- VALIDAÇÃO 2
-- Cadastro de distância - O total de KM não pode estar nulo

select i_distancias,
	     total_km
  from bethadba.distancias
 where total_km is null;


-- CORREÇÃO
-- Atualizando o total de KM para 999 onde está nulo

update bethadba.distancias
   set total_km = 999
 where total_km is null;

-- FIM DO ARQUIVO RH - Validação - 2.sql

-- RH - Validação: RH - Validação - 20.sql

-- VALIDAÇÃO 20
-- Verifica se há ausências concomitantes

select a1.i_funcionarios,
	   a1.dt_ausencia,
	   a1.dt_ultimo_dia,
	   a2.dt_ausencia as dt_ausencia_concomitante,
	   a2.dt_ultimo_dia as dt_ultimo_dia_concomitante
  from bethadba.ausencias a1
  join bethadba.ausencias a2
    on a1.i_funcionarios = a2.i_funcionarios
   and a1.i_entidades = a2.i_entidades
 where (a1.dt_ausencia between dt_ausencia_concomitante and dt_ultimo_dia_concomitante or a1.dt_ultimo_dia between dt_ausencia_concomitante and dt_ultimo_dia_concomitante)
   and (a1.dt_ausencia <> dt_ausencia_concomitante or a1.dt_ultimo_dia <> dt_ultimo_dia_concomitante)
 order by a1.i_funcionarios, a1.dt_ausencia;


-- CORREÇÃO
-- Ajustar as datas de ausência para evitar sobreposição

update bethadba.ausencias a1
   set a1.dt_ultimo_dia = coalesce(dateadd(day, -1, a2.dt_ausencia), a1.dt_ultimo_dia)
  from bethadba.ausencias a2
 where (a1.dt_ausencia between a2.dt_ausencia and a2.dt_ultimo_dia or a1.dt_ultimo_dia between a2.dt_ausencia and a2.dt_ultimo_dia)
   and (a1.dt_ausencia <> a2.dt_ausencia or a1.dt_ultimo_dia <> a2.dt_ultimo_dia)
   and a1.i_funcionarios = a2.i_funcionarios
   and a1.i_entidades = a2.i_entidades;

-- FIM DO ARQUIVO RH - Validação - 20.sql

-- RH - Validação: RH - Validação - 3.sql

-- VALIDAÇÃO 3
-- Licença prêmio no cadastro de matrícula - Não pode ser incluída uma configuração com data anterior à data de admissão da matrícula

select licencas_premio_per.i_entidades,
       licencas_premio_per.i_funcionarios,
       funcionarios.dt_admissao,
       licencas_premio_per.dt_inicial,
       licencas_premio_per.dt_final
  from bethadba.licencas_premio
 inner join bethadba.licencas_premio_per
    on licencas_premio.i_entidades = licencas_premio_per.i_entidades
   and licencas_premio.i_licencas_premio = licencas_premio_per.i_licencas_premio
   and licencas_premio.i_funcionarios  = licencas_premio_per.i_funcionarios
 inner join bethadba.funcionarios 
    on licencas_premio.i_entidades = funcionarios.i_entidades
   and licencas_premio.i_funcionarios  = funcionarios.i_funcionarios
 where funcionarios.dt_admissao > licencas_premio_per.dt_inicial;


-- CORREÇÃO
-- A correção deve ser feita no cadastro de matrícula, onde não deve ser possível incluir uma licença prêmio com data inicial anterior à data de admissão do funcionário.

update bethadba.licencas_premio_per
   set dt_inicial = funcionarios.dt_admissao
  from bethadba.funcionarios
 where licencas_premio_per.i_entidades = funcionarios.i_entidades
   and licencas_premio_per.i_funcionarios = funcionarios.i_funcionarios
   and licencas_premio_per.dt_inicial < funcionarios.dt_admissao;

-- FIM DO ARQUIVO RH - Validação - 3.sql

-- RH - Validação: RH - Validação - 4.sql

-- VALIDAÇÃO 4
-- Função Gratificada - Não pode ser incluída uma configuração com data anterior à data de admissão da matrícula

select funcoes_func.i_entidades,
       funcoes_func.i_funcionarios,
       dt_admissao,
       dt_inicial,
       dt_final
  from bethadba.funcoes_func
  left join bethadba.funcionarios 
    on funcoes_func.i_funcionarios = funcionarios.i_funcionarios
   and funcoes_func.i_entidades = funcionarios.i_entidades
 where dt_inicial < dt_admissao
    or dt_final < dt_admissao;


-- CORREÇÃO
-- Atualizar as datas de início e fim para que não sejam anteriores à data de admissão

update bethadba.funcoes_func
   set dt_inicial = dt_admissao,
       dt_final = dt_admissao
 where dt_inicial < dt_admissao
    or dt_final < dt_admissao;

-- FIM DO ARQUIVO RH - Validação - 4.sql

-- RH - Validação: RH - Validação - 5.sql

-- VALIDAÇÃO 5
-- Periodo Aquisitivo Licenca premio - A data inicial não pode ser superior a data final

select i_entidades,
       i_funcionarios,
       i_licencas_premio,
       i_licencas_premio_per,
       dt_inicial,
       dt_final 
  from bethadba.licencas_premio_per as lpp
 where dt_inicial > dt_final
 order by i_entidades, i_funcionarios, i_licencas_premio, i_licencas_premio_per, dt_inicial, dt_final asc;


-- CORREÇÃO
-- Periodo Aquisitivo Licenca premio - A data inicial não pode ser superior a data final

update bethadba.licencas_premio_per as lpp
   set dt_inicial = dt_final
 where dt_inicial > dt_final;

-- FIM DO ARQUIVO RH - Validação - 5.sql

-- RH - Validação: RH - Validação - 6.sql

-- VALIDAÇÃO 6
-- Periodo Aquisitivo Licenca premio - A quantidade de dias de direito deve ser informada

select i_entidades,
       i_funcionarios,
       i_licencas_premio
  from bethadba.licencas_premio  
 where num_dias_licenca is null
    or num_dias_licenca < 0
 order by i_entidades, i_funcionarios, i_licencas_premio asc;


-- CORREÇÃO
-- A quantidade de dias de direito deve ser informada

update bethadba.licencas_premio
   set num_dias_licenca = 0
 where num_dias_licenca is null
    or num_dias_licenca < 0;

-- FIM DO ARQUIVO RH - Validação - 6.sql

-- RH - Validação: RH - Validação - 7.sql

-- VALIDAÇÃO 7
-- Periodo Aquisitivo Licenca premio - A data inicial ou final não pode estar nula

select i_entidades,
       i_funcionarios,
       i_licencas_premio,
       i_licencas_premio_per 
  from bethadba.licencas_premio_per as lpp
 where (dt_inicial is null or dt_final is null)
   and i_averbacoes is null
   and status = 'S'
   and observacao not like '%averb%'
 order by i_entidades, i_funcionarios, i_licencas_premio, i_licencas_premio_per asc;


-- CORREÇÃO
-- Atualiza as datas inicial e final para a data atual onde estiverem nulas e não houver averbação, status for 'S' e observação não contiver 'averb'

update bethadba.licencas_premio_per as lpp
   set dt_inicial = current_date,
       dt_final = current_date
 where (dt_inicial is null or dt_final is null)
   and i_averbacoes is null
   and status = 'S'
   and observacao not like '%averb%';

-- FIM DO ARQUIVO RH - Validação - 7.sql

-- RH - Validação: RH - Validação - 8.sql

-- VALIDAÇÃO 8
-- Comissão de avaliação - O membro da comissão deve possuir uma função com descrição entre PRESIDENTE, MEMBRO ou SECRETARIO

select i_comissoes_aval,
       i_pessoas,
       funcao
  from bethadba.comissoes_aval_membros
 where funcao not like 'MEMBRO%' 
   and funcao not like 'PRESIDENTE%' 
   and funcao not like 'SECRETARIO%';


-- CORREÇÃO
-- Atualiza a função para 'MEMBRO' quando a função não é válidada

update bethadba.comissoes_aval_membros
   set funcao = 'MEMBRO'
 where funcao not like 'MEMBRO%'
   and funcao not like 'PRESIDENTE%'
   and funcao not like 'SECRETARIO%';

-- FIM DO ARQUIVO RH - Validação - 8.sql

-- RH - Validação: RH - Validação - 9.sql

-- VALIDAÇÃO 9
-- Configuração adicional da matricula - A data inicial da configuração não pode ser anterior a data de admissão

select af.i_entidades,
       af.i_funcionarios,
       af.i_adicionais,
       af.dt_inicial,
       f.dt_admissao
  from bethadba.adic_funcs as af
  join bethadba.funcionarios as f
    on af.i_entidades = f.i_entidades
   and af.i_funcionarios = f.i_funcionarios
 where af.dt_inicial < f.dt_admissao;


-- CORREÇÃO
-- Atualiza a data inicial da configuração adicional da matrícula para a data de admissão do funcionário

update bethadba.adic_funcs as af
  join bethadba.funcionarios as f
    on af.i_entidades = f.i_entidades
   and af.i_funcionarios = f.i_funcionarios
   set af.dt_inicial = f.dt_admissao
 where af.dt_inicial < f.dt_admissao;

-- FIM DO ARQUIVO RH - Validação - 9.sql

