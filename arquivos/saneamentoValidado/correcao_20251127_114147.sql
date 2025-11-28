call bethadba.dbp_conn_gera (1, year(today()), 300, 0);
call bethadba.pg_setoption('fire_triggers','off');
call bethadba.pg_setoption('wait_for_COMMIT','on');
commit;

-- FOLHA - Validação - 102

-- Insere os logradouros na tabela ruas e atualiza o código das ruas na tabela pessoas_enderecos

begin
  declare w_pessoa integer;
  declare w_nome_rua varchar(120);
  declare w_conta integer;
 
  set w_conta = (select max(i_ruas)
  				         from bethadba.ruas); -- Informar aqui o último código de logradouro cadastrado no sistema
 
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

commit;

-- FOLHA - Validação - 11

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

commit;

-- FOLHA - Validação - 127

-- Atualiza os campos CNPJ que estão nulos para 0 para que não sejam considerados na validação e não gere erro de validação.

update bethadba.bethadba.rais_campos
   set CNPJ = right('000000000000' || cast((row_number() over) as varchar(12)), 12) || '91'
 where CNPJ is null;

commit;

-- FOLHA - Validação - 131

-- Atualiza a data de alterações para 18 anos após a data de nascimento para os registros onde a data de nascimento é maior que a data de alterações

update bethadba.hist_pessoas_fis
   set dt_alteracoes = DATEADD(year, 18, dt_nascimento)
 where dt_nascimento > dt_alteracoes;

commit;

-- FOLHA - Validação - 132

-- Atualiza o campo indicativo_entidade_educativa para 'N' onde está nulo (considerando que a entidade educacional não é obrigatória)

update bethadba.hist_entidades_compl
   set indicativo_entidade_educativa = 'N'
 where indicativo_entidade_educativa is null;

commit;

-- FOLHA - Validação - 133

-- Adiciona data de fechamento de cálculo da folha para as entidades que não possuem data de fechamento de cálculo da folha

update bethadba.dados_calc
   set dt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
 where dt_fechamento is null
   and i_competencias < '2099-12-01';

commit;

-- FOLHA - Validação - 134

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

commit;

-- FOLHA - Validação - 142

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
begin
	select i_caracteristicas,
	       row_number() over (order by ordem, i_caracteristicas) as nova_ordem
	  into #temp_ordem
	  from bethadba.funcionarios_caract_cfg;
	
	-- Etapa 2: Atualizar a tabela original
	update bethadba.funcionarios_caract_cfg
	   set bethadba.funcionarios_caract_cfg.ordem = t.nova_ordem
  	  from #temp_ordem as t
	 where bethadba.funcionarios_caract_cfg.i_caracteristicas = t.i_caracteristicas;
end;

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

commit;

-- FOLHA - Validação - 143

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

commit;

-- FOLHA - Validação - 144

-- Atualiza a data de nascimento para 18 anos antes da data de alteração mais recente da pessoa física na tabela de histórico considerando que a data de nascimento não pode ser nula e que a pessoa física deve ter pelo menos 18 anos.

update bethadba.pessoas_fisicas pf
   set pf.dt_nascimento = DATEADD(year, -18, hpf.dt_alteracoes)
  from bethadba.hist_pessoas_fis hpf
 where pf.dt_nascimento is null
   and pf.i_pessoas = hpf.i_pessoas;

commit;

-- FOLHA - Validação - 145

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

commit;

-- FOLHA - Validação - 147

-- Verificar se o funcionário realmente não possui movimentações no período.

begin

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

end;

commit;

-- FOLHA - Validação - 154

-- Atualiza a data de nascimento do dependente como data de inicio do dependente

update bethadba.dependentes d
   set dt_ini_depende = pf.dt_nascimento
  from bethadba.pessoas_fisicas  pf
 where d.dt_ini_depende is null
   and d.i_dependentes = pf.i_pessoas;

commit;

-- FOLHA - Validação - 155

-- Atribui o motivo '1 - Nascimento' ao dependente que não possui motivo de início

update bethadba.dependentes
   set mot_ini_depende = case
                            when grau = 1 then 1
                            when grau = 2 then 7
                            when grau = 10 then 9
                            when grau = 9 then 8
                            when grau = 3 then 9
                         end
 where mot_ini_depende is null;

commit;

-- FOLHA - Validação - 156

-- Deletar duplicidade de dependentes com mais de uma configuração de IRRF quando o dependente for o mesmo

delete bethadba.dependentes_func
  from (select i_dependentes,
	   		   row_number() over (partition by i_dependentes order by i_dependentes) as rn
		  from (select distinct i_dependentes, dep_irrf
		  		  from bethadba.dependentes_func df) as thd
		 order by i_dependentes) as tab
 where tab.rn > 1
   and dependentes_func.i_dependentes = tab.i_dependentes;

commit;

-- FOLHA - Validação - 157

-- Atualiza os endereços de pessoas com os valores máximos das entidades para i_ruas, i_bairros e i_cidades onde os valores estão faltando

update bethadba.pessoas_enderecos
   set i_ruas = (select max(i_ruas) from bethadba.entidades),
       i_bairros = (select max(i_bairros) from bethadba.entidades),
       i_cidades = (select max(i_cidades) from bethadba.entidades)
 where i_ruas is null
    or i_bairros is null
    or i_cidades is null;

commit;

-- FOLHA - Validação - 16

-- Atualiza os atos com número nulo para o i_atos como número do ato

update bethadba.atos 
   set num_ato = i_atos 
 where num_ato is null
    or num_ato = '';

commit;

-- FOLHA - Validação - 17

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

commit;

-- FOLHA - Validação - 188

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

commit;

-- FOLHA - Validação - 189

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

commit;

-- FOLHA - Validação - 19

-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: 105) para evitar problemas de integridade referencial

update bethadba.vinculos
   set categoria_esocial = 105
 where categoria_esocial is null
   and i_vinculos = 3;

commit;

-- FOLHA - Validação - 194

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

commit;

-- FOLHA - Validação - 198

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

commit;

-- FOLHA - Validação - 199

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

-- OBS: COMO A VALIDAÇÃO 199 INSERE INFORMAÇÕES NA bethadba.hist_cargos_compl, FAZ-SE NECESSÁRIO APÓS RODAR ELA EFETUAR AS DUAS VALIDAÇÕES ATERIORES E SE RETORNAR 
-- INFORMAÇÕES NAS VALIDAÇÕES 189 E 198, RODAR NOVAMENTE E QUANTAS VEZES FOR NECESSÁRIO ESTES COMANDOS DE AJUSTE

commit;

-- FOLHA - Validação - 21

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

commit;

-- FOLHA - Validação - 22

-- Atualiza a data de fechamento das folhas que não foram fechadas, adicionando a data de fechamento como o último dia do mês da competência

update bethadba.processamentos
   set dt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
 where dt_fechamento is null;

commit;

-- FOLHA - Validação - 24

-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: '38' para aposentadoria, exceto por invalidez) para evitar problemas de integridade referencial
                
update bethadba.motivos_apos
   set categoria_esocial = '38' //Aposentadoria, exceto por ivalidez
 where i_motivos_apos in (1,2,3,4,8,9)
   and categoria_esocial is null;

update bethadba.motivos_apos
   set categoria_esocial = '39' //Aposentadoria por ivalidez
 where i_motivos_apos in (5,6,7)
   and categoria_esocial is null;

commit;

-- FOLHA - Validação - 25

-- Atualiza os históricos salariais com salário zerado ou nulo para um valor mínimo (exemplo: 0.01) para evitar problemas de cálculos futuros

update bethadba.hist_salariais
   set salario = 0.01
 where salario = 0 or salario is null;

commit;

-- FOLHA - Validação - 26

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

commit;

-- FOLHA - Validação - 33

-- Atualiza os tipos de atos repetidos para evitar duplicidade, adicionando o i_tipos_atos ao nome do tipo de atos

update bethadba.tipos_atos
   set tipos_atos.nome = tipos_atos.i_tipos_atos || '-' || tipos_atos.nome
 where tipos_atos.i_tipos_atos in(select i_tipos_atos
                                    from bethadba.tipos_atos
                                   where (select count(i_tipos_atos)
                                            from bethadba.tipos_atos t
                                           where trim(t.nome) = trim(tipos_atos.nome)) > 1);

commit;

-- FOLHA - Validação - 35

-- Atualiza a natureza de texto jurídico para 99 (SEM INFORMAÇÃO) onde a natureza de texto jurídico é nula
                 
insert into bethadba.natureza_texto_juridico (i_natureza_texto_juridico, descricao, codigo_tce, classif)
values (99, 'SEM INFORMAÇÃO', 99, 9);

update bethadba.atos
   set i_natureza_texto_juridico = 99
 where i_natureza_texto_juridico is null;

commit;

-- FOLHA - Validação - 38

-- Atualiza a descrição da configuração de organograma para abreviar 'Entidade' para 'Ent' onde a descrição é maior que 30 caracteres

update bethadba.config_organ 
   set descricao = replace(descricao, 'Entidade', 'Ent')
 where length(descricao) > 30;

commit;

-- FOLHA - Validação - 4

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

commit;

-- FOLHA - Validação - 41

-- Atualiza os nomes dos cargos repetidos para evitar duplicidade, adicionando o i_cargos ao nome do cargo
   
update bethadba.cargos
   set cargos.nome = trim(cargos.i_cargos) || '-' || trim(cargos.nome)
 where cargos.i_cargos in(select i_cargos
                            from bethadba.cargos
                           where (select count(i_cargos)
                                    from bethadba.cargos c
                                   where trim(c.nome) = trim(cargos.nome)) > 1);

commit;

-- FOLHA - Validação - 45

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

commit;

-- FOLHA - Validação - 54

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

commit;

-- FOLHA - Validação - 56

-- Atualiza os nomes dos níveis salariais repetidos, adicionando o identificador do nível ao início do nome e garantindo que os nomes sejam únicos

update bethadba.niveis
   set niveis.nome = niveis.i_niveis || ' - ' || niveis.nome
 where niveis.i_niveis in (select i_niveis
                             from bethadba.niveis
                            where (select count(i_niveis)
                                     from bethadba.niveis as n
                                    where trim(n.nome) = trim(niveis.nome)) > 1);

commit;

-- FOLHA - Validação - 57

-- Atualiza a data de nomeação para ser igual à data de posse

update bethadba.hist_cargos
   set dt_nomeacao = dt_posse
 where dt_nomeacao > dt_posse;

commit;

-- FOLHA - Validação - 65

-- Atualiza o valor do sub-teto para 99999 onde o valor é nulo, garantindo que todos os tipos administrativos tenham um valor definido para o sub-teto
                
update bethadba.hist_tipos_adm as hta
   set hta.vlr_sub_teto = '99999'
  from bethadba.entidades as e
 where hta.i_tipos_adm = e.i_tipos_adm
   and hta.i_competencias = (select max(x.i_competencias)
                               from bethadba.hist_tipos_adm as x
                              where x.i_tipos_adm = hta.i_tipos_adm
                                and x.vlr_sub_teto is null);

commit;

-- FOLHA - Validação - 78

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

commit;

-- FOLHA - Validação - 81

-- Atualiza a inscrição municipal para '0' onde o tipo de pessoa é 'J' e a inscrição municipal tem mais de 9 dígitos

update bethadba.pessoas
   set inscricao_municipal = null
 where tipo_pessoa = 'J'
   and length(inscricao_municipal) > 9;

commit;

-- FOLHA - Validação - 97

-- Atualiza o campo num_reg para que tenha exatamente 32 caracteres, preenchendo com zeros à esquerda

update bethadba.pessoas_fis_compl
   set num_reg = replicate('0', 32 - length(bethadba.dbf_retira_caracteres_especiais(num_reg))) + bethadba.dbf_retira_caracteres_especiais(num_reg)
 where length(bethadba.dbf_retira_caracteres_especiais(num_reg)) < 32
   and num_reg is not null;

commit;

call bethadba.pg_setoption('fire_triggers','on');
call bethadba.pg_setoption('wait_for_COMMIT','off');
commit;