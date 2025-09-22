-- PONTO - Validação: PONTO - Validação - 1.sql

-- VALIDAÇÃO 1
-- Busca as descrições repetidas no horário ponto

select list(i_entidades) as entidades, 
       list(i_horarios_ponto) as horario, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.horarios_ponto
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza as descrições duplicadas adicionando um sufixo numérico para diferenciá-las

-- 1. Criar uma tabela temporária com identificadores únicos para as duplicadas
create table #duplicadas (i_entidades integer, i_horarios_ponto integer, nova_descricao char(100));

-- 2. Inserir na tabela temporária os valores com nova descrição
insert into #duplicadas (i_entidades, i_horarios_ponto, nova_descricao)
select i_entidades, hp.i_horarios_ponto, hp.descricao || ' (' || row_number() over (partition by hp.descricao order by hp.i_horarios_ponto) || ')' as nova_descricao
  from bethadba.horarios_ponto hp
 where hp.descricao in (select descricao
                          from bethadba.horarios_ponto
                         group by descricao
                        having count(*) > 1);

-- 3. Atualizar os registros duplicados (exceto o primeiro, que manterá a descrição original)
update bethadba.horarios_ponto hp
   set descricao = (select d.nova_descricao
                      from #duplicadas d
                     where d.i_entidades = hp.i_entidades
                       and d.i_horarios_ponto = hp.i_horarios_ponto)
 where exists (select 1
                 from #duplicadas d
                where d.i_entidades = hp.i_entidades  
                  and d.i_horarios_ponto = hp.i_horarios_ponto);

-- 4. (Opcional) Excluir a tabela temporária
drop table #duplicadas;

-- FIM DO ARQUIVO PONTO - Validação - 1.sql

-- PONTO - Validação: PONTO - Validação - 2.sql

-- VALIDAÇÃO 2
-- Busca as descrições repetidas na turma

select list(i_entidades) as entidades, 
       list(i_turmas) as turma, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.turmas
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza as descrições repetidas para que sejam únicas

update bethadba.turmas
   set descricao = i_turmas || ' - ' || descricao
 where exists (select 1 
                 from bethadba.turmas t2
                where t1.descricao = t2.descricao
                  and t1.i_turmas <> t2.i_turmas);

-- FIM DO ARQUIVO PONTO - Validação - 2.sql

-- PONTO - Validação: PONTO - Validação - 3.sql

-- VALIDAÇÃO 3
-- Verifica a descrição do motivo de alteração do ponto se contém mais que 30 caracteres

select i_motivos_altponto,
       length(descricao) as tamanho_descricao
  from bethadba.motivos_altponto 
 where tamanho_descricao > 30;


-- CORREÇÃO
-- Trunca a descrição do motivo de alteração do ponto para 30 caracteres

update bethadba.motivos_altponto
   set descricao = left(descricao, 30)
 where length(descricao) > 30;

-- FIM DO ARQUIVO PONTO - Validação - 3.sql

-- PONTO - Validação: PONTO - Validação - 4.sql

-- VALIDAÇÃO 4
-- Busca os funcionários com marcações com origem inválida

select i_funcionarios,
       mensagem_erro = 'Não são permitidas marcações com origem de Pré-assinaladas'
  from bethadba.apuracoes_marc as am
 where origem_marc not in ('O','I','A');


-- CORREÇÃO
-- Atualiza as marcações com origem inválida para uma origem válida

update bethadba.apuracoes_marc
   set origem_marc = 'I'
 where origem_marc not in ('O','I','A');

-- FIM DO ARQUIVO PONTO - Validação - 4.sql

-- PONTO - Validação: PONTO - Validação - 5.sql

-- VALIDAÇÃO 5
-- Busca as ocorrências do ponto com nome repetido

select LIST(i_ocorrencias_ponto) as ocorrencias_ponto, 
       trim(nome) as nose, 
       count(nome) as cods,
       mensagem_erro = 'Ocorrencias do ponto com nome repetido'
  from bethadba.ocorrencias_ponto
 group by nose
having cods > 1;


-- CORREÇÃO
-- Atualiza os pontos com nome repetido para adicionar um sufixo numérico

update bethadba.ocorrencias_ponto
   set nome = (select count(*) 
                 from bethadba.ocorrencias_ponto as op 
                where op.nome = bethadba.ocorrencias_ponto.nome) + 1 || ' - ' || nome
 where nome in (select nome 
                   from bethadba.ocorrencias_ponto 
                  group by nome 
                 having count(nome) > 1);

-- FIM DO ARQUIVO PONTO - Validação - 5.sql

-- PONTO - Validação: PONTO - Validação - 6.sql

-- VALIDAÇÃO 6
-- Busca as Permutas com datas nulas

select i_entidades, 
       i_funcionarios, 
       i_turmas 
  from bethadba.permuta_func_turmas as pft
 where dt_inicial is null
    or dt_final is null;


-- CORREÇÃO
-- Exclui as permutas com datas nulas

delete bethadba.permuta_func_turmas as pft
 where dt_inicial is null
    or dt_final is null;

-- FIM DO ARQUIVO PONTO - Validação - 6.sql

