call bethadba.dbp_conn_gera (1, year(today()), 300, 0);
call bethadba.pg_setoption('fire_triggers','off');
call bethadba.pg_setoption('wait_for_COMMIT','on');
commit;

-- FOLHA - Validação - 1

-- Atualiza os nomes dos logradouros duplicados para evitar duplicidade

update bethadba.ruas
   set nome = i_ruas || '-' || nome
 where i_ruas in (select i_ruas
                    from bethadba.ruas
                   where (select count(1)
                            from bethadba.ruas r
                           where (r.i_cidades = ruas.i_cidades or r.i_cidades is null)
                             and trim(r.nome) = trim(ruas.nome)) > 1);

commit;

-- FOLHA - Validação - 10

-- Atualiza os PIS's inválidos para nulo
                 
update bethadba.pessoas_fisicas 
   set num_pis = null 
 where i_pessoas in (select pessoas.i_pessoas
                       from bethadba.pessoas 
                       left join bethadba.pessoas_fisicas
                      where bethadba.dbf_chk_pis(num_pis) > 0
   and pessoas.tipo_pessoa != 'J'
   and num_pis is not null);

commit;

-- FOLHA - Validação - 102

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

commit;

-- FOLHA - Validação - 107

-- Atualiza a data final da lotação para a data de fim do vínculo temporário apenas para os casos onde a data final da lotação é maior que a data de fim

update bethadba.locais_mov
   set dt_final = dt_fim_vinculo
  from bethadba.locais_mov lm
  left join bethadba.funcionarios_vinctemp vt
    on lm.i_funcionarios = vt.i_funcionarios
 where lm.dt_final > vt.dt_fim_vinculo;

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

-- FOLHA - Validação - 112

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

commit;

-- FOLHA - Validação - 113

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

commit;

-- FOLHA - Validação - 118

-- Atualiza as faixas de licenças prêmios para o valor 99, que é o valor máximo permitido

update bethadba.licpremio_faixas
   set i_faixas = 99
 where i_faixas = 999;

commit;

-- FOLHA - Validação - 119

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

commit;

-- FOLHA - Validação - 120

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

commit;

-- FOLHA - Validação - 121

-- Atualiza o número da sala para 1

update bethadba.locais_aval 
   set num_sala = 1
 where i_pessoas in (select i_pessoas
                       from bethadba.locais_aval
                      where num_sala is null
                         or num_sala = ' ')
   and num_sala is null
    or num_sala = ' ';

commit;

-- FOLHA - Validação - 127

-- Atualiza os campos CNPJ que estão nulos para 0 para que não sejam considerados na validação e não gere erro de validação.

update bethadba.bethadba.rais_campos
   set CNPJ = right('000000000000' || cast((row_number() over) as varchar(12)), 12) || '91'
 where CNPJ is null;

commit;

-- FOLHA - Validação - 128

-- Insere os registros de pessoas fisicas que não possuem historico na tabela de historico de pessoas fisicas.

insert into bethadba.hist_pessoas_fis (i_pessoas, dt_alteracoes, dt_nascimento, sexo, rg, orgao_emis_rg, uf_emis_rg, dt_emis_rg, cpf, num_pis, dt_pis, carteira_prof, serie_cart, uf_emis_carteira, dt_emis_carteira, zona_eleitoral, secao_eleitoral, titulo_eleitor, grau_instrucao, estado_civil, cnh, categoria_cnh, dt_vencto_cnh, dt_primeira_cnh, observacoes_cnh, dt_emissao_cnh, i_estados_cnh, ric, orgao_ric, dt_emissao_ric, raca, certidao, ddd, telefone, ddd_cel, celular, email, tipo_validacao, tipo_pessoa, ident_estrangeiro, dt_validade_est, tipo_visto_est, cart_trab_est, serie_cart_est, dt_exp_cart_est, dt_val_cart_est, i_paises, orgao_emissor_est, dt_emissao_est, i_paises_nacionalidade, data_chegada_est, ano_chegada_est, casado_brasileiro_est, filho_brasileiro_est, i_situacao_estrangeiro, residencia_fiscal_exterior, i_pais_residencia_fiscal, indicativo_nif, numero_identificacao_fiscal, forma_tributacao)
select i_pessoas, dt_nascimento, dt_nascimento, sexo, rg, orgao_emis_rg, uf_emis_rg, dt_emis_rg, cpf, num_pis, dt_pis , carteira_prof , serie_cart , uf_emis_carteira , dt_emis_carteira, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'F', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
  from bethadba.pessoas_fisicas 
 where i_pessoas in (select i_pessoas 
		       from bethadba.pessoas_fisicas as pf 
		      where i_pessoas not in (select distinct(i_pessoas)
					  	from bethadba.hist_pessoas_fis as hpf));

commit;

-- FOLHA - Validação - 129

-- Atualiza a data a vigorar do ato para que não seja maior que a movimentação do ato.

update bethadba.atos_func as af
 inner join bethadba.atos as a
    on af.i_atos = a.i_atos
   set a.dt_vigorar = af.dt_movimento
 where a.dt_vigorar > af.dt_movimento;

commit;

-- FOLHA - Validação - 130

-- Atualiza a ordenação dos agrupadores de eventos que estão com ordenação nula com o valor do campo i_agrupadores

update bethadba.agrupadores_eventos
   set ordenacao = i_agrupadores
 where ordenacao is null;

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

-- FOLHA - Validação - 135

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

commit;

-- FOLHA - Validação - 140

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
	   --and (canceladoA = 'false' and canceladoB = 'false')
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

-- FOLHA - Validação - 15

-- Atualiza os logradouros sem cidades para a cidade padrão (i_entidades = 1)
  
update bethadba.ruas
   set i_cidades = (select max(i_cidades)
                      from bethadba.entidades
                     where i_entidades = 1)
 where i_cidades is null;

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
                         end
 where grau in (1, 2)
   and mot_ini_depende is null;

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

-- FOLHA - Validação - 158

-- Atualiza a coluna i_cidades na tabela pessoas_enderecos com o valor correto da tabela ruas

update bethadba.pessoas_enderecos as pe
   set pe.i_cidades = r.i_cidades 
  from bethadba.ruas as r
 where r.i_ruas = pe.i_ruas
   and r.i_cidades <> pe.i_cidades;

commit;

-- FOLHA - Validação - 16

-- Atualiza os atos com número nulo para o i_atos como número do ato

update bethadba.atos 
   set num_ato = i_atos 
 where num_ato is null
    or num_ato = '';

commit;

-- FOLHA - Validação - 162

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

commit;

-- FOLHA - Validação - 166

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

-- FOLHA - Validação - 170

-- Atualiza a data de vencimento da CNH para um dia após a data de emissão da CNH

update bethadba.pessoas_fis_compl pfc 
   set dt_vencto_cnh = DATEADD(DAY, 1, dt_emissao_cnh)
 where pfc.dt_vencto_cnh < pfc.dt_emissao_cnh 
   and pfc.dt_vencto_cnh is not null
   and pfc.dt_emissao_cnh is not null;

commit;

-- FOLHA - Validação - 171

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

commit;

-- FOLHA - Validação - 172

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

commit;

-- FOLHA - Validação - 176

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

commit;

-- FOLHA - Validação - 18

-- Atualiza os CBO's nulos para um valor padrão (exemplo: 312320) para evitar problemas de integridade referencial

update bethadba.cargos
   set i_cbo = 312320 
 where i_cargos = 9999;

commit;

-- FOLHA - Validação - 180

-- Remove a configuração de férias dos cargos com classificação comissionado ou não classificado

update bethadba.cargos_compl
   set cargos_compl.i_config_ferias = null
  from bethadba.cargos c
  join bethadba.tipos_cargos tc
    on c.i_tipos_cargos = tc.i_tipos_cargos,
       bethadba.hist_cargos as hc
 where c.i_entidades = cargos_compl.i_entidades
   and c.i_cargos = cargos_compl.i_cargos
   and c.i_entidades = hc.i_entidades
   and c.i_cargos = hc.i_cargos
   and tc.classif in (0, 2)
   and cargos_compl.i_config_ferias is not null
   and not exists(select 1
   			    	      from bethadba.periodos
               	   where periodos.i_entidades = hc.i_entidades
                 	   and periodos.i_funcionarios = hc.i_funcionarios);

commit;

-- FOLHA - Validação - 181

-- Inserir as caracteristicas que não existem na tabela de caracteristicas CFG

insert into bethadba.funcionarios_caract_cfg (i_caracteristicas, ordem, permite_excluir, dt_expiracao)
select distinct fpa.i_caracteristicas,
       (select coalesce(max(ordem), 0) + 1
          from bethadba.funcionarios_caract_cfg) as ordemNova,
       'S',
       CAST('2999-12-31' AS DATE)
  from bethadba.funcionarios_prop_adic fpa
 where fpa.i_caracteristicas not in (select i_caracteristicas
                                       from bethadba.funcionarios_caract_cfg);

commit;

-- FOLHA - Validação - 186

-- Truncar a descrição para 50 caracteres

update bethadba.periodos_trab
   set descricao = substr(descricao, 1, 50)
 where length(descricao) > 50;

commit;

-- FOLHA - Validação - 187

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

commit;

-- FOLHA - Validação - 192

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

commit;

-- FOLHA - Validação - 193

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

commit;

-- FOLHA - Validação - 195

-- Excluir agrupadores sem eventos

delete from agrupadores_eventos
 where not exists (select first 1
                     from bethadba.eventos
                    where i_agrupadores = agrupadores_eventos.i_agrupadores);

commit;

-- FOLHA - Validação - 197

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

commit;

-- FOLHA - Validação - 20

-- Atualiza os vinculos empregaticios repetidos para evitar duplicidade, adicionando o i_vinculos ao nome do vinculo

update bethadba.vinculos
   set vinculos.descricao = vinculos.i_vinculos || vinculos.descricao
 where i_vinculos in (2, 12);

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

-- FOLHA - Validação - 23

1
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

commit;

-- FOLHA - Validação - 24

-- Atualiza a categoria eSocial nulo para um valor padrão (exemplo: '38' para aposentadoria, exceto por invalidez) para evitar problemas de integridade referencial
                
update bethadba.motivos_apos
   set categoria_esocial = '38' //Aposentadoria, exceto por ivalidez
 where i_motivos_apos in (1,2,3,4,8,9);

update bethadba.motivos_apos
   set categoria_esocial = '39' //Aposentadoria por ivalidez
 where i_motivos_apos in (5,6,7);

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

-- FOLHA - Validação - 27

-- Atualiza as movimentações de pessoal repetidos para evitar duplicidade, adicionando o i_tipos_movpes ao nome do tipo de movimentação

update bethadba.tipos_movpes
   set tipos_movpes.descricao = tipos_movpes.i_tipos_movpes || '-' || tipos_movpes.descricao 
 where tipos_movpes.i_tipos_movpes in(select i_tipos_movpes
                                        from bethadba.tipos_movpes
                                       where (select count(i_tipos_movpes)
                                                from bethadba.tipos_movpes t
                                               where trim(t.descricao) = trim(tipos_movpes.descricao)) > 1);

commit;

-- FOLHA - Validação - 29

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

commit;

-- FOLHA - Validação - 3

-- Atualiza a data de vencimento da CNH para ser igual à data da primeira habilitação se a data de vencimento for menor que a data da primeira habilitação

update bethadba.pessoas_fis_compl
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;
 
update bethadba.hist_pessoas_fis
   set dt_vencto_cnh = dt_primeira_cnh
 where dt_vencto_cnh < dt_primeira_cnh;

commit;

-- FOLHA - Validação - 30

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

commit;

-- FOLHA - Validação - 35

-- Atualiza a natureza de texto jurídico para 99 (SEM INFORMAÇÃO) onde a natureza de texto jurídico é nula
                 
insert into bethadba.natureza_texto_juridico (i_natureza_texto_juridico, descricao, codigo_tce, classif)
values (99, 'SEM INFORMAÇÃO', 99, 9);

update bethadba.atos
   set i_natureza_texto_juridico = 99
 where i_natureza_texto_juridico is null;

commit;

-- FOLHA - Validação - 36

-- Atualiza a data de publicação do ato para ser igual à data de fonte de divulgação onde a data de fonte de divulgação é menor que a data de publicação do ato

update bethadba.atos as a
 inner join bethadba.fontes_atos as fa
    on (fa.i_atos = a.i_atos)
   set a.dt_publicacao = fa.dt_publicacao
 where fa.dt_publicacao < a.dt_publicacao;

commit;

-- FOLHA - Validação - 37

-- Insere o tipo de afastamento 1 (Afastamento para Férias) na configuração de cancelamento de férias, garantindo que haja pelo menos um tipo de afastamento associado

insert into bethadba.canc_ferias_afast (i_canc_ferias, i_tipos_afast)
values (2, 1);

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

-- FOLHA - Validação - 40

-- Atualiza os RG's repetidos para nulo, evitando duplicidade
 
update bethadba.pessoas_fisicas as pf1
   set rg = null
 where exists (select 1
                 from bethadba.pessoas_fisicas as pf2
                where pf1.rg = pf2.rg
                  and pf1.i_pessoas <> pf2.i_pessoas);

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

-- FOLHA - Validação - 46

-- Exclui os eventos de média vantagem que não possuem eventos vinculados

delete from bethadba.mediasvant
 where not exists(select 1
                    from bethadba.mediasvant_eve
                   where mediasvant_eve.i_eventos_medias = mediasvant.i_eventos);

commit;

-- FOLHA - Validação - 47

-- Exclui os eventos de média vantagem que estão compondo outros eventos de média vantagem

delete from bethadba.mediasvant_eve 
 where i_eventos = 1033;

commit;

-- FOLHA - Validação - 5

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

commit;

-- FOLHA - Validação - 52

-- Atualiza os nomes dos grupos funcionais repetidos, adicionando o identificador da entidade ao final do nome

update bethadba.grupos
   set nome = i_entidades || ' - ' || nome
 where nome in (select nome
                  from bethadba.grupos
                 group by nome
                having count(nome) > 1);

commit;

-- FOLHA - Validação - 53

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

-- FOLHA - Validação - 55

-- Atualiza a data inicial do ato para ser igual à data de vigorar se a data inicial for nula

update bethadba.atos 
   set dt_inicial = dt_vigorar 
 where dt_inicial is null;

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

-- FOLHA - Validação - 58

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

commit;

-- FOLHA - Validação - 59

-- Altera a previdência federal para 'Sim' e as demais para 'Não' quando o histórico da matrícula possuí mais de uma previdência marcada

update bethadba.hist_funcionarios
   set prev_federal = 'S',
       prev_estadual = 'N',
       fundo_ass = 'N',
       fundo_prev = 'N'
 where length(REPLACE(prev_federal || prev_estadual || fundo_ass || fundo_prev, 'N', '')) > 1;

commit;

-- FOLHA - Validação - 68

-- Atualiza a conta bancária dos funcionários com forma de pagamento 'R' (Crédito em conta) para a conta bancária correspondente na tabela pessoas_contas

update bethadba.hist_funcionarios
   set i_pessoas_contas = (select i_pessoas_contas
                             from bethadba.pessoas_contas
                            where i_pessoas = hist_funcionarios.i_pessoas)
 where forma_pagto = 'R'
   and i_pessoas_contas is null;

commit;

-- FOLHA - Validação - 7

-- Atualiza a data de nascimento dos dependentes com grau de parentesco 1, 6, 8 ou 11 para ser igual à do responsável se a data de nascimento do dependente for menor que a do responsável

update bethadba.dependentes 
  join bethadba.pessoas_fisicas p
    on (p.i_pessoas = dependentes.i_pessoas)
  join bethadba.pessoas_fisicas pdep
    on (pdep.i_pessoas = dependentes.i_dependentes)
   set pdep.dt_nascimento = p.dt_nascimento
 where dependentes.grau in (1, 6, 8, 11)
   and pdep.dt_nascimento < p.dt_nascimento;

commit;

-- FOLHA - Validação - 70

-- Atualiza a data de fim do gozo das férias para um dia antes da data de rescisão para os funcionários que possuem férias com data de fim do gozo igual ou após a data da rescisão.

update bethadba.ferias, bethadba.rescisoes
   set ferias.dt_gozo_fin = (rescisoes.dt_rescisao - 1)
 where ferias.i_entidades = rescisoes.i_entidades
   and ferias.i_funcionarios = rescisoes.i_funcionarios
   and ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;

commit;

-- FOLHA - Validação - 71

-- Atualiza a conta bancária dos funcionários com forma de pagamento 'R' (Crédito em conta) para a conta bancária correspondente na tabela pessoas_contas

update bethadba.hist_funcionarios hf
   set forma_pagto = 'D'
 where forma_pagto = 'R'
   and i_pessoas_contas is null;

commit;

-- FOLHA - Validação - 74

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

-- FOLHA - Validação - 79

-- Atualiza a data de rescisão para o dia seguinte ao término do gozo de férias

update bethadba.rescisoes, bethadba.ferias
   set bethadba.rescisoes.dt_rescisao = dateadd(day, 1, dt_gozo_fin)
 where bethadba.ferias.i_entidades = rescisoes.i_entidades
   and bethadba.ferias.i_funcionarios = rescisoes.i_funcionarios
   and bethadba.ferias.dt_gozo_fin >= rescisoes.dt_rescisao
   and rescisoes.dt_canc_resc is null;

commit;

-- FOLHA - Validação - 8

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

commit;

-- FOLHA - Validação - 80

-- Atualiza o campo observação do motivo do cancelamento de férias para nulo (considerando que o campo observação é do tipo texto longo e não deve ter mais de 50 caracteres)

update bethadba.periodos_ferias
   set observacao = null
 where length(observacao) > 50;

commit;

-- FOLHA - Validação - 81

-- Atualiza a inscrição municipal para '0' onde o tipo de pessoa é 'J' e a inscrição municipal tem mais de 9 dígitos

update bethadba.pessoas
   set inscricao_municipal = null
 where tipo_pessoa = 'J'
   and length(inscricao_municipal) > 9;

commit;

-- FOLHA - Validação - 85

-- Atualiza o nome do pai para um valor fictício quando o nome do pai é igual ao nome da mãe e o nome do pai não é nulo ou vazio.

update bethadba.pessoas_fis_compl
   set nome_pai = 'PAI_FICTICIO_' || cast(i_pessoas as varchar)
 where nome_pai = nome_mae
   and nome_pai is not null
   and nome_pai <> '';

commit;

-- FOLHA - Validação - 86

-- Corrige o email para NULL se for inválido

update bethadba.pessoas
   set email = replace(replace(replace(trim(replace(email, 'ç', 'c')), ' ', ''),',',''),'ã','a')
 where email is not null
   and bethadba.dbf_valida_email(trim(email)) = 1;

commit;

-- FOLHA - Validação - 87

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

commit;

-- FOLHA - Validação - 9

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

commit;

-- FOLHA - Validação - 92

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

commit;

-- FOLHA - Validação - 97

-- Atualiza o campo num_reg para que tenha exatamente 32 caracteres, preenchendo com zeros à esquerda

update bethadba.pessoas_fis_compl
   set num_reg = replicate('0', 32 - length(bethadba.dbf_retira_caracteres_especiais(num_reg))) + bethadba.dbf_retira_caracteres_especiais(num_reg)
 where length(bethadba.dbf_retira_caracteres_especiais(num_reg)) < 32
   and num_reg is not null;

commit;

-- PONTO - Validação - 1

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

commit;

-- PONTO - Validação - 2

-- Atualiza as descrições repetidas para que sejam únicas

update bethadba.turmas
   set descricao = i_turmas || ' - ' || descricao
 where exists (select 1 
                 from bethadba.turmas t2
                where turmas.descricao = t2.descricao
                  and turmas.i_turmas <> t2.i_turmas);

commit;

-- PONTO - Validação - 3

-- Trunca a descrição do motivo de alteração do ponto para 30 caracteres

update bethadba.motivos_altponto
   set descricao = left(descricao, 30)
 where length(descricao) > 30;

commit;

-- PONTO - Validação - 4

-- Atualiza as marcações com origem inválida para uma origem válida

update bethadba.apuracoes_marc
   set origem_marc = 'I'
 where origem_marc not in ('O','I','A');

commit;

-- RH - Validação - 1



commit;

-- RH - Validação - 17

-- Atualiza os candidatos que não possuem área de atuação para a área de atuação padrão (1)

update bethadba.candidatos
   set i_areas_atuacao = 1
 where i_areas_atuacao is null;

commit;

-- RH - Validação - 18

-- Inserir os dados na tabela planos_saude_tabelas_faixas

insert into bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
values (1, 1, 1, 1, 1, 0, 17, 100.00);

commit;

-- RH - Validação - 19

-- Atualizar os registros na tabela planos_saude_tabelas_faixas para preencher idade_ini e idade_fin com valores padrão, se necessário.

update bethadba.planos_saude_tabelas_faixas
   set idade_ini = 0, idade_fin = 100
 where idade_ini is null
    or idade_fin is null;

commit;

-- RH - Validação - 20

-- Ajustar as datas de ausência para evitar sobreposição

update bethadba.ausencias a1
   set a1.dt_ultimo_dia = coalesce(dateadd(day, -1, a2.dt_ausencia), a1.dt_ultimo_dia)
  from bethadba.ausencias a2
 where (a1.dt_ausencia between a2.dt_ausencia and a2.dt_ultimo_dia or a1.dt_ultimo_dia between a2.dt_ausencia and a2.dt_ultimo_dia)
   and (a1.dt_ausencia <> a2.dt_ausencia or a1.dt_ultimo_dia <> a2.dt_ultimo_dia)
   and a1.i_funcionarios = a2.i_funcionarios
   and a1.i_entidades = a2.i_entidades;

commit;

-- RH - Validação - 3

-- A correção deve ser feita no cadastro de matrícula, onde não deve ser possível incluir uma licença prêmio com data inicial anterior à data de admissão do funcionário.

update bethadba.licencas_premio_per
   set dt_inicial = funcionarios.dt_admissao
  from bethadba.funcionarios
 where licencas_premio_per.i_entidades = funcionarios.i_entidades
   and licencas_premio_per.i_funcionarios = funcionarios.i_funcionarios
   and licencas_premio_per.dt_inicial < funcionarios.dt_admissao;

commit;

-- RH - Validação - 9

-- Atualiza a data inicial da configuração adicional da matrícula para a data de admissão do funcionário

update bethadba.adic_funcs as af
  join bethadba.funcionarios as f
    on af.i_entidades = f.i_entidades
   and af.i_funcionarios = f.i_funcionarios
   set af.dt_inicial = f.dt_admissao
 where af.dt_inicial < f.dt_admissao;

commit;

call bethadba.pg_setoption('fire_triggers','on');
call bethadba.pg_setoption('wait_for_COMMIT','off');
commit;