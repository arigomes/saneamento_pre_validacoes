-- FOLHA - Validação: FOLHA - Validação - 1.sql

-- VALIDAÇÃO 01
-- Descricao de Logradouros Duplicadas

select list(i_ruas) as ruas, 
       trim(nome) as nome,
       i_cidades, 
       count(nome) as quantidade
  from bethadba.ruas 
 group by nome, i_cidades
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os nomes dos logradouros duplicados para evitar duplicidade

update bethadba.ruas
   set nome = i_ruas || '-' || nome
 where i_ruas in (select i_ruas
                    from bethadba.ruas
                   where (select count(1)
                            from bethadba.ruas r
                           where (r.i_cidades = ruas.i_cidades or r.i_cidades is null)
                             and trim(r.nome) = trim(ruas.nome)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 1.sql

-- FOLHA - Validação: FOLHA - Validação - 10.sql

-- VALIDAÇÃO 10 
-- PIS inválido

select pessoas.i_pessoas
  from bethadba.pessoas 
  left join bethadba.pessoas_fisicas
 where bethadba.dbf_chk_pis(num_pis) > 0
   and pessoas.tipo_pessoa != 'J'
   and num_pis is not null;


-- CORREÇÃO
-- Atualiza os PIS's inválidos para nulo
                 
update bethadba.pessoas_fisicas 
   set num_pis = null 
 where i_pessoas in (select pessoas.i_pessoas
                       from bethadba.pessoas 
                       left join bethadba.pessoas_fisicas
                      where bethadba.dbf_chk_pis(num_pis) > 0
   and pessoas.tipo_pessoa != 'J'
   and num_pis is not null);

-- FIM DO ARQUIVO FOLHA - Validação - 10.sql

-- FOLHA - Validação: FOLHA - Validação - 100.sql

-- VALIDAÇÃO 100
-- Estagiários sem informação na tabela estagios

select i_funcionarios
  from bethadba.hist_funcionarios as hf,
       bethadba.vinculos as v
 where v.i_vinculos = hf.i_vinculos
   and v.categoria_esocial = 901
   and hf.i_funcionarios not in (select e.i_funcionarios
   								   from bethadba.estagios as e
   							      where e.i_entidades = hf.i_entidades
									and e.i_funcionarios = hf.i_funcionarios);


-- CORREÇÃO
-- Insere os estagiários na tabela estagios com informações padrão

insert into bethadba.estagios (i_entidades, i_funcionarios, i_formacoes, i_atos, i_pessoas, dt_inicial, dt_final, nivel_curso, periodo, fase, num_contrato, dt_prorrog, objetivo, seguro_vida, num_apolice, estagio_obrigatorio)
  with FirstRight as (select *,
                             row_number() over (partition by i_funcionarios order by i_funcionarios) as rn
					              from bethadba.hist_funcionarios)
select fu.i_entidades,
       fu.i_funcionarios,
       ISNULL(fu.i_formacoes_estagio, '1') as i_formacoes,
       null as i_atos,
       3732 as i_pessoas, -- Essa pessoa aqui é o código da pessoa jurídica vinculada ao estágio. Cada entidade deve-se alterar esse código para o correto.
       fu.dt_admissao as dt_inicial,
       '2999-12-31' as dt_final,
       '2' as nivel_curso,
       '1' as periodo,
       'NI' as fase,
       null as num_contrato,
       null as dt_prorrog,
       null as objetivo,
       'N' as seguro_vida,
       null as num_apolice,
       'N' as estagio_obrigatorio
  from bethadba.funcionarios as fu
  left join FirstRight as f
    on (f.i_entidades = fu.i_entidades
   and f.i_funcionarios = fu.i_funcionarios
   and f.rn = 1)
  join bethadba.vinculos as v
    on v.i_vinculos = f.i_vinculos
  join bethadba.pessoas as p
    on fu.i_pessoas = p.i_pessoas
 where v.categoria_esocial = 901
   and fu.i_funcionarios not in (select e.i_funcionarios
                                   from bethadba.estagios as e
                                  where e.i_entidades = fu.i_entidades
                                    and e.i_funcionarios = fu.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 100.sql

-- FOLHA - Validação: FOLHA - Validação - 101.sql

-- VALIDAÇÃO 101
-- Verifica os bancos fora do padrao

select i_pessoas
  from bethadba.pessoas_contas
 where i_bancos >= 758
   and i_bancos != 800;


-- CORREÇÃO
-- Atualiza os bancos fora do padrão para o banco 800 (Banco do Brasil)

update bethadba.pessoas_contas
   set i_bancos = 800
 where i_bancos >= 758
   and i_bancos != 800;

-- FIM DO ARQUIVO FOLHA - Validação - 101.sql

-- FOLHA - Validação: FOLHA - Validação - 102.sql

-- VALIDAÇÃO 102
-- Pessoas com nome das ruas cadastrados sem codigo das ruas

select i_pessoas, nome_rua
  from bethadba.pessoas_enderecos
 where nome_rua is not null
   and i_ruas is null;


-- CORREÇÃO
-- Insere os logradouros na tabela ruas e atualiza o código das ruas na tabela pessoas_enderecos

begin
  declare w_pessoa integer;
  declare w_nome_rua varchar(120);
  declare w_conta integer;
 
  set w_conta = 49; -- Informar aqui o último código de logradouro cadastrado no sistema
 
  llloop: for ll as cursor2 dynamic scroll cursor for
	  select i_pessoas,
           nome_rua
      from bethadba.pessoas_enderecos
     where nome_rua is not null and i_ruas is null
  do
    set w_conta = w_conta + 1;
    set w_pessoa = i_pessoas;
    set w_nome_rua = nome_rua;

    insert into bethadba.ruas (i_ruas, i_ruas_ini, i_ruas_fim, i_cidades, nome, tipo, cep. epigrafe, lei, zona_fiscal, extensao, dia_vcto, i_sefaz) 
    values (w_conta, null, null, null, w_nome_rua, 57, null, null, null, null, null, null);

    update bethadba.pessoas_enderecos
       set i_ruas = w_conta
     where i_ruas is null
       and i_pessoas = w_pessoa
       and nome_rua = w_nome_rua;
  end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 102.sql

-- FOLHA - Validação: FOLHA - Validação - 103.sql

-- VALIDAÇÃO 103
-- Verifica o pensionista com data menor que rescisão da matricula de origem com pensão por morte

select beneficiarios.i_funcionarios
  from bethadba.beneficiarios,
       bethadba.rescisoes,
       bethadba.funcionarios
 where beneficiarios.i_entidades = rescisoes.i_entidades 
   and beneficiarios.i_instituidor = rescisoes.i_funcionarios
   and beneficiarios.i_funcionarios = funcionarios.i_funcionarios 
   and beneficiarios.i_entidades = funcionarios.i_entidades
   and funcionarios.tipo_pens = 1
   and rescisoes.trab_dia_resc = 'S'
   and funcionarios.dt_admissao <= rescisoes.dt_rescisao;


-- CORREÇÃO
-- Atualiza a data de admissão do funcionário para o dia seguinte da rescisão
-- Isso garante que a data de admissão não seja anterior à data de rescisão

update bethadba.funcionarios
   set funcionarios.dt_admissao = dateadd(day, 1, rescisoes.dt_rescisao)
  from bethadba.beneficiarios , bethadba.rescisoes , bethadba.funcionarios 
 where beneficiarios.i_entidades = rescisoes.i_entidades
   and beneficiarios.i_instituidor = rescisoes.i_funcionarios
   and beneficiarios.i_funcionarios = funcionarios.i_funcionarios
   and beneficiarios.i_entidades = funcionarios.i_entidades 
   and funcionarios.dt_admissao<=  rescisoes.dt_rescisao;

-- FIM DO ARQUIVO FOLHA - Validação - 103.sql

-- FOLHA - Validação: FOLHA - Validação - 104.sql

-- VALIDAÇÃO 104
-- Eventos sem histórico

select e.i_eventos
  from bethadba.eventos as e
 where e.i_eventos not in (select he.i_eventos
 					  		 from bethadba.hist_eventos as he
 							where he.i_eventos = e.i_eventos);


-- CORREÇÃO
-- Insere os eventos que não possuem histórico na tabela de histórico de eventos

insert into bethadba.hist_eventos
            (i_eventos,
             nome,
             taxa,
             sai_rais,
             compoe_hmes,
             classif_evento,
             desativado,
             codigo_tce,
             inverte_compoe_liq,
             dt_criacao,
             grupo_provisao,
             i_eventos_provisao,
             i_eventos_ajuste_neg,
             i_eventos_distorcao_pos,
             i_eventos_abono,
             i_eventos_fervenc,
             i_eventos_pensmor13,
             deduc_fundo_financ,
             i_atos,
             envia_fly_transparencia,
             montar_base_fgts_integral_afast,
             i_competencias,
             tipo_pd,
             unidade,
             compoe_liq,
             digitou_form,
             cods_conversao,
             seq_impressao,
             descricao,
             caracteristica,
             deduc_prevmun,
             classif_provisao,
             i_eventos_ajuste_pos,
             i_eventos_estorno,
             i_eventos_distorcao_neg,
             i_eventos_ferprop,
             i_eventos_fercoletiva,
             i_agrupadores,
             natureza)
	 select i_eventos,
	 	    nome,taxa,
 		    sai_rais,
 		    compoe_hmes,
		    classif_evento,
		    desativado,
		    codigo_tce,
		    inverte_compoe_liq,
		    dt_criacao,
		    grupo_provisao,
		    i_eventos_provisao,
		    i_eventos_ajuste_neg,
		    i_eventos_distorcao_pos,
		    i_eventos_abono,
		    i_eventos_fervenc,
		    i_eventos_pensmor13,
		    deduc_fundo_financ,
		    i_atos,
		    envia_fly_transparencia,
		    montar_base_fgts_integral_afast,
		    '1900-01-01',
		    tipo_pd,
		    unidade,
		    compoe_liq,
		    digitou_form,
		    cods_conversao,
		    seq_impressao,
		    descricao,
		    caracteristica,
		    deduc_prevmun,
		    classif_provisao,
		    i_eventos_ajuste_pos,
		    i_eventos_estorno,
		    i_eventos_distorcao_neg,
		    i_eventos_ferprop,
		    i_eventos_fercoletiva,
		    i_agrupadores,
	   		natureza
  	   from bethadba.eventos as e
	  where e.i_eventos not in (select he.i_eventos
 	  	 				  		  from bethadba.hist_eventos as he
	 							 where he.i_eventos = e.i_eventos);

-- FIM DO ARQUIVO FOLHA - Validação - 104.sql

-- FOLHA - Validação: FOLHA - Validação - 105.sql

-- VALIDAÇÃO 105
-- Verifica Faltas que tenham competência de desconto quando o tipo da falta for (1 - Em dias)

select i_entidades, 
       i_funcionarios,
       tipo_faltas
  from bethadba.faltas 
 where tipo_faltas = 1
   and comp_descto is not null
   and tipo_descto = 1;


-- CORREÇÃO
-- Atualiza a competência de desconto para nulo quando o tipo da falta for (1 - Em dias)

update bethadba.faltas
   set comp_descto = null
 where tipo_faltas = 1
   and comp_descto is not null
   and tipo_descto = 1;

-- FIM DO ARQUIVO FOLHA - Validação - 105.sql

-- FOLHA - Validação: FOLHA - Validação - 106.sql

-- VALIDAÇÃO 106
-- Pessoas com certidão de nasicmento maior que 32 caracteres

select i_pessoas,
       num_reg
  from bethadba.pessoas_fis_compl
 where length(num_reg)  > 32;


-- CORREÇÃO
-- Atualiza o campo num_reg para null onde o tamanho é maior que 32 caracteres

update bethadba.pessoas_fis_compl
   set num_reg = null
 where length(num_reg) > 32;

-- FIM DO ARQUIVO FOLHA - Validação - 106.sql

-- FOLHA - Validação: FOLHA - Validação - 107.sql

-- VALIDAÇÃO 107
-- Funcionario com data de fim de lotação maior que a data de fim de contrato

select f.i_entidades,
       f.i_funcionarios,
       f.dt_final,
       fv.dt_fim_vinculo
  from bethadba.locais_mov f
  left join bethadba.funcionarios_vinctemp fv 
    on f.i_funcionarios = fv.i_funcionarios
 where f.dt_final > fv.dt_fim_vinculo;


-- CORREÇÃO
-- Atualiza a data final da lotação para a data de fim do vínculo temporário apenas para os casos onde a data final da lotação é maior que a data de fim

update bethadba.locais_mov
   set dt_final = dt_fim_vinculo
  from bethadba.locais_mov lm
  left join bethadba.funcionarios_vinctemp vt
    on lm.i_funcionarios = vt.i_funcionarios
 where lm.dt_final > vt.dt_fim_vinculo;

-- FIM DO ARQUIVO FOLHA - Validação - 107.sql

-- FOLHA - Validação: FOLHA - Validação - 108.sql

-- VALIDAÇÃO 108
-- Verifica o pensionista que esta com o campo tipo_pens null

select f.i_entidades,
       f.i_funcionarios, 
       f.tipo_pens  
  from bethadba.funcionarios f 
  join bethadba.hist_funcionarios hf
    on f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades 
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos 
 where f.tipo_pens is null
   and v.tipo_func = 'B'
   and v.categoria_esocial is null;


-- CORREÇÃO
-- Atualiza o campo tipo_pens para 1 (pensão por morte) para os pensionistas que estão com o campo tipo_pens como null

update bethadba.funcionarios as f
   set f.tipo_pens = 1
  from bethadba.hist_funcionarios hf,
       bethadba.vinculos v 
 where f.tipo_pens is null
   and f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
   and hf.i_vinculos = v.i_vinculos
   and v.tipo_func = 'B'
   and v.categoria_esocial is null;

-- FIM DO ARQUIVO FOLHA - Validação - 108.sql

-- FOLHA - Validação: FOLHA - Validação - 109.sql

-- VALIDAÇÃO 109
-- Busca as pessoas estrangeiras com data de nascimento maior que data de chegada

select pf.i_pessoas,
       pf.dt_nascimento,
       pe.data_chegada  
  from bethadba.pessoas_fisicas pf 
  join bethadba.pessoas_estrangeiras pe
    on pf.i_pessoas = pe.i_pessoas 
 where pf.dt_nascimento > pe.data_chegada;


-- CORREÇÃO
-- Atualiza a data de chegada para ser igual à data de nascimento + 1 dia se a data de nascimento for maior que a data de chegada

update bethadba.pessoas_fisicas a
  join bethadba.pessoas_estrangeiras b
    on (a.i_pessoas = b.i_pessoas)
   set data_chegada = dateadd(dd,1,dt_nascimento)
 where a.dt_nascimento > b.data_chegada;

-- FIM DO ARQUIVO FOLHA - Validação - 109.sql

-- FOLHA - Validação: FOLHA - Validação - 11.sql

-- VALIDAÇÃO 11
-- Verifica CNPJ Nulo

select pj.i_pessoas
  from bethadba.pessoas_juridicas pj 
 inner join bethadba.pessoas p
    on (pj.i_pessoas = p.i_pessoas)
 where cnpj is null;


-- CORREÇÃO
-- Atualiza os CNPJ nulos para 0 para evitar erros de validação.

-- Cria tabela temporária com os CNPJs gerados
create local temporary table tmp_cnpj (i_pessoas integer, novo_cnpj varchar(14));

insert into tmp_cnpj (i_pessoas, novo_cnpj)
select i_pessoas,
       right('000000000000' || cast(row_num as varchar(12)), 12) || '91'
  from (select i_pessoas, row_number() over (order by i_pessoas) as row_num
          from bethadba.pessoas_juridicas
         where cnpj is null) as t;

-- Atualiza os registros usando a tabela temporária
update bethadba.pessoas_juridicas pj
   set cnpj = tmp.novo_cnpj
  from tmp_cnpj tmp
 where pj.i_pessoas = tmp.i_pessoas
   and pj.cnpj is null;

drop table tmp_cnpj;

-- FIM DO ARQUIVO FOLHA - Validação - 11.sql

-- FOLHA - Validação: FOLHA - Validação - 110.sql

-- VALIDAÇÃO 110
-- Verifica afastamentos concomitantes do mesmo funcionario

select a.i_entidades,
       a.i_funcionarios,
       a.dt_afastamento,
       isnull(a.dt_ultimo_dia, a.dt_afastamento) as dt_ultimo_dia,
       temRescisao = (select 1
       					        from bethadba.tipos_afast ta
       				         where ta.i_tipos_afast = a.i_tipos_afast
       				           and ta.classif = 8),
       trabalhouUltimoDia = if temRescisao is not null then
                              (select r.trab_dia_resc
                                 from bethadba.rescisoes r
                          		   join bethadba.motivos_resc mr
                                   on r.i_motivos_resc = mr.i_motivos_resc
                                 join bethadba.tipos_afast ta2
                                   on mr.i_tipos_afast = ta2.i_tipos_afast
                                where r.i_entidades = a.i_entidades
                                  and r.i_funcionarios = a.i_funcionarios
                                  and ta2.classif in (8,9))
                            else
                              'N'
                            endif
  from bethadba.afastamentos a
  join bethadba.afastamentos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
 where (a.dt_afastamento between b.dt_afastamento and b.dt_ultimo_dia or a.dt_ultimo_dia between b.dt_afastamento and b.dt_ultimo_dia)
   and (a.dt_afastamento <> b.dt_afastamento or a.dt_ultimo_dia <> b.dt_ultimo_dia)
   and temRescisao is null
   and (trabalhouUltimoDia is null or trabalhouUltimoDia = 'N');


-- CORREÇÃO
-- Atualiza a data do último dia do afastamento para funcionários que possuem afastamentos concomitantes

update bethadba.afastamentos a
  join bethadba.afastamentos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
   and (a.dt_afastamento between b.dt_afastamento and b.dt_ultimo_dia or a.dt_ultimo_dia between b.dt_afastamento and b.dt_ultimo_dia)
   and (a.dt_afastamento <> b.dt_afastamento or a.dt_ultimo_dia <> b.dt_ultimo_dia)
   set a.dt_ultimo_dia = dateadd(dd, -1, b.dt_afastamento)
 where a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
   and (a.dt_afastamento between b.dt_afastamento and b.dt_ultimo_dia or a.dt_ultimo_dia between b.dt_afastamento and b.dt_ultimo_dia)
   and (a.dt_afastamento <> b.dt_afastamento or a.dt_ultimo_dia <> b.dt_ultimo_dia);

-- FIM DO ARQUIVO FOLHA - Validação - 110.sql

-- FOLHA - Validação: FOLHA - Validação - 111.sql

-- VALIDAÇÃO 111
-- Verifica ferias concomitantes do mesmo funcionario

select a.i_funcionarios,
       a.dt_gozo_ini ,
       a.dt_gozo_fin
  from bethadba.ferias a 
  join bethadba.ferias b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios 
 where (a.dt_gozo_ini between b.dt_gozo_ini and b.dt_gozo_fin or a.dt_gozo_fin between b.dt_gozo_ini and b.dt_gozo_fin)
   and (a.dt_gozo_ini <> b.dt_gozo_ini or a.dt_gozo_fin <> b.dt_gozo_fin);


-- CORREÇÃO
-- Atualiza as datas de gozo das férias para evitar sobreposição, ajustando a data inicial ou final conforme necessário

update bethadba.ferias a
   set a.dt_gozo_ini = case when a.dt_gozo_ini between b.dt_gozo_ini and b.dt_gozo_fin then
                            DATEADD(day, 1, b.dt_gozo_fin)
                       else
                            a.dt_gozo_ini
                       end,
       a.dt_gozo_fin = case when a.dt_gozo_fin between b.dt_gozo_ini and b.dt_gozo_fin then
                            DATEADD(day, -1, b.dt_gozo_ini)
                       else
                            a.dt_gozo_fin 
                       end
  from bethadba.ferias b
 where a.i_funcionarios = b.i_funcionarios 
   and (a.dt_gozo_ini between b.dt_gozo_ini and b.dt_gozo_fin or a.dt_gozo_fin between b.dt_gozo_ini and b.dt_gozo_fin)
   and (a.dt_gozo_ini <> b.dt_gozo_ini or a.dt_gozo_fin <> b.dt_gozo_fin);

-- FIM DO ARQUIVO FOLHA - Validação - 111.sql

-- FOLHA - Validação: FOLHA - Validação - 112.sql

-- VALIDAÇÃO 112
-- Verifica os afastamentos concomitantes com ferias do funcionário

select a.i_funcionarios,
       a.dt_afastamento,
       a.dt_ultimo_dia,
       b.dt_gozo_ini,
       b.dt_gozo_fin
  from bethadba.afastamentos a 
  join bethadba.ferias b
    on a.i_funcionarios = b.i_funcionarios 
 where a.dt_afastamento between b.dt_gozo_ini and b.dt_gozo_fin;


-- CORREÇÃO
-- Atualiza a data inicial do afastamento para o dia seguinte ao término das férias para os funcionários que possuem afastamentos concomitantes com férias
                
update bethadba.afastamentos as a
   set a.dt_afastamento = DATEADD(dd, 1, b.dt_gozo_fin)
  from bethadba.ferias as b
 where a.dt_afastamento between b.dt_gozo_ini and b.dt_gozo_fin
   and a.i_funcionarios = b.i_funcionarios
   and not exists (select 1
			               from bethadba.afastamentos as a2
      		          where a2.i_funcionarios = a.i_funcionarios
			                and a2.dt_afastamento = DATEADD(dd, 1, b.dt_gozo_fin));

-- FIM DO ARQUIVO FOLHA - Validação - 112.sql

-- FOLHA - Validação: FOLHA - Validação - 113.sql

-- VALIDAÇÃO 113
-- Verifica os afastamentos concomitantes com ferias do funcionario

select a.i_funcionarios,
       a.dt_inicial,
       b.dt_afastamento,
       b.dt_ultimo_dia
  from bethadba.faltas a 
  join bethadba.afastamentos b
    on a.i_funcionarios = b.i_funcionarios 
 where a.dt_inicial between b.dt_afastamento and b.dt_ultimo_dia and a.i_entidades = b.i_entidades;


-- CORREÇÃO
-- Atualiza a data do afastamento para o dia seguinte ao término da falta para os funcionários que possuem afastamentos concomitantes com faltas

update bethadba.afastamentos as a
   set a.dt_afastamento = DATEADD(dd, 1, b.dt_inicial)
  from bethadba.faltas as b
 where a.dt_afastamento between b.dt_inicial and b.dt_ultimo_dia
   and a.i_funcionarios = b.i_funcionarios
   and a.i_entidades = b.i_entidades
   and not exists (select 1
                     from bethadba.afastamentos as a2
      		        where a2.i_funcionarios = a.i_funcionarios
                      and a2.dt_afastamento = DATEADD(dd, 1, b.dt_inicial));

-- FIM DO ARQUIVO FOLHA - Validação - 113.sql

-- FOLHA - Validação: FOLHA - Validação - 114.sql

-- VALIDAÇÃO 114
-- Verifica as faltas concomitantes com as ferias do funcionario

select a.i_funcionarios,
       a.dt_inicial
  from bethadba.faltas a 
  join bethadba.ferias b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
 where a.dt_inicial between b.dt_gozo_ini and b.dt_gozo_fin;


-- CORREÇÃO
-- Atualiza a data inicial da falta para o dia seguinte ao término das férias para os funcionários que possuem faltas concomitantes com férias

delete bethadba.faltas as a
  from bethadba.ferias as b
 where a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
   and a.dt_inicial between b.dt_gozo_ini and b.dt_gozo_fin;

-- FIM DO ARQUIVO FOLHA - Validação - 114.sql

-- FOLHA - Validação: FOLHA - Validação - 115.sql

-- VALIDAÇÃO 115
-- Verifica os funcionarios sem historico de funcionarios

select distinct i_funcionarios 
  from bethadba.funcionarios
 where i_funcionarios not in (select i_funcionarios
                                from bethadba.hist_funcionarios);


-- CORREÇÃO
-- Insere o histórico de funcionários para os funcionários que não possuem histórico, utilizando os dados atuais dos funcionários

insert into bethadba.hist_funcionarios(i_entidades,i_funcionarios,dt_alteracoes,i_config_organ,i_organogramas,i_grupos,i_vinculos,i_pessoas,i_bancos,i_agencias,i_pessoas_contas,i_horarios,
func_princ,i_agentes_nocivos,optante_fgts,prev_federal,prev_estadual,fundo_ass,fundo_prev,ocorrencia_sefip,forma_pagto,multiplic,tipo_contrato,fundo_financ,remunerado_cargo_efetivo,
i_turmas,num_quadro_cp,num_cp,provisorio,bate_cartao,i_pessoas_estagio,dt_final_estagio,nivel_curso_estagio,num_apolice_estagio,estagio_obrigatorio_estagio,i_agente_integracao_estagio,
i_supervisor_estagio,controle_jornada,grau_exposicao,tipo_admissao,tipo_trabalhador,i_sindicatos,seguro_vida_estagio,categoria,desc_salario_variavel,duracao_ben,dt_vencto,tipo_beneficio,
i_responsaveis,tipo_ingresso,aposentado,recebe_abono)
select a.i_entidades,
       a.i_funcionarios,
       a.dt_admissao as dt_alteracoes,
       1 as i_config_organ,
       '0101' as i_organogramas,
       1 as i_grupos,
       5 as i_vinculos,
       a.i_pessoas,
       null as i_bancos,
       null as i_agencias,
       null as i_pessoas_contas,
       null as i_horarios,
       null as func_princ,
       null as i_agentes_nocivos,
       'N' as optante_fgts,
       'S' as prev_federal,
       'N' as prev_estadual,
       'N' as fundo_ass,
       'N' as fundo_prev,
       0 as ocorrencia_sefip,
       'R' as forma_pagto,
       1 as multiplic,
       null as tipo_contrato,
       'N' as fundo_financ,
       'N' as remunerado_cargo_efetivo,
       null as i_turmas,
       null as num_quadro_cp,
       null as num_cp,
       null as provisorio,
       null as bate_cartao,
       null as i_pessoas_estagio,
       null as dt_final_estagio,
       null as nivel_curso_estagio,
       null as num_apolice_estagio,
       null as estagio_obrigatorio_estagio,
       null as i_agente_integracao_estagio,
       null as i_supervisor_estagio,
       null as controle_jornada,
       null as grau_exposicao,
       null as tipo_admissao,
       null as tipo_trabalhador,
       null as i_sindicatos,
       null as seguro_vida_estagio,
       'M' as categoria,
       null as desc_salario_variavel,
       null as duracao_ben,
       null as dt_vencto,
       null as tipo_beneficio,
       null as i_responsaveis,
       null as tipo_ingresso,
       null as aposentado,
       null as recebe_abono
  from bethadba.funcionarios a
 where i_funcionarios in (select z.i_funcionarios
                            from bethadba.funcionarios z
                           where i_funcionarios not in (select i_funcionarios
                                                          from bethadba.hist_funcionarios));

-- FIM DO ARQUIVO FOLHA - Validação - 115.sql

-- FOLHA - Validação: FOLHA - Validação - 116.sql

-- VALIDAÇÃO 116
-- Verifica os funcionarios sem historico de cargo

select i_funcionarios
  from bethadba.funcionarios  
 where i_funcionarios not in (select i_funcionarios
                                from bethadba.hist_cargos);


-- CORREÇÃO
-- Insere o histórico de cargo para os funcionários que não possuem histórico, assumindo o cargo atual como o último

insert into bethadba.hist_cargos
       (i_entidades,
        i_funcionarios,
        dt_alteracoes,
        dt_saida,
        i_cargos,
        i_motivos_altcar,
        i_atos,
        i_concursos,
        dt_nomeacao,
        dt_posse,
        i_atos_saida,
        parecer_contr_interno,
        afim,
        desconsidera_rotina_prorrogacao,
        desconsidera_rotina_rodada,
        dt_exercicio,
        reabilitado_readaptado)
select f.i_entidades,
       f.i_funcionarios,
       CAST(f.dt_admissao AS datetime),
       null,
       'INFORMAR O CARGO A SER VINCULADO A MATRÍCULA',
       null,
       null,
       null,
       null,
       null,
       null,
       'S',
       null,
       'N',
       'N',
       f.dt_admissao, -- já está no formato date
       null
  from bethadba.funcionarios f
 where f.i_funcionarios not in (select i_funcionarios
                                  from bethadba.hist_cargos);

-- FIM DO ARQUIVO FOLHA - Validação - 116.sql

-- FOLHA - Validação: FOLHA - Validação - 117.sql

-- VALIDAÇÃO 117
-- Verifica os funcionarios sem historico

select f.i_funcionarios
  from bethadba.funcionarios as f
 where f.i_funcionarios not in (select hs.i_funcionarios
 								                  from bethadba.hist_salariais as hs);


-- CORREÇÃO
-- Insere o histórico salarial para os funcionários que não possuem histórico, assumindo o salário atual como o último

insert into bethadba.hist_salariais
       (i_entidades,
        i_funcionarios,
        dt_alteracoes,
        i_niveis,
        i_clas_niveis,
        i_referencias,
        i_motivos_altsal,
        i_atos,salario,
        horas_mes,
        horas_sem,
        observacao,
        controla_jornada_parc,
        deduz_iss,
        aliq_iss,
        qtd_dias_servico,
        dt_alteracao_esocial,
        dt_chave_esocial)
select f.i_entidades,
       f.i_funcionarios,
       CAST(f.dt_admissao AS datetime),
       null,
       null,
       null,
       null,
       null,
       0.01,
       200.00,
       40.00,
       null,
       null,
       null,
       null,
       null,
       null,
       f.dt_admissao -- já está no formato date
  from bethadba.funcionarios f
 where f.i_funcionarios not in (select hs.i_funcionarios
                                  from bethadba.hist_salariais as hs);

-- FIM DO ARQUIVO FOLHA - Validação - 117.sql

-- FOLHA - Validação: FOLHA - Validação - 118.sql

-- VALIDAÇÃO 118
-- Verifica quantidade de licenças prêmios

select i_licpremio_config,
       i_faixas
  from bethadba.licpremio_faixas
 where i_faixas > 99;


-- CORREÇÃO
-- Atualiza as faixas de licenças prêmios para o valor 99, que é o valor máximo permitido

update bethadba.licpremio_faixas
   set i_faixas = 99
 where i_faixas = 999;

-- FIM DO ARQUIVO FOLHA - Validação - 118.sql

-- FOLHA - Validação: FOLHA - Validação - 119.sql

-- VALIDAÇÃO 119
-- O autônomo deve ter serviço lançado para todos os meses compreendidos pelo lançamento de variáveis

select v.i_entidades,
       v.i_funcionarios,
       isnull(count((hs.dt_alteracoes)),0) as quantidade,
       v.dt_inicial,
       v.dt_final,
       mes = if DATEDIFF(month, v.dt_inicial, v.dt_final) = 0 then
       			if v.dt_inicial = v.dt_final then
       				1
       			else
       				0
       			endif
             else
                DATEDIFF(month, v.dt_inicial, v.dt_final)
             endif
  from bethadba.variaveis v
  join bethadba.hist_salariais hs
    on v.i_entidades = hs.i_entidades
   and v.i_funcionarios = hs.i_funcionarios
  join bethadba.funcionarios f
    on hs.i_entidades = f.i_entidades
   and hs.i_funcionarios = f.i_funcionarios
 where isnull(date(hs.dt_alteracoes),GETDATE()) between v.dt_inicial and v.dt_final
   and f.tipo_func = 'A'
   and f.conselheiro_tutelar = 'N'
 group by hs.i_entidades, hs.i_funcionarios,v.dt_inicial, v.dt_final, v.i_funcionarios, v.i_entidades
having quantidade < mes
 order by v.i_entidades,v.i_funcionarios;


-- CORREÇÃO
-- Excluir as variáveis que não possuem serviço lançado para todos os meses compreendidos pelo lançamento de variáveis

delete from bethadba.variaveis
 where exists (select 1  
                 from bethadba.hist_salariais hs  
                 join bethadba.funcionarios f  
                   on hs.i_entidades = f.i_entidades  
                  and hs.i_funcionarios = f.i_funcionarios  
                where hs.i_entidades = variaveis.i_entidades  
                  and hs.i_funcionarios = variaveis.i_funcionarios  
                  and ISNULL(date(hs.dt_alteracoes), GETDATE()) between variaveis.dt_inicial and variaveis.dt_final  
                  and f.tipo_func = 'A'  
                  and f.conselheiro_tutelar = 'N'  
                group by hs.i_entidades, hs.i_funcionarios 
               having ISNULL(count((hs.dt_alteracoes)), 0) < (case when DATEDIFF(month, variaveis.dt_inicial, variaveis.dt_final) = 0 then   
                                                                 case when variaveis.dt_inicial = variaveis.dt_final then
                                                                     1
                                                                 else
                                                                     0  
                                                                 end  
                                                              else
                                                                 DATEDIFF(month, variaveis.dt_inicial, variaveis.dt_final)  
                                                              end));

-- FIM DO ARQUIVO FOLHA - Validação - 119.sql

-- FOLHA - Validação: FOLHA - Validação - 12.sql

-- VALIDAÇÃO 12
-- Verifica a descrição dos logradouros que tem caracter especial no inicio da descrição

select substring(nome, 1, 1) as nome_com_caracter,
       i_ruas
  from bethadba.ruas 
 where nome_com_caracter in ('[', ']');


-- CORREÇÃO
-- Retira o caracter especial do inicio da descrição dos logradouros

update bethadba.ruas
   set nome = ltrim(nome, '[]')
 where substring(nome, 1, 1) in ('[', ']');

-- FIM DO ARQUIVO FOLHA - Validação - 12.sql

-- FOLHA - Validação: FOLHA - Validação - 120.sql

-- VALIDAÇÃO 120
-- Concursos sem data de homologação informada

select concursos.i_entidades, 
       concursos.i_concursos,
       candidatos.i_candidatos,
       concursos.dt_homolog
  from bethadba.candidatos
  left join bethadba.concursos
    on candidatos.i_concursos = concursos.i_concursos
 where candidatos.dt_nomeacao is null
   and candidatos.dt_posse is null
   and candidatos.dt_doc_nao_posse is null
   and candidatos.dt_prorrog_posse is null
   and concursos.dt_homolog is null;


-- CORREÇÃO
-- Atualiza a data de homologação para 30 dias após o início das inscrições

update bethadba.candidatos 
  left join bethadba.concursos
    on candidatos.i_concursos = concursos.i_concursos
   set dt_homolog = dateadd(dd,30,dt_ini_insc)
 where i_candidatos in (select candidatos.i_candidatos
                          from bethadba.candidatos
                          left join bethadba.concursos
                            on candidatos.i_concursos = concursos.i_concursos
                         where candidatos.dt_nomeacao is null
                           and candidatos.dt_posse is null
                           and candidatos.dt_doc_nao_posse is null
                           and candidatos.dt_prorrog_posse is null
                           and concursos.dt_homolog is null)
   and dt_homolog is null;

-- FIM DO ARQUIVO FOLHA - Validação - 120.sql

-- FOLHA - Validação: FOLHA - Validação - 121.sql

-- VALIDAÇÃO 121
-- Verifica locais de avaliação sem números de sala

select i_pessoas,
       i_locais_aval
  from bethadba.locais_aval
 where num_sala is null
    or num_sala = ' ';


-- CORREÇÃO
-- Atualiza o número da sala para 1

update bethadba.locais_aval 
   set num_sala = 1
 where i_pessoas in (select i_pessoas
                       from bethadba.locais_aval
                      where num_sala is null
                         or num_sala = ' ')
   and num_sala is null
    or num_sala = ' ';

-- FIM DO ARQUIVO FOLHA - Validação - 121.sql

-- FOLHA - Validação: FOLHA - Validação - 122.sql

-- VALIDAÇÃO 122
-- Configuração Rais sem controle de ponto

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where sistema_ponto is null
   and i_parametros_rel = 2;


-- CORREÇÃO
-- Configuração Rais sem controle de ponto

update bethadba.parametros_rel
   set sistema_ponto = coalesce(
       (select top 1 sistema_ponto
          from bethadba.parametros_rel
         where sistema_ponto is not null
           and i_parametros_rel = 2
         group by sistema_ponto
         order by count(*) desc
       ), 1)
 where sistema_ponto is null
   and i_parametros_rel = 2;

-- FIM DO ARQUIVO FOLHA - Validação - 122.sql

-- FOLHA - Validação: FOLHA - Validação - 123.sql

-- VALIDAÇÃO 123
-- Configuração Rais com tipo de inscrição inválida

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and (tipo_insc is null or tipo_insc = 'C');


-- CORREÇÃO
-- Atualiza o tipo de inscrição para 'F' (Pessoa Física) na configuração do RAIS

update bethadba.parametros_rel
   set tipo_insc = 'F'
 where i_parametros_rel = 2
   and (tipo_insc is null or tipo_insc = 'C');

-- FIM DO ARQUIVO FOLHA - Validação - 123.sql

-- FOLHA - Validação: FOLHA - Validação - 124.sql

-- VALIDAÇÃO 124
-- Configuração Rais sem controle de ponto

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and mes_base is null;


-- CORREÇÃO
-- Atualiza o mês base para outubro de 2023 para o parâmetro de controle de ponto sem controle de ponto que não possui mês base definido.

update bethadba.parametros_rel
   set mes_base = '2023-10-01'
 where i_parametros_rel = 2
   and mes_base is null;

-- FIM DO ARQUIVO FOLHA - Validação - 124.sql

-- FOLHA - Validação: FOLHA - Validação - 125.sql

-- VALIDAÇÃO 125
-- Configuração Rais sem responsável

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and nome_resp is null;


-- CORREÇÃO
-- Atualiza o responsável para a configuração Rais caso não tenha responsável cadastrado

update bethadba.parametros_rel
   set nome_resp = 'RAIS'
 where i_parametros_rel = 2
   and nome_resp is null;

-- FIM DO ARQUIVO FOLHA - Validação - 125.sql

-- FOLHA - Validação: FOLHA - Validação - 126.sql

-- VALIDAÇÃO 126
-- Configuração Rais com contato nulo

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and tipo_insc = 'J'
   and contato is null;


-- CORREÇÃO
-- Atualiza o contato para espaço em branco onde é nulo

update bethadba.parametros_rel
   set contato = 'CONTATO RAIS'
 where i_parametros_rel = 2
   and tipo_insc = 'J'
   and contato is null;

-- FIM DO ARQUIVO FOLHA - Validação - 126.sql

-- FOLHA - Validação: FOLHA - Validação - 127.sql

-- VALIDAÇÃO 127
-- Configuração Rais sem controle de ponto

select rc.campo
  from bethadba.rais_campos rc
 where exists (select 1
                 from bethadba.rais_eventos re
                where re.campo = rc.campo)
   and rc.cnpj is null;


-- CORREÇÃO
-- Atualiza os campos CNPJ que estão nulos para 0 para que não sejam considerados na validação e não gere erro de validação.

update bethadba.bethadba.rais_campos
   set CNPJ = right('000000000000' || cast((row_number() over) as varchar(12)), 12) || '91'
 where CNPJ is null;

-- FIM DO ARQUIVO FOLHA - Validação - 127.sql

-- FOLHA - Validação: FOLHA - Validação - 128.sql

-- VALIDAÇÃO 128
-- Pessoa fisica sem historico

select i_pessoas 
  from bethadba.pessoas_fisicas pf 
 where i_pessoas not in (select distinct(i_pessoas)
 						   from bethadba.hist_pessoas_fis hpf);


-- CORREÇÃO
-- Insere os registros de pessoas fisicas que não possuem historico na tabela de historico de pessoas fisicas.

insert into bethadba.hist_pessoas_fis (i_pessoas, dt_alteracoes, dt_nascimento, sexo, rg, orgao_emis_rg, uf_emis_rg, dt_emis_rg, cpf, num_pis, dt_pis, carteira_prof, serie_cart, uf_emis_carteira, dt_emis_carteira, zona_eleitoral, secao_eleitoral, titulo_eleitor, grau_instrucao, estado_civil, cnh, categoria_cnh, dt_vencto_cnh, dt_primeira_cnh, observacoes_cnh, dt_emissao_cnh, i_estados_cnh, ric, orgao_ric, dt_emissao_ric, raca, certidao, ddd, telefone, ddd_cel, celular, email, tipo_validacao, tipo_pessoa, ident_estrangeiro, dt_validade_est, tipo_visto_est, cart_trab_est, serie_cart_est, dt_exp_cart_est, dt_val_cart_est, i_paises, orgao_emissor_est, dt_emissao_est, i_paises_nacionalidade, data_chegada_est, ano_chegada_est, casado_brasileiro_est, filho_brasileiro_est, i_situacao_estrangeiro, residencia_fiscal_exterior, i_pais_residencia_fiscal, indicativo_nif, numero_identificacao_fiscal, forma_tributacao)
select i_pessoas, '2024-01-01', dt_nascimento, sexo, rg, orgao_emis_rg, uf_emis_rg, dt_emis_rg, cpf, num_pis, dt_pis , carteira_prof , serie_cart , uf_emis_carteira , dt_emis_carteira, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'F', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
  from bethadba.pessoas_fisicas 
 where i_pessoas in (select i_pessoas 
		       from bethadba.pessoas_fisicas as pf 
		      where i_pessoas not in (select distinct(i_pessoas)
					  	from bethadba.hist_pessoas_fis as hpf));

-- FIM DO ARQUIVO FOLHA - Validação - 128.sql

-- FOLHA - Validação: FOLHA - Validação - 129.sql

-- VALIDAÇÃO 129
-- A data a vigorar do ato não pode ser maior que a movimentação

select atos_func.i_funcionarios,
       atos.i_atos, atos_func.dt_movimento, dt_vigorar 
  from bethadba.atos_func
  left join bethadba.atos
    on atos_func.i_atos = atos.i_atos
 where atos.dt_vigorar > atos_func.dt_movimento;


-- CORREÇÃO
-- Atualiza a data a vigorar do ato para que não seja maior que a movimentação do ato.

update bethadba.atos_func as af
 inner join bethadba.atos as a
    on af.i_atos = a.i_atos
   set a.dt_vigorar = af.dt_movimento
 where a.dt_vigorar > af.dt_movimento;

-- FIM DO ARQUIVO FOLHA - Validação - 129.sql

-- FOLHA - Validação: FOLHA - Validação - 13.sql

-- VALIDAÇÃO 13
-- Verifica os bairros com descrição repetidos

select list(i_bairros) as idbairro, 
       trim(nome) as nomes, 
       count(nome) as quantidade
  from bethadba.bairros 
 group by nomes
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os nomes dos bairros repetidos para evitar duplicidade

update bethadba.bairros
   set bairros.nome = bairros.nome || ' - (Cod: ' || i_bairros  || ')'
 where bairros.i_bairros in (select codigo
				   		       from (select max(i_bairros) as codigo,
							   				nome
      				  				   from bethadba.bairros
      				  				  where (select count(i_bairros)
	   		 		 						   from bethadba.bairros as b
       		 			 					  where trim(b.nome) = trim(bairros.nome)) > 1
       		 		  	 	  		  group by nome) as maior);

-- FIM DO ARQUIVO FOLHA - Validação - 13.sql

-- FOLHA - Validação: FOLHA - Validação - 130.sql

-- VALIDAÇÃO 130
-- Cadastro agrupador de evento

select ae.i_agrupadores
  from bethadba.agrupadores_eventos ae
 where ordenacao is null;


-- CORREÇÃO
-- Atualiza a ordenação dos agrupadores de eventos que estão com ordenação nula com o valor do campo i_agrupadores

update bethadba.agrupadores_eventos
   set ordenacao = i_agrupadores
 where ordenacao is null;

-- FIM DO ARQUIVO FOLHA - Validação - 130.sql

-- FOLHA - Validação: FOLHA - Validação - 131.sql

-- VALIDAÇÃO 131
-- Data de alteração do histórico não pode ser menor que a data de nascimento

select i_pessoas
  from bethadba.hist_pessoas_fis
 where dt_nascimento > dt_alteracoes;


-- CORREÇÃO
-- Atualiza a data de alterações para 18 anos após a data de nascimento para os registros onde a data de nascimento é maior que a data de alterações

update bethadba.hist_pessoas_fis
   set dt_alteracoes = DATEADD(year, 18, dt_nascimento)
 where dt_nascimento > dt_alteracoes;

-- FIM DO ARQUIVO FOLHA - Validação - 131.sql

-- FOLHA - Validação: FOLHA - Validação - 132.sql

-- VALIDAÇÃO 132
-- Obrigatório informar a entidade educacional (S/N)

select i_entidades,
	     indicativo_entidade_educativa
  from bethadba.hist_entidades_compl as hec
 where indicativo_entidade_educativa is null;


-- CORREÇÃO
-- Atualiza o campo indicativo_entidade_educativa para 'N' onde está nulo (considerando que a entidade educacional não é obrigatória)

update bethadba.hist_entidades_compl
   set indicativo_entidade_educativa = 'N'
 where indicativo_entidade_educativa is null;

-- FIM DO ARQUIVO FOLHA - Validação - 132.sql

-- FOLHA - Validação: FOLHA - Validação - 133.sql

-- VALIDAÇÃO 133
-- Verifica a existência de data de fechamento de cálculo da folha

select funcionarios.i_funcionarios,
       dados_calc.dt_fechamento
  from bethadba.dados_calc,
       bethadba.funcionarios 
 where dados_calc.i_entidades = funcionarios.i_entidades
   and dados_calc.i_funcionarios = funcionarios.i_funcionarios
   and dt_fechamento is null;


-- CORREÇÃO
-- Adiciona data de fechamento de cálculo da folha para as entidades que não possuem data de fechamento de cálculo da folha

for a1 as a2 cursor for
    select xxi_ent = i_entidades,
           xxi_compe = i_competencias,
           i_competencias,
           linha = row_number() over (order by xxi_ent),
           xxdt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
      from bethadba.dados_calc dc 
     where dt_fechamento is null
do
    update bethadba.dados_calc
       set dt_fechamento = xxdt_fechamento
     where i_competencias < '2099-12-01'
       and i_entidades = xxi_ent;
       
    message 'Data de fechamento adicionada: ' || xxdt_fechamento || ', na competencia: ' || i_competencias || '. Linha: ' ||linha to client;
end for;

-- FIM DO ARQUIVO FOLHA - Validação - 133.sql

-- FOLHA - Validação: FOLHA - Validação - 134.sql

-- VALIDAÇÃO 134
-- Verifica os lançamentos posteriores a rescisão

select hf.i_entidades as chave_dsk1,
       hf.i_funcionarios as chave_dsk2,
       r.dt_rescisao,
       v2.dt_inicial,
       v2.dt_final 
  from bethadba.hist_funcionarios hf
 inner join bethadba.hist_cargos hc
    on hf.i_entidades = hc.i_entidades
   and hf.i_funcionarios = hc.i_funcionarios
   and hf.dt_alteracoes <= hc.dt_alteracoes 
 inner join bethadba.funcionarios f
    on f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
 inner join bethadba.rescisoes r
    on r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
 inner join bethadba.variaveis v2
    on r.i_entidades = v2.i_entidades
   and r.i_funcionarios = v2.i_funcionarios 
 inner join bethadba.vinculos v
    on v.i_vinculos = hf.i_vinculos
 where (r.dt_rescisao < v2.dt_inicial or r.dt_rescisao < v2.dt_final)
   and r.i_motivos_apos is null
   and r.dt_canc_resc is null
   and r.i_rescisoes  = (select max(r.i_rescisoes)
                           from bethadba.rescisoes r
                          where r.i_entidades = f.i_entidades
                            and r.i_funcionarios = f.i_funcionarios
                            and r.dt_canc_resc is null
                            and r.i_motivos_apos is null)
 group by hf.i_entidades, hf.i_funcionarios, r.dt_rescisao, v2.dt_inicial, v2.dt_final 
 order by hf.i_entidades, hf.i_funcionarios;


-- CORREÇÃO
-- Deleta as variáveis com data inicial maior que a data de rescisão
delete from bethadba.variaveis
 where exists (select 1
      			     from (select r.i_entidades,
      			 		    	        r.i_funcionarios,
      			 			            max(r.dt_rescisao) as data_rescisao
                         from bethadba.rescisoes r
                        where r.i_entidades = variaveis.i_entidades
                          and r.i_funcionarios = variaveis.i_funcionarios
                          and r.dt_canc_resc is null
                          and r.i_motivos_apos is null
                        group by r.i_entidades, r.i_funcionarios) resc
      			     join bethadba.funcionarios f
        		       on f.i_entidades = resc.i_entidades
       			      and f.i_funcionarios = resc.i_funcionarios
     			      where variaveis.i_entidades = resc.i_entidades
       			      and variaveis.i_funcionarios = resc.i_funcionarios
       			      and variaveis.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis.dt_inicial > resc.data_rescisao);

-- Atualiza as variáveis com data final maior que a data de rescisão
update bethadba.variaveis
   set dt_final = cast(left(resc.data_rescisao, 7) || '-01' as date)
  from (select r.i_entidades,
               r.i_funcionarios,
               max(r.dt_rescisao) as data_rescisao
          from bethadba.rescisoes r
         where r.dt_canc_resc is null
           and r.i_motivos_apos is null
         group by r.i_entidades, r.i_funcionarios) resc
 where variaveis.i_entidades = resc.i_entidades
   and variaveis.i_funcionarios = resc.i_funcionarios
   and variaveis.i_eventos is not null
   and variaveis.dt_final > resc.data_rescisao;

-- FIM DO ARQUIVO FOLHA - Validação - 134.sql

-- FOLHA - Validação: FOLHA - Validação - 135.sql

-- VALIDAÇÃO 135
-- Verifica os lançamentos posteriores a data de cessação do aposentado e que não possuem motivo de rescisão válido

select hf.i_entidades as chave_dsk1,
       hf.i_funcionarios as chave_dsk2,
       r.dt_rescisao,
       sub.dt_rescisao as dataCessacao,
       v2.dt_inicial,
       v2.dt_final 
  from bethadba.hist_funcionarios hf
 inner join bethadba.hist_cargos hc
    on hf.i_entidades = hc.i_entidades 
   and hf.i_funcionarios = hc.i_funcionarios 
   and hf.dt_alteracoes <= hc.dt_alteracoes 
 inner join bethadba.funcionarios f
    on f.i_funcionarios = hf.i_funcionarios 
   and f.i_entidades = hf.i_entidades
 inner join bethadba.rescisoes r
    on r.i_funcionarios = hf.i_funcionarios 
   and r.i_entidades = hf.i_entidades
 inner join bethadba.variaveis v2
    on r.i_entidades = v2.i_entidades 
   and r.i_funcionarios = v2.i_funcionarios 
 inner join bethadba.vinculos v
    on v.i_vinculos = hf.i_vinculos
  left join (select resc.i_entidades,
                    resc.i_funcionarios,
                    max(resc.dt_rescisao) as dt_rescisao
               from bethadba.rescisoes resc
               join bethadba.motivos_resc mot
                 on resc.i_motivos_resc = mot.i_motivos_resc
              where mot.dispensados = 4
                and resc.dt_canc_resc is null
              group by resc.i_entidades, resc.i_funcionarios) as sub
    on hf.i_entidades = sub.i_entidades
   and hf.i_funcionarios = sub.i_funcionarios
 where r.i_motivos_apos is not null 
   and sub.dt_rescisao is not null 
   and (sub.dt_rescisao < v2.dt_inicial or sub.dt_rescisao < v2.dt_final)
 order by hf.i_entidades, hf.i_funcionarios;


-- CORREÇÃO
-- Excluir os registros de variáveis que não possuem motivo de rescisão válido e que estão com data de cessação posterior a data de rescisão

delete bethadba.variaveis
 where i_entidades in (select hf.i_entidades
                         from bethadba.hist_funcionarios hf
                        inner join bethadba.hist_cargos hc
                           on hf.i_entidades = hc.i_entidades 
                          and hf.i_funcionarios = hc.i_funcionarios 
                          and hf.dt_alteracoes <= hc.dt_alteracoes 
                        inner join bethadba.funcionarios f
                           on f.i_funcionarios = hf.i_funcionarios 
                          and f.i_entidades = hf.i_entidades
                        inner join bethadba.rescisoes r
                           on r.i_funcionarios = hf.i_funcionarios
                          and r.i_entidades = hf.i_entidades
                        inner join bethadba.variaveis v2
                           on r.i_entidades = v2.i_entidades 
                          and r.i_funcionarios = v2.i_funcionarios 
                        inner join bethadba.vinculos v
                           on v.i_vinculos = hf.i_vinculos
                         left join (select resc.i_entidades,
                                           resc.i_funcionarios,
                                           max(resc.dt_rescisao) as dt_rescisao
                                      from bethadba.rescisoes resc
                                      join bethadba.motivos_resc mot
                                        on resc.i_motivos_resc = mot.i_motivos_resc
                                     where mot.dispensados = 4
                                       and resc.dt_canc_resc is null
                                     group by resc.i_entidades, resc.i_funcionarios) as sub
                           on hf.i_entidades = sub.i_entidades
                          and hf.i_funcionarios = sub.i_funcionarios
                        where r.i_motivos_apos is not null 
                          and sub.dt_rescisao is not null 
                          and (sub.dt_rescisao < v2.dt_inicial or sub.dt_rescisao < v2.dt_final)
                        order by hf.i_entidades, hf.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 135.sql

-- FOLHA - Validação: FOLHA - Validação - 136.sql

-- VALIDAÇÃO 136
-- Verifica os funcionarios que não contém rescisão

select fpa.i_entidades,
       fpa.i_funcionarios
  from bethadba.funcionarios_prop_adic fpa  
 where fpa.i_caracteristicas = 20369 
   and fpa.valor_caracter = '1'
   and fpa.i_funcionarios not in (select r.i_funcionarios
                                    from bethadba.rescisoes r
                                   where r.i_motivos_apos is not null
                                     and r.dt_canc_resc is null);


-- CORREÇÃO
-- Altera o campo adicional 20369 para '0' quando o funcionário não tem rescisão

update bethadba.funcionarios_prop_adic fpa
   set fpa.valor_caracter = '0'
 where fpa.i_caracteristicas = 20369 
   and fpa.valor_caracter = '1'
   and fpa.i_funcionarios not in (select r.i_funcionarios
                                    from bethadba.rescisoes r
                                   where r.i_motivos_apos is not null
                                     and r.dt_canc_resc is null);

-- FIM DO ARQUIVO FOLHA - Validação - 136.sql

-- FOLHA - Validação: FOLHA - Validação - 137.sql

-- VALIDAÇÃO 137
-- Verifica os funcionarios que não contém rescisão

select fpa.i_entidades,
       fpa.i_funcionarios
  from bethadba.funcionarios_prop_adic fpa
 where fpa.i_caracteristicas = 20369
   and fpa.valor_caracter = '2'
   and fpa.i_funcionarios not in (select i_funcionarios
                                    from bethadba.beneficiarios)
 order by fpa.i_funcionarios;


-- CORREÇÃO
-- Altera o valor do campo valor_caracter para '0' para os funcionários que não são beneficiários e que possuem o valor '2' na característica 20369

update bethadba.funcionarios_prop_adic
   set valor_caracter = '0'
 where i_caracteristicas = 20369
   and valor_caracter = '2'
   and i_funcionarios not in (select i_funcionarios
                                from bethadba.beneficiarios);

-- FIM DO ARQUIVO FOLHA - Validação - 137.sql

-- FOLHA - Validação: FOLHA - Validação - 138.sql

-- VALIDAÇÃO 138
-- Calculo base outras empresas

select i_pessoas,
       dt_vigencia_ini,
       dt_vigencia_fin
  from bethadba.bases_calc_outras_empresas 
 where dt_vigencia_fin >= date(dateadd(year,100,GETDATE()));


-- CORREÇÃO
-- Atualiza a data de vigência final para 100 anos a partir da data atual para os registros que possuem data de vigência final maior ou igual a 100 anos a partir da data atual.
-- Isso garante que os registros estejam dentro de um intervalo de vigência válido.

update bethadba.bases_calc_outras_empresas
   set dt_vigencia_fin = date(dateadd(year,100,GETDATE()))
 where dt_vigencia_fin >= date(dateadd(year,100,GETDATE()));

-- FIM DO ARQUIVO FOLHA - Validação - 138.sql

-- FOLHA - Validação: FOLHA - Validação - 14.sql

-- VALIDAÇÃO 14
-- Verifica os nomes dos tipos bases repetidos

select list(i_tipos_bases) tiposs, 
       nome, 
       count(nome) as quantidade
  from bethadba.tipos_bases 
 group by nome 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os nomes dos tipos bases repetidos para evitar duplicidade

update bethadba.tipos_bases
   set nome = i_tipos_bases || ' - ' || nome
 where nome in (select nome
                  from bethadba.tipos_bases 
                 group by nome 
                having count(nome) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 14.sql

-- FOLHA - Validação: FOLHA - Validação - 140.sql

-- VALIDAÇÃO 140
-- Periodo aquisitivo de ferias concomitantes

select a.i_entidades,
       a.i_funcionarios,
       a.i_periodos,
       a.dt_aquis_ini as dataInicioA,
       a.dt_aquis_fin as dataFimA,
       b.dt_aquis_ini as dataInicioB,
       b.dt_aquis_fin as dataFimB,
       canceladoA = if exists (select 1
                                 from bethadba.periodos_ferias pf 
                                where a.i_entidades = pf.i_entidades
                                  and a.i_funcionarios = pf.i_funcionarios
                                  and a.i_periodos = pf.i_periodos
                                  and pf.tipo in (5,7)) then 'true' else 'false' endif,
       canceladoB = if exists (select 1
                                 from bethadba.periodos_ferias pf 
                                where b.i_entidades = pf.i_entidades
                                  and b.i_funcionarios = pf.i_funcionarios
                                  and b.i_periodos = pf.i_periodos
                                  and pf.tipo in (5,7)) then 'true' else 'false' endif,     
       diferencaPeriodo = b.i_periodos - a.i_periodos,
       diferenca = DATEDIFF(day, a.dt_aquis_fin , b.dt_aquis_ini) 
  from bethadba.periodos a 
  join bethadba.periodos b
    on a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios
 where a.i_periodos < b.i_periodos
   and diferencaPeriodo = 1
   and diferenca <> 1 
   and (canceladoA = 'false' and canceladoB = 'false')
 order by a.i_entidades, a.i_funcionarios, a.i_periodos, a.dt_aquis_ini;


-- CORREÇÃO
-- Ajuste da data de fim do periodo aquisitivo de ferias para o dia anterior ao inicio do proximo periodo aquisitivo

begin
  declare w_entidade integer;
  declare w_funcionario integer;
  declare w_periodo integer;
  declare w_new_data_aquis_fim timestamp;

  llloop: for ll as cursor1 dynamic scroll cursor for
	select a.i_entidades,
    	   a.i_funcionarios,
	       a.i_periodos,
    	   a.dt_aquis_ini as dataInicioA,
	       a.dt_aquis_fin as dataFimA,
    	   b.dt_aquis_ini as dataInicioB,
	       b.dt_aquis_fin as dataFimB,
    	   canceladoA = if exists (select 1
        	                         from bethadba.periodos_ferias as pf
            	                    where a.i_entidades = pf.i_entidades
                	                  and a.i_funcionarios = pf.i_funcionarios
                    	              and a.i_periodos = pf.i_periodos
                        	          and pf.tipo in (5,7)) then 'true' else 'false' endif,
	       canceladoB = if exists (select 1
    	                             from bethadba.periodos_ferias as pf
        	                        where b.i_entidades = pf.i_entidades
            	                      and b.i_funcionarios = pf.i_funcionarios
                	                  and b.i_periodos = pf.i_periodos
                    	              and pf.tipo in (5,7)) then 'true' else 'false' endif,
	       diferencaPeriodo = b.i_periodos - a.i_periodos,
    	   diferenca = DATEDIFF(day, a.dt_aquis_fin , b.dt_aquis_ini)
	  from bethadba.periodos as a,
	  	   bethadba.periodos as b
	 where a.i_periodos < b.i_periodos
	   and a.i_entidades = b.i_entidades
	   and a.i_funcionarios = b.i_funcionarios
	   and diferencaPeriodo = 1
	   and diferenca <> 1 
	   and (canceladoA = 'false' and canceladoB = 'false')
	 order by a.i_entidades, a.i_funcionarios, a.i_periodos, a.dt_aquis_ini
  
  do
  
	  set w_entidade = i_entidades;
    set w_funcionario = i_funcionarios;
    set w_periodo = i_periodos;
    set w_new_data_aquis_fim = DATEADD(DAY, -1, dataInicioB);

    update bethadba.periodos as p
       set p.dt_aquis_fin = w_new_data_aquis_fim
     where p.i_entidades = w_entidade
       and p.i_funcionarios = w_funcionario
       and p.i_periodos = w_periodo
  end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 140.sql

-- FOLHA - Validação: FOLHA - Validação - 141.sql

-- VALIDAÇÃO 141
-- Data do processo de homologação maior que a data atual do sistema

select pj.i_entidades,
       pj.i_pessoas,
       pj.i_funcionarios,
       pj.dt_homologacao,
       pj.dt_final,
       dataAtual = getDate()
  from bethadba.processos_judiciais pj 
 where pj.dt_homologacao > dataAtual 
    or pj.dt_homologacao > pj.dt_final;


-- CORREÇÃO
-- Atualiza a data de homologação para a data atual se for maior que a data final

update bethadba.processos_judiciais
   set dt_homologacao = case
                           when dt_final < getDate() then
                              dt_final
                           else
                              getDate()
                        end
 where dt_homologacao > getDate()
    or dt_homologacao > dt_final;

-- FIM DO ARQUIVO FOLHA - Validação - 141.sql

-- FOLHA - Validação: FOLHA - Validação - 142.sql

-- VALIDAÇÃO 142
-- ordem de características duplicada

select nome,
  ordem,
  count(ordem) as quantidade
  from (select 'cargos' as nome, ordem
     from bethadba.cargos_caract_cfg
  union all
   select 'eventos' as nome, ordem
     from bethadba.eventos_caract_cfg
  union all
   select 'tipos_cargos' as nome, ordem
     from bethadba.tipos_cargos_caract_cfg
  union all
   select 'tipos_afast' as nome, ordem
     from bethadba.tipos_afast_caract_cfg
  union all
   select 'atos' as nome, ordem
     from bethadba.atos_caract_cfg
  union all
   select 'areas_atuacao' as nome, ordem
     from bethadba.areas_atuacao_caract_cfg
  union all
   select 'empresas' as nome, ordem
     from bethadba.empresas_ant_caract_cfg
  union all
   select 'niveis' as nome, ordem
     from bethadba.niveis_caract_cfg
  union all
   select 'organogramas' as nome, ordem
     from bethadba.organogramas_caract_cfg
  union all
   select 'funcionario' as nome, ordem
     from bethadba.funcionarios_caract_cfg
  union all
   select 'hist_cargos' as nome, ordem
     from bethadba.hist_cargos_caract_cfg
  union all
   select 'pessoas' as nome, ordem
     from bethadba.pessoas_caract_cfg) as tab
 group by nome, ordem
having quantidade > 1;


-- CORREÇÃO
-- A correção será feita através de uma atualização da ordem das características, garantindo que cada uma tenha uma ordem única.

-- bethadba.cargos_caract_cfg
with ordenados as (
  select id_cargo_caract_cfg,
         row_number() over (order by ordem, id_cargo_caract_cfg) as nova_ordem
    from bethadba.cargos_caract_cfg
)
update bethadba.cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.cargos_caract_cfg.id_cargo_caract_cfg = ordenados.id_cargo_caract_cfg;

-- bethadba.eventos_caract_cfg
with ordenados as (
  select id_evento_caract_cfg,
         row_number() over (order by ordem, id_evento_caract_cfg) as nova_ordem
    from bethadba.eventos_caract_cfg
)
update bethadba.eventos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.eventos_caract_cfg.id_evento_caract_cfg = ordenados.id_evento_caract_cfg;

-- bethadba.tipos_cargos_caract_cfg
with ordenados as (
  select id_tipo_cargo_caract_cfg,
         row_number() over (order by ordem, id_tipo_cargo_caract_cfg) as nova_ordem
    from bethadba.tipos_cargos_caract_cfg
)
update bethadba.tipos_cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.tipos_cargos_caract_cfg.id_tipo_cargo_caract_cfg = ordenados.id_tipo_cargo_caract_cfg;

-- bethadba.tipos_afast_caract_cfg
with ordenados as (
  select id_tipo_afast_caract_cfg,
         row_number() over (order by ordem, id_tipo_afast_caract_cfg) as nova_ordem
    from bethadba.tipos_afast_caract_cfg
)
update bethadba.tipos_afast_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.tipos_afast_caract_cfg.id_tipo_afast_caract_cfg = ordenados.id_tipo_afast_caract_cfg;

-- bethadba.atos_caract_cfg
with ordenados as (
  select id_ato_caract_cfg,
         row_number() over (order by ordem, id_ato_caract_cfg) as nova_ordem
    from bethadba.atos_caract_cfg
)
update bethadba.atos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.atos_caract_cfg.id_ato_caract_cfg = ordenados.id_ato_caract_cfg;

-- bethadba.areas_atuacao_caract_cfg
with ordenados as (
  select id_area_atuacao_caract_cfg,
         row_number() over (order by ordem, id_area_atuacao_caract_cfg) as nova_ordem
    from bethadba.areas_atuacao_caract_cfg
)
update bethadba.areas_atuacao_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.areas_atuacao_caract_cfg.id_area_atuacao_caract_cfg = ordenados.id_area_atuacao_caract_cfg;

-- bethadba.empresas_ant_caract_cfg
with ordenados as (
  select id_empresa_ant_caract_cfg,
         row_number() over (order by ordem, id_empresa_ant_caract_cfg) as nova_ordem
    from bethadba.empresas_ant_caract_cfg
)
update bethadba.empresas_ant_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.empresas_ant_caract_cfg.id_empresa_ant_caract_cfg = ordenados.id_empresa_ant_caract_cfg;

-- bethadba.niveis_caract_cfg
with ordenados as (
  select id_nivel_caract_cfg,
         row_number() over (order by ordem, id_nivel_caract_cfg) as nova_ordem
    from bethadba.niveis_caract_cfg
)
update bethadba.niveis_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.niveis_caract_cfg.id_nivel_caract_cfg = ordenados.id_nivel_caract_cfg;

-- bethadba.organogramas_caract_cfg
with ordenados as (
  select id_organograma_caract_cfg,
         row_number() over (order by ordem, id_organograma_caract_cfg) as nova_ordem
    from bethadba.organogramas_caract_cfg
)
update bethadba.organogramas_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.organogramas_caract_cfg.id_organograma_caract_cfg = ordenados.id_organograma_caract_cfg;

-- bethadba.funcionarios_caract_cfg
with ordenados as (
  select id_funcionario_caract_cfg,
         row_number() over (order by ordem, id_funcionario_caract_cfg) as nova_ordem
    from bethadba.funcionarios_caract_cfg
)
update bethadba.funcionarios_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.funcionarios_caract_cfg.id_funcionario_caract_cfg = ordenados.id_funcionario_caract_cfg;

-- bethadba.hist_cargos_caract_cfg
with ordenados as (
  select id_hist_cargo_caract_cfg,
         row_number() over (order by ordem, id_hist_cargo_caract_cfg) as nova_ordem
    from bethadba.hist_cargos_caract_cfg
)
update bethadba.hist_cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.hist_cargos_caract_cfg.id_hist_cargo_caract_cfg = ordenados.id_hist_cargo_caract_cfg;

-- bethadba.pessoas_caract_cfg
with ordenados as (
  select id_pessoa_caract_cfg,
         row_number() over (order by ordem, id_pessoa_caract_cfg) as nova_ordem
    from bethadba.pessoas_caract_cfg
)
update bethadba.pessoas_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.pessoas_caract_cfg.id_pessoa_caract_cfg = ordenados.id_pessoa_caract_cfg;


-- FIM DO ARQUIVO FOLHA - Validação - 142.sql

-- FOLHA - Validação: FOLHA - Validação - 143.sql

-- VALIDAÇÃO 143
-- ordem duplicada de campos adicionais

select nome,
  ordem,
  list(codigo),
  count(ordem) as quantidade
  from (select 'cargos' as nome, ordem, i_caracteristicas as codigo
   from bethadba.cargos_caract_cfg 
    union all    
    select 'eventos' as nome, ordem, i_caracteristicas as codigo
   from bethadba.eventos_caract_cfg
    union all    
    select 'tipos_cargos' as nome, ordem, i_caracteristicas as codigo
   from bethadba.tipos_cargos_caract_cfg
    union all    
    select 'tipos_afast' as nome, ordem, i_caracteristicas as codigo
   from bethadba.tipos_afast_caract_cfg
    union all    
    select 'atos' as nome, ordem, i_caracteristicas as codigo
   from bethadba.atos_caract_cfg
    union all    
    select 'areas_atuacao' as nome, ordem, i_caracteristicas as codigo
   from bethadba.areas_atuacao_caract_cfg
    union all    
    select 'empresas' as nome, ordem, i_caracteristicas as codigo
   from bethadba.empresas_ant_caract_cfg    
    union all    
    select 'niveis' as nome, ordem, i_caracteristicas as codigo
   from bethadba.niveis_caract_cfg        
    union all    
    select 'organogramas' as nome, ordem, i_caracteristicas as codigo
   from bethadba.organogramas_caract_cfg
    union all    
    select 'funcionario' as nome, ordem, i_caracteristicas as codigo
   from bethadba.funcionarios_caract_cfg fcc
    union all    
    select 'hist_cargos' as nome, ordem, i_caracteristicas as codigo
   from bethadba.hist_cargos_caract_cfg    
    union all    
    select 'pessoas' as nome, ordem, i_caracteristicas as codigo
   from bethadba.pessoas_caract_cfg) as tab
 group by nome, ordem
having quantidade > 1;


-- CORREÇÃO
-- A correção será feita através de uma atualização da ordem dos campos adicionais, garantindo que cada um tenha uma ordem única.

-- bethadba.cargos_caract_cfg
with ordenados as (
  select id_cargo_caract_cfg,
         row_number() over (order by ordem, id_cargo_caract_cfg) as nova_ordem
    from bethadba.cargos_caract_cfg
)
update bethadba.cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.cargos_caract_cfg.id_cargo_caract_cfg = ordenados.id_cargo_caract_cfg;

-- bethadba.eventos_caract_cfg
with ordenados as (
  select id_evento_caract_cfg,
         row_number() over (order by ordem, id_evento_caract_cfg) as nova_ordem
    from bethadba.eventos_caract_cfg
)
update bethadba.eventos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.eventos_caract_cfg.id_evento_caract_cfg = ordenados.id_evento_caract_cfg;

-- bethadba.tipos_cargos_caract_cfg
with ordenados as (
  select id_tipo_cargo_caract_cfg,
         row_number() over (order by ordem, id_tipo_cargo_caract_cfg) as nova_ordem
    from bethadba.tipos_cargos_caract_cfg
)
update bethadba.tipos_cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.tipos_cargos_caract_cfg.id_tipo_cargo_caract_cfg = ordenados.id_tipo_cargo_caract_cfg;

-- bethadba.tipos_afast_caract_cfg
with ordenados as (
  select id_tipo_afast_caract_cfg,
         row_number() over (order by ordem, id_tipo_afast_caract_cfg) as nova_ordem
    from bethadba.tipos_afast_caract_cfg
)
update bethadba.tipos_afast_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.tipos_afast_caract_cfg.id_tipo_afast_caract_cfg = ordenados.id_tipo_afast_caract_cfg;

-- bethadba.atos_caract_cfg
with ordenados as (
  select id_ato_caract_cfg,
         row_number() over (order by ordem, id_ato_caract_cfg) as nova_ordem
    from bethadba.atos_caract_cfg
)
update bethadba.atos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.atos_caract_cfg.id_ato_caract_cfg = ordenados.id_ato_caract_cfg;

-- bethadba.areas_atuacao_caract_cfg
with ordenados as (
  select id_area_atuacao_caract_cfg,
         row_number() over (order by ordem, id_area_atuacao_caract_cfg) as nova_ordem
    from bethadba.areas_atuacao_caract_cfg
)
update bethadba.areas_atuacao_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.areas_atuacao_caract_cfg.id_area_atuacao_caract_cfg = ordenados.id_area_atuacao_caract_cfg;

-- bethadba.empresas_ant_caract_cfg
with ordenados as (
  select id_empresa_ant_caract_cfg,
         row_number() over (order by ordem, id_empresa_ant_caract_cfg) as nova_ordem
    from bethadba.empresas_ant_caract_cfg
)
update bethadba.empresas_ant_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.empresas_ant_caract_cfg.id_empresa_ant_caract_cfg = ordenados.id_empresa_ant_caract_cfg;

-- bethadba.niveis_caract_cfg
with ordenados as (
  select id_nivel_caract_cfg,
         row_number() over (order by ordem, id_nivel_caract_cfg) as nova_ordem
    from bethadba.niveis_caract_cfg
)
update bethadba.niveis_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.niveis_caract_cfg.id_nivel_caract_cfg = ordenados.id_nivel_caract_cfg;

-- bethadba.organogramas_caract_cfg
with ordenados as (
  select id_organograma_caract_cfg,
         row_number() over (order by ordem, id_organograma_caract_cfg) as nova_ordem
    from bethadba.organogramas_caract_cfg
)
update bethadba.organogramas_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.organogramas_caract_cfg.id_organograma_caract_cfg = ordenados.id_organograma_caract_cfg;

-- bethadba.funcionarios_caract_cfg
with ordenados as (
  select id_funcionario_caract_cfg,
         row_number() over (order by ordem, id_funcionario_caract_cfg) as nova_ordem
    from bethadba.funcionarios_caract_cfg
)
update bethadba.funcionarios_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.funcionarios_caract_cfg.id_funcionario_caract_cfg = ordenados.id_funcionario_caract_cfg;

-- bethadba.hist_cargos_caract_cfg
with ordenados as (
  select id_hist_cargo_caract_cfg,
         row_number() over (order by ordem, id_hist_cargo_caract_cfg) as nova_ordem
    from bethadba.hist_cargos_caract_cfg
)
update bethadba.hist_cargos_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.hist_cargos_caract_cfg.id_hist_cargo_caract_cfg = ordenados.id_hist_cargo_caract_cfg;

-- bethadba.pessoas_caract_cfg
with ordenados as (
  select id_pessoa_caract_cfg,
         row_number() over (order by ordem, id_pessoa_caract_cfg) as nova_ordem
    from bethadba.pessoas_caract_cfg
)
update bethadba.pessoas_caract_cfg
   set ordem = ordenados.nova_ordem
  from ordenados
 where bethadba.pessoas_caract_cfg.id_pessoa_caract_cfg = ordenados.id_pessoa_caract_cfg;

-- FIM DO ARQUIVO FOLHA - Validação - 143.sql

-- FOLHA - Validação: FOLHA - Validação - 144.sql

-- VALIDAÇÃO 144
-- Pessoa fisica sem data de nascimento

select i_pessoas
  from bethadba.pessoas_fisicas
 where dt_nascimento is null
 order by i_pessoas;


-- CORREÇÃO
-- Atualiza a data de nascimento para 18 anos antes da data de alteração mais recente da pessoa física na tabela de histórico considerando que a data de nascimento não pode ser nula e que a pessoa física deve ter pelo menos 18 anos.

update bethadba.pessoas_fisicas pf
   set pf.dt_nascimento = DATEADD(year, -18, hpf.dt_alteracoes)
  from bethadba.hist_pessoas_fis hpf
 where pf.dt_nascimento is null
   and pf.i_pessoas = hpf.i_pessoas;

-- FIM DO ARQUIVO FOLHA - Validação - 144.sql

-- FOLHA - Validação: FOLHA - Validação - 145.sql

-- VALIDAÇÃO 145
-- Histórico de pessoa fisica sem data de nascimento

select i_pessoas
  from bethadba.hist_pessoas_fis
 where dt_nascimento is null
 order by i_pessoas;


-- CORREÇÃO
-- Atualiza a data de nascimento no histórico de pessoa física com a data de nascimento da pessoa física caso esteja nula no histórico de pessoa física
-- Caso a data de nascimento esteja nula na pessoa física, não será atualizado no histórico de pessoa física também e permanecerá nulo no histórico de pessoa física

begin	
	declare w_i_pessoas integer;
	declare w_dt_nascimento timestamp;
	
    llLoop: for ll as cur_01 dynamic scroll cursor for
		select hpf.i_pessoas as pessoas,
			   pf.dt_nascimento as nascimento
		  from bethadba.hist_pessoas_fis hpf
		  join bethadba.pessoas_fisicas pf
		    on (hpf.i_pessoas = pf.i_pessoas)
		 where hpf.dt_nascimento is null
    do
 		set w_i_pessoas = pessoas;
 		set w_dt_nascimento = nascimento;

  update bethadba.hist_pessoas_fis 
	 set dt_nascimento = w_dt_nascimento
   where dt_nascimento is null
	 and i_pessoas = w_i_pessoas;
    end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 145.sql

-- FOLHA - Validação: FOLHA - Validação - 146.sql

-- VALIDAÇÃO 146
-- Validar se o CPF é numérico na tabela hist_pessoas_fis

select i_pessoas ,
       dt_alteracoes ,
       isnumeric(cpf) as validacao 
  from bethadba.hist_pessoas_fis hpf 
 where cpf is not null
   and cpf <> ''
   and validacao = 0;


-- CORREÇÃO
-- Atualizar o campo CPF para NULL onde o CPF não for numérico na tabela hist_pessoas_fis

update bethadba.hist_pessoas_fis
   set cpf = (select right('0000000000' + cast(row_number() over (order by i_pessoas) as varchar(11)), 11)
                from (select i_pessoas
                        from bethadba.hist_pessoas_fis
                       where cpf is not null
                         and cpf <> ''
                         and isnumeric(cpf) = 0) as sub
               where sub.i_pessoas = hist_pessoas_fis.i_pessoas)
 where cpf is not null
   and cpf <> ''
   and isnumeric(cpf) = 0
   and not exists (select 1
                     from bethadba.hist_pessoas_fis h2
                    where h2.cpf = right('0000000000' + cast(row_number() over (order by hist_pessoas_fis.i_pessoas) as varchar(11)), 11)
                      and h2.i_pessoas <> hist_pessoas_fis.i_pessoas);

-- FIM DO ARQUIVO FOLHA - Validação - 146.sql

-- FOLHA - Validação: FOLHA - Validação - 147.sql

-- VALIDAÇÃO 147
-- Calculo mensal sem movimentações

select dc.i_entidades,
       dc.i_funcionarios,
       dc.i_competencias,
       dc.i_processamentos,
       dc.i_tipos_proc,
       dc.dt_pagto,
       temRescisao = if exists (select 1 
                                  from bethadba.movimentos as m
                                 where m.i_entidades = dc.i_entidades
                                   and m.i_funcionarios = dc.i_funcionarios
                                   and m.i_tipos_proc = dc.i_tipos_proc
                                   and m.i_processamentos = dc.i_processamentos
                                   and m.i_competencias = dc.i_competencias
                                   and m.mov_resc = 'S') then 'S' else 'N' endif
  from bethadba.dados_calc as dc
 where dc.i_tipos_proc in (11, 41, 42)
   and dc.dt_fechamento is not null
   and temRescisao = 'N'
   and not exists (select 1
                     from bethadba.movimentos as m 
                    where m.i_funcionarios = dc.i_funcionarios
                      and m.i_entidades = dc.i_entidades
                      and m.i_tipos_proc = dc.i_tipos_proc
                      and m.i_processamentos = dc.i_processamentos
                      and m.i_competencias = dc.i_competencias
                      and m.mov_resc = 'N');


-- CORREÇÃO
-- Verificar se o funcionário realmente não possui movimentações no período.

begin

  -- Caso positivo, excluir o registro da tabela bases_calc.
  delete 
    from bethadba.bases_calc
   where bases_calc.i_tipos_proc in (11, 41, 42)
     and not exists (select 1
                       from bethadba.movimentos as m 
                       where m.i_funcionarios = bases_calc.i_funcionarios
                         and m.i_entidades = bases_calc.i_entidades
                         and m.i_tipos_proc = bases_calc.i_tipos_proc
                         and m.i_processamentos = bases_calc.i_processamentos
                         and m.i_competencias = bases_calc.i_competencias);

  -- Caso positivo, excluir o registro da tabela dados_calc.
  delete
    from bethadba.dados_calc
  where dados_calc.i_tipos_proc in (11, 41, 42)
    and dados_calc.dt_fechamento is not null
    and not exists (select 1
                      from bethadba.movimentos as m 
                      where m.i_funcionarios = dados_calc.i_funcionarios
                        and m.i_entidades = dados_calc.i_entidades
                        and m.i_tipos_proc = dados_calc.i_tipos_proc
                        and m.i_processamentos = dados_calc.i_processamentos
                        and m.i_competencias = dados_calc.i_competencias);

  -- Caso positivo, excluir o registro da tabela periodos_calculo_fecha.
  delete 
    from bethadba.periodos_calculo_fecha
   where periodos_calculo_fecha.i_tipos_proc in (11, 41, 42)
     and not exists (select 1
                       from bethadba.movimentos as m 
                      where m.i_funcionarios = periodos_calculo_fecha.i_funcionarios
                        and m.i_entidades = periodos_calculo_fecha.i_entidades
                        and m.i_tipos_proc = periodos_calculo_fecha.i_tipos_proc
                        and m.i_processamentos = periodos_calculo_fecha.i_processamentos
                        and m.i_competencias = periodos_calculo_fecha.i_competencias);

end;

-- FIM DO ARQUIVO FOLHA - Validação - 147.sql

-- FOLHA - Validação: FOLHA - Validação - 148.sql

-- VALIDAÇÃO 148
-- Calculo de ferias sem registros

select dc.i_entidades,
       dc.i_funcionarios,
       dc.i_competencias,
       dc.i_processamentos,
       dc.i_tipos_proc,
       dc.dt_pagto
  from bethadba.dados_calc as dc
 where dc.i_tipos_proc = 80
   and dc.dt_fechamento is not null
   and not exists (select 1 
                     from bethadba.ferias_proc as fp
                     left join bethadba.ferias as f
                       on (fp.i_entidades = f.i_entidades
                      and fp.i_funcionarios = f.i_funcionarios
                      and fp.i_ferias = f.i_ferias)
                    where dc.i_entidades = fp.i_entidades
                      and dc.i_funcionarios = fp.i_funcionarios
                      and dc.i_tipos_proc = fp.i_tipos_proc
                      and dc.i_processamentos = fp.i_processamentos
                      and dc.i_competencias = fp.i_competencias);


-- CORREÇÃO
-- Deletar os registros da tabela dados_calc referente ao calculo de ferias sem registros na tabela ferias_proc e ferias

begin
    -- Caso positivo, excluir o registro da tabela movimentos.
  delete from bethadba.movimentos
  where movimentos.i_tipos_proc = 80
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where movimentos.i_entidades = fp.i_entidades
                        and movimentos.i_funcionarios = fp.i_funcionarios
                        and movimentos.i_tipos_proc = fp.i_tipos_proc
                        and movimentos.i_processamentos = fp.i_processamentos
                        and movimentos.i_competencias = fp.i_competencias);

  -- Caso positivo, excluir o registro da tabela dados_calc.
  delete from bethadba.dados_calc
  where dados_calc.i_tipos_proc = 80
    and dados_calc.dt_fechamento is not null
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where dados_calc.i_entidades = fp.i_entidades
                        and dados_calc.i_funcionarios = fp.i_funcionarios
                        and dados_calc.i_tipos_proc = fp.i_tipos_proc
                        and dados_calc.i_processamentos = fp.i_processamentos
                        and dados_calc.i_competencias = fp.i_competencias);

  -- Caso positivo, excluir o registro da tabela bases_calc.
  delete from bethadba.bases_calc
  where bases_calc.i_tipos_proc = 80
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where bases_calc.i_entidades = fp.i_entidades
                        and bases_calc.i_funcionarios = fp.i_funcionarios
                        and bases_calc.i_tipos_proc = fp.i_tipos_proc
                        and bases_calc.i_processamentos = fp.i_processamentos
                        and bases_calc.i_competencias = fp.i_competencias);
end;

-- FIM DO ARQUIVO FOLHA - Validação - 148.sql

-- FOLHA - Validação: FOLHA - Validação - 149.sql

-- VALIDAÇÃO 149
-- Pensionistas não registrados

select f.i_entidades,
       f.i_funcionarios,
       f.tipo_pens
  from bethadba.funcionarios as f 
 where f.tipo_pens in (1, 2)
   and f.tipo_func = 'B'
   and not exists (select 1
                     from bethadba.beneficiarios as b
                    where f.i_entidades = b.i_entidades
                      and f.i_funcionarios = b.i_funcionarios)
 order by f.i_entidades, f.i_funcionarios asc;


-- CORREÇÃO
-- Inserir os pensionistas não registrados na tabela de beneficiários

insert into bethadba.beneficiarios (i_entidades,i_funcionarios,i_entidades_inst,i_instituidor,i_atos,duracao_ben,dt_vencto,perc_recebto,config,alvara,dt_alvara,situacao,dt_cessacao,motivo_cessacao,parecer_interno,motivo_inicio,origem_beneficio,nr_beneficio,acao_judicial,matricula_instituidor,cnpj_instituidor,tipo_beneficio,data_recebido,cnpj_ente_sucedido,observacao_beneficio,nr_beneficio_anterior)
select f.i_entidades,
       f.i_funcionarios,
       1 as i_entidades_inst, -- Supondo que a entidade do instituidor é a entidade 1
       1 as i_instituidor, -- Supondo que o instituidor é o ID 1
       null as i_atos,
       'V' as duracao_ben, -- Supondo que a Data de duração do benefício é 'V - Vitalícia'
       null as dt_vencto,
       100 as perc_recebto, -- Percentual de recebimento padrão '100%'
       1 as config, -- Configuração padrão
       null as alvara,
       null as dt_alvara,
       null as situacao,
       null as dt_cessacao,
       null as motivo_cessacao,
       'N' as parecer_interno, -- Parecer interno padrão 'N - Nenhum'
       null as motivo_inicio,
       null as origem_beneficio,
       null as nr_beneficio,
       null as acao_judicial,
       null as matricula_instituidor,
       null as cnpj_instituidor,
       null as tipo_beneficio,
       null as data_recebido,
       null as cnpj_ente_sucedido,
       null as observacao_beneficio,
       null as nr_beneficio_anterior
  from bethadba.funcionarios as f 
 where f.tipo_pens in (1, 2)
   and f.tipo_func = 'B'
   and not exists (select 1
                     from bethadba.beneficiarios as b
                    where f.i_entidades = b.i_entidades
                      and f.i_funcionarios = b.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 149.sql

-- FOLHA - Validação: FOLHA - Validação - 15.sql

-- VALIDAÇÃO 15
-- Verifica os logradouros sem cidades

select i_ruas,
       nome
  from bethadba.ruas 
 where i_cidades is null;


-- CORREÇÃO
-- Atualiza os logradouros sem cidades para a cidade padrão (i_entidades = 1)
  
update bethadba.ruas
   set i_cidades = (select max(i_cidades)
                      from bethadba.entidades
                     where i_entidades = 1)
 where i_cidades is null;

-- FIM DO ARQUIVO FOLHA - Validação - 15.sql

-- FOLHA - Validação: FOLHA - Validação - 150.sql

-- VALIDAÇÃO 150
-- Pensionistas que não possuí cessação do benefício e que o instituidor não possui rescisão com motivo de morte ou possui rescisão com motivo de morte, mas com data de cancelamento

select f.i_entidades, 
       f.i_funcionarios,
       b.i_entidades_inst,
       b.i_instituidor,
       f.tipo_pens
  from bethadba.funcionarios f 
  join bethadba.beneficiarios b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios 
 where f.tipo_func = 'B' 
   and f.tipo_pens = 1
   and exists (select 1 from bethadba.rescisoes r 
                 join bethadba.motivos_apos ma
                   on r.i_motivos_apos = ma.i_motivos_apos 
                 join bethadba.tipos_afast ta
                   on ma.i_tipos_afast = ta.i_tipos_afast
                where r.i_entidades = b.i_entidades_inst 
                  and r.i_funcionarios = b.i_instituidor
                  and r.i_motivos_apos is not null
                  and r.dt_canc_resc is null
                  and ta.classif = 9)
   and not exists (select 1
                     from bethadba.rescisoes resc
                     join bethadba.motivos_resc mot
                       on (resc.i_motivos_resc = mot.i_motivos_resc)
                    where resc.i_entidades = b.i_entidades_inst
                      and resc.i_funcionarios = b.i_instituidor
                      and mot.dispensados = 4
                      and resc.dt_canc_resc is null)
 order by f.i_entidades, f.i_funcionarios asc;


-- CORREÇÃO
-- Atualizar o beneficiário inserindo data final de cessação do benefício

update bethadba.beneficiarios b
  join bethadba.funcionarios f
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
   set b.dt_cessacao = convert(varchar(10), getdate(), 120)
 where f.tipo_func = 'B'
   and f.tipo_pens = 1
   and exists (select 1
                 from bethadba.rescisoes r 
                 join bethadba.motivos_apos ma
                   on r.i_motivos_apos = ma.i_motivos_apos 
                 join bethadba.tipos_afast ta
                   on ma.i_tipos_afast = ta.i_tipos_afast
                where r.i_entidades = b.i_entidades_inst 
                  and r.i_funcionarios = b.i_instituidor
                  and r.i_motivos_apos is not null
                  and r.dt_canc_resc is null
                  and ta.classif = 9)
   and not exists (select 1
                     from bethadba.rescisoes resc 
                     join bethadba.motivos_resc mot
                       on (resc.i_motivos_resc = mot.i_motivos_resc)
                    where resc.i_entidades = b.i_entidades_inst 
                      and resc.i_funcionarios = b.i_instituidor 
                      and mot.dispensados = 4                                
                      and resc.dt_canc_resc is null);

-- FIM DO ARQUIVO FOLHA - Validação - 150.sql

-- FOLHA - Validação: FOLHA - Validação - 151.sql

-- VALIDAÇÃO 151
-- Pensionistas sem dependente

select f.i_funcionarios,
       b.i_instituidor,
       f.i_pessoas,
       pessoaInstituidor = (select f2.i_pessoas
                               from bethadba.funcionarios as f2 
                              where f2.i_entidades = b.i_entidades_inst
                                and f2.i_funcionarios = b.i_instituidor)
  from bethadba.funcionarios as f
  join bethadba.beneficiarios as b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
 where f.tipo_func = 'B' 
   and f.tipo_pens in (1, 2)
   and not exists (select 1
                     from bethadba.dependentes as d
                    where d.i_pessoas = pessoaInstituidor
                      and d.i_dependentes = f.i_pessoas);


-- CORREÇÃO
-- Inserir a pessoa do pensionistas como dependente do instituidor

insert into bethadba.dependentes (i_pessoas,i_dependentes,grau,dt_casamento,dt_ini_depende,mot_ini_depende,dt_fin_depende,mot_fin_depende,ex_conjuge,descricao)
select pessoaInstituidor = (select f2.i_pessoas
                              from bethadba.funcionarios as f2 
                             where f2.i_entidades = b.i_entidades_inst
                               and f2.i_funcionarios = b.i_instituidor),
       f.i_pessoas,
       1 as grau,
       null as dt_casamento,
       dt_ini_depende = isnull(isnull((select dt_nascimento
                                         from bethadba.pessoas_fisicas
                                        where i_pessoas = f.i_pessoas
                                          and dt_nascimento is not null
                                          and dt_nascimento <> '01/01/1900'), (select dt_nascimento
                                                                                 from bethadba.pessoas_fisicas
                                                                                where i_pessoas = (select f2.i_pessoas
                                                                                                     from bethadba.funcionarios as f2 
                                                                                                    where f2.i_entidades = b.i_entidades_inst
                                                                                                      and f2.i_funcionarios = b.i_instituidor)
                                                                                  and dt_nascimento is not null
                                                                                  and dt_nascimento <> '01/01/1900')), null),
       1 as mot_ini_depende,
       null as dt_fin_depende,
       null as mot_fin_depende,
       null as ex_conjuge,
       'Dependente - Pensionista' as descricao
  from bethadba.funcionarios as f
  join bethadba.beneficiarios as b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
 where f.tipo_func = 'B' 
   and f.tipo_pens in (1, 2)
   and not exists (select 1
                     from bethadba.dependentes as d
                    where d.i_pessoas = (select f2.i_pessoas
                                           from bethadba.funcionarios as f2 
                                          where f2.i_entidades = b.i_entidades_inst
                                            and f2.i_funcionarios = b.i_instituidor)
                      and d.i_dependentes = f.i_pessoas);

-- FIM DO ARQUIVO FOLHA - Validação - 151.sql

-- FOLHA - Validação: FOLHA - Validação - 152.sql

-- VALIDAÇÃO 152
-- Instituidor sem afastamento

select f.i_entidades, 
       f.i_funcionarios,
       b.i_entidades_inst,
       b.i_instituidor,
       f.tipo_pens
  from bethadba.funcionarios f 
  join bethadba.beneficiarios b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios 
 where f.tipo_func = 'B' 
   and f.tipo_pens in (1, 2)
   and exists (select 1
                 from bethadba.rescisoes r 
                 join bethadba.motivos_apos ma
                   on r.i_motivos_apos = ma.i_motivos_apos 
                 join bethadba.tipos_afast ta
                   on ma.i_tipos_afast = ta.i_tipos_afast
                where r.i_entidades = b.i_entidades_inst
                  and r.i_funcionarios = b.i_instituidor
                  and r.i_motivos_apos is not null
                  and r.dt_canc_resc is null
                  and ta.classif = 9)
   and not exists (select 1
                     from bethadba.afastamentos a
                     join bethadba.tipos_afast ta2
                       on a.i_tipos_afast = ta2.i_tipos_afast
                    where a.i_entidades = b.i_entidades_inst
                      and a.i_funcionarios = b.i_instituidor
                      and ta2.classif = 9)
 order by f.i_entidades, f.i_funcionarios asc;


-- CORREÇÃO
-- Insere um afastamento para o instituidor com a classificação 9

insert into bethadba.afastamentos (i_entidades,i_funcionarios,dt_afastamento,i_tipos_afast,i_atos,dt_ultimo_dia,req_benef,comp_comunic,observacao,manual,sequencial,dt_afastamento_origem,desconsidera_rotina_prorrogacao,desconsidera_rotina_rodada,parecer_interno,conversao_fim_mp_664_2014,i_cid,i_medico_emitente,orgao_classe,nr_conselho,i_estados_orgao,acidente_transito,retificacao,dt_afastamento_retificacao,dt_retificacao,i_tipos_afast_antes,dt_afastamento_geracao,i_tipos_afast_geracao,origem_retificacao,tipo_processo,numero_processo)
select b.i_entidades,
       b.i_instituidor,
       dataAfastamento = (select dt_rescisao
                            from bethadba.rescisoes r 
                            join bethadba.motivos_apos ma
                              on r.i_motivos_apos = ma.i_motivos_apos 
                            join bethadba.tipos_afast ta
                              on ma.i_tipos_afast = ta.i_tipos_afast
                           where r.i_entidades = b.i_entidades_inst
                             and r.i_funcionarios = b.i_instituidor
                             and r.i_motivos_apos is not null
                             and r.dt_canc_resc is null
                             and ta.classif = 9),
       tiposAfastamento = (select ta.i_tipos_afast
                             from bethadba.rescisoes r 
                             join bethadba.motivos_apos ma
                               on r.i_motivos_apos = ma.i_motivos_apos 
                             join bethadba.tipos_afast ta
                               on ma.i_tipos_afast = ta.i_tipos_afast
                            where r.i_entidades = b.i_entidades_inst
                              and r.i_funcionarios = b.i_instituidor
                              and r.i_motivos_apos is not null
                              and r.dt_canc_resc is null
                              and ta.classif = 9),
       null,
       null,
       null,
       null,
       null,
       'S',
       null,
       null,
       'N',
       'N',
       'N',
       'N',
       null,
       null,
       null,
       null,
       null,
       null,
       'N',
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null
  from bethadba.funcionarios f
  join bethadba.beneficiarios b
    on f.i_entidades = b.i_entidades
   and f.i_funcionarios = b.i_funcionarios
 where f.tipo_func = 'B'
   and f.tipo_pens in (1, 2)
   and exists (select 1
                 from bethadba.rescisoes r 
                 join bethadba.motivos_apos ma
                   on r.i_motivos_apos = ma.i_motivos_apos 
                 join bethadba.tipos_afast ta
                   on ma.i_tipos_afast = ta.i_tipos_afast
                where r.i_entidades = b.i_entidades_inst
                  and r.i_funcionarios = b.i_instituidor
                  and r.i_motivos_apos is not null
                  and r.dt_canc_resc is null
                  and ta.classif = 9)
   and not exists (select 1
                     from bethadba.afastamentos a
                     join bethadba.tipos_afast ta2
                       on a.i_tipos_afast = ta2.i_tipos_afast
                    where a.i_entidades = b.i_entidades_inst
                      and a.i_funcionarios = b.i_instituidor
                      and ta2.classif = 9);

-- FIM DO ARQUIVO FOLHA - Validação - 152.sql

-- FOLHA - Validação: FOLHA - Validação - 153.sql

-- VALIDAÇÃO 153
-- Lotação fisica principal

select i_entidades,
       i_funcionarios,
       count(*) as total 
  from bethadba.locais_mov lm 
 where principal = 'S'
 group by i_entidades, i_funcionarios  
having total > 1
 order by 1,2 asc;


-- CORREÇÃO
-- Atualizar a lotação fisica principal 'S' para apenas uma por funcionário, setando as demais para 'N' considerando como principal a lotação física com data inicial menor e sem data final
-- ou com data final maior que as demais.

update bethadba.locais_mov lm1
   set principal = 'S'
 where principal = 'N'
   and not exists (select 1
                     from bethadba.locais_mov lm2 
                    where lm2.i_entidades = lm1.i_entidades
                      and lm2.i_funcionarios = lm1.i_funcionarios
                      and lm2.principal = 'S'
                      and (lm2.data_inicial < lm1.data_inicial 
                       or (lm2.data_inicial = lm1.data_inicial 
                      and (lm2.data_final is null
                       or lm2.data_final > lm1.data_final))));

update bethadba.locais_mov lm
   set principal = 'N'
 where principal = 'S'
   and exists (select 1
                 from bethadba.locais_mov lm2 
                where lm2.i_entidades = lm.i_entidades
                  and lm2.i_funcionarios = lm.i_funcionarios
                  and lm2.principal = 'S'
                  and (lm2.data_inicial < lm.data_inicial 
                   or (lm2.data_inicial = lm.data_inicial 
                  and (lm2.data_final is null
                   or lm2.data_final > lm.data_final))));

-- FIM DO ARQUIVO FOLHA - Validação - 153.sql

-- FOLHA - Validação: FOLHA - Validação - 154.sql

-- VALIDAÇÃO 154
-- Dependente sem data de inicio

select i_pessoas, 
       i_dependentes 
  from bethadba.dependentes d
 where dt_ini_depende is null;


-- CORREÇÃO
-- Atualiza a data de nascimento do dependente como data de inicio do dependente

update bethadba.dependentes d
   set dt_ini_depende = pf.dt_nascimento
  from bethadba.pessoas_fisicas  pf
 where d.dt_ini_depende is null
   and d.i_dependentes = pf.i_pessoas;

-- FIM DO ARQUIVO FOLHA - Validação - 154.sql

-- FOLHA - Validação: FOLHA - Validação - 155.sql

-- VALIDAÇÃO 155
-- Dependente sem motivo de inicio

select i_pessoas, 
       i_dependentes 
  from bethadba.dependentes d
 where mot_ini_depende is null;


-- CORREÇÃO
-- Atribui o motivo '1 - Nascimento' ao dependente que não possui motivo de início

update bethadba.dependentes
   set mot_ini_depende =  1
 where mot_ini_depende is null;

-- FIM DO ARQUIVO FOLHA - Validação - 155.sql

-- FOLHA - Validação: FOLHA - Validação - 156.sql

-- VALIDAÇÃO 156
-- Dependente com mais de uma configuração de IRRF

select i_dependentes,
	     count(i_dependentes) as total
  from (select distinct i_dependentes,
  						 dep_irrf
  		    from bethadba.dependentes_func df) as thd
 group by i_dependentes having total > 1;

-- CORREÇÃO
-- Deletar duplicidade de dependentes com mais de uma configuração de IRRF quando o dependente for o mesmo

delete from bethadba.dependentes_func
 where rowid in (select df.rowid
                   from (select i_dependentes,
                                dep_irrf,
                                row_number() over (partition by i_dependentes order by rowid) as rn
                           from bethadba.dependentes_func) df
                  where df.rn > 1
                    and df.i_dependentes in (select i_dependentes
                                               from (select i_dependentes,
                                                            count(i_dependentes) as total
                                                       from (select distinct i_dependentes,
                                                                             dep_irrf
                                                               from bethadba.dependentes_func) as thd
                                                      group by i_dependentes
                                                     having total > 1)));

-- FIM DO ARQUIVO FOLHA - Validação - 156.sql

-- FOLHA - Validação: FOLHA - Validação - 157.sql

-- VALIDAÇÃO 157
-- Dados faltantes em endereços de pessoas

select i_pessoas
  from bethadba.pessoas_enderecos as pe 
 where pe.i_ruas is null
    or pe.i_bairros is null
    or pe.i_cidades is null;


-- CORREÇÃO
-- Atualiza os endereços de pessoas com os valores máximos das entidades para i_ruas, i_bairros e i_cidades onde os valores estão faltando

update bethadba.pessoas_enderecos
   set i_ruas = (select max(i_ruas) from bethadba.entidades),
       i_bairros = (select max(i_bairros) from bethadba.entidades),
       i_cidades = (select max(i_cidades) from bethadba.entidades)
 where i_ruas is null
    or i_bairros is null
    or i_cidades is null;

-- FIM DO ARQUIVO FOLHA - Validação - 157.sql

-- FOLHA - Validação: FOLHA - Validação - 158.sql

-- VALIDAÇÃO 158
-- Dados divergentes em endereços de pessoas

select pe.i_pessoas,
	     pe.i_cidades,
	     r.i_cidades
  from bethadba.pessoas_enderecos as pe
  join bethadba.ruas as r
    on pe.i_ruas = r.i_ruas
 where pe.i_cidades <> r.i_cidades;


-- CORREÇÃO
-- Atualiza a coluna i_cidades na tabela pessoas_enderecos com o valor correto da tabela ruas

update bethadba.pessoas_enderecos as pe
   set pe.i_cidades = r.i_cidades 
  from bethadba.ruas as r
 where r.i_ruas = pe.i_ruas
   and r.i_cidades <> pe.i_cidades;

-- FIM DO ARQUIVO FOLHA - Validação - 158.sql

-- FOLHA - Validação: FOLHA - Validação - 159.sql

-- VALIDAÇÃO 159
-- Averbação sem tipo de conta

select distinct hf.i_entidades,
       hf.i_funcionarios 
  from bethadba.hist_funcionarios hf 
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where v.i_adicionais is not null
   and exists (select 1
                 from bethadba.funcionarios f
                where f.i_entidades = hf.i_entidades
                  and f.i_funcionarios = hf.i_funcionarios
                  and f.tipo_func  = 'F'
                  and f.conta_adicional = 'N');


-- CORREÇÃO
-- Atualiza conta_adicional para 'S' para funcionários com tipo_func = 'F' e conta_adicional = 'N' e possui vinculo com adicionais

update bethadba.funcionarios
   set conta_adicional = 'S'
 where i_entidades in (select distinct hf.i_entidades
                         from bethadba.hist_funcionarios hf
                         join bethadba.vinculos v
                           on hf.i_vinculos = v.i_vinculos
                        where v.i_adicionais is not null
                          and exists (select 1
                                        from bethadba.funcionarios f
                                       where f.i_entidades = hf.i_entidades
                                         and f.i_funcionarios = hf.i_funcionarios
                                         and f.tipo_func = 'F'
                                         and f.conta_adicional = 'N'))
   and i_funcionarios in (select distinct hf.i_funcionarios
                            from bethadba.hist_funcionarios hf
                            join bethadba.vinculos v
                              on hf.i_vinculos = v.i_vinculos
                           where v.i_adicionais is not null
                             and exists (select 1
                                           from bethadba.funcionarios f
                                          where f.i_entidades = hf.i_entidades
                                            and f.i_funcionarios = hf.i_funcionarios
                                            and f.tipo_func = 'F'
                                            and f.conta_adicional = 'N'));

-- FIM DO ARQUIVO FOLHA - Validação - 159.sql

-- FOLHA - Validação: FOLHA - Validação - 16.sql

-- VALIDAÇÃO 16
-- Verifica os atos com número nulos

select i_atos
  from bethadba.atos 
 where num_ato is null
    or num_ato = '';


-- CORREÇÃO
-- Atualiza os atos com número nulo para o i_atos como número do ato

update bethadba.atos 
   set num_ato = i_atos 
 where num_ato is null
    or num_ato = '';

-- FIM DO ARQUIVO FOLHA - Validação - 16.sql

-- FOLHA - Validação: FOLHA - Validação - 160.sql

-- VALIDAÇÃO 160
-- Averbação sem tipo de conta

select distinct hf.i_entidades,
       hf.i_funcionarios
  from bethadba.hist_funcionarios as hf 
  join bethadba.vinculos as v
    on hf.i_vinculos = v.i_vinculos
 where v.gera_licpremio = 'S'
   and exists (select 1
                 from bethadba.funcionarios as f
                where f.i_entidades = hf.i_entidades
                  and f.i_funcionarios = hf.i_funcionarios
                  and f.tipo_func = 'F'
   and f.conta_licpremio = 'N');


-- CORREÇÃO
-- Atualiza conta_licpremio para 'S' para funcionários com tipo_func = 'F' e conta_licpremio = 'N' e possui vinculo com adicionais

update bethadba.funcionarios f
   set conta_licpremio = 'S'
  from bethadba.hist_funcionarios hf
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where v.gera_licpremio = 'S'
   and f.tipo_func = 'F'
   and f.i_entidades = hf.i_entidades
   and f.i_funcionarios = hf.i_funcionarios
   and f.conta_licpremio = 'N';

-- FIM DO ARQUIVO FOLHA - Validação - 160.sql

-- FOLHA - Validação: FOLHA - Validação - 161.sql

-- VALIDAÇÃO 161
-- Organograma não cadastrado no controle de vagas do cargo

select distinct hf.i_entidades,
       hf.i_funcionarios,
       hf.i_config_organ,
       hf.i_organogramas,              
       hc.i_cargos,
       num_sintetico = (select no3.tot_digitos
                          from bethadba.niveis_organ no3
                         where no3.i_config_organ = hf.i_config_organ
                           and no3.i_niveis_organ = organogramas.nivel  - 1),
       sintetico = left(hf.i_organogramas, num_sintetico) + repeat('0', (select no3.num_digitos
                                                                           from bethadba.niveis_organ no3
                                                                          where no3.i_config_organ = hf.i_config_organ
                                                                            and no3.i_niveis_organ = organogramas.nivel))
  from bethadba.funcionarios,
       bethadba.hist_cargos hc,
       bethadba.hist_funcionarios hf,
       (select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hf.dt_alteracoes,
               origemHistorico = 'FUNCIONARIO'
          from bethadba.funcionarios f 
          join bethadba.hist_funcionarios hf
            on (f.i_entidades = hf.i_entidades
           and f.i_funcionarios = hf.i_funcionarios
           and hf.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos afast
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                                                  and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                               from bethadba.tipos_afast 
                                                                                              where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                                                and tipos_afast.classif = 9)), date('2999-12-31')))
        union
        select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hc.dt_alteracoes ,
               origemHistorico = 'CARGO'
          from bethadba.funcionarios f 
          join bethadba.hist_cargos hc
            on (f.i_entidades = hc.i_entidades
           and f.i_funcionarios = hc.i_funcionarios
           and hc.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos afast
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                           from bethadba.tipos_afast 
                                                                          where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                            and tipos_afast.classif = 9)), date('2999-12-31')))
         where not exists (select distinct 1
                             from bethadba.hist_funcionarios hf
                            where hf.i_entidades = hc.i_entidades
                              and hf.i_funcionarios = hc.i_funcionarios
                              and hf.dt_alteracoes = hc.dt_alteracoes)
         order by dataAlteracao) as tabAlt,
       bethadba.cargos,
       bethadba.tipos_cargos,
       bethadba.organogramas        
 where funcionarios.i_entidades = tabAlt.entidade
   and funcionarios.i_funcionarios = tabAlt.funcionario
   and cargos.i_cargos = hc.i_cargos
   and cargos.i_entidades = hc.i_entidades
   and funcionarios.i_funcionarios = hf.i_funcionarios
   and funcionarios.i_entidades = hf.i_entidades
   and hf.i_funcionarios = hc.i_funcionarios
   and hf.i_entidades = hc.i_entidades
   and hf.i_config_organ = organogramas.i_config_organ
   and hf.i_organogramas = organogramas.i_organogramas
   and hf.dt_alteracoes = bethadba.dbf_GetDataHisFun(hf.i_entidades, hf.i_funcionarios, dataAlteracao)
   and hc.dt_alteracoes = bethadba.dbf_GetDataHisCar(hc.i_entidades, hc.i_funcionarios, dataAlteracao)
   and funcionarios.tipo_func = 'F'
   and exists (select 1
                 from bethadba.cargos_organogramas co
                where co.i_entidades = hf.i_entidades
                  and co.i_cargos = hc.i_cargos)
   and not exists (select 1
                     from bethadba.cargos_organogramas co
                    where co.i_entidades = hf.i_entidades
                      and co.i_cargos = hc.i_cargos
                      and co.i_organogramas = sintetico);


-- CORREÇÃO
update bethadba.cargos_organogramas
   set i_organogramas = sintetico
  from (select hf.i_entidades,
               hf.i_funcionarios,
               hf.i_config_organ,
               hf.i_organogramas,              
               hc.i_cargos,
               num_sintetico = (select no3.tot_digitos
                                  from bethadba.niveis_organ no3
                                 where no3.i_config_organ = hf.i_config_organ
                                   and no3.i_niveis_organ = organogramas.nivel  - 1),
               sintetico = left(hf.i_organogramas, num_sintetico) + repeat('0', (select no3.num_digitos
                                                                                   from bethadba.niveis_organ no3
                                                                                  where no3.i_config_organ = hf.i_config_organ
                                                                                    and no3.i_niveis_organ = organogramas.nivel))
          from bethadba.funcionarios,
               bethadba.hist_cargos hc,
               bethadba.hist_funcionarios hf,
               (select entidade = f.i_entidades,
                       funcionario = f.i_funcionarios,
                       dataAlteracao = hf.dt_alteracoes,
                       origemHistorico = 'FUNCIONARIO'
                  from bethadba.funcionarios f 
                  join bethadba.hist_funcionarios hf
                    on (f.i_entidades = hf.i_entidades
                   and f.i_funcionarios = hf.i_funcionarios
                   and hf.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                                     from bethadba.afastamentos afast
                                                    where afast.i_entidades = f.i_entidades
                                                      and afast.i_funcionarios = f.i_funcionarios
                                                      and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                   from bethadba.tipos_afast 
                                                                                  where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                                    and tipos_afast.classif = 9)), date('2999-12-31')))
                union
                select entidade = f.i_entidades,
                       funcionario = f.i_funcionarios,
                       dataAlteracao = hc.dt_alteracoes ,
                       origemHistorico = 'CARGO'
                  from bethadba.funcionarios f
                  join bethadba.hist_cargos hc
                    on (f.i_entidades = hc.i_entidades
                   and f.i_funcionarios = hc.i_funcionarios
                   and hc.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                                     from bethadba.afastamentos afast
                                                    where afast.i_entidades = f.i_entidades
                                                      and afast.i_funcionarios = f.i_funcionarios
                                                      and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                   from bethadba.tipos_afast 
                                                                                  where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                                    and tipos_afast.classif = 9)), date('2999-12-31')))
                 where not exists (select distinct 1
                                     from bethadba.hist_funcionarios hf
                                    where hf.i_entidades = hc.i_entidades
                                      and hf.i_funcionarios = hc.i_funcionarios
                                      and hf.dt_alteracoes = hc.dt_alteracoes)
                 order by dataAlteracao) as tabAlt,
               bethadba.cargos,
               bethadba.tipos_cargos,
               bethadba.organogramas
         where funcionarios.i_entidades = tabAlt.entidade
           and funcionarios.i_funcionarios = tabAlt.funcionario
           and cargos.i_cargos = hc.i_cargos
           and cargos.i_entidades = hc.i_entidades
           and funcionarios.i_funcionarios = hf.i_funcionarios
           and funcionarios.i_entidades = hf.i_entidades
           and hf.i_funcionarios = hc.i_funcionarios
           and hf.i_entidades = hc.i_entidades
           and hf.i_config_organ = organogramas.i_config_organ
           and hf.i_organogramas = organogramas.i_organogramas
           and hf.dt_alteracoes = bethadba.dbf_GetDataHisFun(hf.i_entidades, hf.i_funcionarios, dataAlteracao)
           and hc.dt_alteracoes = bethadba.dbf_GetDataHisCar(hc.i_entidades, hc.i_funcionarios, dataAlteracao)
           and funcionarios.tipo_func = 'F'
           and exists (select 1
                         from bethadba.cargos_organogramas co
                        where co.i_entidades = hf.i_entidades
                          and co.i_cargos = hc.i_cargos)
           and not exists (select 1
                             from bethadba.cargos_organogramas co
                            where co.i_entidades = hf.i_entidades
                              and co.i_cargos = hc.i_cargos
                              and co.i_organogramas = sintetico)) as sintetico
 where cargos_organogramas.i_entidades = sintetico.i_entidades
   and cargos_organogramas.i_cargos = sintetico.i_cargos
   and cargos_organogramas.i_organogramas = sintetico.i_organogramas
   and cargos_organogramas.i_config_organ = sintetico.i_config_organ;

-- FIM DO ARQUIVO FOLHA - Validação - 161.sql

-- FOLHA - Validação: FOLHA - Validação - 162.sql

-- VALIDAÇÃO 162
-- Lançamentos sem dados de ferias

select pf.i_entidades,
       pf.i_funcionarios,
       pf.i_periodos,
       pf.i_periodos_ferias
  from bethadba.periodos_ferias pf 
 where not exists(select 1
                    from bethadba.ferias f
                   where f.i_entidades = pf.i_entidades
                     and f.i_funcionarios = pf.i_funcionarios
                     and f.i_periodos = pf.i_periodos
                     and f.i_ferias = pf.i_ferias)
   and pf.manual = 'N'
   and pf.tipo not in (1, 6, 7);


-- CORREÇÃO
-- Exclui os lançamentos de períodos de férias que não possuem dados de férias associados e que não são do tipo manual, férias coletivas ou férias de rescisão

delete bethadba.periodos_ferias
 where i_funcionarios in (select pf.i_funcionarios
                            from bethadba.periodos_ferias pf 
                           where not exists(select 1
                                              from bethadba.ferias f
                                             where f.i_entidades = pf.i_entidades
                                               and f.i_funcionarios = pf.i_funcionarios
                                               and f.i_periodos = pf.i_periodos
                                               and f.i_ferias = pf.i_ferias)
                             and pf.manual = 'N'
                             and pf.tipo not in(1, 6, 7))
   and i_periodos in (select pf.i_periodos
                        from bethadba.periodos_ferias pf 
                       where not exists(select 1
                                          from bethadba.ferias f
                                         where f.i_entidades = pf.i_entidades
                                           and f.i_funcionarios = pf.i_funcionarios
                                           and f.i_periodos = pf.i_periodos
                                           and f.i_ferias = pf.i_ferias)
                         and pf.manual = 'N'                                
                         and pf.tipo not in(1, 6, 7))
   and i_periodos_ferias in (select pf.i_periodos_ferias
                               from bethadba.periodos_ferias pf 
                              where not exists(select 1
                                                 from bethadba.ferias f
                                                where f.i_entidades = pf.i_entidades
                                                  and f.i_funcionarios = pf.i_funcionarios
                                                  and f.i_periodos = pf.i_periodos
                                                  and f.i_ferias = pf.i_ferias)
                                and pf.manual = 'N'                                
                                and pf.tipo not in(1, 6, 7));

-- FIM DO ARQUIVO FOLHA - Validação - 162.sql

-- FOLHA - Validação: FOLHA - Validação - 163.sql

-- VALIDAÇÃO 163
-- Processo trabalhista não contém pagamento de encargo

select pj.i_entidades,
       pj.i_funcionarios,
       pj.i_processos_judiciais
  from bethadba.processos_judiciais pj
 where pj.i_funcionarios not in (select i_funcionarios
                                   from bethadba.processos_judic_pagamentos_encargos);


-- CORREÇÃO
-- 1. Realizar update para inserir um valor no campo vlr_prev_oficial
-- 2. Inserir na tabela processos_judic_pagamentos_det o relacionamento com os processos judiciais
-- 3. Inserir na tabela processos_judic_pagamentos_encargos o relacionamento com os processos judiciais

-- Update para o campo vlr_prev_oficial
update bethadba.processos_judic_compet
   set vlr_prev_oficial = 1;

-- Insert para o relacionamento com a tabela processos_judic_pagamentos_det
insert into bethadba.processos_judic_pagamentos_det
      (i_entidades, i_funcionarios, i_processos_judiciais, i_competencias, i_tipos_proc, data_referencia)
select pj.i_entidades,
       pj.i_funcionarios,
       pj.i_processos_judiciais,
       pj.dt_final,
       11,
       pj.dt_final
  from bethadba.processos_judiciais pj
 where pj.i_funcionarios not in (select i_funcionarios
                                   from bethadba.processos_judic_pagamentos_encargos);
                  
-- Insert para o relacionamento com a tabela processos_judic_pagamentos_encargos
insert into bethadba.processos_judic_pagamentos_encargos
      (i_entidades, i_funcionarios, i_processos_judiciais, i_competencias, i_tipos_proc, data_referencia, i_receitas, aliquota, valor_inss)
select 1,
       pj.i_funcionarios,
       pj.i_processos_judiciais,
       pj.dt_final,
       11,
       pj.dt_final,
       113851,
       null,
       null
  from bethadba.processos_judiciais pj
 where pj.i_funcionarios not in (select i_funcionarios
                                   from bethadba.processos_judic_pagamentos_encargos)
   and pj.i_processos_judiciais not in (select i_processos_judiciais
                                          from bethadba.processos_judic_pagamentos_encargos);

-- FIM DO ARQUIVO FOLHA - Validação - 163.sql

-- FOLHA - Validação: FOLHA - Validação - 164.sql

-- VALIDAÇÃO 164
-- Autônomos com categorias diferentes de contribuinte individual

select f.i_entidades,
       f.i_funcionarios,
       f.tipo_func, 
       hf.i_vinculos, 
       v.categoria_esocial  
  from bethadba.funcionarios f 
  join bethadba.hist_funcionarios hf
    on f.i_entidades = hf.i_entidades
   and f.i_funcionarios = hf.i_funcionarios
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos 
 where f.tipo_func = 'A'
   and v.categoria_esocial not in ('701')
   and f.conselheiro_tutelar = 'N';

-- CORREÇÃO
-- Atualizar categoria do eSocial para 701 (Contribuinte Individual) para autônomos

update bethadba.vinculos v
   set v.categoria_esocial = '701'
 where v.i_vinculos in (select hf.i_vinculos
                          from bethadba.funcionarios f 
                          join bethadba.hist_funcionarios hf
                            on f.i_entidades = hf.i_entidades
                           and f.i_funcionarios = hf.i_funcionarios
                         where f.tipo_func = 'A'
                           and f.conselheiro_tutelar = 'N'
                           and v.categoria_esocial not in ('701'));

-- FIM DO ARQUIVO FOLHA - Validação - 164.sql

-- FOLHA - Validação: FOLHA - Validação - 165.sql

-- VALIDAÇÃO 165
-- Folhas de rescisão com processamentos incorretos

select dc.i_entidades,
       dc.i_funcionarios, 
       dc.i_tipos_proc, 
       dc.i_competencias, 
       m.mov_resc 
  from bethadba.dados_calc as dc
  join bethadba.movimentos m
    on dc.i_entidades = m.i_entidades
   and dc.i_funcionarios = m.i_funcionarios
   and dc.i_tipos_proc = m.i_tipos_proc
   and dc.i_processamentos = m.i_processamentos
   and dc.i_competencias = m.i_competencias
 where dc.i_tipos_proc not in (11, 42)
   and m.mov_resc = 'S';

-- CORREÇÃO
-- Atualiza os tipos de processo para 11 (Rescisão) onde necessário

update bethadba.dados_calc
  join bethadba.movimentos m
    on dc.i_entidades = m.i_entidades
   and dc.i_funcionarios = m.i_funcionarios
   and dc.i_tipos_proc = m.i_tipos_proc
   and dc.i_processamentos = m.i_processamentos
   and dc.i_competencias = m.i_competencias
   set i_tipos_proc = 11
 where dc.i_tipos_proc not in (11, 42)
   and m.mov_resc = 'S';

-- FIM DO ARQUIVO FOLHA - Validação - 165.sql

-- FOLHA - Validação: FOLHA - Validação - 166.sql

-- VALIDAÇÃO 166
-- CPF inválido

select i_pessoas,
       cpf,
       digitoAtual,
       digitoCalculado
  from (select i_pessoas, 
               cpf,
               MOD(MOD(cast(substring(cpf,1,1) + substring(cpf,2,1) * 2 + substring(cpf,3,1) * 3 + 
                substring(cpf,4,1) * 4 + substring(cpf,5,1) * 5 + substring(cpf,6,1) * 6 +
                substring(cpf,7,1) * 7 + substring(cpf,8,1) * 8 + substring(cpf,9,1) * 9 as int), 11), 10) as resto1,
               MOD(MOD(cast(substring(cpf,2,1) + substring(cpf,3,1) * 2 + substring(cpf,4,1) * 3 + 
                substring(cpf,5,1) * 4 + substring(cpf,6,1) * 5 + substring(cpf,7,1) * 6 + 
                substring(cpf,8,1) * 7 + substring(cpf,9,1) * 8 + resto1 * 9 as int),11),10) as resto2,
               string(resto1) || string(resto2) as digitoCalculado,
               right(cpf,2) as digitoAtual
          from bethadba.hist_pessoas_fis as hpf
         where cpf is not null and cpf <> ''
           and right(cpf,2) <> digitoCalculado
           and length(cpf) = 11) as tab;

-- CORREÇÃO
-- Atualizar o CPF com o dígito correto

update bethadba.hist_pessoas_fis as hpf
   set cpf = string(MOD(MOD(cast(substring(hpf.cpf,1,1) + substring(hpf.cpf,2,1) * 2 + substring(hpf.cpf,3,1) * 3 + 
              substring(hpf.cpf,4,1) * 4 + substring(hpf.cpf,5,1) * 5 + substring(hpf.cpf,6,1) * 6 +
              substring(hpf.cpf,7,1) * 7 + substring(hpf.cpf,8,1) * 8 + substring(hpf.cpf,9,1) * 9 as int), 11), 10))
             ||
             string(MOD(MOD(cast(substring(hpf.cpf,2,1) + substring(hpf.cpf,3,1) * 2 + substring(hpf.cpf,4,1) * 3 + 
              substring(hpf.cpf,5,1) * 4 + substring(hpf.cpf,6,1) * 5 + substring(hpf.cpf,7,1) * 6 + 
              substring(hpf.cpf,8,1) * 7 + substring(hpf.cpf,9,1) * 8 + 
             MOD(MOD(cast(substring(hpf.cpf,1,1) + substring(hpf.cpf,2,1) * 2 + substring(hpf.cpf,3,1) * 3 + 
              substring(hpf.cpf,4,1) * 4 + substring(hpf.cpf,5,1) * 5 + substring(hpf.cpf,6,1) * 6 +
              substring(hpf.cpf,7,1) * 7 + substring(hpf.cpf,8,1) * 8 + substring(hpf.cpf,9,1) * 9 as int), 11), 10) * 9 as int),11),10))
 where i_pessoas in (select i_pessoas
                       from (select i_pessoas, 
                                    MOD(MOD(cast(substring(cpf,1,1) + substring(cpf,2,1) * 2 + substring(cpf,3,1) * 3 + 
                                      substring(cpf,4,1) * 4 + substring(cpf,5,1) * 5 + substring(cpf,6,1) * 6 +
                                      substring(cpf,7,1) * 7 + substring(cpf,8,1) * 8 + substring(cpf,9,1) * 9 as int), 11), 10) as resto1,
                                    MOD(MOD(cast(substring(cpf,2,1) + substring(cpf,3,1) * 2 + substring(cpf,4,1) * 3 + 
                                      substring(cpf,5,1) * 4 + substring(cpf,6,1) * 5 + substring(cpf,7,1) * 6 + 
                                      substring(cpf,8,1) * 7 + substring(cpf,9,1) * 8 + resto1 * 9 as int),11),10) as resto2,
                                    string(resto1) || string(resto2) as digitoCalculado,
                                    right(cpf,2) as digitoAtual
                               from bethadba.hist_pessoas_fis as hpf
                              where cpf is not null and cpf <> ''
                                and right(cpf,2) <> digitoCalculado
                                and length(cpf) = 11) as tab);

-- FIM DO ARQUIVO FOLHA - Validação - 166.sql

-- FOLHA - Validação: FOLHA - Validação - 167.sql

-- VALIDAÇÃO 167
-- Ceritidão de obito nulas

select i_pessoas,
       dt_obito,
       ehfalecido 
  from bethadba.pessoas_fis_obito as pfo
 where ehfalecido = 'S'
   and certidao is null;

-- CORREÇÃO
-- Atualizar a certidão de óbito para 'N' onde ehfalecido é 'S' e certidão é nula

update bethadba.pessoas_fis_obito
   set ehfalecido = 'N'
 where ehfalecido = 'S'
   and certidao is null;

-- FIM DO ARQUIVO FOLHA - Validação - 167.sql

-- FOLHA - Validação: FOLHA - Validação - 168.sql

-- VALIDAÇÃO 168
-- Data de CNH menor que a data de nascimento

select pf.i_pessoas,
       pf.dt_nascimento,
       pfc.dt_primeira_cnh 
  from bethadba.pessoas_fis_compl pfc 
  join bethadba.pessoas_fisicas pf
    on pfc.i_pessoas = pf.i_pessoas 
 where dt_primeira_cnh < pf.dt_nascimento
   and dt_primeira_cnh is not null;


-- CORREÇÃO
-- Atualiza a data de primeira CNH para 18 anos após a data de nascimento para os registros onde a data de CNH é anterior à data de nascimento

update bethadba.pessoas_fis_compl pfc
  join bethadba.pessoas_fisicas pf
    on pfc.i_pessoas = pf.i_pessoas
   set pfc.dt_primeira_cnh = DATEADD(year, 18, pf.dt_nascimento)
 where pfc.dt_primeira_cnh < pf.dt_nascimento
   and pfc.dt_primeira_cnh is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 168.sql

-- FOLHA - Validação: FOLHA - Validação - 169.sql

-- VALIDAÇÃO 169
-- Data da primeira CNH maior que a da emissão da CNH

select pfc.i_pessoas,
       pfc.dt_primeira_cnh,
       pfc.dt_emissao_cnh
  from bethadba.pessoas_fis_compl pfc 
 where pfc.dt_primeira_cnh > pfc.dt_emissao_cnh 
   and pfc.dt_primeira_cnh is not null
   and pfc.dt_emissao_cnh is not null;


-- CORREÇÃO
-- Atualiza a data da primeira CNH para ser igual a data de emissão da CNH quando a data da primeira CNH for maior que a data de emissão da CNH e ambas as datas não forem nulas

update bethadba.pessoas_fis_compl pfc
   set dt_primeira_cnh = dt_emissao_cnh
 where pfc.dt_primeira_cnh > pfc.dt_emissao_cnh 
   and pfc.dt_primeira_cnh is not null
   and pfc.dt_emissao_cnh is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 169.sql

-- FOLHA - Validação: FOLHA - Validação - 17.sql

-- VALIDAÇÃO 17
-- Verifica os atos repetidos

select list(i_atos) as idatos,
       num_ato,
       i_tipos_atos,
       count(num_ato) as quantidade
from bethadba.atos 
group by num_ato, i_tipos_atos 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os atos repetidos para evitar duplicidade, adicionando o i_atos ao nome do ato

update bethadba.atos
   set num_ato = i_atos || ' - ' || num_ato
 where i_atos in (select i_atos
                    from bethadba.atos
                   where atos.i_atos in (select i_atos
                                          from bethadba.atos
                                         where (select count(i_atos)
                                                  from bethadba.atos b
                                                 where trim(b.num_ato) = trim(atos.num_ato)
                                                   and atos.i_tipos_atos = b.i_tipos_atos) > 1));

-- Substituir o update atual pela procedure procedure_unificacao_atos.sql

-- FIM DO ARQUIVO FOLHA - Validação - 17.sql

-- FOLHA - Validação: FOLHA - Validação - 170.sql

-- VALIDAÇÃO 170
-- Data de vencimento da CNH menor que a da emissão da CNH

select pfc.i_pessoas,
       pfc.dt_vencto_cnh,
       pfc.dt_emissao_cnh
  from bethadba.pessoas_fis_compl pfc
 where pfc.dt_vencto_cnh < pfc.dt_emissao_cnh
   and pfc.dt_vencto_cnh is not null
   and pfc.dt_emissao_cnh is not null;


-- CORREÇÃO
-- Atualiza a data de vencimento da CNH para um dia após a data de emissão da CNH

update bethadba.pessoas_fis_compl pfc 
   set dt_vencto_cnh = DATEADD(DAY, 1, dt_emissao_cnh)
 where pfc.dt_vencto_cnh < pfc.dt_emissao_cnh 
   and pfc.dt_vencto_cnh is not null
   and pfc.dt_emissao_cnh is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 170.sql

-- FOLHA - Validação: FOLHA - Validação - 171.sql

-- VALIDAÇÃO 171
-- afastament sem rescisão ou data divergente da rescisão com o afastamento.

select a.i_entidades,
       a.i_funcionarios,
       a.dt_afastamento,
       dt_rescisao = (select first r.dt_rescisao
                        from bethadba.rescisoes r
                       where r.dt_canc_resc is null
                         and r.i_entidades = a.i_entidades
                         and r.i_funcionarios = a.i_funcionarios
                         and r.dt_rescisao = a.dt_afastamento)
  from bethadba.afastamentos a
  join bethadba.tipos_afast ta
    on a.i_tipos_afast = ta.i_tipos_afast
 where ta.classif = 8
   and a.dt_ultimo_dia is null
   and dt_rescisao is null
 order by i_funcionarios  asc;


-- CORREÇÃO
-- Afastamentos sem rescisão ou data divergente da rescisão com o afastamento.

begin
    declare w_i_entidades integer;
    declare w_i_funcionarios integer;
    declare w_dt_afastamento timestamp;
    
    llLoop: for ll as cur_01 dynamic scroll cursor for
        select a.i_entidades,
               a.i_funcionarios,
               a.dt_afastamento,
               dt_rescisao = (select first r.dt_rescisao
                                from bethadba.rescisoes r
                               where r.dt_canc_resc is null
                                 and r.i_entidades = a.i_entidades
                                 and r.i_funcionarios = a.i_funcionarios
                                 and r.dt_rescisao = a.dt_afastamento)
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on a.i_tipos_afast = ta.i_tipos_afast
         where ta.classif = 8
           and a.dt_ultimo_dia is null
           and dt_rescisao is null
         order by i_funcionarios asc
    do 
        set w_i_entidades = i_entidades;
        set w_i_funcionarios = i_funcionarios;
        set w_dt_afastamento = dt_afastamento;
  
        update bethadba.rescisoes 
           set dt_rescisao = w_dt_afastamento
         where i_funcionarios = w_i_funcionarios
           and i_entidades = w_i_entidades;
  
        -- DEPOIS DESCOMENTAR as LINHAS A BAIXO E RODA-LAS
        -- insert into bethadba.rescisoes
        --  (i_entidades,i_funcionarios,i_rescisoes,i_motivos_resc,dt_rescisao,aviso_ind,vlr_saldo_fgts,fgts_mesant,compl_mensal,complementar,trab_dia_resc,proc_adm,deb_adm_pub,tipo_decisao,mensal,repor_vaga,aviso_desc,dt_chave_esocial)
        -- values (w_i_entidades,w_i_funcionarios,1,15,w_dt_afastamento,'N',0,'S','N','N','N','N','N','A','N','N','N',w_dt_afastamento);

    end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 171.sql

-- FOLHA - Validação: FOLHA - Validação - 172.sql

-- VALIDAÇÃO 172
-- Rescisão sem afastamento ou data divergente do afastamento com a rescisão.

select r.i_entidades,
       r.i_funcionarios,
       r.dt_rescisao
  from bethadba.rescisoes r
  join bethadba.motivos_resc mr
    on r.i_motivos_resc = mr.i_motivos_resc
  join bethadba.tipos_afast ta2
    on mr.i_tipos_afast = ta2.i_tipos_afast
 where ta2.classif = 8
   and r.i_motivos_apos is null
   and mr.dispensados <> 4
   and not exists (select 1
                     from bethadba.afastamentos a
                     join bethadba.tipos_afast ta
                       on a.i_tipos_afast = ta.i_tipos_afast
                    where ta.classif = 8 
                      and a.i_entidades = r.i_entidades
                      and a.i_funcionarios = r.i_funcionarios 
                      and a.dt_afastamento = r.dt_rescisao)

union all

select r.i_entidades,
       r.i_funcionarios,
       r.dt_rescisao
  from bethadba.rescisoes r
  join bethadba.motivos_apos mr
    on r.i_motivos_apos = mr.i_motivos_apos
  join bethadba.tipos_afast ta2
    on mr.i_tipos_afast = ta2.i_tipos_afast
 where ta2.classif = 9
   and r.i_motivos_apos is not null
   and not exists (select 1
                     from bethadba.afastamentos a
                     join bethadba.tipos_afast ta
                       on a.i_tipos_afast = ta.i_tipos_afast
                    where ta.classif = 9
                      and a.i_entidades = r.i_entidades
                      and a.i_funcionarios = r.i_funcionarios
                      and a.dt_afastamento = r.dt_rescisao)

union all 

select r.i_entidades,
       r.i_funcionarios,
       r.dt_rescisao
  from bethadba.rescisoes r
  join bethadba.motivos_apos mr
    on r.i_motivos_apos = mr.i_motivos_apos
  join bethadba.tipos_afast ta2
    on mr.i_tipos_afast = ta2.i_tipos_afast
 where ta2.classif = 8
   and r.i_motivos_apos is not null
   and not exists(select 1
                    from bethadba.afastamentos a
                    join bethadba.tipos_afast ta
                      on a.i_tipos_afast = ta.i_tipos_afast
                   where ta.classif = 8
                     and a.i_entidades = r.i_entidades
                     and a.i_funcionarios = r.i_funcionarios
                     and a.dt_afastamento = r.dt_rescisao)

 order by i_funcionarios asc;


-- CORREÇÃO
-- Atualizar o afastamento com a data da rescisão se não houver afastamento, criar um novo com a data da rescisão

update bethadba.rescisoes
   set dt_rescisao = a.dt_afastamento
  from bethadba.afastamentos a
  join bethadba.tipos_afast ta
    on a.i_tipos_afast = ta.i_tipos_afast
 where ((ta.classif = 8 and rescisoes.i_motivos_apos is null)
    or (ta.classif = 9 and rescisoes.i_motivos_apos is not null)
    or (ta.classif = 8 and rescisoes.i_motivos_apos is not null))
   and rescisoes.i_entidades = a.i_entidades
   and rescisoes.i_funcionarios = a.i_funcionarios
   and rescisoes.dt_rescisao <> a.dt_afastamento;


-- Se não houver afastamento, criar um novo afastamento com a data da rescisão.
insert into bethadba.afastamentos(
       i_entidades,
       i_funcionarios,
       dt_afastamento,
       i_tipos_afast,
       i_atos,
       dt_ultimo_dia,
       req_benef,
       comp_comunic,
       observacao,
       manual,
       sequencial,
       dt_afastamento_origem,
       desconsidera_rotina_prorrogacao,
       desconsidera_rotina_rodada,
       parecer_interno,
       conversao_fim_mp_664_2014,
       i_cid,
       i_medico_emitente,
       orgao_classe,
       nr_conselho,
       i_estados_orgao,
       acidente_transito,
       retificacao,
       dt_afastamento_retificacao,
       dt_retificacao,
       i_tipos_afast_antes,
       dt_afastamento_geracao,
       i_tipos_afast_geracao,
       origem_retificacao,
       tipo_processo,
       numero_processo)
select r.i_entidades,
       r.i_funcionarios,
       r.dt_rescisao,
       ta.i_tipos_afast,
       null,    -- i_atos
       null,    -- dt_ultimo_dia
       null,    -- req_benef
       null,    -- comp_comunic
       null,    -- observacao
       'S',     -- manual
       null,    -- sequencial
       null,    -- dt_afastamento_origem
       'N',     -- desconsidera_rotina_prorrogacao
       'N',     -- desconsidera_rotina_rodada
       'N',     -- parecer_interno
       'N',     -- conversao_fim_mp_664_2014
       null,    -- i_cid
       null,    -- i_medico_emitente
       null,    -- orgao_classe
       null,    -- nr_conselho
       null,    -- i_estados_orgao
       null,    -- acidente_transito
       'N',     -- retificacao
       null,    -- dt_afastamento_retificacao
       null,    -- dt_retificacao
       null,    -- i_tipos_afast_antes
       null,    -- dt_afastamento_geracao
       null,    -- i_tipos_afast_geracao
       null,    -- origem_retificacao
       null,    -- tipo_processo
       null     -- numero_processo
  from bethadba.rescisoes r
  join bethadba.tipos_afast ta
    on (ta.classif = 8 or ta.classif = 9)
 where not exists (select 1
                     from bethadba.afastamentos a
                    where a.i_entidades = r.i_entidades
                      and a.i_funcionarios = r.i_funcionarios
                      and a.dt_afastamento = r.dt_rescisao
                      and a.i_tipos_afast = ta.i_tipos_afast);

-- FIM DO ARQUIVO FOLHA - Validação - 172.sql

-- FOLHA - Validação: FOLHA - Validação - 173.sql

-- VALIDAÇÃO 173
-- Verifica se existem afastamentos de demissão com data de retorno preenchida.

select a.i_entidades,
       a.i_funcionarios,
       a.dt_afastamento,
       a.dt_ultimo_dia
  from bethadba.afastamentos a
  join bethadba.tipos_afast ta
    on a.i_tipos_afast = ta.i_tipos_afast
 where ta.classif = 8 
   and a.dt_ultimo_dia is not null
   and exists (select first 1
                 from bethadba.rescisoes r
                 join bethadba.motivos_resc mr
                   on r.i_motivos_resc = mr.i_motivos_resc
                 join bethadba.tipos_afast ta2
                   on mr.i_tipos_afast = ta2.i_tipos_afast
                where r.i_entidades = a.i_entidades
                  and r.i_funcionarios = a.i_funcionarios 
                  and r.dt_canc_resc is null            
                  and r.i_motivos_apos is null
                  and r.dt_rescisao = a.dt_afastamento
                  and ta2.classif = 8)
 order by i_entidades, i_funcionarios asc;
        
        
-- CORREÇÃO
-- Atualiza os registros da tabela afastamentos deixando nulo a coluna dt_ultimo_dia

update bethadba.afastamentos
   set dt_ultimo_dia = null
 where dt_ultimo_dia is not null
   and i_tipos_afast in (select a.i_tipos_afast
                           from bethadba.afastamentos a
                           join bethadba.tipos_afast ta
                             on a.i_tipos_afast = ta.i_tipos_afast
                          where ta.classif = 8
                            and a.dt_ultimo_dia is not null
                            and exists (select first 1
                                          from bethadba.rescisoes r
                                          join bethadba.motivos_resc mr
                                            on r.i_motivos_resc = mr.i_motivos_resc
                                          join bethadba.tipos_afast ta2
                                            on mr.i_tipos_afast = ta2.i_tipos_afast
                                         where r.i_entidades = a.i_entidades
                                           and r.i_funcionarios = a.i_funcionarios
                                           and r.dt_canc_resc is null
                                           and r.i_motivos_apos is null
                                           and r.dt_rescisao = a.dt_afastamento
                                           and ta2.classif = 8));

-- FIM DO ARQUIVO FOLHA - Validação - 173.sql

-- FOLHA - Validação: FOLHA - Validação - 174.sql

-- VALIDAÇÃO 174
-- Quantidades de digitos menores a configuração

select o.i_config_organ,
       o.i_organogramas,
       o.descricao,
       nivel_maximo = (select max(no2.i_niveis_organ)
                         from bethadba.niveis_organ as no2
                        where no2.i_config_organ = o.i_config_organ), 
       total_digitos = (select no2.tot_digitos
                          from bethadba.niveis_organ as no2
                         where no2.i_config_organ = o.i_config_organ
                           and no2.i_niveis_organ = nivel_maximo),
       total_digito_org = length(o.i_organogramas)                        
  from bethadba.organogramas as o
 where total_digito_org < total_digitos
    or total_digito_org > total_digitos;


-- CORREÇÃO
-- Atualizar o campo i_organogramas com a quantidade correta de digitos conforme configuração
-- Exemplo: Configuração com 3 niveis e 2 digitos cada nivel = 6 digitos

Update bethadba.organogramas
   set i_organogramas = right(i_organogramas + replicate('0', (select max(no2.tot_digitos)
                                                                 from bethadba.niveis_organ as no2
                                                                where no2.i_config_organ = o.i_config_organ)),
                                                              (select max(no2.tot_digitos)
                                                                 from bethadba.niveis_organ as no2
                                                                where no2.i_config_organ = o.i_config_organ))
  from bethadba.organogramas as o
 where length(o.i_organogramas) < (select max(no2.tot_digitos)
                                     from bethadba.niveis_organ as no2
                                    where no2.i_config_organ = o.i_config_organ)
    or length(o.i_organogramas) > (select max(no2.tot_digitos)
                                     from bethadba.niveis_organ as no2
                                    where no2.i_config_organ = o.i_config_organ);

-- FIM DO ARQUIVO FOLHA - Validação - 174.sql

-- FOLHA - Validação: FOLHA - Validação - 175.sql

-- VALIDAÇÃO 175
-- Lançamentos manuais com registros de ferias

select pf.i_entidades,
       pf.i_funcionarios,
       pf.i_periodos,
       pf.i_periodos_ferias,
       pf.i_ferias,
       pf.manual
  from bethadba.periodos_ferias as pf
  join bethadba.ferias as f
    on pf.i_entidades = f.i_entidades
   and pf.i_funcionarios = f.i_funcionarios
   and pf.i_periodos = f.i_periodos
   and pf.i_ferias = f.i_ferias
 where pf.manual = 'S'
   and pf.i_ferias is not null
   and pf.tipo <> 1;


-- CORREÇÃO
-- Atualiza lançamentos manuais para não manual

update periodos_ferias as pf
   set pf.manual = 'N'
  from bethadba.ferias as f
 where pf.i_entidades = f.i_entidades
   and pf.i_funcionarios = f.i_funcionarios
   and pf.i_periodos = f.i_periodos
   and pf.i_ferias = f.i_ferias
   and pf.manual = 'S'
   and pf.i_ferias is not null
   and pf.tipo <> 1;

-- FIM DO ARQUIVO FOLHA - Validação - 175.sql

-- FOLHA - Validação: FOLHA - Validação - 176.sql

-- VALIDAÇÃO 176
-- Conselheiro com vinculo com a categoria_esocial diferente de 771

select hf.i_entidades,
       hf.i_funcionarios,
       hf.i_vinculos 
  from bethadba.hist_funcionarios as hf
  join bethadba.funcionarios as f
    on hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where f.tipo_func = 'A' 
   and f.conselheiro_tutelar = 'S'
   and v.categoria_esocial <> '771';


-- CORREÇÃO
-- Atualizar a categoria_esocial do vinculo do conselheiro para 771

update bethadba.vinculos
   set categoria_esocial = '771'
 where i_vinculos in (select hf.i_vinculos
                        from bethadba.hist_funcionarios as hf
                        join bethadba.funcionarios as f
                          on hf.i_entidades = f.i_entidades
                         and hf.i_funcionarios = f.i_funcionarios
                       where f.tipo_func = 'A' 
                         and f.conselheiro_tutelar = 'S'
                         and hf.i_vinculos is not null
                         and hf.i_vinculos in (select i_vinculos
                                                 from bethadba.vinculos
                                                where categoria_esocial <> '771'));

-- FIM DO ARQUIVO FOLHA - Validação - 176.sql

-- FOLHA - Validação: FOLHA - Validação - 177.sql

-- VALIDAÇÃO 177
-- Autônomo com vinculo com a categoria_esocial diferente de 701

select hf.i_entidades,
       hf.i_funcionarios,
       hf.i_vinculos 
  from bethadba.hist_funcionarios hf 
  join bethadba.funcionarios f
    on hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios 
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where f.tipo_func = 'A' 
   and f.conselheiro_tutelar = 'N'
   and v.categoria_esocial not in ('701', '711', '741');


-- CORREÇÃO
-- Atualizar a categoria_esocial do vinculo para 701

update bethadba.vinculos v
   set v.categoria_esocial = '701'
 where v.categoria_esocial not in ('701', '711', '741')
   and exists (select 1 
                 from bethadba.hist_funcionarios hf 
                 join bethadba.funcionarios f
                   on hf.i_entidades = f.i_entidades
                  and hf.i_funcionarios = f.i_funcionarios 
                where hf.i_vinculos = v.i_vinculos
                  and f.tipo_func = 'A' 
                  and f.conselheiro_tutelar = 'N');

-- FIM DO ARQUIVO FOLHA - Validação - 177.sql

-- FOLHA - Validação: FOLHA - Validação - 178.sql

-- VALIDAÇÃO 178
-- Funcionario com vínculo com a categoria_esocial 771 ou 701

select hf.i_entidades,
       hf.i_funcionarios,
       hf.i_vinculos,
       v.categoria_esocial
  from bethadba.hist_funcionarios as hf 
  join bethadba.funcionarios as f
    on hf.i_entidades = f.i_entidades
   and hf.i_funcionarios = f.i_funcionarios 
  join bethadba.vinculos v
    on hf.i_vinculos = v.i_vinculos
 where f.tipo_func = 'F'
   and v.categoria_esocial in ('701','771');


-- Correção
-- Atualiza o vínculo para 5 (Estatutário - Regime Estatutário - Efetivo) para funcionários do tipo F (Funcionário Público) com vínculo com a categoria_esocial 701 ou 771

update bethadba.vinculos
   set categoria_esocial = '5'
 where i_vinculos in (select hf.i_vinculos
                        from bethadba.hist_funcionarios as hf 
                        join bethadba.funcionarios as f
                          on hf.i_entidades = f.i_entidades
                         and hf.i_funcionarios = f.i_funcionarios 
                        join bethadba.vinculos v
                          on hf.i_vinculos = v.i_vinculos
                       where f.tipo_func = 'F'
                         and v.categoria_esocial in ('701','771'));

-- FIM DO ARQUIVO FOLHA - Validação - 178.sql

-- FOLHA - Validação: FOLHA - Validação - 179.sql

-- VALIDAÇÃO 179
-- Lançamentos de gozo com datas divergentes da data de inicio de gozo

select p.i_entidades,
       p.i_funcionarios,
       pf.i_periodos,
       pf.dt_periodo,
       f.dt_gozo_ini,
       pf.i_periodos_ferias,
       f.i_ferias
  from bethadba.periodos as p 
  join bethadba.periodos_ferias as pf
    on p.i_entidades = pf.i_entidades 
   and p.i_funcionarios = pf.i_funcionarios
   and p.i_periodos = pf.i_periodos 
  join bethadba.ferias as f
    on pf.i_entidades = f.i_entidades
   and pf.i_funcionarios = f.i_funcionarios
   and pf.i_periodos = f.i_periodos
   and pf.i_ferias = f.i_ferias
 where pf.manual = 'N' 
   and pf.dt_periodo <> f.dt_gozo_ini
   and pf.tipo = 2;


-- Correção
-- O script abaixo irá atualizar a data do período de férias com a data de início do gozo

begin
    declare w_dt_gozo_ini date;
    declare w_dt_periodo date;
    declare w_i_funcionarios integer;
    declare w_i_periodos_ferias integer;
    declare w_i_ferias integer;
    declare w_i_periodos integer;
    declare w_i_entidades integer;
    
    llloop: for ll as meuloop2 dynamic scroll cursor for
      select p.i_entidades,
             p.i_funcionarios,
             pf.i_periodos,
             pf.dt_periodo,
             f.dt_gozo_ini,
             pf.i_periodos_ferias,
             f.i_ferias
        from bethadba.periodos p 
        join bethadba.periodos_ferias pf
          on p.i_entidades = pf.i_entidades 
         and p.i_funcionarios = pf.i_funcionarios
         and p.i_periodos = pf.i_periodos 
        join bethadba.ferias f
          on pf.i_entidades = f.i_entidades
         and pf.i_funcionarios = f.i_funcionarios
         and pf.i_periodos = f.i_periodos
         and pf.i_ferias = f.i_ferias
       where pf.manual = 'N' 
         and pf.dt_periodo <> f.dt_gozo_ini
         and pf.tipo = 2

    do
        set w_dt_gozo_ini = dt_gozo_ini;
        set w_dt_periodo = dt_periodo;
        set w_i_funcionarios = i_funcionarios;
        set w_i_periodos_ferias = i_periodos_ferias;
        set w_i_ferias = i_ferias;
        set w_i_periodos = i_periodos;
        set w_i_entidades = i_entidades;

        update bethadba.periodos_ferias 
           set dt_periodo = w_dt_gozo_ini
         where i_funcionarios = w_i_funcionarios 
           and i_ferias = w_i_ferias
           and i_periodos = w_i_periodos
    end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 179.sql

-- FOLHA - Validação: FOLHA - Validação - 18.sql

-- VALIDAÇÃO 18
-- Verifica os CBO's nulos nos cargos

select i_entidades,
       i_cargos,
       i_cbo,
       i_tipos_cargos,
       nome
  from bethadba.cargos
 where i_cbo is null;


-- CORREÇÃO
-- Atualiza os CBO's nulos para um valor padrão (exemplo: 312320) para evitar problemas de integridade referencial

update bethadba.cargos
   set i_cbo = 312320 
 where i_cargos = 9999;

-- FIM DO ARQUIVO FOLHA - Validação - 18.sql

-- FOLHA - Validação: FOLHA - Validação - 180.sql

-- VALIDAÇÃO 180
-- Cargos com classificação comissionado ou não classificado com configuração de ferias

select c.i_entidades,
       c.nome,
       c.i_tipos_cargos,
       cc.i_config_ferias,
       tc.classif 
  from bethadba.cargos as c
  join bethadba.tipos_cargos as tc
    on c.i_tipos_cargos = tc.i_tipos_cargos
  join bethadba.cargos_compl as cc
    on c.i_entidades = cc.i_entidades
   and c.i_cargos = cc.i_cargos
 where tc.classif in (0, 2)
   and cc.i_config_ferias is not null;


-- CORREÇÃO
-- Remove a configuração de férias dos cargos com classificação comissionado ou não classificado

update bethadba.cargos_compl cc
   set i_config_ferias = null
  from bethadba.cargos c
  join bethadba.tipos_cargos tc
    on c.i_tipos_cargos = tc.i_tipos_cargos
 where c.i_entidades = cc.i_entidades
   and c.i_cargos = cc.i_cargos
   and tc.classif in (0, 2)
   and cc.i_config_ferias is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 180.sql

-- FOLHA - Validação: FOLHA - Validação - 181.sql

-- VALIDAÇÃO 181
-- Caracteristicas de matrículas não presentes na tabela de caracteristicas CFG

select distinct i_caracteristicas
  from bethadba.funcionarios_prop_adic
 where i_caracteristicas not in (select i_caracteristicas
   								                 from bethadba.funcionarios_caract_cfg fcc);


-- CORREÇÃO
-- Inserir as caracteristicas que não existem na tabela de caracteristicas CFG

insert into bethadba.funcionarios_caract_cfg (i_caracteristicas, ordem, permite_excluir, dt_expiracao)
select fpa.i_caracteristicas,
       (select coalesce(max(ordem), 0) + row_number() over (order by fpa.i_caracteristicas)
          from bethadba.funcionarios_caract_cfg) as ordem,
       'S',
       to_date('31/12/9999','dd/mm/yyyy')
  from bethadba.funcionarios_prop_adic fpa
 where fpa.i_caracteristicas not in (select i_caracteristicas
                                       from bethadba.funcionarios_caract_cfg);

-- FIM DO ARQUIVO FOLHA - Validação - 181.sql

-- FOLHA - Validação: FOLHA - Validação - 182.sql

-- VALIDAÇÃO 182
-- Data final da vigência de bases anteriores de outras empresas equivocada. (Causa Travamento do Arqjob)

select i_pessoas,
       i_empresas,
       dt_vigencia_ini,
       dt_vigencia_fin
  from bethadba.bases_calc_outras_empresas 
 where dt_vigencia_fin > '2100-01-01';


-- CORREÇÃO
-- Atualiza a data final da vigência para 2100-01-01 onde estiver maior que essa data e não for nula

update bethadba.bases_calc_outras_empresas
   set dt_vigencia_fin = '2099-12-31'
 where dt_vigencia_fin > '2100-01-01';

-- FIM DO ARQUIVO FOLHA - Validação - 182.sql

-- FOLHA - Validação: FOLHA - Validação - 183.sql

-- VALIDAÇÃO 183
-- Concessão com tag manual como S porém com lançamento de ferias

select pf.i_entidades,
       pf.i_funcionarios,
       pf.i_periodos,
       pf.manual,
       pf.i_ferias
  from bethadba.periodos_ferias pf
 where pf.tipo <> 1
   and pf.manual = 'S'
   and pf.i_ferias is not null;


-- CORREÇÃO
-- Atualizar a coluna manual para 'N' onde o tipo é diferente de 1 e i_ferias não é nulo

update bethadba.periodos_ferias pf
   set pf.manual = 'N'
 where pf.tipo <> 1
   and pf.manual = 'S'
   and pf.i_ferias is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 183.sql

-- FOLHA - Validação: FOLHA - Validação - 184.sql

-- VALIDAÇÃO 184
-- Descrição da natureza de texto jurídica duplicada

select a.i_natureza_texto_juridico,
       a.descricao
  from bethadba.natureza_texto_juridico as a
 where exists(select first 1
                from bethadba.natureza_texto_juridico as b
               where b.descricao = a.descricao
                 and b.i_natureza_texto_juridico <> a.i_natureza_texto_juridico);


-- CORREÇÃO
-- Atualizar a descrição da natureza de texto jurídico duplicada inserindo o prefixo 'i_natureza_texto_juridico'

update bethadba.natureza_texto_juridico as a
   set descricao = i_natureza_texto_juridico || ' - ' || a.descricao
 where exists(select first 1
                from bethadba.natureza_texto_juridico as b
               where b.descricao = a.descricao
                 and b.i_natureza_texto_juridico <> a.i_natureza_texto_juridico);

-- FIM DO ARQUIVO FOLHA - Validação - 184.sql

-- FOLHA - Validação: FOLHA - Validação - 185.sql

-- VALIDAÇÃO 185
-- Descrição de tipos de cargos duplicadas

select a.i_tipos_cargos,
       a.descricao
  from bethadba.tipos_cargos as a
 where exists(select first 1
 				from bethadba.tipos_cargos as b
               where b.descricao = a.descricao
                 and b.i_tipos_cargos <> a.i_tipos_cargos);


-- CORREÇÃO
-- Atualizar a descrição do tipo de cargo duplicada inserindo o prefixo 'i_tipos_cargos - ' antes da descrição original

update bethadba.tipos_cargos as a
   set descricao = a.i_tipos_cargos || ' - ' || a.descricao
 where exists (select first 1
 				         from bethadba.tipos_cargos as b
                where b.descricao = a.descricao
                  and b.i_tipos_cargos <> a.i_tipos_cargos);

-- FIM DO ARQUIVO FOLHA - Validação - 185.sql

-- FOLHA - Validação: FOLHA - Validação - 186.sql

-- VALIDAÇÃO 186
-- Descrição com caracteres superior ao limite(50)

select i_entidades,
       i_periodos_trab,
       descricao
  from bethadba.periodos_trab
 where length(descricao) > 50;


-- CORREÇÃO
-- Truncar a descrição para 50 caracteres

update bethadba.periodos_trab
   set descricao = substr(descricao, 1, 50)
 where length(descricao) > 50;

-- FIM DO ARQUIVO FOLHA - Validação - 186.sql

-- FOLHA - Validação: FOLHA - Validação - 187.sql

-- VALIDAÇÃO 187
-- Pessoas com número da certidão contendo mais de 15 dígitos para os modelos antigos.

select i_pessoas,
       modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(pessoas_fis_compl.num_reg)) = 1 then
                   'NOVO'
                else
                   'ANTIGO'
                endif,
       numeroNascimento = if modelo = 'ANTIGO' then 
                            pessoas_fis_compl.num_reg 
                          else
                            bethadba.dbf_retira_alfa_de_inteiros(pessoas_fis_compl.num_reg)
                          endif
  from bethadba.pessoas_fis_compl
 where numeroNascimento is not null
   and length(numeroNascimento) > 15
   and modelo = 'ANTIGO';


-- CORREÇÃO
-- Atualizar os registros com número da certidão contendo mais de 15 dígitos para os modelos antigos.

update bethadba.pessoas_fis_compl
   set num_reg = right(replicate('0', 15) + bethadba.dbf_retira_caracteres_especiais(num_reg), 15)
    where i_pessoas in (select i_pessoas
                     from (select i_pessoas,
                              modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(pessoas_fis_compl.num_reg)) = 1 then
                                       'NOVO'
                                     else
                                       'ANTIGO'
                                     endif,
                              numeroNascimento = if modelo = 'ANTIGO' then 
                                               pessoas_fis_compl.num_reg 
                                             else
                                               bethadba.dbf_retira_alfa_de_inteiros(pessoas_fis_compl.num_reg)
                                             endif
                           from bethadba.pessoas_fis_compl
                          where numeroNascimento is not null
                           and length(numeroNascimento) > 15
                           and modelo = 'ANTIGO') as subquery);

-- FIM DO ARQUIVO FOLHA - Validação - 187.sql

-- FOLHA - Validação: FOLHA - Validação - 188.sql

-- VALIDAÇÃO 188
-- Data do historico do cadastro anterior a data de nascimento atual

select pf.i_pessoas,
       pf.dt_nascimento,
       hpf.dt_alteracoes
  from bethadba.hist_pessoas_fis as hpf 
  join bethadba.pessoas_fisicas as pf 
 where hpf.dt_alteracoes < pf.dt_nascimento;


-- CORREÇÃO
-- Atualiza a data de alteração do histórico para a data de nascimento atual para os registros onde a data de alteração é anterior à data de nascimento

update hist_pessoas_fis as hpf
   set hpf.dt_alteracoes = case when exists (select 1
                                               from hist_pessoas_fis hpf2
                                              where hpf2.i_pessoas = hpf.i_pessoas
                                                and hpf2.dt_alteracoes = pf.dt_nascimento)
                                then
                                  dateadd(day, 1, pf.dt_nascimento)
                                else
                                  pf.dt_nascimento
                                 end
  from pessoas_fisicas as pf
 where hpf.i_pessoas = pf.i_pessoas
   and hpf.dt_alteracoes < pf.dt_nascimento;

-- FIM DO ARQUIVO FOLHA - Validação - 188.sql

-- FOLHA - Validação: FOLHA - Validação - 189.sql

-- VALIDAÇÃO 189
-- Historicos de cargos com niveis com data anterior a criação do nivel.

select niveis.i_entidades,
	     niveis.i_cargos,
       niveis.dt_alteracao_cargos,
       niveis.i_niveis,
       niveis.dt_alteracao_nivel,
       niveis.rn
  from (select distinct n.i_entidades,
                        hcc.i_cargos,
                        hcc.dt_alteracoes as dt_alteracao_cargos,
  						          n.i_niveis,
                        n.dt_alteracoes as dt_alteracao_nivel,
                        row_number() over (partition by n.i_entidades, n.i_niveis order by n.dt_alteracoes ASC) as rn
          from bethadba.hist_cargos_compl hcc,
          	   bethadba.hist_niveis n
         where n.i_entidades = hcc.i_entidades 
           and n.i_niveis = hcc.i_niveis
           and dt_alteracao_cargos < (select min(dt_alteracoes)
           								              from bethadba.hist_niveis n2
           							               where n2.i_entidades = n.i_entidades
           							   	             and n2.i_niveis = n.i_niveis)) as niveis
 where niveis.rn = 1;


-- CORREÇÃO
-- Cria tabela temporária para armazenar os dados que serão utilizados na atualização do histórico de níveis com a data do histórico do cargo mais antigo do nível referenciado.
call bethadba.dbp_conn_gera(1, 2025, 300);
call bethadba.pg_setoption('wait_for_commit','on');
call bethadba.pg_habilitartriggers('off');

if exists (select 1 from sys.systable where table_name = 'valida_189') then 
	drop table valida_189;
end if;
	
create table valida_189(
	i_entidades integer,
	i_cargos integer ,        
	dt_alteracao_cargos timestamp,
	i_niveis integer,
	dt_alteracao_nivel timestamp,
	rn integer);

insert into valida_189
select niveis.i_entidades,
       niveis.i_cargos,
       niveis.dt_alteracao_cargos,
       niveis.i_niveis,
       niveis.dt_alteracao_nivel,
       niveis.rn
  from (select distinct n.i_entidades,
                        hcc.i_cargos,
                        hcc.dt_alteracoes as dt_alteracao_cargos,
                        n.i_niveis,
                        n.dt_alteracoes as dt_alteracao_nivel,
                        ROW_NUMBER() over (partition by n.i_entidades, n.i_niveis order by n.dt_alteracoes asc) as rn
          from bethadba.hist_cargos_compl hcc,
               bethadba.hist_niveis n
         where n.i_entidades = hcc.i_entidades
           and n.i_entidades in (1)
           and n.i_niveis = hcc.i_niveis
           and dt_alteracao_cargos < (select MIN(dt_alteracoes)
                                        from bethadba.hist_niveis n2
                                       where n2.i_entidades = n.i_entidades
                                         and n2.i_niveis = n.i_niveis)) as niveis
 where niveis.rn = 1;

call bethadba.dbp_conn_gera(1, 2025, 300);
call bethadba.pg_setoption('wait_for_commit','on');
call bethadba.pg_habilitartriggers('off');


-- Atualiza o histórico do nivel com a data do histórico do cargo mais antigo do nivel
update bethadba.hist_niveis as n,
	   valida_189
   set n.dt_alteracoes = (select min(a.dt_alteracao_cargos)
   							from valida_189 as a
   						   where a.i_entidades = n.i_entidades
   						     and a.i_niveis = n.i_niveis) 
 where dt_alteracoes in (select MIN(dt_alteracoes)
                           from bethadba.hist_niveis n2
                          where n2.i_entidades = n.i_entidades
                            and n2.i_niveis = n.i_niveis)
   and valida_189.i_entidades = n.i_entidades
   and valida_189.i_niveis = n.i_niveis;

update bethadba.hist_clas_niveis as n,
	   valida_189
   set n.dt_alteracoes = (select min(a.dt_alteracao_cargos)
							from valida_189 as a
						   where a.i_entidades = n.i_entidades
						     and a.i_niveis = n.i_niveis) 
 where n.i_niveis = valida_189.i_niveis
   and n.i_entidades = valida_189.i_entidades  
   and n.dt_alteracoes = valida_189.dt_alteracao_nivel;

commit;

-- FIM DO ARQUIVO FOLHA - Validação - 189.sql

-- FOLHA - Validação: FOLHA - Validação - 19.sql

-- VALIDAÇÃO 19
-- Verifica categoria eSocial nulo no vínculo empregatício

select i_vinculos,
       descricao,
       categoria_esocial
  from bethadba.vinculos
 where categoria_esocial is null
   and tipo_func <> 'B';


-- CORREÇÃO
-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: 105) para evitar problemas de integridade referencial

update bethadba.vinculos
   set categoria_esocial = 105
 where categoria_esocial is null
   and i_vinculos = 3;

-- FIM DO ARQUIVO FOLHA - Validação - 19.sql

-- FOLHA - Validação: FOLHA - Validação - 190.sql

-- VALIDAÇÃO 190
-- Descrição de habilitação superior ao limite de caracteres

select aa.i_areas_atuacao,
       aa.nome,
       aa.descr_habilitacao
  from bethadba.areas_atuacao as aa
 where length(aa.descr_habilitacao) > 100;


-- CORREÇÃO
-- A correção deve ser feita no cadastro da área de atuação, reduzindo o tamanho da descrição para 100 caracteres ou menos.

update bethadba.areas_atuacao
   set descr_habilitacao = substr(descr_habilitacao, 1, 100)
 where length(descr_habilitacao) > 100;

-- FIM DO ARQUIVO FOLHA - Validação - 190.sql

-- FOLHA - Validação: FOLHA - Validação - 191.sql

-- VALIDAÇÃO 191
-- Data de ultimo dia anterior a data de afastamento

select a.i_entidades,
       a.i_funcionarios,
       a.dt_afastamento,
       a.dt_ultimo_dia
  from bethadba.afastamentos as a
 where a.dt_ultimo_dia < a.dt_afastamento;


-- CORREÇÃO
-- Atualiza a data de ultimo dia para ser um dia após a data de afastamento para os registros que possuem data de ultimo dia anterior a data de afastamento

update afastamentos as a
   set a.dt_ultimo_dia = DATEADD(day, 1, a.dt_afastamento)
 where a.dt_ultimo_dia < a.dt_afastamento;

-- FIM DO ARQUIVO FOLHA - Validação - 191.sql

-- FOLHA - Validação: FOLHA - Validação - 192.sql

-- VALIDAÇÃO 192
-- Numero de certidão civil duplicada

select i_pessoas,
       modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(A.num_reg)) = 1 then
       				    'NOVO'
                else
                  'ANTIGO'
                endif,
       numeroNascimento = if modelo = 'ANTIGO' then 
							              A.num_reg 
                          else
                            bethadba.dbf_retira_alfa_de_inteiros(A.num_reg)
                          endif
  from bethadba.pessoas_fis_compl A
 where numeroNascimento is not null
   and exists(select first modeloB = if isnumeric(bethadba.dbf_retira_caracteres_especiais(B.num_reg)) = 1 then
                                        'NOVO'
                        			       else
				                                'ANTIGO'
                			               endif,
		                 numeroNascimentoB = if modeloB = 'ANTIGO' then 
										                  			B.num_reg 
			                                   else
             				                        bethadba.dbf_retira_alfa_de_inteiros(B.num_reg)
                             				     endif
	              from bethadba.pessoas_fis_compl B
	             where A.i_pessoas <> B.i_pessoas
                 and numeroNascimentoB = numeroNascimento);


-- CORREÇÃO
-- Atualizar o campo num_reg para que o mesmo não seja duplicado na tabela pessoas_fis_compl

update bethadba.pessoas_fis_compl
   set num_reg = null
 where i_pessoas in (select i_pessoas
                       from (select i_pessoas,
                                    modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(A.num_reg)) = 1 then
                                                'NOVO'
                                              else
                                                'ANTIGO'
                                              endif,
                                    numeroNascimento = if modelo = 'ANTIGO' then 
                                                          A.num_reg 
                                                        else
                                                          bethadba.dbf_retira_alfa_de_inteiros(A.num_reg)
                                                        endif
                               from bethadba.pessoas_fis_compl A
                              where numeroNascimento is not null
                                and exists(select first modeloB = if isnumeric(bethadba.dbf_retira_caracteres_especiais(B.num_reg)) = 1 then
                                                                      'NOVO'
                                                                  else
                                                                      'ANTIGO'
                                                                  endif,
                                                  numeroNascimentoB = if modeloB = 'ANTIGO' then 
                                                                          B.num_reg 
                                                                      else
                                                                          bethadba.dbf_retira_alfa_de_inteiros(B.num_reg)
                                                                      endif
                                             from bethadba.pessoas_fis_compl B
                                            where A.i_pessoas <> B.i_pessoas
                                              and numeroNascimentoB = numeroNascimento)) as subquery);

-- FIM DO ARQUIVO FOLHA - Validação - 192.sql

-- FOLHA - Validação: FOLHA - Validação - 193.sql

-- VALIDAÇÃO 193
-- É necessario preencher o campo desenoração de folha.

select hpp.i_entidades,
       hpp.i_competencias,
       t.i_entidade_conv,
       t.i_tabelas,
       t.i_cpt_ini_conv,
       hpp.desoneracao_folha
  from bethadba.hist_parametros_previd as hpp,
       bethadba.conv_cloud_tabelas_encargos as t
 where t.i_entidades = hpp.i_entidades
   and t.i_cpt_ini_conv >= '2024-01'
   and hpp.desoneracao_folha is null
   and hpp.i_competencias = (select max(hpp2.i_competencias) 
                               from bethadba.hist_parametros_previd as hpp2 
                              where hpp2.i_entidades = hpp.i_entidades 
                                and hpp2.i_competencias <= t.i_cpt_ini_conv);


-- CORREÇÃO
-- Preenchendo o campo desoneração de folha com o valor 2

update bethadba.hist_parametros_previd as hpp
   set hpp.desoneracao_folha = 2
  from bethadba.conv_cloud_tabelas_encargos as t
 where t.i_entidades = hpp.i_entidades
   and t.i_cpt_ini_conv >= '2024-01'
   and hpp.desoneracao_folha is null
   and hpp.i_competencias = (select max(hpp2.i_competencias)
                               from bethadba.hist_parametros_previd as hpp2
                              where hpp2.i_entidades = hpp.i_entidades
                                and hpp2.i_competencias <= t.i_cpt_ini_conv);

-- FIM DO ARQUIVO FOLHA - Validação - 193.sql

-- FOLHA - Validação: FOLHA - Validação - 194.sql

-- VALIDAÇÃO 194
-- Configuração sem responsável

select pr.i_entidades,
       pr.i_parametros_rel,
       tipoInscricao = tipo_insc,
       nome = isnull(nome_resp,''),
       pessoaJuridicaAx = isnull((select first i_pessoas
                                    from bethadba.pessoas
                                   where SIMILAR(nome,nome_resp) >= 80),0),
       pessoaFisicaAx = isnull((select first i_pessoas
                                  from bethadba.pessoas
                                 where SIMILAR(nome,nome_resp) >= 80),0)
  from bethadba.parametros_rel as pr
 where pr.i_parametros_rel = 2        
   and ((tipoInscricao = 'J' and pessoaJuridicaAx = 0)
    or (tipoInscricao = 'F' and pessoaFisicaAx = 0));


-- CORREÇÃO
-- Exclui os registros de parâmetros de relatório que estejam com tipo de inscrição
-- 'J' e sem pessoa jurídica associada ou com tipo de inscrição 'F' e sem pessoa física associada

update bethadba.parametros_rel pr
   set pr.nome_resp = (select nome
   						           from bethadba.pessoas_nomes
   						          where i_pessoas = (select top 1 e.i_pessoas
                                   					 from bethadba.hist_entidades_compl e
					                                  where e.i_entidades = pr.i_entidades
                                              and i_pessoas is not null
                    					              order by i_competencias desc))
 where pr.i_parametros_rel = 2
   and ((pr.tipo_insc = 'J'
   and isnull((select first i_pessoas
                 from bethadba.pessoas
                where SIMILAR(nome, pr.nome_resp) >= 80),0) = 0)
    or (pr.tipo_insc = 'F'
   and isnull((select first i_pessoas
                 from bethadba.pessoas
                where SIMILAR(nome, pr.nome_resp) >= 80),0) = 0));

-- FIM DO ARQUIVO FOLHA - Validação - 194.sql

-- FOLHA - Validação: FOLHA - Validação - 195.sql

-- VALIDAÇÃO 195
-- Agrupador sem eventos

select i_agrupadores,
       descricao,
       tipo
  from bethadba.agrupadores_eventos as ae
 where not exists(select first 1
                    from bethadba.eventos
                   where i_agrupadores = ae.i_agrupadores);


-- CORREÇÃO
-- Excluir agrupadores sem eventos

delete from agrupadores_eventos
 where not exists (select first 1
                     from bethadba.eventos
                    where i_agrupadores = agrupadores_eventos.i_agrupadores);

-- FIM DO ARQUIVO FOLHA - Validação - 195.sql

-- FOLHA - Validação: FOLHA - Validação - 196.sql

-- VALIDAÇÃO 196
-- Categoria esocial com tipos divergentes

select i_vinculos,
	     categoria_esocial,
       descricao,
       tipo_vinculo
  from bethadba.vinculos as v
 where categoria_esocial is not null
   and exists (select first 1
                 from bethadba.vinculos as v2
                where v2.categoria_esocial = v.categoria_esocial
                  and v2.tipo_vinculo <> v.tipo_vinculo)
 order by 2 asc;


-- CORREÇÃO
-- Atualizar o tipo de vínculo para que não haja divergência de categoria_esocial

update bethadba.vinculos as v
   set tipo_vinculo = (select tipo_vinculo
                         from bethadba.vinculos as v2
                        where v2.categoria_esocial = v.categoria_esocial
                          and i_vinculos = (select min(v3.i_vinculos)
                                              from bethadba.vinculos as v3
                                             where v3.categoria_esocial = v.categoria_esocial))
 where categoria_esocial is not null
   and i_vinculos > (select min(v4.i_vinculos)
                       from bethadba.vinculos as v4
                      where v4.categoria_esocial = v.categoria_esocial);

-- FIM DO ARQUIVO FOLHA - Validação - 196.sql

-- FOLHA - Validação: FOLHA - Validação - 197.sql

-- VALIDAÇÃO 197
-- Lacuna entre períodos aquisitivos de férias

select periodos.i_entidades as Entidade, 
       periodos.i_funcionarios as Funcionario, 
       periodos.i_periodos as Periodo, 
       periodos.dt_aquis_ini as DataInicioPeriodo, 
       periodos.dt_aquis_fin as DataFimPeriodo,
       if datacancelado is not null then datacancelado else periodos.dt_aquis_fin endif as DataFimPeriodoCloud,
       (select dt_periodo
          from bethadba.periodos_ferias pf
         where pf.i_entidades = periodos.i_entidades
           and pf.i_funcionarios = periodos.i_funcionarios
           and pf.i_periodos = periodos.i_periodos
           and pf.tipo = 5) as DataCancelado
  from bethadba.periodos,
       bethadba.funcionarios
 where periodos.i_entidades = funcionarios.i_entidades
   and periodos.i_funcionarios = funcionarios.i_funcionarios
   and not exists (select 1
   					         from bethadba.rescisoes
                    where rescisoes.i_entidades = funcionarios.i_entidades
                      and rescisoes.i_funcionarios = funcionarios.i_funcionarios)
   and exists(select 1
                from bethadba.periodos p
               where p.i_entidades = funcionarios.i_entidades
                 and p.i_funcionarios = funcionarios.i_funcionarios
                 and p.dt_aquis_fin < periodos.dt_aquis_ini)
   and not exists(select p1.i_entidades,
                         p1.i_funcionarios,
                         p1.i_periodos,
                         p1.dt_aquis_ini as DataInicioPeriodo2,
                         if datacancelado1 is not null then datacancelado1 else p1.dt_aquis_fin endif as DataFimPeriodo2,
                         (select dt_periodo
                            from bethadba.periodos_ferias pf
                           where pf.i_entidades = p1.i_entidades
                             and pf.i_funcionarios = p1.i_funcionarios
                             and pf.i_periodos = p1.i_periodos
                             and pf.tipo = 5) as datacancelado1
		                from bethadba.periodos p1,
		                     bethadba.funcionarios f1
		               where p1.i_entidades = f1.i_entidades
                     and p1.i_funcionarios = f1.i_funcionarios
			               and p1.i_entidades = periodos.i_entidades
            			   and p1.i_funcionarios = periodos.i_funcionarios
                     and datafimperiodo2 = dateadd(day, -1, periodos.dt_aquis_ini))
 order by periodos.i_entidades, periodos.i_funcionarios, periodos.i_periodos;


-- CORREÇÃO
-- Atualizar a data de fim do período aquisitivo de férias para o dia anterior ao início do próximo período aquisitivo de férias

update bethadba.periodos per
   set per.dt_aquis_fin = dateadd(day, -1, p.dt_aquis_ini)
  from bethadba.periodos p
 where per.i_entidades = p.i_entidades
   and per.i_funcionarios = p.i_funcionarios
   and p.dt_aquis_ini > per.dt_aquis_ini
   and not exists (select 1
                     from bethadba.periodos p2
                    where p2.i_entidades = p.i_entidades
                      and p2.i_funcionarios = p.i_funcionarios
                      and p2.dt_aquis_ini > p.dt_aquis_ini
                      and p2.dt_aquis_ini < p.dt_aquis_ini)
   and not exists (select 1
                     from bethadba.rescisoes r
                    where r.i_entidades = per.i_entidades
                      and r.i_funcionarios = per.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 197.sql

-- FOLHA - Validação: FOLHA - Validação - 198.sql

-- VALIDAÇÃO 198
-- Há níveis salariais não presente nos historicos de cargos

select distinct funcionarios.i_entidades as chave_dsk1,
       funcionarios.i_funcionarios as chave_dsk2,
	     dataAlteracao = tabAlt.dataAlteracao,
	     hs.i_niveis,
	     hc.i_cargos
  from bethadba.funcionarios,
       bethadba.hist_cargos as hc,
       bethadba.concursos,
       bethadba.hist_funcionarios as hf,
       bethadba.hist_salariais as hs,
       bethadba.niveis,
       bethadba.planos_salariais,
       bethadba.pessoas,
       bethadba.pessoas_fisicas,
       bethadba.cargos,
       bethadba.tipos_cargos,
       bethadba.cargos_compl,
       bethadba.vinculos,
       (select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
	             dataAlteracao = hf.dt_alteracoes,
    	         origemHistorico = 'FUNCIONARIO'
          from bethadba.funcionarios as f,
               bethadba.hist_funcionarios as hf
         where f.i_entidades = hf.i_entidades
           and f.i_funcionarios = hf.i_funcionarios
           and hf.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos as afast
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                           from bethadba.tipos_afast 
                                                                          where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                            and tipos_afast.classif = 9)), date('2999-12-31'))
                        
		   union
         
        select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hc.dt_alteracoes,
               origemHistorico = 'CARGO'
          from bethadba.funcionarios as f,
               bethadba.hist_cargos as hc
         where f.i_entidades = hc.i_entidades
           and f.i_funcionarios = hc.i_funcionarios
           and hc.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos as afast	
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                           from bethadba.tipos_afast 
                                                                          where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                            and tipos_afast.classif = 9)), date('2999-12-31'))
           and not exists (select distinct 1
                             from bethadba.hist_funcionarios as hf
                            where hf.i_entidades = hc.i_entidades
                              and hf.i_funcionarios = hc.i_funcionarios
                              and hf.dt_alteracoes = hc.dt_alteracoes)
                              
		   union
		 
        select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hs.dt_alteracoes,
               origemHistorico = 'SALARIO' 
          from bethadba.funcionarios as f, 
               bethadba.hist_salariais as hs
         where f.i_entidades = hs.i_entidades
           and f.i_funcionarios = hs.i_funcionarios
           and hs.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos as afast
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                           from bethadba.tipos_afast 
                                                                          where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                                                            and tipos_afast.classif = 9)),date('2999-12-31'))
           and not exists (select distinct 1
         				             from bethadba.hist_funcionarios as hf 
                            where hf.i_entidades = hs.i_entidades
                              and hf.i_funcionarios = hs.i_funcionarios
                              and hf.dt_alteracoes = hs.dt_alteracoes)
           and not exists (select distinct 1
           					         from bethadba.hist_cargos as hc
                            where hs.i_entidades = hc.i_entidades
                              and hs.i_funcionarios = hc.i_funcionarios
                              and hs.dt_alteracoes = hc.dt_alteracoes)
         order by dataAlteracao) as tabAlt
 where funcionarios.i_entidades = tabAlt.entidade
   and funcionarios.i_funcionarios = tabAlt.funcionario
   and hc.i_entidades = concursos.i_entidades
   and hc.i_concursos = concursos.i_concursos
   and niveis.i_entidades = hs.i_entidades
   and niveis.i_niveis = hs.i_niveis
   and pessoas.i_pessoas = pessoas_fisicas.i_pessoas
   and planos_salariais.i_planos_salariais = niveis.i_planos_salariais
   and tipos_cargos.i_tipos_cargos = cargos.i_tipos_cargos
   and cargos.i_cargos = hc.i_cargos
   and cargos.i_entidades = hc.i_entidades
   and funcionarios.i_funcionarios = hf.i_funcionarios
   and funcionarios.i_entidades = hf.i_entidades
   and pessoas.i_pessoas = funcionarios.i_pessoas
   and hf.i_funcionarios = hc.i_funcionarios
   and hf.i_entidades = hc.i_entidades
   and hs.i_funcionarios = hc.i_funcionarios
   and hs.i_entidades = hc.i_entidades
   and hs.dt_alteracoes = bethadba.dbf_GetDataHisSal(hs.i_entidades, hs.i_funcionarios, dataAlteracao)
   and hf.dt_alteracoes = bethadba.dbf_GetDataHisFun(hf.i_entidades, hf.i_funcionarios, dataAlteracao)
   and hc.dt_alteracoes = bethadba.dbf_GetDataHisCar(hc.i_entidades, hc.i_funcionarios, dataAlteracao)
   and hf.i_vinculos = vinculos.i_vinculos
   and cargos_compl.i_entidades = cargos.i_entidades
   and cargos_compl.i_cargos = cargos.i_cargos
   and funcionarios.tipo_func = 'F'
   and vinculos.categoria_esocial <> 901
   and hs.i_niveis is not null
   and exists (select first 1
   			 	       from bethadba.hist_cargos_compl as hcc
   			 	      where hcc.i_entidades = chave_dsk1
   			 	        and hcc.i_cargos = hc.i_cargos
                  and date(dataAlteracao) between date(hcc.dt_alteracoes)
                  and isnull(hcc.dt_final,'2999-12-31'))
   and not exists (select first 1
   					         from bethadba.hist_cargos_compl as hcc
   					        where hcc.i_entidades = chave_dsk1
   					          and hcc.i_cargos = hc.i_cargos
   					          and hcc.i_niveis = hs.i_niveis
                      and date(dataAlteracao) between date(hcc.dt_alteracoes)
        			        and isnull(hcc.dt_final,'2999-12-31'));


-- CORREÇÃO
-- Cria tabela temporária para ajustar os dados
if exists (select 1 from sys.systable where table_name = 'ajusta_198_1') then 
	drop table ajusta_198_1;
end if;

create table   ajusta_198_1(
	i_entidades integer,
	i_funcionarios integer ,        
	dataAlteracao timestamp,
	i_niveis integer,
	i_cargos integer);

insert into ajusta_198_1
select distinct funcionarios.i_entidades as chave_dsk1,
		        funcionarios.i_funcionarios as chave_dsk2,        
		        dataAlteracao = tabAlt.dataAlteracao,
		        hs.i_niveis,
		        hc.i_cargos
  from bethadba.funcionarios,
       bethadba.hist_cargos hc
  left outer join bethadba.concursos
    on (hc.i_entidades = concursos.i_entidades
   and hc.i_concursos = concursos.i_concursos),
       bethadba.hist_funcionarios hf, 
       bethadba.hist_salariais hs
  left outer join bethadba.niveis
    on niveis.i_entidades = hs.i_entidades
   and niveis.i_niveis = hs.i_niveis
  left outer join bethadba.planos_salariais
    on planos_salariais.i_planos_salariais = niveis.i_planos_salariais,
       (select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hf.dt_alteracoes,
               origemHistorico = 'FUNCIONARIO'
          from bethadba.funcionarios f 
          join bethadba.hist_funcionarios hf
            on (f.i_entidades = hf.i_entidades
           and f.i_funcionarios = hf.i_funcionarios
           and hf.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos afast
                                             where afast.i_entidades = f.i_entidades
                                               and afast.i_funcionarios = f.i_funcionarios
                                               and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                             								from bethadba.tipos_afast 
                                             							   where tipos_afast.i_tipos_afast = afast.i_tipos_afast
                                             							     and tipos_afast.classif = 9)), date('2999-12-31'))) 
       union
        select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hc.dt_alteracoes ,
               origemHistorico = 'CARGO'
          from bethadba.funcionarios f 
          join bethadba.hist_cargos hc
            on (f.i_entidades = hc.i_entidades
           and f.i_funcionarios = hc.i_funcionarios
           and hc.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                             from bethadba.afastamentos afast
                                            where afast.i_entidades = f.i_entidades
                                              and afast.i_funcionarios = f.i_funcionarios
                                              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
							                                               from bethadba.tipos_afast 
							                                              where tipos_afast.i_tipos_afast = afast.i_tipos_afast
							                                                and tipos_afast.classif = 9)), date('2999-12-31')))  
         where not exists(select distinct 1
         					from bethadba.hist_funcionarios hf 
                           where hf.i_entidades = hc.i_entidades
                             and hf.i_funcionarios= hc.i_funcionarios
                             and hf.dt_alteracoes = hc.dt_alteracoes)
       union 
        select entidade = f.i_entidades,
               funcionario = f.i_funcionarios,
               dataAlteracao = hs.dt_alteracoes,
               origemHistorico = 'SALARIO' 
          from bethadba.funcionarios f 
          join bethadba.hist_salariais hs
            on (f.i_entidades = hs.i_entidades
           and f.i_funcionarios = hs.i_funcionarios
           and hs.dt_alteracoes <= isnull((select first afast.dt_afastamento
								             from bethadba.afastamentos afast
								            where afast.i_entidades = f.i_entidades
								              and afast.i_funcionarios = f.i_funcionarios
								              and afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
																           from bethadba.tipos_afast 
																          where tipos_afast.i_tipos_afast = afast.i_tipos_afast
																            and tipos_afast.classif = 9)), date('2999-12-31')))
         where not exists(select distinct 1
         					from bethadba.hist_funcionarios hf 
                           where hf.i_entidades = hs.i_entidades
                             and hf.i_funcionarios= hs.i_funcionarios
                             and hf.dt_alteracoes = hs.dt_alteracoes) 
                             and not exists(select distinct 1
                             				  from bethadba.hist_cargos hc 
                           					 where hs.i_entidades = hc.i_entidades
                           					   and hs.i_funcionarios = hc.i_funcionarios
                           					   and hs.dt_alteracoes = hc.dt_alteracoes)
       order by dataAlteracao) as tabAlt,
       bethadba.pessoas
  left outer join bethadba.pessoas_fisicas
    on (pessoas.i_pessoas = pessoas_fisicas.i_pessoas),
       bethadba.cargos,
       bethadba.tipos_cargos,
       bethadba.cargos_compl,
       bethadba.vinculos
 where funcionarios.i_entidades = tabAlt.entidade
   and funcionarios.i_funcionarios = tabAlt.funcionario
   and tipos_cargos.i_tipos_cargos = cargos.i_tipos_cargos
   and cargos.i_cargos = hc.i_cargos
   and cargos.i_entidades = hc.i_entidades
   and funcionarios.i_funcionarios = hf.i_funcionarios
   and funcionarios.i_entidades = hf.i_entidades
   and pessoas.i_pessoas = funcionarios.i_pessoas
   and hf.i_funcionarios = hc.i_funcionarios
   and hf.i_entidades = hc.i_entidades
   and hs.i_funcionarios = hc.i_funcionarios
   and hs.i_entidades = hc.i_entidades
   and hs.dt_alteracoes = bethadba.dbf_GetDataHisSal(hs.i_entidades, hs.i_funcionarios, dataAlteracao)
   and hf.dt_alteracoes = bethadba.dbf_GetDataHisFun(hf.i_entidades, hf.i_funcionarios, dataAlteracao)
   and hc.dt_alteracoes = bethadba.dbf_GetDataHisCar(hc.i_entidades, hc.i_funcionarios, dataAlteracao)
   and hf.i_vinculos = vinculos.i_vinculos
   and cargos_compl.i_entidades = cargos.i_entidades
   and cargos_compl.i_cargos = cargos.i_cargos
   and funcionarios.tipo_func = 'F'
   and vinculos.categoria_esocial <> 901
   and hs.i_niveis is not NULL
   and exists (select first 1
   				 from bethadba.hist_cargos_compl hcc
   				where hcc.i_entidades = chave_dsk1
   				  and hcc.i_cargos = hc.i_cargos
                  and date(dataAlteracao) between date(hcc.dt_alteracoes)
                  and isnull(hcc.dt_final,'2999-12-31'))
   and not exists (select first 1
   					 from bethadba.hist_cargos_compl hcc
   					where hcc.i_entidades = chave_dsk1
   					  and hcc.i_cargos = hc.i_cargos
   					  and hcc.i_niveis = hs.i_niveis
                      and date(dataAlteracao) between date(hcc.dt_alteracoes)
					  and isnull(hcc.dt_final,'2999-12-31'));

commit;

delete ajusta_198_1 
 where dataAlteracao <> (select min(a.dataAlteracao)
 						   from ajusta_198_1 as a
 						  where a.i_entidades = ajusta_198_1.i_entidades
 						    and a.i_cargos = ajusta_198_1.i_cargos 
   							and a.i_niveis = ajusta_198_1.i_niveis);

update bethadba.hist_cargos_compl as h,
	   ajusta_198_1
   set h.dt_alteracoes = ajusta_198_1.dataAlteracao 
 where h.dt_alteracoes = (select min(i.dt_alteracoes)
 							from bethadba.hist_cargos_compl as i
 						   where i.i_entidades = h.i_entidades 
							 and i.i_cargos = h.i_cargos
							 and i.i_niveis = h.i_niveis)
   and ajusta_198_1.i_entidades = h.i_entidades 
   and ajusta_198_1.i_cargos = h.i_cargos
   and ajusta_198_1.i_niveis = h.i_niveis
   and h.dt_alteracoes > dataAlteracao;

update bethadba.hist_niveis as h,
	   ajusta_198_1 
   set h.dt_alteracoes = ajusta_198_1.dataAlteracao 
 where h.dt_alteracoes = (select min(i.dt_alteracoes)
 							from bethadba.hist_niveis as i
 						   where i.i_entidades = h.i_entidades
 						     and i.i_niveis = h.i_niveis)
   and ajusta_198_1.i_entidades = h.i_entidades
   and ajusta_198_1.i_niveis = h.i_niveis
   and h.dt_alteracoes > ajusta_198_1.dataAlteracao;

update bethadba.hist_clas_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)
   						  from bethadba.hist_niveis as a
   						 where hist_clas_niveis.i_entidades = a.i_entidades
   						   and hist_clas_niveis.i_niveis = a.i_niveis) 
 where dt_alteracoes = (select min(a.dt_alteracoes)
 						  from bethadba.hist_clas_niveis as a
 						 where hist_clas_niveis.i_entidades = a.i_entidades
 						   and hist_clas_niveis.i_niveis = a.i_niveis)
   and (select min(a.dt_alteracoes)
		  from bethadba.hist_niveis as a
		 where hist_clas_niveis.i_entidades = a.i_entidades
		   and hist_clas_niveis.i_niveis = a.i_niveis) <> dt_alteracoes;

commit;
 

if exists (select 1 from sys.systable where table_name = 'hist_cargos_compl_aux') then 
	drop table hist_cargos_compl_aux;
else
	create table hist_cargos_compl_aux(
		i_entidades integer,
		i_cargos integer,
		dataAlteracao timestamp,
		i_niveis integer);
end if;


insert into hist_cargos_compl_aux
select distinct i_entidades,
				i_cargos,
				dataAlteracao,
				i_niveis
  from ajusta_198_1
 where dataAlteracao = (select min(a.dataAlteracao)
 						  from ajusta_198_1 as a
 						 where a.i_entidades = ajusta_198_1.i_entidades
 						   and a.i_cargos = ajusta_198_1.i_cargos 
   						   and a.i_niveis = ajusta_198_1.i_niveis)
   and not exists (select 1
					 from bethadba.hist_cargos_compl as i
					where i.i_entidades = ajusta_198_1.i_entidades
					  and i.i_cargos = ajusta_198_1.i_cargos
					  and i.i_niveis =ajusta_198_1.i_niveis);

alter table hist_cargos_compl_aux add (seq integer);

update hist_cargos_compl_aux
   set seq = number(*);

update hist_cargos_compl_aux
   set dataAlteracao = replace(dataAlteracao, '.000000', '.00000'||seq)
 where length(seq) = 1;

update hist_cargos_compl_aux
   set dataAlteracao = replace(dataAlteracao, '.000000', '.0000'||seq)
 where length(seq) = 2;

update hist_cargos_compl_aux
   set dataAlteracao = replace(dataAlteracao, '.000000', '.000'||seq)
 where length(seq) = 3;

update hist_cargos_compl_aux
   set dataAlteracao = replace(dataAlteracao, '.000000', '.00'||seq)
 where length(seq) = 4;

insert into bethadba.hist_cargos_compl(i_entidades,i_cargos,dt_alteracoes,i_niveis)  
select i_entidades,
	   i_cargos,
	   dataAlteracao,
	   i_niveis
  from hist_cargos_compl_aux as hcca
 where dataAlteracao = (select min(a.dataAlteracao)
 						  from hist_cargos_compl_aux as a
 						 where a.i_entidades = hcca.i_entidades
 						   and a.i_cargos = hcca.i_cargos
 						   and a.i_niveis = hcca.i_niveis)
   and not exists (select 1
   					 from bethadba.hist_cargos_compl as i
 					where i.i_entidades = hcca.i_entidades 
 					  and i.i_cargos = hcca.i_cargos 
 					  and i.i_niveis =hcca.i_niveis);

update bethadba.hist_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes) - 1
   						  from bethadba.hist_cargos_compl as a
   						 where a.i_entidades = hist_niveis.i_entidades
        				   and a.i_niveis = hist_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
 						  from bethadba.hist_niveis as c 
						 where c.i_entidades = hist_niveis.i_entidades
						   and c.i_niveis = hist_niveis.i_niveis)
   and (select min(a.dt_alteracoes)+1 from   bethadba.hist_cargos_compl as a where a.i_entidades =hist_niveis.i_entidades
        and  a.i_niveis =hist_niveis.i_niveis) < hist_niveis.dt_alteracoes;

update  bethadba.hist_clas_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)
 						  from bethadba.hist_niveis as a
 					     where a.i_entidades = hist_clas_niveis.i_entidades
                           and a.i_niveis =hist_clas_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
 						  from bethadba.hist_clas_niveis as c 
						 where c.i_entidades = hist_clas_niveis.i_entidades
						   and c.i_niveis = hist_clas_niveis.i_niveis)
   and (select min(a.dt_alteracoes)
   		  from bethadba.hist_niveis as a
   		 where a.i_entidades = hist_clas_niveis.i_entidades
           and a.i_niveis = hist_clas_niveis.i_niveis) < hist_clas_niveis.dt_alteracoes;

commit;

update bethadba.hist_clas_niveis
   set dt_alteracoes = (select min(b.dt_alteracoes)
						  from bethadba.hist_niveis as b    
       					 where b.i_entidades = hist_clas_niveis.i_entidades 
       					   and b.i_niveis = hist_clas_niveis.i_niveis)
 where dt_alteracoes = (select min(a.dt_alteracoes)
 						  from bethadba.hist_clas_niveis as a 
                         where a.i_entidades = hist_clas_niveis.i_entidades 
                           and a.i_niveis = hist_clas_niveis.i_niveis
                           and a.i_clas_niveis = hist_clas_niveis.i_clas_niveis
                           and a.i_referencias = hist_clas_niveis.i_referencias )
   and dt_alteracoes <> (select min(b.dt_alteracoes)
   						   from bethadba.hist_niveis as b    
       					  where b.i_entidades = hist_clas_niveis.i_entidades 
       						and b.i_niveis = hist_clas_niveis.i_niveis);

commit;

update bethadba.hist_cargos_compl 
   set dt_final = null
 where dt_final is not null
   and exists (select 1
   				 from bethadba.hist_salariais as a
   				where a.i_entidades = hist_cargos_compl.i_entidades 
				  and a.i_niveis = hist_cargos_compl.i_niveis
				  and dt_final < a.dt_alteracoes);

commit;

-- FIM DO ARQUIVO FOLHA - Validação - 198.sql

-- FOLHA - Validação: FOLHA - Validação - 199.sql

-- VALIDAÇÃO 199
-- há niveis salarias usados fora da vigência do cargo

select hs.i_entidades,
  min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
  hs.i_niveis as nivel_salario,
  hc.i_cargos,
  hcc.dt_alteracoes as dt_alteracao_cargo,
  hcc.i_niveis as nivel_cargo
  from bethadba.hist_salariais hs
  join bethadba.hist_cargos hc 
    on hs.i_funcionarios = hc.i_funcionarios 
   and hs.i_entidades = hc.i_entidades
  join bethadba.hist_cargos_compl hcc 
    on hc.i_cargos = hcc.i_cargos 
   and hc.i_entidades = hcc.i_entidades
 where hs.i_niveis is not null
   and hs.dt_alteracoes < hcc.dt_alteracoes
   and hs.i_niveis = hcc.i_niveis
 group by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis
 order by hs.i_entidades, hc.i_cargos,  hs.i_niveis;


-- CORREÇÃO
-- Cria tabela temporária para armazenar os ajustes
if exists (select 1 from sys.systable where table_name = 'cnv_ajuste_199') then 
	drop table cnv_ajuste_199
end if;

create table cnv_ajuste_199(
	i_entidades integer,
	menor_dt_alteracao_salario timestamp,
	nivel_salario integer,
	i_cargos integer,
	dt_alteracao_cargo timestamp,
	nivel_cargo integer);

insert into cnv_ajuste_199
select hs.i_entidades,
       min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
       hs.i_niveis as nivel_salario,
       hc.i_cargos,
       min(hcc.dt_alteracoes) as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo
  from bethadba.hist_salariais hs
  join bethadba.hist_cargos hc 
    on hs.i_funcionarios = hc.i_funcionarios 
   and hs.i_entidades = hc.i_entidades
  join bethadba.hist_cargos_compl hcc 
    on hc.i_cargos = hcc.i_cargos 
   and hc.i_entidades = hcc.i_entidades
 where hs.i_niveis is not null
   and hs.dt_alteracoes < (select min(hcc2.dt_alteracoes) 
                             from bethadba.hist_cargos_compl hcc2
                            where hcc2.i_entidades = hcc.i_entidades
                              and hcc2.i_niveis = hcc.i_niveis)
   and hs.i_niveis = hcc.i_niveis
 group by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.i_niveis
 order by hs.i_entidades, hc.i_cargos, hs.i_niveis;

commit;

update bethadba.hist_salariais,
	   cnv_ajuste_199 
   set hist_salariais.dt_alteracoes = dt_alteracao_cargo
 where convert(date, menor_dt_alteracao_salario) = convert(date, dt_alteracao_cargo)
   and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
   and hist_salariais.i_niveis = nivel_salario;

delete cnv_ajuste_199;

insert into cnv_ajuste_199
select hs.i_entidades,
       min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
       hs.i_niveis as nivel_salario,
       hc.i_cargos,
       min(hcc.dt_alteracoes) as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo
  from bethadba.hist_salariais hs
  join bethadba.hist_cargos hc 
    on hs.i_funcionarios = hc.i_funcionarios 
   and hs.i_entidades = hc.i_entidades
  join bethadba.hist_cargos_compl hcc 
    on hc.i_cargos = hcc.i_cargos 
   and hc.i_entidades = hcc.i_entidades
 where hs.i_niveis is not null
   and hs.dt_alteracoes < (select min(hcc2.dt_alteracoes) 
                             from bethadba.hist_cargos_compl hcc2
                            where hcc2.i_entidades = hcc.i_entidades
                              and hcc2.i_niveis = hcc.i_niveis)
   and hs.i_niveis = hcc.i_niveis
 group by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.i_niveis
 order by hs.i_entidades, hc.i_cargos, hs.i_niveis;
 
commit;

update cnv_ajuste_199,
	   bethadba.hist_cargos_compl as hcc
   set hcc.dt_alteracoes = menor_dt_alteracao_salario 
 where convert(date, menor_dt_alteracao_salario) < convert(date, dt_alteracao_cargo)
   and hcc.i_entidades = cnv_ajuste_199.i_entidades
   and hcc.i_cargos = cnv_ajuste_199.i_cargos
   and hcc.i_niveis = cnv_ajuste_199.nivel_cargo
   and hcc.dt_alteracoes = (select min(a.dt_alteracoes)
											from bethadba.hist_cargos_compl as a
										   where a.i_entidades = hcc.i_entidades
											 and a.i_cargos = hcc.i_cargos
											 and a.i_niveis = hcc.i_niveis);

commit;

update bethadba.hist_salariais,
	   cnv_ajuste_199 
   set hist_salariais.dt_alteracoes = dt_alteracao_cargo
 where convert(date, menor_dt_alteracao_salario ) = convert(date, dt_alteracao_cargo)
   and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
   and hist_salariais.i_niveis = nivel_salario;

alter table cnv_ajuste_199 add (nv_menor_dt_alteracao_salario timestamp);

update cnv_ajuste_199
   set nv_menor_dt_alteracao_salario = menor_dt_alteracao_salario - number(*);

insert into bethadba.hist_cargos_compl on existing skip
select a.i_entidades,
	   a.i_cargos,
	   nv_menor_dt_alteracao_salario,
	   a.i_niveis,
	   a.i_clas_niveis_ini,
	   a.i_referencias_ini,
	   a.i_clas_niveis_fin,
	   a.i_referencias_fin,
	   a.i_atos,
	   null 
  from bethadba.hist_cargos_compl as a,
  	   cnv_ajuste_199 as b
 where a.i_cargos = b.i_cargos 
   and a.i_entidades = b.i_entidades
   and a.i_niveis = b.nivel_salario
   and not exists (select 1
   					 from bethadba.hist_cargos_compl as c
   					where c.i_cargos = b.i_cargos 
   and c.i_entidades = b.i_entidades
   and c.i_niveis = b.nivel_salario
   and c.dt_alteracoes = menor_dt_alteracao_salario);

commit;
 
update bethadba.hist_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes) -1
						  from bethadba.hist_cargos_compl as a
						 where a.i_entidades = hist_niveis.i_entidades
						   and a.i_niveis = hist_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
 						  from bethadba.hist_niveis as c 
						 where c.i_entidades = hist_niveis.i_entidades
						   and c.i_niveis = hist_niveis.i_niveis)
   and (select min(a.dt_alteracoes) + 1
   		  from bethadba.hist_cargos_compl as a
   		 where a.i_entidades = hist_niveis.i_entidades
           and a.i_niveis = hist_niveis.i_niveis) < hist_niveis.dt_alteracoes;

update bethadba.hist_clas_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)
  						  from bethadba.hist_niveis as a
  						 where a.i_entidades = hist_clas_niveis.i_entidades
                       	   and a.i_niveis = hist_clas_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
 						  from bethadba.hist_clas_niveis as c 
						 where c.i_entidades = hist_clas_niveis.i_entidades
						   and c.i_niveis = hist_clas_niveis.i_niveis)
   and (select min(a.dt_alteracoes)
   		  from bethadba.hist_niveis as a
   		 where a.i_entidades = hist_clas_niveis.i_entidades
           and a.i_niveis = hist_clas_niveis.i_niveis) < hist_clas_niveis.dt_alteracoes;

commit;

-- OBS: COMO A VALIDAÇÃO 199 INSERE INFORMAÇÕES NA bethadba.hist_cargos_compl, FAZ-SE NECESSÁRIO APÓS RODAR ELA EFETUAR AS DUAS VALIDAÇÕES ATERIORES E SE RETORNAR 
-- INFORMAÇÕES NAS VALIDAÇÕES 189 E 198, RODAR NOVAMENTE E QUANTAS VEZES FOR NECESSÁRIO ESTES COMANDOS DE AJUSTE

-- FIM DO ARQUIVO FOLHA - Validação - 199.sql

-- FOLHA - Validação: FOLHA - Validação - 2.sql

-- VALIDAÇÃO 02
-- Busca as pessoas com data de nascimento maior que data de admissão

select i_funcionarios,
       i_entidades,
       f.dt_admissao, f.dt_admissao as admissao,
       pf.dt_nascimento, pf.dt_nascimento as datanascimento,
       pf.i_pessoas,
       pf.i_pessoas as pessoas,
       p.nome
  from bethadba.funcionarios f
 inner join bethadba.pessoas_fisicas pf
    on (f.i_pessoas = pf.i_pessoas)
 inner join bethadba.pessoas p
    on (f.i_pessoas = p.i_pessoas)
 where pf.dt_nascimento > f.dt_admissao;


-- CORREÇÃO
-- Atualiza a data de nascimento das pessoas para ser igual à data de admissão se a data de nascimento for maior que a data de admissão

update bethadba.pessoas_fisicas
   set PF.dt_nascimento = F.dt_admissao
  from bethadba.funcionarios as F
  left join bethadba.pessoas_fisicas as PF
    on PF.i_pessoas = F.i_pessoas
 where PF.dt_nascimento > F.dt_admissao;

-- FIM DO ARQUIVO FOLHA - Validação - 2.sql

-- FOLHA - Validação: FOLHA - Validação - 20.sql

-- VALIDAÇÃO 20
-- Renomeia os vinculos empregaticios repetidos

select list(i_vinculos) as vinculos, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.vinculos 
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os vinculos empregaticios repetidos para evitar duplicidade, adicionando o i_vinculos ao nome do vinculo

update bethadba.vinculos
   set vinculos.descricao = vinculos.i_vinculos || vinculos.descricao
 where i_vinculos in (2, 12);

-- FIM DO ARQUIVO FOLHA - Validação - 20.sql

-- FOLHA - Validação: FOLHA - Validação - 21.sql

-- VALIDAÇÃO 21
-- Verifica categoria eSocial nulo no motivo de rescisão

select i_motivos_resc,
       descricao,
       categoria_esocial
  from bethadba.motivos_resc
 where categoria_esocial is null
   and dispensados not in (3);


-- CORREÇÃO
-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: '01') para evitar problemas de integridade referencial

update bethadba.motivos_resc set categoria_esocial = '01' where i_motivos_resc = 1;
update bethadba.motivos_resc set categoria_esocial = '02' where i_motivos_resc = 2;
update bethadba.motivos_resc set categoria_esocial = '04' where i_motivos_resc = 3;
update bethadba.motivos_resc set categoria_esocial = '07' where i_motivos_resc = 4;
update bethadba.motivos_resc set categoria_esocial = '12' where i_motivos_resc = 6;
update bethadba.motivos_resc set categoria_esocial = '10' where i_motivos_resc = 8;
update bethadba.motivos_resc set categoria_esocial = '24' where i_motivos_resc = 9;
update bethadba.motivos_resc set categoria_esocial = '03' where i_motivos_resc = 10;
update bethadba.motivos_resc set categoria_esocial = '04' where i_motivos_resc = 11;
update bethadba.motivos_resc set categoria_esocial = '06' where i_motivos_resc = 12;
update bethadba.motivos_resc set categoria_esocial = '10' where i_motivos_resc = 13;
update bethadba.motivos_resc set categoria_esocial = '10' where i_motivos_resc = 14;
update bethadba.motivos_resc set categoria_esocial = '06' where i_motivos_resc = 15;
update bethadba.motivos_resc set categoria_esocial = '40' where i_motivos_resc = 16;
update bethadba.motivos_resc set categoria_esocial = '40' where i_motivos_resc = 17;

-- FIM DO ARQUIVO FOLHA - Validação - 21.sql

-- FOLHA - Validação: FOLHA - Validação - 22.sql

-- VALIDAÇÃO 22 
-- Verifica as folha que não foram fechadas conforme competência passada por parâmetro

select i_entidades,
       i_competencias
  from bethadba.processamentos 
 where dt_fechamento is null;


-- CORREÇÃO
-- Atualiza a data de fechamento das folhas que não foram fechadas, adicionando a data de fechamento como o último dia do mês da competência

for a1 as a2 cursor for
    select xxi_ent = i_entidades,
           xxi_compe = i_competencias,
           i_competencias,
           linha = row_number() over (order by xxi_ent),
           xxdt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
      from bethadba.processamentos
     where dt_fechamento is null
       and i_competencias < '2999-12-01'
do
    update bethadba.processamentos
       set dt_fechamento = xxdt_fechamento
     where i_competencias = xxi_compe
       and i_entidades = xxi_ent;
    
    message 'Data de fechamento adicionada: ' || xxdt_fechamento || ', na competencia: ' || i_competencias || '. Linha: ' ||linha to client; 
end for;

-- FIM DO ARQUIVO FOLHA - Validação - 22.sql

-- FOLHA - Validação: FOLHA - Validação - 23.sql

-- VALIDAÇÃO 23
-- Verifica as folhas de ferias sem data de pagamento

select bethadba.dbf_getdatapagamentoferias(ferias.i_entidades,ferias.i_funcionarios,ferias.i_periodos,ferias.i_ferias) as dataPagamento,
       i_entidades,
       i_ferias,
       i_funcionarios,
       i_periodos
  from bethadba.ferias
 where dataPagamento is null;


-- CORREÇÃO 1
-- Atualiza as folhas de férias sem data de pagamento, definindo a data de pagamento como o último dia do mês da competência

insert into bethadba.ferias_proc
select i_entidades,
  	   i_funcionarios,
 	   i_ferias,
  	   80,
       date(year(dt_gozo_ini) || '-' || month(dt_gozo_ini) || '-01') as competencia, 
	   1,
       1
  from bethadba.ferias
 where not exists(select 1
  		            from bethadba.ferias_proc
           	       where ferias_proc.i_entidades = ferias.i_entidades
               		 and ferias_proc.i_funcionarios = ferias.i_funcionarios
                     and ferias_proc.i_ferias = ferias.i_ferias);

-- CORREÇÃO 2
-- Atualiza as folhas de férias sem data de pagamento, definindo a data de pagamento como o último dia do mês da competência

begin
	declare w_i_entidades integer;
    declare w_competencias timestamp;
	
	llloop: for ll as meuloop1 dynamic scroll cursor for
        select i_entidades,
               i_funcionarios,
               i_ferias,
               80,
               date(year(dt_gozo_ini) || '-' || month(dt_gozo_ini) || '-01') as competencia_calculada,
               (select p.i_processamentos
             	  from bethadba.processamentos p
             	 where p.i_tipos_proc = 80
             	   and p.i_competencias = competencia_calculada) as processamentos_consulta
          from bethadba.ferias
         where not exists(select 1
                       		from bethadba.ferias_proc
                       	   where ferias_proc.i_entidades = ferias.i_entidades
                       		 and ferias_proc.i_funcionarios = ferias.i_funcionarios
                       		 and ferias_proc.i_ferias = ferias.i_ferias) 
		   and processamentos_consulta is null
	do
		set w_i_entidades = i_entidades;
		set w_competencias = competencia_calculada;

		insert into bethadba.processamentos (i_entidades,i_tipos_proc,i_competencias,i_processamentos,dt_fechamento,dt_pagto,simulado,dt_liberacao,pagto_realizado) 
		values (w_i_entidades,80,w_competencias,1,w_competencias,w_competencias,'N',w_competencias,'S');
	end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 23.sql

-- FOLHA - Validação: FOLHA - Validação - 24.sql

-- VALIDAÇÃO 24
-- Verifica categoria eSocial nulo no motivo de aposentadoria

select i_motivos_apos,
       descricao,
       categoria_esocial
  from bethadba.motivos_apos
 where categoria_esocial is null;

              
-- CORREÇÃO
-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: '38' para aposentadoria, exceto por invalidez) para evitar problemas de integridade referencial
                
update bethadba.motivos_apos
   set categoria_esocial = '38' //Aposentadoria, exceto por ivalidez
 where i_motivos_apos in (1,2,3,4,8,9);

update bethadba.motivos_apos
   set categoria_esocial = '39' //Aposentadoria por ivalidez
 where i_motivos_apos in (5,6,7);

-- FIM DO ARQUIVO FOLHA - Validação - 24.sql

-- FOLHA - Validação: FOLHA - Validação - 25.sql

-- VALIDAÇÃO 25
-- Verifica históricos salariais com salário zerado ou nulo

select i_entidades, 
       i_funcionarios, 
       dt_alteracoes 
  from bethadba.hist_salariais
 where salario in (0, null);


-- CORREÇÃO
-- Atualiza os históricos salariais com salário zerado ou nulo para um valor mínimo (exemplo: 0.01) para evitar problemas de cálculos futuros

update bethadba.hist_salariais
   set salario = 0.01
 where salario = 0 or salario is null;

-- FIM DO ARQUIVO FOLHA - Validação - 25.sql

-- FOLHA - Validação: FOLHA - Validação - 26.sql

-- VALIDAÇÃO 26
-- Verifica se existe variáveis lançadas com data inicial ou final maior que a data de rescisão

select left(tab.data_afastamento, 8) || '01' as nova_data_final,
	   tab.dt_inicial,
	   tab.data_afastamento,
	   tab.dt_final,
	   *
  from (select a.i_entidades,
  			   a.i_funcionarios,
  			   coalesce(ta.classif, 1) as classif,
  			   max(a.dt_afastamento) as data_afastamento,
  			   f.conselheiro_tutelar,
  			   v.i_eventos,
  			   v.i_processamentos,
  			   v.i_tipos_proc,
  			   v.dt_inicial,
  			   v.dt_final 
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on (ta.i_tipos_afast = a.i_tipos_afast)
          join bethadba.funcionarios f
            on (f.i_entidades = a.i_entidades
           and f.i_funcionarios = a.i_funcionarios)
          left join bethadba.variaveis v
            on (v.i_entidades = a.i_entidades
           and v.i_funcionarios = a.i_funcionarios)
         where ta.classif = 8
           and a.dt_afastamento <= today()
           and isnull(a.dt_ultimo_dia, today()) >= today()
           and v.i_eventos is not null
           and f.conselheiro_tutelar = 'N'
         group by a.i_entidades, a.i_funcionarios, ta.classif, f.conselheiro_tutelar, v.i_eventos, v.i_processamentos, v.i_tipos_proc , v.dt_inicial , v.dt_final 
         order by a.i_entidades, a.i_funcionarios,  v.dt_inicial , v.dt_final ) as tab
 where tab.dt_inicial > tab.data_afastamento
    or tab.dt_final > tab.data_afastamento;


-- CORREÇÃO
-- Deleta as variáveis com data inicial maior que a data de rescisão
begin

delete from bethadba.variaveis
 where exists (select 1
      			     from (select a.i_entidades,
      			 		    	        a.i_funcionarios,
      			 			            max(a.dt_afastamento) as data_afastamento
              			     from bethadba.afastamentos a
              			     join bethadba.tipos_afast ta
                		       on ta.i_tipos_afast = a.i_tipos_afast
             			      where ta.classif = 8
               			      and a.dt_afastamento <= today()
               			      and isnull(a.dt_ultimo_dia, today()) >= today()
             			      group by a.i_entidades, a.i_funcionarios) af
      			     join bethadba.funcionarios f
        		       on f.i_entidades = af.i_entidades
       			      and f.i_funcionarios = af.i_funcionarios
     			      where variaveis.i_entidades = af.i_entidades
       			      and variaveis.i_funcionarios = af.i_funcionarios
       			      and variaveis.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis.dt_inicial > af.data_afastamento);

delete from bethadba.variaveis_ocorrencias_apur
 where exists (select 1
      			     from (select a.i_entidades,
      			 		    	        a.i_funcionarios,
      			 			            max(a.dt_afastamento) as data_afastamento
              			     from bethadba.afastamentos a
              			     join bethadba.tipos_afast ta
                		       on ta.i_tipos_afast = a.i_tipos_afast
             			      where ta.classif = 8
               			      and a.dt_afastamento <= today()
               			      and isnull(a.dt_ultimo_dia, today()) >= today()
             			      group by a.i_entidades, a.i_funcionarios) af
      			     join bethadba.funcionarios f
        		       on f.i_entidades = af.i_entidades
       			      and f.i_funcionarios = af.i_funcionarios
     			      where variaveis_ocorrencias_apur.i_entidades = af.i_entidades
       			      and variaveis_ocorrencias_apur.i_funcionarios = af.i_funcionarios
       			      and variaveis_ocorrencias_apur.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis_ocorrencias_apur.dt_inicial > af.data_afastamento);

end;

-- Atualiza as variáveis com data final maior que a data de rescisão
begin

update bethadba.variaveis
   set dt_final = cast(left(af.data_afastamento, 7) || '-01' as date)
  from (select a.i_entidades,
               a.i_funcionarios,
               max(a.dt_afastamento) as data_afastamento
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on ta.i_tipos_afast = a.i_tipos_afast
         where ta.classif = 8
           and a.dt_afastamento <= today()
           and isnull(a.dt_ultimo_dia, today()) >= today()
         group by a.i_entidades, a.i_funcionarios) af
  join bethadba.funcionarios f
    on f.i_entidades = af.i_entidades
   and f.i_funcionarios = af.i_funcionarios
 where variaveis.i_entidades = af.i_entidades
   and variaveis.i_funcionarios = af.i_funcionarios
   and variaveis.i_eventos is not null
   and f.conselheiro_tutelar = 'N'
   and variaveis.dt_final > af.data_afastamento;

update bethadba.variaveis_ocorrencias_apur
   set dt_final = cast(left(af.data_afastamento, 7) || '-01' as date)
  from (select a.i_entidades,
               a.i_funcionarios,
               max(a.dt_afastamento) as data_afastamento
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on ta.i_tipos_afast = a.i_tipos_afast
         where ta.classif = 8
           and a.dt_afastamento <= today()
           and isnull(a.dt_ultimo_dia, today()) >= today()
         group by a.i_entidades, a.i_funcionarios) af
  join bethadba.funcionarios f
    on f.i_entidades = af.i_entidades
   and f.i_funcionarios = af.i_funcionarios
 where variaveis_ocorrencias_apur.i_entidades = af.i_entidades
   and variaveis_ocorrencias_apur.i_funcionarios = af.i_funcionarios
   and variaveis_ocorrencias_apur.i_eventos is not null
   and f.conselheiro_tutelar = 'N'
   and variaveis_ocorrencias_apur.dt_final > af.data_afastamento;

end;

-- FIM DO ARQUIVO FOLHA - Validação - 26.sql

-- FOLHA - Validação: FOLHA - Validação - 27.sql

-- VALIDAÇÃO 27
-- Busca as movimentações de pessoal repetidos

select list(i_tipos_movpes) as tiposs, 
       descricao,
       count(descricao) as quantidade 
  from bethadba.tipos_movpes 
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza as movimentações de pessoal repetidos para evitar duplicidade, adicionando o i_tipos_movpes ao nome do tipo de movimentação

update bethadba.tipos_movpes
   set tipos_movpes.descricao = tipos_movpes.i_tipos_movpes || '-' || tipos_movpes.descricao 
 where tipos_movpes.i_tipos_movpes in(select i_tipos_movpes
                                        from bethadba.tipos_movpes
                                       where (select count(i_tipos_movpes)
                                                from bethadba.tipos_movpes t
                                               where trim(t.descricao) = trim(tipos_movpes.descricao)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 27.sql

-- FOLHA - Validação: FOLHA - Validação - 28.sql

-- VALIDAÇÃO 28
-- Busca os tipos de afastamentos repetidos

select list(i_tipos_afast) tiposafs, 
       trim(descricao) descricoes,
       count(descricao) as quantidade 
  from bethadba.tipos_afast 
 group by descricoes
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os tipos de afastamentos repetidos para evitar duplicidade, adicionando o i_tipos_afast ao nome do tipo de afastamento

update bethadba.tipos_afast
   set tipos_afast.descricao = tipos_afast.i_tipos_afast || '-' || tipos_afast.descricao
 where tipos_afast.i_tipos_afast in (select i_tipos_afast
                                       from bethadba.tipos_afast
                                      where (select count(i_tipos_afast)
                                               from bethadba.tipos_afast as t
                                              where trim(t.descricao) = trim(tipos_afast.descricao)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 28.sql

-- FOLHA - Validação: FOLHA - Validação - 29.sql

-- VALIDAÇÃO 29
-- Busca as alterações de históricos dos funcionários maior que a data de rescisão

select hs.i_funcionarios,
       hs.i_entidades,
       date(hs.dt_alteracoes) dt_alt,
       r.dt_rescisao dt_resc,
       date(STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8))) as dt_alteracoes_novo
  from bethadba.hist_funcionarios hs
 inner join bethadba.rescisoes r on (hs.i_funcionarios = r.i_funcionarios and hs.i_entidades = r.i_entidades)
 where hs.dt_alteracoes > STRING((select max(s.dt_rescisao) 
                                    from bethadba.rescisoes s 
                                    join bethadba.motivos_resc mr on(s.i_motivos_resc = mr.i_motivos_resc)
                                   where s.i_funcionarios = r.i_funcionarios 
                                     and s.i_entidades = r.i_entidades
                                     and mr.dispensados != 3
                                     and s.dt_reintegracao is null
                                     and s.dt_canc_resc is null), ' 23:59:59')
 order by hs.dt_alteracoes DESC;


-- CORREÇÃO
-- Atualiza os históricos de funcionários com data de alteração maior que a data de rescisão, ajustando a data de alteração para um minuto após a última alteração ou para o primeiro dia do mês da data de rescisão se não houver alterações anteriores
-- Isso garante que as alterações sejam consistentes com a data de rescisão e evita problemas de integridade referencial

begin
  declare lsmsg varchar(100);
  declare w_nova_alteracao timestamp;
  declare w_ultima_alteracao timestamp;
  declare w_rescisao date;
  declare w_conta integer;

  set w_conta = 0;
  llloop: for ll as meuloop2 dynamic scroll cursor for
    select hist_funcionarios.i_entidades as w_entidade, hist_funcionarios.i_funcionarios as w_funcionario, hist_funcionarios.dt_alteracoes as w_alteracao
      from bethadba.hist_funcionarios
     where hist_funcionarios.dt_alteracoes > STRING((select max(s.dt_rescisao)
                                                       from bethadba.rescisoes s join
                                                            bethadba.motivos_resc mr on(s.i_motivos_resc = mr.i_motivos_resc)
                                                       where s.i_funcionarios = hist_funcionarios.i_funcionarios
                                                         and s.i_entidades = hist_funcionarios.i_entidades
                                                         and mr.dispensados != 3
                                                         and s.dt_reintegracao is null
                                                         and s.dt_canc_resc is null), ' 23:59:59')
     order by hist_funcionarios.i_entidades, hist_funcionarios.i_funcionarios, hist_funcionarios.dt_alteracoes
  do
    set w_conta = w_conta + 1;
    set lsmsg = string(w_entidade) || '-' || string(w_funcionario) || '-' || String(w_alteracao);
message(lsmsg) to client;
set w_rescisao = (select max(s.dt_rescisao)
                    from bethadba.rescisoes s join bethadba.motivos_resc mr on(s.i_motivos_resc = mr.i_motivos_resc)
                   where s.i_entidades = w_entidade
                     and s.i_funcionarios = w_funcionario
                     and mr.dispensados != 3
                     and s.dt_reintegracao is null
                     and s.dt_canc_resc is null);
set w_ultima_alteracao = (select max(dt_alteracoes)
							from bethadba.hist_funcionarios
                           where hist_funcionarios.i_entidades = w_entidade
                             and hist_funcionarios.i_funcionarios = w_funcionario
                             and cast(hist_funcionarios.dt_alteracoes as date) = w_rescisao);
if w_ultima_alteracao is null then
  set w_nova_alteracao = cast((String(w_rescisao) + ' 01:00:00') as timestamp)
 else
  set w_nova_alteracao = DateAdd(minute, 1, w_ultima_alteracao);
end if;

delete bethadba.hist_funcionarios_qualif_profissional
 where i_entidades = w_entidade
   and i_funcionarios = w_funcionario
   and dt_alteracoes = w_alteracao;

delete from bethadba.hist_funcionarios_prop_adic
 where i_entidades = w_entidade
   and i_funcionarios = w_funcionario
   and dt_alteracoes = w_alteracao;

update bethadba.hist_funcionarios
   set dt_alteracoes = w_nova_alteracao
 where i_entidades = w_entidade
   and i_funcionarios = w_funcionario
   and dt_alteracoes = w_alteracao;

end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 29.sql

-- FOLHA - Validação: FOLHA - Validação - 3.sql

-- VALIDAÇÃO 03
-- Busca a data de vencimento da CNH menor que a data de emissão da 1ª habilitação

select i_pessoas,
       dt_primeira_cnh,
       dt_vencto_cnh
  from bethadba.pessoas_fis_compl
 where dt_primeira_cnh > dt_vencto_cnh
 
union
 
select i_pessoas,
       dt_primeira_cnh,
       dt_vencto_cnh
  from bethadba.hist_pessoas_fis hpf  
 where dt_primeira_cnh > dt_vencto_cnh;


-- CORREÇÃO
-- Atualiza a data de vencimento da CNH para ser igual à data da primeira habilitação se a data de vencimento for menor que a data da primeira habilitação

update bethadba.pessoas_fis_compl
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;
 
update bethadba.hist_pessoas_fis
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;

-- FIM DO ARQUIVO FOLHA - Validação - 3.sql

-- FOLHA - Validação: FOLHA - Validação - 30.sql

-- VALIDAÇÃO 30
-- Busca as alterações de salário dos funcionários maior que a data de rescisão

select hs.i_funcionarios,
       hs.i_entidades,
       hs.dt_alteracoes,
       r.dt_rescisao,
       STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)) as dt_alteracoes_novo
  from bethadba.hist_salariais hs
 inner join bethadba.rescisoes r
    on (hs.i_funcionarios = r.i_funcionarios
   and hs.i_entidades = r.i_entidades)
 where hs.dt_alteracoes > STRING((select max(s.dt_rescisao) 
                                    from bethadba.rescisoes s 
                                    join bethadba.motivos_resc mr
                                      on (s.i_motivos_resc = mr.i_motivos_resc)
                                   where s.i_funcionarios = r.i_funcionarios 
                                     and s.i_entidades = r.i_entidades
                                     and s.dt_canc_resc is null
                                     and s.dt_reintegracao is null
                                     and mr.dispensados != 3), ' 23:59:59')
 order by hs.dt_alteracoes DESC;


-- CORREÇÃO
-- Alterar a data do campo hs.dt_alteracoes para um minuto após a última alteração dentro do mesmo mês da data do campo r.dt_rescisao sem gerar duplicidade

-- Cria a tabela temporária de minutos
create local temporary table minutos (n int);
insert into minutos
select row_num - 1
from sa_rowgenerator(1, 1440);

-- Atualiza a tabela de histórico salarial
update bethadba.hist_salariais hs
   set dt_alteracoes = (
      select min(dt_nova)
        from (
            select dateadd(minute, m.n, STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8))) as dt_nova
              from bethadba.rescisoes r2
             cross join minutos m
             where r2.i_funcionarios = hs.i_funcionarios
               and r2.i_entidades = hs.i_entidades
               and r2.dt_rescisao = r.dt_rescisao
               and not exists (
                   select 1
                     from bethadba.hist_salariais hsx
                    where hsx.i_funcionarios = hs.i_funcionarios
                      and hsx.i_entidades = hs.i_entidades
                      and hsx.dt_alteracoes = dateadd(minute, m.n, STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)))
               )
        ) as possiveis
    )
  from bethadba.rescisoes r
 where hs.i_entidades = r.i_entidades
   and hs.i_funcionarios = r.i_funcionarios
   and dt_alteracoes > STRING((select max(s.dt_rescisao) 
                      from bethadba.rescisoes s 
                      join bethadba.motivos_resc mr
                        on (s.i_motivos_resc = mr.i_motivos_resc)
                      where s.i_funcionarios = r.i_funcionarios 
                        and s.i_entidades = r.i_entidades
                        and s.dt_canc_resc is null
                        and s.dt_reintegracao is null
                        and mr.dispensados != 3), ' 23:59:59');

drop table minutos;

-- FIM DO ARQUIVO FOLHA - Validação - 30.sql

-- FOLHA - Validação: FOLHA - Validação - 31.sql

-- VALIDAÇÃO 31
-- Alterações de cargo dos funcionários maior que a data de rescisão

select hs.i_funcionarios,
       hs.i_entidades,
       hs.dt_alteracoes,
       r.dt_rescisao,
       STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)) as dt_alteracoes_novo
  from bethadba.hist_cargos as hs
 inner join bethadba.rescisoes as r
    on (hs.i_funcionarios = r.i_funcionarios and hs.i_entidades = r.i_entidades)
 where hs.dt_alteracoes > STRING((select max(s.dt_rescisao) 
                                    from bethadba.rescisoes as s
                                    join bethadba.motivos_resc mr
                                      on (s.i_motivos_resc = mr.i_motivos_resc)
                                   where s.i_funcionarios = r.i_funcionarios 
                                     and s.i_entidades = r.i_entidades
                                     and s.dt_canc_resc is null
                                     and s.dt_reintegracao is null
                                     and mr.dispensados != 3), ' 23:59:59')
 order by hs.dt_alteracoes DESC;


-- CORREÇÃO
-- Atualiza os históricos de cargos com data de alteração maior que a data de rescisão, ajustando a data de alteração para um minuto após a última alteração ou para o primeiro dia do mês da data de rescisão se não houver alterações anteriores

for a1 as a2 cursor for
    select
        hs.i_funcionarios,
        hs.i_entidades,
        hs.dt_alteracoes,
        r.dt_rescisao,
        linha = row_number() over (order by hs.i_funcionarios),
        dt_alteracoes_novo = dateadd(ss, -linha , date(STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)))),
        xSQL = 'update bethadba.hist_cargos set dt_alteracoes = '''||dt_alteracoes_novo||''' where i_funcionarios = '||hs.i_funcionarios||' and i_entidades = '||hs.i_entidades||' and dt_alteracoes = '''||hs.dt_alteracoes||''';'
    from bethadba.hist_cargos hs
    inner join bethadba.rescisoes r on (hs.i_funcionarios = r.i_funcionarios and hs.i_entidades = r.i_entidades)
    where hs.dt_alteracoes > STRING((select max(s.dt_rescisao)
                                           from bethadba.rescisoes s
                                           join bethadba.motivos_resc mr on(s.i_motivos_resc = mr.i_motivos_resc)
                                           where s.i_funcionarios = r.i_funcionarios
                                           and s.i_entidades = r.i_entidades
                                           and s.dt_canc_resc is null
                                           and s.dt_reintegracao is null
                                           and mr.dispensados != 3), ' 23:59:59')
    order by hs.i_funcionarios
do
    message xSQL ||' linha: '||linha to client;
    execute immediate xSQL;
end for;

-- FIM DO ARQUIVO FOLHA - Validação - 31.sql

-- FOLHA - Validação: FOLHA - Validação - 32.sql

-- VALIDAÇÃO 32
-- Classificações que estão com código errado no tipo de afastamento

select i_tipos_afast,
       classif,
       descricao
  from bethadba.tipos_afast
 where classif in (1, null);


-- CORREÇÃO
-- Atualiza a classificação dos tipos de afastamento para 2 (outros) onde a classificação é nula ou igual a 1

update bethadba.tipos_afast
   set classif = 2
 where classif is null
    or classif = 1;

-- FIM DO ARQUIVO FOLHA - Validação - 32.sql

-- FOLHA - Validação: FOLHA - Validação - 33.sql

-- VALIDAÇÃO 33
-- Busca os tipos de atos repetidos

select list(i_tipos_atos) as ttt, 
       nome,
       count(nome) as quantidade 
  from bethadba.tipos_atos 
 group by nome 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os tipos de atos repetidos para evitar duplicidade, adicionando o i_tipos_atos ao nome do tipo de atos

update bethadba.tipos_atos
   set tipos_atos.nome = tipos_atos.i_tipos_atos || '-' || tipos_atos.nome
 where tipos_atos.i_tipos_atos in(select i_tipos_atos
                                    from bethadba.tipos_atos
                                   where (select count(i_tipos_atos)
                                            from bethadba.tipos_atos t
                                           where trim(t.nome) = trim(tipos_atos.nome)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 33.sql

-- FOLHA - Validação: FOLHA - Validação - 34.sql

-- VALIDAÇÃO 34
-- Níveis de organogramas com separadores nulos 

select i_config_organ,
       i_niveis_organ,
       descricao 
  from bethadba.niveis_organ 
 where separador_nivel is null
   and i_niveis_organ != 1


-- CORREÇÃO
-- Atualiza os níveis de organogramas com separadores nulos, definindo o separador como '.'

update niveis_organ
   set separador_nivel = '.'
 where separador_nivel is null;

-- FIM DO ARQUIVO FOLHA - Validação - 34.sql

-- FOLHA - Validação: FOLHA - Validação - 35.sql

-- VALIDAÇÃO 35
-- Verifica a natureza de texto jurúdico se é nulo nos atos

select i_atos 
  from bethadba.atos 
 where i_natureza_texto_juridico is null;


-- CORREÇÃO
-- Atualiza a natureza de texto jurídico para 99 (SEM INFORMAÇÃO) onde a natureza de texto jurídico é nula
                 
insert into bethadba.natureza_texto_juridico (i_natureza_texto_juridico, descricao, codigo_tce, classif)
values (99, 'SEM INFORMAÇÃO', 99, 9);

update bethadba.atos
   set i_natureza_texto_juridico = 99
 where i_natureza_texto_juridico is null;

-- FIM DO ARQUIVO FOLHA - Validação - 35.sql

-- FOLHA - Validação: FOLHA - Validação - 36.sql

-- VALIDAÇÃO 36
-- Verifica se a data de fonte de divulgação é menor que a data de publicação do ato

select a.i_atos,
       fa.dt_publicacao,
       fa.dt_publicacao as dd,
       a.dt_publicacao    ,
       a.dt_publicacao as tttt                
  from bethadba.atos as a
 inner join bethadba.fontes_atos as fa
    on (fa.i_atos = a.i_atos)
 where fa.dt_publicacao < a.dt_publicacao;


-- CORREÇÃO
-- Atualiza a data de publicação do ato para ser igual à data de fonte de divulgação onde a data de fonte de divulgação é menor que a data de publicação do ato

update bethadba.atos as a
 inner join bethadba.fontes_atos as fa
    on (fa.i_atos = a.i_atos)
   set a.dt_publicacao = fa.dt_publicacao
 where fa.dt_publicacao < a.dt_publicacao;

-- FIM DO ARQUIVO FOLHA - Validação - 36.sql

-- FOLHA - Validação: FOLHA - Validação - 37.sql

-- VALIDAÇÃO 37
-- Ter ao menos um tipo de afastamento na configuração do cancelamento de férias

select i_canc_ferias,descricao
  from bethadba.canc_ferias as cf
 where not exists (select i_tipos_afast
                     from bethadba.canc_ferias_afast as cfa
                    where cfa.i_canc_ferias = cf.i_canc_ferias);


-- CORREÇÃO
-- Insere o tipo de afastamento 1 (Afastamento para Férias) na configuração de cancelamento de férias, garantindo que haja pelo menos um tipo de afastamento associado

insert into bethadba.canc_ferias_afast (i_canc_ferias, i_tipos_afast)
values (2, 1);

-- FIM DO ARQUIVO FOLHA - Validação - 37.sql

-- FOLHA - Validação: FOLHA - Validação - 38.sql

-- VALIDAÇÃO 38
-- Verifica descrição de configuração de organograma se é maior que 30 caracteres

select i_config_organ,
       descricao,
       length(descricao) as tamanho 
  from bethadba.config_organ
 where tamanho > 30;


-- CORREÇÃO
-- Atualiza a descrição da configuração de organograma para abreviar 'Entidade' para 'Ent' onde a descrição é maior que 30 caracteres

update bethadba.config_organ 
   set descricao = replace(descricao, 'Entidade', 'Ent')
 where length(descricao) > 30;

-- FIM DO ARQUIVO FOLHA - Validação - 38.sql

-- FOLHA - Validação: FOLHA - Validação - 39.sql

-- VALIDAÇÃO 39
-- Verifica descrição de configuração de organograma repetido

select list(i_config_organ) as iconfig,
       descricao,
       count(descricao) as quantidade
  from bethadba.config_organ 
 group by descricao 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza a descrição da configuração de organograma repetido para evitar duplicidade, adicionando o i_config_organ ao nome da configuração

update bethadba.config_organ
   set descricao = i_config_organ || '-' || descricao
 where i_config_organ in (select i_config_organ
                            from bethadba.config_organ
                           where(select count(i_config_organ)
                                   from bethadba.config_organ co
                                  where trim(co.descricao) = trim(config_organ.descricao)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 39.sql

-- FOLHA - Validação: FOLHA - Validação - 4.sql

-- VALIDAÇÃO 04  
-- Busca os campos adicionais com descrição repetido

select list(i_caracteristicas) as caracteristicas, 
       trim(nome) as nomes, 
       count(nome) 
  from bethadba.caracteristicas 
 group by nomes
having count(nome) > 1;


-- CORREÇÃO
-- Atualiza os nomes dos campos adicionais repetidos para evitar duplicidade
                
update bethadba.caracteristicas
   set nome = i_caracteristicas || nome
 where i_caracteristicas in (select nm_caract
							   from (select max(i_caracteristicas) as nm_caract,
							   				nome
 									   from bethadba.caracteristicas
 									  where (select count(1)
 											   from bethadba.caracteristicas c
 											  where c.i_caracteristicas = c.i_caracteristicas
 												and trim(c.nome) = trim(caracteristicas.nome)) > 1
									  group by nome ) as maior);

-- FIM DO ARQUIVO FOLHA - Validação - 4.sql

-- FOLHA - Validação: FOLHA - Validação - 40.sql

-- VALIDAÇÃO 40
-- Verifica os RG's repetidos

select list(i_pessoas) as pess,
       rg,
       count(rg) as quantidade
  from bethadba.pessoas_fisicas
 group by rg 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os RG's repetidos para nulo, evitando duplicidade
 
update bethadba.pessoas_fisicas as pf1
   set rg = null
 where exists (select 1
                 from bethadba.pessoas_fisicas as pf2
                where pf1.rg = pf2.rg
                  and pf1.i_pessoas <> pf2.i_pessoas);

-- FIM DO ARQUIVO FOLHA - Validação - 40.sql

-- FOLHA - Validação: FOLHA - Validação - 41.sql

-- VALIDAÇÃO 41
-- Verifica os cargos com descrição repetidos

select cargos.i_entidades as identidade,
       cargos.nome as nome,
       count(cargos.nome) as quantidade,
       list(cargos.i_cargos) as codigos
  from bethadba.cargos
 group by cargos.i_entidades, cargos.nome
having count(cargos.nome) > 1;


-- CORREÇÃO
-- Atualiza os nomes dos cargos repetidos para evitar duplicidade, adicionando o i_cargos ao nome do cargo
   
update bethadba.cargos
   set cargos.nome = trim(cargos.i_cargos) || '-' || trim(cargos.nome)
 where cargos.i_cargos in(select i_cargos
                            from bethadba.cargos
                           where (select count(i_cargos)
                                    from bethadba.cargos c
                                   where trim(c.nome) = trim(cargos.nome)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 41.sql

-- FOLHA - Validação: FOLHA - Validação - 42.sql

-- VALIDAÇÃO 42
-- Verifica o término de vigência maior que 2099 na tabela bethadba.bases_calc_outras_empresas

select i_pessoas
  from bethadba.bases_calc_outras_empresas
 where dt_vigencia_fin > '2099-01-01';


-- CORREÇÃO
-- Atualiza a data de término de vigência para 2099-01-01 onde a data de término de vigência é maior que 2099-01-01

update bethadba.bases_calc_outras_empresas
   set dt_vigencia_fin = '2099-01-01'
 where i_pessoas in (select i_pessoas
                       from bethadba.bases_calc_outras_empresas
                      where dt_vigencia_fin > '2099-01-01')
   and dt_vigencia_fin >'2099-01-01';

-- FIM DO ARQUIVO FOLHA - Validação - 42.sql

-- FOLHA - Validação: FOLHA - Validação - 43.sql

-- VALIDAÇÃO 43
-- Verifica o número de endereço se está vazio

select i_pessoas
  from bethadba.pessoas_enderecos 
 where numero = '';


-- CORREÇÃO
-- Atualiza o número de endereço para 0 onde o número é vazio

update bethadba.pessoas_enderecos 
   set numero = 0
 where i_pessoas in (select i_pessoas
                       from bethadba.pessoas_enderecos 
                      where numero = '')
   and numero = '';

-- FIM DO ARQUIVO FOLHA - Validação - 43.sql

-- FOLHA - Validação: FOLHA - Validação - 44.sql

-- VALIDAÇÃO 44
-- Verifica o nome de rua se está vazio

select i_ruas, nome
  from bethadba.ruas 
 where nome = ''
    or nome is null;


-- CORREÇÃO
-- Atualiza o nome da rua para 'rua sem nome' onde o nome está vazio ou é nulo

update bethadba.ruas 
   set nome = 'rua sem nome 40'
 where i_ruas = 40;

-- FIM DO ARQUIVO FOLHA - Validação - 44.sql

-- FOLHA - Validação: FOLHA - Validação - 45.sql

-- VALIDAÇÃO 45
-- Verifica os funcionários sem previdência

select hf.i_entidades ,
       hf.i_funcionarios                
  from bethadba.hist_funcionarios hf
 inner join bethadba.funcionarios f
    on f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
 inner join bethadba.rescisoes r
    on r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
 inner join bethadba.vinculos v
    on v.i_vinculos = hf.i_vinculos
 where hf.prev_federal = 'N'
   and hf.prev_estadual = 'N'
   and hf.fundo_ass = 'N'
   and hf.fundo_prev = 'N'
   and hf.fundo_financ = 'N'
   and f.tipo_func = 'F'
   and r.i_motivos_resc not in (8)
   and v.categoria_esocial <> '901'
 group by hf.i_funcionarios, hf.i_entidades
 order by hf.i_entidades, hf.i_funcionarios;


-- CORREÇÃO
-- Altera a previdência federal para 'Sim' quando o histórico da matrícula não possuí nenhuma previdência marcada

update bethadba.hist_funcionarios hf
   set hf.prev_federal = 'S'
  from bethadba.funcionarios f,
       bethadba.rescisoes r,
       bethadba.vinculos v
 where f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
   and r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
   and v.i_vinculos = hf.i_vinculos
   and coalesce(hf.prev_federal, 'N') = 'N'
   and coalesce(hf.prev_estadual, 'N') = 'N'
   and coalesce(hf.fundo_ass, 'N') = 'N'
   and coalesce(hf.fundo_prev, 'N') = 'N'
   and coalesce(hf.fundo_financ, 'N') = 'N'
   and f.tipo_func = 'F'
   and r.i_motivos_resc not in (8)
   and v.categoria_esocial <> '901';


-- FIM DO ARQUIVO FOLHA - Validação - 45.sql

-- FOLHA - Validação: FOLHA - Validação - 46.sql

-- VALIDAÇÃO 46
-- Verifica os eventos de média vantagem que não tem eventos vinculados

select m.i_eventos as eventos,                
       me.i_eventos_medias
  from bethadba.mediasvant m
  left join bethadba.mediasvant_eve me
    on (m.i_eventos = me.i_eventos_medias)
 where me.i_eventos_medias is null;


-- CORREÇÃO
-- Exclui os eventos de média vantagem que não possuem eventos vinculados

delete from bethadba.mediasvant
 where not exists(select 1
                    from bethadba.mediasvant_eve
                   where mediasvant_eve.i_eventos_medias = mediasvant.i_eventos);

-- FIM DO ARQUIVO FOLHA - Validação - 46.sql

-- FOLHA - Validação: FOLHA - Validação - 47.sql

-- VALIDAÇÃO 47
-- Verifica os eventos de média/vantagem se estão compondo outros eventos de média/vantagem

select i_eventos_medias,
       i_eventos
  from bethadba.mediasvant_eve 
 where i_eventos in (select i_eventos
                       from bethadba.mediasvant);


-- CORREÇÃO
-- Exclui os eventos de média vantagem que estão compondo outros eventos de média vantagem

delete from bethadba.mediasvant_eve 
 where i_eventos = 1033;

-- FIM DO ARQUIVO FOLHA - Validação - 47.sql

-- FOLHA - Validação: FOLHA - Validação - 48.sql

-- VALIDAÇÃO 48
-- Data de admissão da matricula maior que a data de inicio da matricula na lotação fisica

select f.dt_admissao,
       lm.i_funcionarios,
       lm.dt_inicial,
       lm.i_entidades,
       lm.i_locais_trab,
       lm.dt_final 
  from bethadba.funcionarios as f
 inner join bethadba.locais_mov as lm
    on (f.i_funcionarios = lm.i_funcionarios
   and f.i_entidades = lm.i_entidades)
 where f.dt_admissao > lm.dt_inicial;


-- CORREÇÃO
-- Atualiza a data inicial da lotação física para a data de admissão do funcionário onde a data de admissão é maior que a data inicial da lotação física

update bethadba.locais_mov
   set lm.dt_inicial = f.dt_admissao
  from bethadba.locais_mov as lm
 inner join bethadba.funcionarios as f
    on (lm.i_funcionarios = f.i_funcionarios
   and f.i_entidades = lm.i_entidades)
 where f.dt_admissao > lm.dt_inicial;

-- FIM DO ARQUIVO FOLHA - Validação - 48.sql

-- FOLHA - Validação: FOLHA - Validação - 49.sql

-- VALIDAÇÃO 49
-- Verifica o motivo nos afastamentos se contém no máximo 150 caracteres

select length(observacao) as tamanho_observacao, 
       i_entidades, 
       i_funcionarios, 
       dt_afastamento 
  from bethadba.afastamentos 
 where length(observacao) > 150;


-- CORREÇÃO
-- Atualiza a observação do afastamento para conter no máximo 150 caracteres

update bethadba.afastamentos
   set observacao = SUBSTR(observacao, 1, 150)
 where length(observacao) > 150;

-- FIM DO ARQUIVO FOLHA - Validação - 49.sql

-- FOLHA - Validação: FOLHA - Validação - 5.sql

-- VALIDAÇÃO 05  
-- Verifica se o dependente está cadastrado como 10 - OUTROS

select i_dependentes,
       i_pessoas,
       mot_ini_depende 
  from bethadba.dependentes,
 where grau = 10;


-- CORREÇÃO
-- Atualiza o grau do dependente para 5 (OUTROS) se o motivo de início do dependente não for um dos motivos válidos ou for nulo

update bethadba.dependentes 
   set grau = 5 
 where grau = 10 
   and mot_ini_depende not in (1,2,3,4,7,8) 
    or mot_ini_depende is null;

update bethadba.dependentes 
   set grau = 2 
 where grau = 10 
   and mot_ini_depende in (7);

update bethadba.dependentes 
   set grau = 8 
 where grau = 10 
   and mot_ini_depende in (2);

update bethadba.dependentes 
   set grau = 1 
 where grau = 10 
   and mot_ini_depende in (1,2,3,4);

-- FIM DO ARQUIVO FOLHA - Validação - 5.sql

-- FOLHA - Validação: FOLHA - Validação - 50.sql

-- VALIDAÇÃO 50
-- Verifica a data inicial no afastamento se é maior que a data final

select i_entidades, 
       i_funcionarios, 
       i_ferias,
       dt_gozo_ini,
       dt_gozo_fin 
  from bethadba.ferias 
 where dt_gozo_ini > dt_gozo_fin;


-- CORREÇÃO
-- Atualiza a data final do gozo de férias para ser igual à data inicial mais o saldo de dias se a data inicial for maior que a data final

update bethadba.ferias
   set dt_gozo_fin = dateadd(day, saldo_dias, dt_gozo_ini)
 where dt_gozo_ini > dt_gozo_fin;

-- FIM DO ARQUIVO FOLHA - Validação - 50.sql

-- FOLHA - Validação: FOLHA - Validação - 51.sql

-- VALIDAÇÃO 51
-- Verifica as rescisões de aposentadoria com motivo nulo

select i_entidades,
       i_funcionarios,
       i_rescisoes 
  from bethadba.rescisoes 
 where i_motivos_resc = 7
   and i_motivos_apos is null;

-- CORREÇÃO
-- Atualiza o motivo de aposentadoria para 1 (aposentadoria por tempo de serviço) onde o motivo de rescisão é 7 (aposentadoria) e o motivo de aposentadoria é nulo
-- Isso garante que todas as rescisões de aposentadoria tenham um motivo definido

update bethadba.rescisoes 
   set i_motivos_apos = 1
 where i_motivos_resc = 7
   and i_motivos_apos is null;

-- FIM DO ARQUIVO FOLHA - Validação - 51.sql

-- FOLHA - Validação: FOLHA - Validação - 52.sql

-- VALIDAÇÃO 52
-- Verifica os grupos funcionais repetidos

select list(i_entidades) as entidades,
       list(i_grupos) as grupos,
       nome,
       count(nome) as quantidade
  from bethadba.grupos
 group by nome 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os nomes dos grupos funcionais repetidos, adicionando o identificador da entidade ao final do nome

update bethadba.grupos g
   set nome = i_grupos || ' - ' || nome
 where nome in (select nome
                  from bethadba.grupos
                 group by nome
                having count(nome) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 52.sql

-- FOLHA - Validação: FOLHA - Validação - 53.sql

-- VALIDAçãO 53
-- Verifica a data inicial de benefÍcio do dependente se é maior que a do titular

select fps.i_entidades,
       fps.i_funcionarios,
       fps.i_pessoas,
       fps.i_sequenciais,
       vigencia_inicial as vigencia_inicial_dependente,
       vigencia_inicial_titular = (select max(vigencia_inicial)
                                     from bethadba.func_planos_saude
                                    where i_sequenciais = 1
                                      and i_funcionarios = fps.i_funcionarios)
  from bethadba.func_planos_saude as fps 
 where fps.i_sequenciais != 1
   and  fps.vigencia_inicial < vigencia_inicial_titular
   and fps.i_pessoas = i_pessoas;


-- CORREÇÃO
-- Atualiza a data de vigência inicial do plano de saúde do dependente para a mesma data do titular
-- Isso garante que a data de vigência inicial do dependente não seja anterior à do titular

update bethadba.func_planos_saude as fp
   set fp.vigencia_inicial = plano_saude.vigencia_inicial_titular
  from (select fps.i_entidades,
               fps.i_funcionarios,
               fps.i_pessoas,
               fps.i_sequenciais,
               vigencia_inicial as vigencia_inicial_dependente,
               vigencia_inicial_titular = (select vigencia_inicial
                                             from bethadba.func_planos_saude
                                            where i_sequenciais = 1
                                              and i_funcionarios = fps.i_funcionarios)
          from bethadba.func_planos_saude as fps 
         where fps.i_sequenciais != 1
           and fps.vigencia_inicial < vigencia_inicial_titular) as plano_saude
 where fp.i_entidades = plano_saude.i_entidades
   and fp.i_funcionarios = plano_saude.i_funcionarios
   and fp.i_pessoas = plano_saude.i_pessoas
   and fp.i_sequenciais = plano_saude.i_sequenciais;

-- FIM DO ARQUIVO FOLHA - Validação - 53.sql

-- FOLHA - Validação: FOLHA - Validação - 54.sql

-- VALIDAÇÃO 54
-- Verifica se o número de telefone na lotação física é maior que 9 caracteres

select i_entidades,
       i_locais_trab,
       fone,
       length(fone) as quantidade
  from bethadba.locais_trab
 where quantidade > 9;


-- CORREÇÃO
-- Atualiza o número de telefone na lotação física para remover caracteres especiais e garantir que o número tenha no máximo 9 caracteres

update bethadba.locais_trab 
   set fone = replace(replace(replace(fone,'(',''),')',''),'48','')
 where fone in (select fone
                  from (select i_entidades,
                               i_locais_trab,
                               fone,
                               length(fone) as quantidade
                          from bethadba.locais_trab
                         where quantidade > 9) as teste);

-- FIM DO ARQUIVO FOLHA - Validação - 54.sql

-- FOLHA - Validação: FOLHA - Validação - 55.sql

-- VALIDAÇÃO 55
-- Busca os atos com data inicial nulo

select i_atos, 
       dt_vigorar 
  from bethadba.atos 
 where dt_inicial is null;


-- CORREÇÃO
-- Atualiza a data inicial do ato para ser igual à data de vigorar se a data inicial for nula

update bethadba.atos 
   set dt_inicial = dt_vigorar 
 where dt_inicial is null;

-- FIM DO ARQUIVO FOLHA - Validação - 55.sql

-- FOLHA - Validação: FOLHA - Validação - 56.sql

-- VALIDAÇÃO 56
-- Busca as descrições repetidas dos níveis salariais

select niveis.i_entidades as entidades,
       niveis.nome as nomes,
       count(niveis.nome) as quantidade,
       list(niveis.i_niveis) as codigos
  from bethadba.niveis
 group by niveis.i_entidades, niveis.nome
having count(niveis.nome) > 1;


-- CORREÇÃO
-- Atualiza os nomes dos níveis salariais repetidos, adicionando o identificador do nível ao início do nome e garantindo que os nomes sejam únicos

update bethadba.niveis
   set niveis.nome = niveis.i_niveis || ' - ' || niveis.nome
 where niveis.i_niveis in (select i_niveis
                             from bethadba.niveis
                            where (select count(i_niveis)
                                     from bethadba.niveis as n
                                    where trim(n.nome) = trim(niveis.nome)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 56.sql

-- FOLHA - Validação: FOLHA - Validação - 57.sql

-- VALIDAÇÃO 57
-- Busca os funcionários com data de nomeação maior que a data de posse

select i_funcionarios 
  from bethadba.hist_cargos
 where dt_nomeacao > dt_posse;


-- CORREÇÃO
-- Atualiza a data de nomeação para ser igual à data de posse

update bethadba.hist_cargos
   set dt_nomeacao = dt_posse
 where dt_nomeacao > dt_posse;

-- FIM DO ARQUIVO FOLHA - Validação - 57.sql

-- FOLHA - Validação: FOLHA - Validação - 58.sql

-- VALIDAÇÃO 58
-- Busca as contas bancárias dos funcionários que estão inválidas

select f.i_funcionarios,
       f.i_entidades,
       hf.dt_alteracoes,
       hf.i_bancos as banco_atual,
       hf.i_agencias as agencia_atual,
       hf.i_pessoas_contas,
       pc.i_bancos as banco_novo,
       pc.i_agencias as agencia_nova
  from bethadba.hist_funcionarios hf
 inner join bethadba.funcionarios f
    on (hf.i_funcionarios = f.i_funcionarios
   and hf.i_entidades = f.i_entidades)
 inner join bethadba.pessoas_contas pc
    on (f.i_pessoas = pc.i_pessoas
   and pc.i_pessoas_contas = hf.i_pessoas_contas)    
 where (pc.i_bancos != hf.i_bancos
    or pc.i_agencias != hf.i_agencias)
   and hf.forma_pagto = 'R';


-- CORREÇÃO
-- Atualiza os dados bancários dos funcionários com forma de pagamento 'R' (Crédito em conta) para os dados correspondentes na tabela pessoas_contas

update bethadba.hist_funcionarios,
       bethadba.pessoas_contas,
       bethadba.funcionarios
   set hist_funcionarios.i_bancos = pessoas_contas.i_bancos,
       hist_funcionarios.i_agencias = pessoas_contas.i_agencias
 where hist_funcionarios.i_entidades = funcionarios.i_entidades
   and hist_funcionarios.i_funcionarios = funcionarios.i_funcionarios
   and pessoas_contas.i_pessoas = funcionarios.i_pessoas
   and hist_funcionarios.i_pessoas_contas = pessoas_contas.i_pessoas_contas
   and (hist_funcionarios.i_bancos <> pessoas_contas.i_bancos
    or hist_funcionarios.i_agencias <> pessoas_contas.i_agencias)
   and hist_funcionarios.forma_pagto = 'R';

-- FIM DO ARQUIVO FOLHA - Validação - 58.sql

-- FOLHA - Validação: FOLHA - Validação - 59.sql

-- VALIDAÇÃO 59
-- Busca os históricos de funcionários com mais do que uma previdência informada

select i_funcionarios,
       i_entidades,
       dt_alteracoes,
       length(REPLACE(prev_federal || prev_estadual || fundo_ass || fundo_prev, 'N', '')) as quantidade
  from bethadba.hist_funcionarios
 where quantidade > 1;


-- CORREÇÃO
-- Altera a previdência federal para 'Sim' e as demais para 'Não' quando o histórico da matrícula possuí mais de uma previdência marcada

update bethadba.hist_funcionarios
   set prev_federal = 'S',
       prev_estadual = 'N',
       fundo_ass = 'N',
       fundo_prev = 'N'
 where length(REPLACE(prev_federal || prev_estadual || fundo_ass || fundo_prev, 'N', '')) > 1;

-- FIM DO ARQUIVO FOLHA - Validação - 59.sql

-- FOLHA - Validação: FOLHA - Validação - 6.sql

-- VALIDAÇÃO 06  
-- Pessoas com data de nascimento maior que data de dependência

select d.i_dependentes,
       pf.dt_nascimento,
       d.dt_ini_depende 
  from bethadba.dependentes d 
  join bethadba.pessoas_fisicas pf
    on (d.i_dependentes = pf.i_pessoas)
 where dt_nascimento > dt_ini_depende;


-- CORREÇÃO
-- Atualiza a data de início da dependência para ser igual à data de nascimento do dependente se a data de nascimento for maior que a data de início da dependência
                
update bethadba.dependentes a 
  join bethadba.pessoas_fisicas b
    on (a.i_dependentes = b.i_pessoas)
   set a.dt_ini_depende = b.dt_nascimento
 where b.dt_nascimento > dt_ini_depende;

-- FIM DO ARQUIVO FOLHA - Validação - 6.sql

-- FOLHA - Validação: FOLHA - Validação - 60.sql

-- VALIDAÇÃO 60
-- Busca os afastamentos com data inicial menor que data de admissão

select (select dt_admissao
          from bethadba.funcionarios
         where i_funcionarios = a.i_funcionarios
           and i_entidades = a.i_entidades) as data_admissao,
	    dt_afastamento,
       dt_ultimo_dia,
       i_entidades,
       i_funcionarios
  from bethadba.afastamentos as a
 where a.dt_afastamento < data_admissao;


-- CORREÇÃO
-- Atualiza a data de afastamento para um dia após a data de admissão do funcionário onde a data de afastamento é menor que a data de admissão

begin
	declare w_dt_afastamento timestamp;
   declare w_dt_ultimo_dia timestamp;
   declare w_i_entidades integer;
   declare w_i_funcionarios integer;
   declare w_dt_admissao timestamp;
   declare w_nova_data timestamp;
	
   llLoop: for ll as cur_01 dynamic scroll cursor for	
      select (select dt_admissao
                from bethadba.funcionarios
               where i_funcionarios = a.i_funcionarios
                 and i_entidades = a.i_entidades) as data_admissao,
             dt_afastamento,
             dt_ultimo_dia, 
             i_entidades, 
             i_funcionarios, 
             i_tipos_afast
        from bethadba.afastamentos as a
       where a.dt_afastamento < data_admissao
       order by a.i_funcionarios ASC
   do
      set w_dt_afastamento = dt_afastamento;
      set w_dt_ultimo_dia = dt_ultimo_dia;
      set w_i_entidades = i_entidades;
      set w_i_funcionarios = i_funcionarios;
      set w_dt_admissao = data_admissao;
      set w_nova_data = dateadd(day, 1, w_dt_admissao);
      
   update bethadba.afastamentos as a
      set dt_afastamento =  w_nova_data
    where i_funcionarios = w_i_funcionarios
      and dt_afastamento = w_dt_afastamento
      and i_entidades = w_i_entidades
   end for;
end;

-- FIM DO ARQUIVO FOLHA - Validação - 60.sql

-- FOLHA - Validação: FOLHA - Validação - 61.sql

-- VALIDAÇÃO 61
-- Busca os dependentes sem motivo de término

select i_pessoas ,
       i_dependentes,
       dt_ini_depende
  from bethadba.dependentes d  
 where mot_fin_depende is null
   and dt_fin_depende is not null;


-- CORREÇÃO
-- Atualiza o motivo de término dos dependentes que não possuem motivo de término para 0 (sem motivo de término)

update bethadba.dependentes
   set mot_fin_depende = 0
 where mot_fin_depende is null
   and dt_fin_depende is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 61.sql

-- FOLHA - Validação: FOLHA - Validação - 62.sql

-- VALIDAÇÃO 62
-- Cargos sem configuração de férias

select i_entidades,
	     i_cargos,
	     (select nome
	   	    from bethadba.cargos
	   	   where cargos.i_entidades = hist_cargos.i_entidades
 	   	     and cargos.i_cargos = hist_cargos.i_cargos) as nome
  from bethadba.hist_cargos
 where i_cargos in (select i_cargos
 	  				          from bethadba.cargos_compl
                     where cargos_compl.i_entidades = hist_cargos.i_entidades
                       and cargos_compl.i_config_ferias is null)
   and exists(select 1
   			 	      from bethadba.periodos
               where periodos.i_entidades = hist_cargos.i_entidades
                 and periodos.i_funcionarios = hist_cargos.i_funcionarios);


-- CORREÇÃO
-- Atualiza os cargos que não possuem configuração de férias

update bethadba.cargos_compl 
   set i_config_ferias = 1
  from bethadba.hist_cargos
 where i_config_ferias is null
   and cargos_compl.i_entidades = hist_cargos.i_entidades
   and cargos_compl.i_cargos = hist_cargos.i_cargos
   and exists(select 1
   			 	      from bethadba.periodos
               where periodos.i_entidades = hist_cargos.i_entidades
                 and periodos.i_funcionarios = hist_cargos.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 62.sql

-- FOLHA - Validação: FOLHA - Validação - 63.sql

-- VALIDAÇÃO 63
-- Quantidade de vagas nos cargos não pode ser maior que 99999

select c1.i_cargos,
       isnull(c1.qtd_vagas,0), 
       isnull(c2.vagas_acresc,0)
  from bethadba.cargos_compl c1
  left join bethadba.mov_cargos c2
    on c1.i_cargos = c2.i_cargos
 where c1.qtd_vagas > 9999
    or c2.vagas_acresc > 9999;


-- CORREÇÃO
-- Atualiza os cargos que possuem quantidade de vagas maior que 9999 e as vagas acrescidas para 9999

update bethadba.cargos_compl a
   set a.qtd_vagas = 9999,
       b.vagas_acresc = 9999
  from bethadba.mov_cargos b
 where a.qtd_vagas > 9999
   and a.i_cargos = b.i_cargos
   and b.vagas_acresc > 9999;

-- FIM DO ARQUIVO FOLHA - Validação - 63.sql

-- FOLHA - Validação: FOLHA - Validação - 64.sql

-- VALIDAÇÃO 64
-- Campo observação nas características à maior que 150 caracteres 

select i_caracteristicas, 
       nome 
  from bethadba.caracteristicas 
 where length(observacao) > 150;


-- CORREÇÃO
-- Atualiza o campo observação das características para nulo quando maior que 150 caracteres

update bethadba.caracteristicas
   set observacao = null
 where length(observacao) > 150;

-- FIM DO ARQUIVO FOLHA - Validação - 64.sql

-- FOLHA - Validação: FOLHA - Validação - 65.sql

-- VALIDAÇÃO 65
-- Verificar Teto Remuneratório

select e.i_entidades as entidade,
       ta.i_tipos_adm as tp_adm,
       competencia = (select max(a.i_competencias)
                        from bethadba.hist_tipos_adm as a 
                       where a.i_tipos_adm = ta.i_tipos_adm), 
       ta.vlr_sub_teto
  from bethadba.hist_tipos_adm as ta
  join bethadba.entidades as e
    on (ta.i_tipos_adm = e.i_tipos_adm)
 where vlr_sub_teto is null
 group by e.i_entidades,
          ta.i_tipos_adm,
          ta.i_competencias, 
          ta.vlr_sub_teto;


-- CORREÇÃO
-- Atualiza o valor do sub-teto para 99999 onde o valor é nulo, garantindo que todos os tipos administrativos tenham um valor definido para o sub-teto
                
update bethadba.hist_tipos_adm as hta
   set hta.vlr_sub_teto = '99999'
  from bethadba.entidades as e
 where hta.i_tipos_adm = e.i_tipos_adm
   and hta.i_competencias = (select max(x.i_competencias)
                               from bethadba.hist_tipos_adm as x
                              where x.i_tipos_adm = hta.i_tipos_adm
                                and x.vlr_sub_teto is null);

-- FIM DO ARQUIVO FOLHA - Validação - 65.sql

-- FOLHA - Validação: FOLHA - Validação - 66.sql

-- VALIDAÇÃO 66
-- Verifica horas mês zerado

select hist_salariais.i_entidades entidade, 
       hist_salariais.i_funcionarios func, 
       hist_salariais.dt_alteracoes dt_alt
  from bethadba.hist_salariais 
  join bethadba.funcionarios f
 where cast(hist_salariais.horas_mes as integer) < 1
   and tipo_func != 'A'
 order by hist_salariais.i_entidades,
          hist_salariais.i_funcionarios, 
          hist_salariais.dt_alteracoes;


-- CORREÇÃO
-- Atualiza horas mês para 220 quando zerado e não for tipo A
-- Considera que o mês tem 220 horas
 
update bethadba.hist_salariais  
   set horas_mes = 220
  from bethadba.funcionarios
 where cast(hist_salariais.horas_mes as integer) < 1
   and hist_salariais.i_entidades = funcionarios.i_entidades
   and hist_salariais.i_funcionarios = funcionarios.i_funcionarios
   and tipo_func != 'A';

-- FIM DO ARQUIVO FOLHA - Validação - 66.sql

-- FOLHA - Validação: FOLHA - Validação - 67.sql

-- VALIDAÇÃO 67
-- Funcionários com data de admissão após o inicio de gozo de férias

select funcionarios.dt_admissao,
       ferias.dt_gozo_ini,
       funcionarios.i_funcionarios
  from bethadba.funcionarios,
       bethadba.ferias
 where funcionarios.i_funcionarios = ferias.i_funcionarios
   and funcionarios.i_entidades = ferias.i_entidades
   and dt_admissao>dt_gozo_ini
   and ferias.num_dias_abono < ferias.saldo_dias
   and num_dias_abono is null;


-- CORREÇÃO
-- Exclui férias de funcionários com data de admissão posterior ao inicio do gozo de férias

delete from bethadba.ferias_proc
 where exists(select 1
                from bethadba.funcionarios, bethadba.ferias
               where funcionarios.i_entidades = ferias.i_entidades
                 and funcionarios.i_funcionarios = ferias.i_funcionarios
                 and ferias.dt_gozo_ini < funcionarios.dt_admissao
                 and ferias.num_dias_abono < ferias.saldo_dias
                 and ferias.i_ferias = ferias_proc.i_ferias
                 and ferias_proc.i_entidades = funcionarios.i_entidades
                 and ferias_proc.i_funcionarios = funcionarios.i_funcionarios);

delete from bethadba.ferias
 where dt_gozo_ini < (select dt_admissao
                        from bethadba.funcionarios
                       where funcionarios.i_entidades = ferias.i_entidades
                         and funcionarios.i_funcionarios = ferias.i_funcionarios)
   and ferias.num_dias_abono < ferias.saldo_dias;

-- FIM DO ARQUIVO FOLHA - Validação - 67.sql

-- FOLHA - Validação: FOLHA - Validação - 68.sql

-- VALIDAÇÃO 68
-- Quando a forma de pagamento for Crédito em conta é necessário informar a conta bancária

select i_funcionarios,
       i_entidades,
       mensagem_erro = 'Funcionarios com recebimento credito em conta sem dados da conta bancaria'
  from bethadba.hist_funcionarios as hf 
 where forma_pagto = 'R'
   and i_pessoas_contas is null;


-- CORREÇÃO
-- Atualiza a conta bancária dos funcionários com forma de pagamento 'R' (Crédito em conta) para a conta bancária correspondente na tabela pessoas_contas

update bethadba.hist_funcionarios
   set i_pessoas_contas = (select i_pessoas_contas
                             from bethadba.pessoas_contas
                            where i_pessoas = hist_funcionarios.i_pessoas)
 where forma_pagto = 'R'
   and i_pessoas_contas is null;

-- FIM DO ARQUIVO FOLHA - Validação - 68.sql

-- FOLHA - Validação: FOLHA - Validação - 69.sql

-- VALIDAÇÃO 69
-- Descrição do motivo de alteração salarial repetida

select list(i_motivos_altsal ) as motivoss, 
       trim(descricao) as descricaos, 
       count(descricao) as quantidade,
       mensagem_erro = 'Descrição de motivo de alteração salarial repetindo'
  from bethadba.motivos_altsal 
 group by descricaos
having quantidade > 1;


-- CORREÇÃO
-- Atualiza a descrição dos motivos de alteração salarial repetidos para evitar duplicidade

update bethadba.motivos_altsal
   set motivos_altsal.descricao = motivos_altsal.descricao || '-' || motivos_altsal.i_motivos_altsal
 where motivos_altsal.i_motivos_altsal in (select i_motivos_altsal
                                             from bethadba.motivos_altsal
                                            where (select count(i_motivos_altsal)
                                                     from bethadba.motivos_altsal m
                                                    where trim(m.descricao) = trim(motivos_altsal.descricao)) > 1);

-- FIM DO ARQUIVO FOLHA - Validação - 69.sql

-- FOLHA - Validação: FOLHA - Validação - 7.sql

-- VALIDAÇÃO 07  
-- Verifica dependente grau de parentesco(1-Filho(a)/6-Neto/8-Menor Tutelado/11-Bisneto) com data de nascimento MENOR que a do seu responsável.

select dependentes.i_pessoas resp ,
       p.dt_nascimento dt_resp, 
       dependentes.i_dependentes dep, 
       pdep.dt_nascimento dt_dep, 
       dependentes.grau grau_p
  from bethadba.dependentes 
  join bethadba.pessoas_fisicas p
    on (p.i_pessoas = dependentes.i_pessoas)
  join bethadba.pessoas_fisicas pdep
    on (pdep.i_pessoas = dependentes.i_dependentes)
 where dependentes.grau in (1, 6, 8, 11)
   and pdep.dt_nascimento < p.dt_nascimento;


-- CORREÇÃO
-- Atualiza a data de nascimento dos dependentes com grau de parentesco 1, 6, 8 ou 11 para ser igual à do responsável se a data de nascimento do dependente for menor que a do responsável

update bethadba.dependentes 
  join bethadba.pessoas_fisicas p
    on (p.i_pessoas = dependentes.i_pessoas)
  join bethadba.pessoas_fisicas pdep
    on (pdep.i_pessoas = dependentes.i_dependentes)
   set pdep.dt_nascimento = p.dt_nascimento
 where dependentes.grau in (1, 6, 8, 11)
   and pdep.dt_nascimento < p.dt_nascimento;

-- FIM DO ARQUIVO FOLHA - Validação - 7.sql

-- FOLHA - Validação: FOLHA - Validação - 70.sql

-- VALIDAÇÃO 70
-- retorna os funcionários que possuem férias com data de fim do gozo igual ou após a data da rescisão.

select ferias.i_entidades,
       ferias.i_funcionarios,
       ferias.dt_gozo_fin, 
       rescisoes.dt_rescisao
  from bethadba.ferias, 
       bethadba.rescisoes
 where ferias.i_entidades = rescisoes.i_entidades
   and ferias.i_funcionarios = rescisoes.i_funcionarios
   and ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;


-- CORREÇÃO
-- Atualiza a data de fim do gozo das férias para um dia antes da data de rescisão para os funcionários que possuem férias com data de fim do gozo igual ou após a data da rescisão.

update bethadba.ferias, bethadba.rescisoes
   set ferias.dt_gozo_fin = (rescisoes.dt_rescisao - 1)
 where ferias.i_entidades = rescisoes.i_entidades
   and ferias.i_funcionarios = rescisoes.i_funcionarios
   and ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;

-- FIM DO ARQUIVO FOLHA - Validação - 70.sql

-- FOLHA - Validação: FOLHA - Validação - 71.sql

-- VALIDAÇÃO 71
-- Informar a conta bancaria quando o pagamento for credito em conta

select hf.i_funcionarios,
       mensagem_erro = 'Permanece inconsistência'
  from bethadba.hist_funcionarios hf 
  join bethadba.afastamentos a
    on (hf.i_funcionarios = a.i_funcionarios)
 where hf.forma_pagto = 'R'
   and hf.i_pessoas_contas is null 
   and a.i_tipos_afast = 7;


-- CORREÇÃO
-- Atualiza a conta bancária dos funcionários com forma de pagamento 'R' (Crédito em conta) para a conta bancária correspondente na tabela pessoas_contas

update bethadba.hist_funcionarios hf
   set forma_pagto = 'D'
 where forma_pagto = 'R'
   and i_pessoas_contas is null;

-- FIM DO ARQUIVO FOLHA - Validação - 71.sql

-- FOLHA - Validação: FOLHA - Validação - 72.sql

-- VALIDAÇÃO 72
-- Verifica data fim na lotação física deve ser maior que a data início

select i_funcionarios,
       ('Local de trabalho - '||i_locais_trab||', do funcion�rio '||i_funcionarios||' esta com a data Inicio - '||dt_inicial||' maior que a data Fim - '||dt_final) as msg
  from bethadba.locais_mov
 where dt_inicial > dt_final;


-- CORREÇÃO
-- Atualiza a data fim para nulo quando a data início for maior que a data fim

update bethadba.locais_mov 
   set dt_final = null
 where dt_inicial > dt_final;

-- FIM DO ARQUIVO FOLHA - Validação - 72.sql

-- FOLHA - Validação: FOLHA - Validação - 73.sql

-- VALIDAÇÃO 73
-- Verifica dependente grau de parentesco(3-Pai/Mãe/4-Avô/Avó/12-Bisavô/Bisavó) com data de nascimento MAIOR que a do seu responsável

select dependentes.i_pessoas as resp,
       p.dt_nascimento as dt_resp, 
       dependentes.i_dependentes as dep, 
       pdep.dt_nascimento as dt_dep, 
       dependentes.grau as grau_p
  from bethadba.dependentes
  join bethadba.pessoas_fisicas as p
    on (p.i_pessoas = dependentes.i_pessoas)
  join bethadba.pessoas_fisicas as pdep
    on (pdep.i_pessoas = dependentes.i_dependentes)
 where dependentes.grau in (3,4,12)
   and pdep.dt_nascimento > p.dt_nascimento;


-- CORREÇÃO
-- Atualiza a data de nascimento dos dependentes com grau de parentesco 3, 4 ou 12 para ser igual à do responsável se a data de nascimento do dependente for maior que a do responsável

update bethadba.pessoas_fisicas
   set dt_nascimento = p.dt_nascimento
  from bethadba.dependentes
  join bethadba.pessoas_fisicas as p
    on (p.i_pessoas = dependentes.i_pessoas)
 where pessoas_fisicas.i_pessoas = dependentes.i_dependentes
   and dependentes.grau in (3,4,12)
   and pessoas_fisicas.dt_nascimento > p.dt_nascimento;

-- FIM DO ARQUIVO FOLHA - Validação - 73.sql

-- FOLHA - Validação: FOLHA - Validação - 74.sql

-- VALIDAÇÃO 74
-- Verifica vinculo com tipo diferente de outros do conselheiro tutelar

select funcionarios.i_entidades entidade,
       funcionarios.i_funcionarios func,
       vinculos.i_vinculos vinc
  from bethadba.funcionarios 
  join bethadba.hist_funcionarios
    on (funcionarios.i_entidades = hist_funcionarios.i_entidades
   and funcionarios.i_funcionarios = hist_funcionarios.i_funcionarios)
  join bethadba.vinculos
    on (hist_funcionarios.i_vinculos = vinculos.i_vinculos)
 where funcionarios.tipo_func = 'A'
   and funcionarios.conselheiro_tutelar = 'S'
   and vinculos.tipo_vinculo <> 3
   and hist_funcionarios.dt_alteracoes = (select max(dt_alteracoes)
                                            from bethadba.hist_funcionarios hf
                                           where hf.i_entidades = funcionarios.i_entidades
                                             and hf.i_funcionarios = funcionarios.i_funcionarios);


-- CORREÇÃO
-- Atualiza o tipo de vínculo para 3 (Conselheiro Tutelar) onde o funcionário é conselheiro tutelar e o tipo de vínculo é diferente de 3

update bethadba.vinculos
   set tipo_vinculo = 3
 where i_vinculos in (select vinculos.i_vinculos
                        from bethadba.funcionarios
                        join bethadba.hist_funcionarios
                          on (funcionarios.i_entidades = hist_funcionarios.i_entidades
                         and funcionarios.i_funcionarios = hist_funcionarios.i_funcionarios)
                        join bethadba.vinculos
                          on (hist_funcionarios.i_vinculos = vinculos.i_vinculos)
                       where funcionarios.tipo_func = 'A'
                         and funcionarios.conselheiro_tutelar = 'S'
                         and vinculos.tipo_vinculo <> 3
                         and hist_funcionarios.dt_alteracoes = (select max(dt_alteracoes)
                                                                  from bethadba.hist_funcionarios hf
                                                                 where hf.i_entidades = funcionarios.i_entidades
                                                                   and hf.i_funcionarios = funcionarios.i_funcionarios));

-- FIM DO ARQUIVO FOLHA - Validação - 74.sql

-- FOLHA - Validação: FOLHA - Validação - 75.sql

-- VALIDAÇÃO 75
-- Verifica Estagiário(s) sem número da apólice de seguro informado

select estagios.i_funcionarios
  from bethadba.estagios
 where num_apolice is null;


-- CORREÇÃO
-- Atualiza o número da apólice de seguro dos estagiários que não possuem número da apólice informado para 0

update bethadba.hist_funcionarios
   set num_apolice_estagio = 0
 where num_apolice_estagio is null 
   and i_funcionarios in (select estagios.i_funcionarios
   					                from bethadba.estagios
          				         where num_apolice is null);

update bethadba.estagios
   set num_apolice = 0
 where num_apolice is null;

-- FIM DO ARQUIVO FOLHA - Validação - 75.sql

-- FOLHA - Validação: FOLHA - Validação - 76.sql

-- VALIDAÇÃO 76
-- Verifica Estagiário(s) sem agente de integração informado

select estagios.i_entidades entidade, 
       estagios.i_funcionarios func,
       hist_funcionarios.dt_alteracoes dt_alt, 
       hist_funcionarios.i_agente_integracao_estagio
  from bethadba.estagios
  join bethadba.hist_funcionarios
    on (estagios.i_entidades = hist_funcionarios.i_entidades
   and estagios.i_funcionarios = hist_funcionarios.i_funcionarios)
 where hist_funcionarios.i_agente_integracao_estagio is null
 order by estagios.i_entidades, 
          estagios.i_funcionarios, 
          hist_funcionarios.dt_alteracoes;


-- CORREÇÃO
-- Atualiza o agente de integração dos estagiários para uma entidade educacional padrão

begin
  -- Variável para armazenar o novo i_pessoas
  declare @nova_entidade int;

  -- Insere entidade educacional se não existir e captura o novo i_pessoas
  if not exists (select 1 from bethadba.pessoas where nome = 'Entidade Educacional') then
    insert into bethadba.pessoas (i_pessoas,dv,nome,nome_fantasia,tipo_pessoa,ddd,telefone,fax,ddd_cel,celular,inscricao_municipal,email,cod_unificacao,nome_social,considera_nome_social_fly)
    select (select coalesce(max(i_pessoas), 0) + 1 from bethadba.pessoas), null, 'Entidade Educacional', null, 'J', null, null, null, null, null, null, null, null, null, 'N';
    set @nova_entidade = (select max(i_pessoas) from bethadba.pessoas where nome = 'Entidade Educacional');
  else
    set @nova_entidade = (select i_pessoas from bethadba.pessoas where nome = 'Entidade Educacional');
  end if;

  update bethadba.hist_funcionarios
     set i_agente_integracao_estagio = @nova_entidade
   where i_agente_integracao_estagio is null
     and exists (
       select 1
         from bethadba.estagios
        where estagios.i_entidades = hist_funcionarios.i_entidades
          and estagios.i_funcionarios = hist_funcionarios.i_funcionarios
     );
end

-- FIM DO ARQUIVO FOLHA - Validação - 76.sql

-- FOLHA - Validação: FOLHA - Validação - 77.sql

-- VALIDAÇÃO 77
-- Verifica Estagiário(s) sem responsável informado
                  
select estagios.i_entidades entidade, 
       estagios.i_funcionarios func
  from bethadba.estagios,
       bethadba.hist_funcionarios
 where hist_funcionarios.i_entidades = estagios.i_entidades
   and hist_funcionarios.i_funcionarios = estagios.i_funcionarios
   and hist_funcionarios.i_supervisor_estagio is null
   and hist_funcionarios.dt_alteracoes = (select max(dt_alteracoes)
   											from bethadba.hist_funcionarios hf
                                           where hf.i_entidades = estagios.i_entidades
                                             and hf.i_funcionarios = estagios.i_funcionarios)
 order by estagios.i_entidades,
          estagios.i_funcionarios;


-- CORREÇÃO
-- Atualiza o supervisor de estágio para o funcionário correspondente, onde o supervisor de estágio é nulo
 
update bethadba.hist_funcionarios 
   set hist_funcionarios.i_supervisor_estagio = (select i_pessoas
                                                   from bethadba.funcionarios
                                                  where hist_funcionarios.i_entidades = funcionarios.i_entidades
                                                    and hist_funcionarios.i_funcionarios = funcionarios.i_funcionarios)
 where bethadba.hist_funcionarios.i_funcionarios in(select hist_funcionarios.i_funcionarios
													  from bethadba.estagios, bethadba.hist_funcionarios
													 where hist_funcionarios.i_entidades = estagios.i_entidades
													   and hist_funcionarios.i_funcionarios = estagios.i_funcionarios
													   and hist_funcionarios.i_supervisor_estagio is null
													   and hist_funcionarios.dt_alteracoes = (select max(dt_alteracoes)
													   											from bethadba.hist_funcionarios hf
												                                               where hf.i_entidades = estagios.i_entidades
                                                												 and hf.i_funcionarios = estagios.i_funcionarios)
													 order by estagios.i_entidades,
															  estagios.i_funcionarios);

-- FIM DO ARQUIVO FOLHA - Validação - 77.sql

-- FOLHA - Validação: FOLHA - Validação - 78.sql

-- VALIDAÇÃO 78
-- Tipo de afastamento deve possuir movimentação de pessoal quando possuir um ato

select af.i_entidades entidade,
       af.i_funcionarios func, 
       af.dt_afastamento dt_afast, 
       af.i_tipos_afast tp_afast
  from bethadba.afastamentos af,
       bethadba.tipos_afast ta
 where af.i_tipos_afast = ta.i_tipos_afast
   and af.i_atos is not null
   and ta.i_tipos_movpes is null
   and ta.i_tipos_afast <> 7
 order by af.i_entidades, af.i_funcionarios, af.dt_afastamento;


-- CORREÇÃO
-- Criar um tipo de movimentação de pessoal genérico para atualizar os tipos de afastamentos
insert into bethadba.tipos_movpes (i_tipos_movpes, descricao, classif, codigo_tce)
values ((select max(i_tipos_movpes) + 1 from bethadba.tipos_movpes),'Afastamento - Genérico',0,null);

-- Atualiza os tipos de afastamento para que possuam a movimentação de pessoal genérica vinculada
update bethadba.tipos_afast
   set i_tipos_movpes = (select max(i_tipos_movpes)
                           from bethadba.tipos_movpes
                          where descricao = 'Afastamento - Genérico')
 where i_tipos_movpes is null
   and i_tipos_afast <> 7;

-- FIM DO ARQUIVO FOLHA - Validação - 78.sql

-- FOLHA - Validação: FOLHA - Validação - 79.sql

-- VALIDAÇÃO 79
-- Funcionarios em férias no dia da rescisão

select rescisoes.i_entidades entidade, 
       rescisoes.i_funcionarios func, 
       rescisoes.dt_rescisao dt_resc, 
       ferias.dt_gozo_ini dt_ini_gozo, 
       ferias.dt_gozo_fin dt_fin_gozo
  from bethadba.rescisoes
  join bethadba.ferias
    on (ferias.i_entidades = rescisoes.i_entidades
   and ferias.i_funcionarios = rescisoes.i_funcionarios)
 where rescisoes.dt_canc_resc is null
   and rescisoes.dt_rescisao >= ferias.dt_gozo_ini
   and rescisoes.dt_rescisao <= ferias.dt_gozo_fin;


-- CORREÇÃO
-- Atualiza a data de rescisão para o dia seguinte ao término do gozo de férias

update bethadba.rescisoes, bethadba.ferias
   set bethadba.rescisoes.dt_rescisao = dateadd(day, 1, dt_gozo_fin)
 where bethadba.ferias.i_entidades = rescisoes.i_entidades
   and bethadba.ferias.i_funcionarios = rescisoes.i_funcionarios
   and bethadba.ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;

-- FIM DO ARQUIVO FOLHA - Validação - 79.sql

-- FOLHA - Validação: FOLHA - Validação - 8.sql

-- VALIDAÇÃO 08  
-- Verifica os CPF's repetidos

select list(pf.i_pessoas) as ipessoa,
       cpf,
       count(cpf) as quantidade
  from bethadba.pessoas_fisicas pf 
 group by cpf 
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os CPF's repetidos para nulo, mantendo apenas o maior i_pessoas

update bethadba.pessoas_fisicas
   set cpf = null
 where i_pessoas in (select maior.numPessoa
 					   from (select max(i_pessoas) as numPessoa,
 					   			    cpf
          					   from bethadba.pessoas_fisicas
          					  where (select count(1)
        					  		   from bethadba.pessoas_fisicas as pf
        					  		  where pf.cpf = pessoas_fisicas.cpf) > 1
							  group by cpf) as maior);

-- FIM DO ARQUIVO FOLHA - Validação - 8.sql

-- FOLHA - Validação: FOLHA - Validação - 80.sql

-- VALIDAÇÃO 80
-- Campo observação do motivo do cancelamento de férias com mais de 50 caracteres

select periodos_ferias.i_entidades entidade, 
       periodos_ferias.i_funcionarios func, 
       periodos_ferias.i_periodos periodo, 
       periodos_ferias.dt_periodo dt_per,
       periodos_ferias.observacao
  from bethadba.periodos_ferias 
 where periodos_ferias.tipo = 5
   and length(observacao) > 50;


-- CORREÇÃO
-- Atualiza o campo observação do motivo do cancelamento de férias para nulo (considerando que o campo observação é do tipo texto longo e não deve ter mais de 50 caracteres)

update bethadba.periodos_ferias
   set observacao = null
 where length(observacao) > 50;

-- FIM DO ARQUIVO FOLHA - Validação - 80.sql

-- FOLHA - Validação: FOLHA - Validação - 81.sql

-- VALIDAÇÃO 81
-- Inscrição municipal da pessoa Juridica maior que 9 digitos

select i_pessoas as pessoa 
  from bethadba.pessoas
 where tipo_pessoa = 'J' 
   and length(inscricao_municipal) > 9;


-- CORREÇÃO
-- Atualiza a inscrição municipal para '0' onde o tipo de pessoa é 'J' e a inscrição municipal tem mais de 9 dígitos

update bethadba.pessoas
   set inscricao_municipal = '0'
 where tipo_pessoa = 'J'
   and length(inscricao_municipal) > 9;

-- FIM DO ARQUIVO FOLHA - Validação - 81.sql

-- FOLHA - Validação: FOLHA - Validação - 82.sql

-- VALIDAÇÃO 82
-- Verifica Cnpj Inválido

select i_pessoas as pessoa
  from bethadba.pessoas_juridicas
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;


-- CORREÇÃO
-- Atualiza o CNPJ inválido para um CNPJ válido fictício

update bethadba.pessoas_juridicas
   set cnpj = right('000000000000' || cast((row_number() over (order by i_pessoas)) as varchar(12)), 12) || '91'
 where cnpj is not null
   and bethadba.dbf_valida_cgc_cpf(cnpj, null, 'J') = 0;

-- FIM DO ARQUIVO FOLHA - Validação - 82.sql

-- FOLHA - Validação: FOLHA - Validação - 83.sql

-- VALIDAÇÃO 83
-- Veririca pessoas jurídicas com cnpjs duplicados

select p.i_pessoas as pessoa, 
       p.nome as nome,
       pj.cnpj as cnpj
  from bethadba.pessoas as p,
  	   bethadba.pessoas_juridicas as pj
 where p.i_pessoas = pj.i_pessoas
   and pj.cnpj in (select distinct pessoas_juridicas.cnpj
                     from bethadba.pessoas_juridicas
                    group by pessoas_juridicas.cnpj
                   having count(pessoas_juridicas.cnpj) > 1);


-- CORREÇÃO
-- Atualiza os CNPJs duplicados para um CNPJ fictício, porém válido, para posterior correção manual
-- Gera CNPJs fictícios únicos para cada registro duplicado
-- Exemplo usando ROW_NUMBER para gerar sufixos únicos (ajuste conforme o SGBD se necessário)

-- Gera CNPJs fictícios únicos para cada registro duplicado usando uma tabela derivada com ROW_NUMBER
update bethadba.pessoas_juridicas pj
   set cnpj = '99999999' || right('0000' || cast(dup.rn as varchar(4)), 4) || '91'
  from (
        select i_pessoas,
               row_number() over (partition by cnpj order by i_pessoas) as rn
          from bethadba.pessoas_juridicas
         where cnpj in (select cnpj
                          from bethadba.pessoas_juridicas
                         group by cnpj
                        having count(*) > 1)
       ) as dup
 where pj.i_pessoas = dup.i_pessoas
   and dup.rn > 1;

-- FIM DO ARQUIVO FOLHA - Validação - 83.sql

-- FOLHA - Validação: FOLHA - Validação - 84.sql

-- VALIDAÇÃO 84
-- Pessoas fisicas com data de nascimento nula 

select f.i_pessoas as pessoa
  from bethadba.pessoas_fisicas f
  join bethadba.dependentes d
    on (d.i_pessoas = f.i_pessoas)
 where f.dt_nascimento is null
 group by f.i_pessoas;


-- CORREÇÃO
-- Atualiza a data de nascimento das pessoas fisicas com base na data de alteração mais recente do histórico de pessoas, subtraindo 18 anos.

update bethadba.pessoas_fisicas pf
   set pf.dt_nascimento = DATEADD(year, -18, max(hpf.dt_alteracoes))
  from bethadba.dependentes d
  join bethadba.hist_pessoas_fis hpf
    on hpf.i_pessoas = d.i_pessoas
 where pf.i_pessoas = d.i_pessoas
   and pf.dt_nascimento is null
 group by pf.i_pessoas;

-- FIM DO ARQUIVO FOLHA - Validação - 84.sql

-- FOLHA - Validação: FOLHA - Validação - 85.sql

-- VALIDAÇÃO 85
-- Pessoas fisicas com nome da afiliação repetidos

select i_pessoas as pessoa,
       nome_pai as nm_pai,
       nome_mae as nm_mae
  from bethadba.pessoas_fis_compl 
 where nome_pai = nome_mae 
   and nome_pai is not null 
   and nome_pai <> '';


-- CORREÇÃO
-- Atualiza o nome do pai para um valor fictício quando o nome do pai é igual ao nome da mãe e o nome do pai não é nulo ou vazio.

update bethadba.pessoas_fis_compl
   set nome_pai = 'PAI_FICTICIO_' || cast(i_pessoas as varchar)
 where nome_pai = nome_mae
   and nome_pai is not null
   and nome_pai <> '';

-- FIM DO ARQUIVO FOLHA - Validação - 85.sql

-- FOLHA - Validação: FOLHA - Validação - 86.sql

-- VALIDAÇÂO 86
-- Pessoas fisicas com email incorreto

select i_pessoas as pessoa, 
       email
  from bethadba.pessoas
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;


-- CORREÇÃO
-- Corrige o email para NULL se for inválido

update bethadba.pessoas
   set email = 'ficticio_' || cast(i_pessoas as varchar) || '@dominiofalso.com'
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;

-- FIM DO ARQUIVO FOLHA - Validação - 86.sql

-- FOLHA - Validação: FOLHA - Validação - 87.sql

-- VALIDAÇÃO 87
-- Dependente é a mesma pessoa que o responsavel

select pf.i_pessoas as pessoa,
	   p.nome as nm,
	   pf.cpf as cpf, 
	   dep.i_pessoas as pessoa_dep, 
	   pdep.nome nm_dep, 
	   dep.cpf cpf_dep
  from bethadba.dependentes,
  	   bethadba.pessoas_fisicas pf,
  	   bethadba.pessoas p,
  	   bethadba.pessoas_fisicas dep,
  	   bethadba.pessoas pdep
 where pf.i_pessoas = dependentes.i_pessoas
   and pf.i_pessoas = p.i_pessoas
   and dep.i_pessoas = dependentes.i_dependentes
   and dep.i_pessoas = pdep.i_pessoas
   and ((dep.cpf = pf.cpf) or (pdep.nome = p.nome));


-- CORREÇÃO
-- Exclui o dependente que é a mesma pessoa que o responsável

delete from bethadba.dependentes
 where exists (select 1
	  			 from bethadba.pessoas_fisicas pf
	  			 join bethadba.pessoas_fisicas dep
				   on dep.i_pessoas = dependentes.i_dependentes
	  			 join bethadba.pessoas p
				   on p.i_pessoas = pf.i_pessoas
	  			 join bethadba.pessoas pdep
				   on pdep.i_pessoas = dep.i_pessoas
	 			where pf.i_pessoas = dependentes.i_pessoas
	   			  and ((dep.cpf = pf.cpf) or (pdep.nome = p.nome)));

-- FIM DO ARQUIVO FOLHA - Validação - 87.sql

-- FOLHA - Validação: FOLHA - Validação - 88.sql

-- VALIDAÇÃO 88
-- Dependentes com a data de inicio de dependencia menor que a data de nascimento

select dependentes.i_pessoas as pessoa, 
       dependentes.i_dependentes as dep, 
       dependentes.dt_ini_depende as dt_ini_dep, 
       pessoas_fisicas.dt_nascimento as dt_nasc
  from bethadba.dependentes,
  	   bethadba.pessoas_fisicas
 where dependentes.i_dependentes = pessoas_fisicas.i_pessoas
   and dependentes.dt_ini_depende is not null
   and dependentes.dt_ini_depende < pessoas_fisicas.dt_nascimento;


-- CORREÇÃO
-- Atualiza a data de início de dependência para ser igual à data de nascimento do dependente se a data de início de dependência for menor que a data de nascimento

update bethadba.dependentes
   set dt_ini_depende = dt_nascimento
  from bethadba.dependentes d,
       bethadba.pessoas_fisicas pf
 where d.i_dependentes = pf.i_pessoas
   and d.dt_ini_depende < pf.dt_nascimento;

-- FIM DO ARQUIVO FOLHA - Validação - 88.sql

-- FOLHA - Validação: FOLHA - Validação - 89.sql

-- VALIDAÇÃO 89
-- Verificar dependentes com data de casamento menor que a data de nascimento do dependente

select dependentes.i_pessoas as pessoa,
       dependentes.i_dependentes as dep, 
       dependentes.dt_casamento as dt_casam, 
       pessoas_fisicas.dt_nascimento as dt_nasc
  from bethadba.dependentes, bethadba.pessoas_fisicas
 where dependentes.i_dependentes = pessoas_fisicas.i_pessoas
   and dependentes.dt_casamento is not null
   and dependentes.dt_casamento < pessoas_fisicas.dt_nascimento;


-- CORREÇÃO
-- Atualiza a data de casamento dos dependentes para nulo se a data de casamento for menor que a data de nascimento do dependente

update bethadba.dependentes
   set dt_casamento = null
  from bethadba.dependentes d,
       bethadba.pessoas_fisicas pf
 where d.i_dependentes = pf.i_pessoas
   and d.dt_casamento < pf.dt_nascimento;

-- FIM DO ARQUIVO FOLHA - Validação - 89.sql

-- FOLHA - Validação: FOLHA - Validação - 9.sql

-- VALIDAÇÃO 09  
-- Verifica os PIS's repetidos

select list(pf.i_pessoas) as idpessoa,
       num_pis,
       count(num_pis) as quantidade
  from bethadba.pessoas_fisicas as pf 
 group by num_pis
having quantidade > 1;


-- CORREÇÃO
-- Atualiza os PIS's repetidos para nulo, mantendo apenas o maior i_pessoas
               
update bethadba.pessoas_fisicas as pf
   set pf.num_pis = null
 where (select count(pf2.num_pis)
          from bethadba.pessoas_fisicas as pf2
         where pf2.num_pis = pf.num_pis) > 1
   and pf.i_pessoas < (select max(pf3.i_pessoas)
                          from bethadba.pessoas_fisicas as pf3
                         where pf3.num_pis = pf.num_pis);
 
update bethadba.hist_pessoas_fis as hpf
   set hpf.num_pis = pf.num_pis
  from bethadba.pessoas_fisicas as pf
 where isnull(hpf.num_pis, '') <> isnull(pf.num_pis, '')
   and hpf.i_pessoas = pf.i_pessoas;

-- FIM DO ARQUIVO FOLHA - Validação - 9.sql

-- FOLHA - Validação: FOLHA - Validação - 90.sql

-- VALIDAÇÃO 90
-- O campo do codigoesocial esta duplicado

select a.i_entidades as entidades,
       a.codigo_esocial as codigo_esocial,
       count(codigo_esocial) as total
  from bethadba.funcionarios as a
 group by entidades, codigo_esocial
having total > 1;


-- CORREÇÃO
-- Atualiza o campo codigo_esocial para remover o último digito e adicionar o correto se o último digito for 2, adiciona 3, se for 1, adiciona 2
-- A atualização é feita apenas para os funcionarios que possuem o codigo_esocial duplicado

update bethadba.funcionarios 
   set codigo_esocial = (substring(codigo_esocial,0, length(codigo_esocial) -1) || case when substring(codigo_esocial,length(codigo_esocial)) = 2 then 3 when substring(codigo_esocial,length(codigo_esocial)) = 1 then 2 end)
 where i_funcionarios in (select funcionarios
                            from (select max(f.i_funcionarios) as funcionarios,
                                         teste.codigo_esocial
                                    from (select a.i_entidades as entidades,
                                                 a.codigo_esocial as codigo_esocial,
                                                 count(codigo_esocial) as total
                                            from bethadba.funcionarios as a
                                           group by entidades, codigo_esocial
                                          having total > 1) as teste
                                    join bethadba.funcionarios f
                                      on (f.codigo_esocial = teste.codigo_esocial)
                                   group by teste.codigo_esocial) as correto);

-- FIM DO ARQUIVO FOLHA - Validação - 90.sql

-- FOLHA - Validação: FOLHA - Validação - 91.sql

-- VALIDAÇÃO 91
-- Deve haver no máximo um local de trabalho principal

select  principal = if isnull(locais_mov.principal,'N') = 'S' then 'true' else 'false' endif,
        dataInicio = dt_inicial,
        dataFim = dt_final,
        i_funcionarios func,
        count(principal) as total,
        max(i_locais_trab)
   from bethadba.locais_mov
  where i_funcionarios = i_funcionarios 
    and i_entidades = i_entidades
    and principal = 'true'
  group by principal, dataInicio, dataFim, principal, i_funcionarios
 having total > 1
  order by locais_mov.i_funcionarios;


-- CORREÇÃO
-- Atualiza o campo principal para 'N' para todos os locais de trabalho dos funcionarios e depois atualiza para 'S' apenas o local de trabalho com a maior data de início

update bethadba.locais_mov
   set principal = 'N';

update bethadba.locais_mov
   set principal = 'S'
 where dt_inicial = (select max(lm.dt_inicial)
                       from bethadba.locais_mov as lm
                      where lm.i_funcionarios = i_funcionarios
                        and lm.i_entidades = i_entidades);

-- FIM DO ARQUIVO FOLHA - Validação - 91.sql

-- FOLHA - Validação: FOLHA - Validação - 92.sql

-- VALIDAÇÃO 92
-- Funcionarios sem local de trabalho principal

select principal = if isnull(locais_mov.principal,'N') = 'S' then 'true' else 'false' endif,
       i_funcionarios func,
       count(principal) as total
  from bethadba.locais_mov
 where i_funcionarios = i_funcionarios 
   and i_entidades = i_entidades
   and principal = 'false'
   and i_funcionarios not in (select lm.i_funcionarios      
                                from bethadba.locais_mov lm
                               where lm.i_funcionarios = locais_mov.i_funcionarios 
                                 and lm.i_entidades = locais_mov.i_entidades
                                 and lm.principal = 'S')
 group by principal, i_funcionarios
having total > 1
 order by locais_mov.i_funcionarios;


-- CORREÇÃO
-- Atualiza o local de trabalho principal para os funcionarios que não possuem um definido
-- Atribui o local de trabalho com maior i_locais_trab como principal

update bethadba.locais_mov
   set principal = 'S'
 where i_funcionarios = i_funcionarios 
   and i_entidades = i_entidades
   and principal = 'N'
   and i_locais_trab = (select max(i_locais_trab)
                          from bethadba.locais_mov lm
                         where lm.i_funcionarios = locais_mov.i_funcionarios 
                           and lm.i_entidades = locais_mov.i_entidades
                           and lm.principal = 'N')
   and i_funcionarios not in (select lm.i_funcionarios      
                                from bethadba.locais_mov lm
                               where lm.i_funcionarios = locais_mov.i_funcionarios 
                                 and lm.i_entidades = locais_mov.i_entidades
                                 and lm.principal = 'S');

-- FIM DO ARQUIVO FOLHA - Validação - 92.sql

-- FOLHA - Validação: FOLHA - Validação - 93.sql

-- VALIDAÇÃO 93
-- Históricos na matricula posterior a data de cessação da aposentadoria

/* RODAR VARIAS VEZES */
select distinct funcionarios.i_entidades as chave_dsk1,
       			funcionarios.i_funcionarios as chave_dsk2,
        		tipo as chave_dsk3,
        		dataAlteracao = hist_funcionarios.dt_alteracoes,
        		inicioVigencia = hist_funcionarios.dt_alteracoes,
        		codigoMatriculaNumero = if(select ctr_contrato_matric from bethadba.parametros_folha) = 'S' then string(left(funcionarios.i_funcionarios,length(funcionarios.i_funcionarios)-(select digitos_matric from bethadba.parametros_folha))) else string(funcionarios.i_funcionarios) endif,
        		codigoMatriculaContrato = if(select ctr_contrato_matric from bethadba.parametros_folha) = 'S' then string(right(funcionarios.i_funcionarios,(select digitos_matric from bethadba.parametros_folha))) else ' ' endif,
        		codigoMatriculaDigitoVerificador = funcionarios.dv,
        		numero = codigoMatriculaNumero,
        		contrato = codigoMatriculaContrato,
        		tipo = 'APOSENTADO',
        		rendimentoMensal = isnull((select sum(valor)
        									 from bethadba.calc_apos_pens cap
        									where cap.i_entidades = funcionarios.i_entidades
                                              and cap.i_funcionarios = funcionarios.i_funcionarios),
                                   		  (select hs.salario
                                   		     from bethadba.hist_salariais hs
                                   		    where hs.i_entidades = funcionarios.i_entidades
                                   		      and hs.i_funcionarios = funcionarios.i_funcionarios
                                   		      and hs.dt_alteracoes = bethadba.dbf_getdatahissal(funcionarios.i_entidades, funcionarios.i_funcionarios, getdate()))),
       			atoAposentadoria = (select max(aposent_pensoes.i_atos)
       								   from bethadba.aposent_pensoes
       								  where funcionarios.i_entidades = aposent_pensoes.i_entidades
       								    and funcionarios.i_funcionarios = aposent_pensoes.i_funcionarios),    
         		dataCessacaoAposentadoria = isnull(rescisoes.dt_canc_resc,(select resc.dt_rescisao
                                                                   		     from bethadba.rescisoes resc
                                                                   		     join bethadba.motivos_resc mot
                                                                   		       on (resc.i_motivos_resc = mot.i_motivos_resc)
                                                                            where resc.i_entidades = funcionarios.i_entidades
                                                                        	  and resc.i_funcionarios = funcionarios.i_funcionarios
                                                                       		  and mot.dispensados = 4                                
                                                                       		  and resc.dt_canc_resc is null)),
        		situacao = if dataCessacaoAposentadoria is not null then 'CESSADO' else 'APOSENTADO' endif                                                                    
    	   from bethadba.funcionarios ,
        		bethadba.hist_funcionarios , 
        		bethadba.rescisoes , 
        		bethadba.motivos_resc , 
        		bethadba.motivos_apos ,
        		bethadba.tipos_afast
    	  where funcionarios.i_entidades = rescisoes.i_entidades
    	    and funcionarios.i_funcionarios = rescisoes.i_funcionarios
    	    and funcionarios.i_entidades = hist_funcionarios.i_entidades
    	    and funcionarios.i_funcionarios = hist_funcionarios.i_funcionarios
    	    and hist_funcionarios.dt_alteracoes = bethadba.dbf_getdatahisfun(funcionarios.i_entidades, funcionarios.i_funcionarios, getdate())
    	    and rescisoes.i_motivos_resc = motivos_resc.i_motivos_resc
    	    and rescisoes.i_motivos_apos = motivos_apos.i_motivos_apos
    	    and motivos_apos.i_tipos_afast = tipos_afast.i_tipos_afast
    	    and tipos_afast.classif = 9
    	    and datacessacaoaposentadoria < dataalteracao;


-- CORREÇÃO
-- Exclui os registros de histórico de funcionários e de histórico de funcionários com proventos adicionais que estejam com data de alteração posterior a data de cessação da aposentadoria

delete from bethadba.hist_funcionarios
 where exists (select 1
				 from bethadba.funcionarios f
				 join bethadba.rescisoes r
				   on f.i_entidades = r.i_entidades
				  and f.i_funcionarios = r.i_funcionarios
				 join bethadba.motivos_resc mr
				   on r.i_motivos_resc = mr.i_motivos_resc
				 join bethadba.motivos_apos ma
				   on r.i_motivos_apos = ma.i_motivos_apos
				 join bethadba.tipos_afast ta
				   on ma.i_tipos_afast = ta.i_tipos_afast
				where ta.classif = 9
				  and f.i_entidades = hist_funcionarios.i_entidades
				  and f.i_funcionarios = hist_funcionarios.i_funcionarios
				  and hist_funcionarios.dt_alteracoes > isnull(r.dt_canc_resc, (select resc.dt_rescisao
																	   			  from bethadba.rescisoes resc
																				  join bethadba.motivos_resc mot
																					on resc.i_motivos_resc = mot.i_motivos_resc
																				 where resc.i_entidades = f.i_entidades
																				   and resc.i_funcionarios = f.i_funcionarios
																				   and mot.dispensados = 4
																				   and resc.dt_canc_resc is null)));

-- FIM DO ARQUIVO FOLHA - Validação - 93.sql

-- FOLHA - Validação: FOLHA - Validação - 94.sql

-- VALIDAÇÃO 94
-- Vinculo empregaticio CLT sem opção federal marcada

select distinct i_entidades,
	   i_funcionarios
  from bethadba.hist_funcionarios,
       bethadba.vinculos
 where hist_funcionarios.i_vinculos = vinculos.i_vinculos
   and tipo_vinculo = 1
   and prev_federal = 'N';


-- CORREÇÃO
-- Atualiza o campo prev_federal para 'S' e fundo_prev para 'N' para os vínculos empregatícios CLT que não possuem opção federal marcada

update bethadba.hist_funcionarios 
 inner join bethadba.vinculos v
    on (hist_funcionarios.i_vinculos = v.i_vinculos)
   set prev_federal = 'S', fundo_prev = 'N'
 where hist_funcionarios.i_vinculos = v.i_vinculos
   and v.tipo_vinculo = 1
   and hist_funcionarios.prev_federal = 'N';

-- FIM DO ARQUIVO FOLHA - Validação - 94.sql

-- FOLHA - Validação: FOLHA - Validação - 95.sql

-- VALIDAÇÃO 95
-- Data inicial do beneficio menor que a data da admissão

select funcionarios.i_entidades,funcionarios.i_funcionarios
  from bethadba.emprestimos,
       bethadba.funcionarios
 where funcionarios.i_entidades = emprestimos.i_entidades
   and funcionarios.i_funcionarios = emprestimos.i_funcionarios
   and dt_admissao > dt_emprestimo;


-- CORREÇÃO
-- Atualiza a data do empréstimo para a data de admissão do funcionário
-- Atenção: essa correção deve ser feita com cautela, pois pode afetar registros de empréstimos já processados.
-- Certifique-se de que essa alteração é apropriada para o contexto do seu sistema.

update bethadba.emprestimos a
   set dt_emprestimo = dt_admissao
  from bethadba.funcionarios b
 where dt_admissao > dt_emprestimo
   and a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios;

-- FIM DO ARQUIVO FOLHA - Validação - 95.sql

-- FOLHA - Validação: FOLHA - Validação - 96.sql

-- VALIDAÇÃO 96
-- Pensionista menor de idade sem responsavel informado

select beneficiarios.i_funcionarios as Matriculas,
       pessoas_fisicas.i_pessoas as PessoasFisicas,
       pessoas_fisicas.dt_nascimento as DataNascimento,
       datename(year, getdate()) - datename(year, dt_nascimento) as IdadePensionista,
       (select i_pessoas
          from bethadba.beneficiarios_repres_legal brl
         where beneficiarios.i_entidades = brl.i_entidades
           and beneficiarios.i_funcionarios = brl.i_funcionarios) as responsavel,
       data_recebido
  from bethadba.beneficiarios,
       bethadba.funcionarios,
       bethadba.pessoas_fisicas
 where funcionarios.i_funcionarios = beneficiarios.i_funcionarios
   and pessoas_fisicas.i_pessoas = funcionarios.i_pessoas
   and idadePensionista < 18 
   and responsavel is null;


-- CORREÇÃO
-- Insere um responsável legal para o beneficiário menor de idade

insert into bethadba.beneficiarios_repres_legal (i_entidades, i_funcionarios, i_pessoas, tipo, dt_inicial, dt_final)
values (2, 292, 2835, 5, 2020-09-01, null);

-- FIM DO ARQUIVO FOLHA - Validação - 96.sql

-- FOLHA - Validação: FOLHA - Validação - 97.sql

-- VALIDAÇÃO 97
-- Numero da certidão maior que 32 caracteres

select i_pessoas,
       modelo = if isnumeric(bethadba.dbf_retira_caracteres_especiais(pessoas_fis_compl.num_reg)) = 1 then
					'NOVO'
                else
                    'ANTIGO'
                endif,
       numeroNascimento = if modelo = 'ANTIGO' then 
							pessoas_fis_compl.num_reg 
                          else
                            bethadba.dbf_retira_alfa_de_inteiros(pessoas_fis_compl.num_reg)
                          endif
  from bethadba.pessoas_fis_compl
 where numeroNascimento is not null 
   and modelo = 'NOVO'
   and (length(numeroNascimento) > 32 or length(numeroNascimento) < 32);


-- CORREÇÃO
-- Atualiza o campo num_reg para que tenha exatamente 32 caracteres, preenchendo com zeros à esquerda

update bethadba.pessoas_fis_compl
   set num_reg = replicate('0', 32 - length(bethadba.dbf_retira_caracteres_especiais(num_reg))) + bethadba.dbf_retira_caracteres_especiais(num_reg)
 where length(bethadba.dbf_retira_caracteres_especiais(num_reg)) < 32
   and num_reg is not null;

-- FIM DO ARQUIVO FOLHA - Validação - 97.sql

-- FOLHA - Validação: FOLHA - Validação - 98.sql

-- VALIDAÇÃO 98
-- Telefone com mais de 11 caracteres na lotação fisica

select i_entidades,
       i_locais_trab,
       fone,
       length(fone) as quantidade
  from bethadba.locais_trab
 where quantidade > 11;


-- CORREÇÃO
-- Atualiza o campo fone para que tenha no máximo 8 caracteres, removendo caracteres especiais e espaços

update bethadba.locais_trab
   set fone = right(trim(replace(replace(replace(fone,'-',''),'(',''),')','')),8)
 where length(fone) > 9;

-- FIM DO ARQUIVO FOLHA - Validação - 98.sql

-- FOLHA - Validação: FOLHA - Validação - 99.sql

-- VALIDAÇÃO 99
-- Configuração do organograma sem niveis

select i_config_organ,
       nivel_unid
  from bethadba.config_organ co 
 where nivel_unid is null;


-- CORREÇÃO
-- Atualiza o nivel_unid para 1 onde ele é nulo

update bethadba.config_organ
   set nivel_unid = 1
 where nivel_unid is null;

-- FIM DO ARQUIVO FOLHA - Validação - 99.sql

