call bethadba.dbp_conn_gera (1, year(today()), 300, 0);
call bethadba.pg_setoption('fire_triggers','off');
call bethadba.pg_setoption('wait_for_COMMIT','on');
commit;

-- FOLHA - Validação - 180

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

commit;

-- FOLHA - Validação - 189

-- Atualiza o histórico do nivel com a data do histórico do cargo
update bethadba.hist_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)
   						  from bethadba.hist_cargos_compl as a
   						 where a.i_entidades = hist_niveis.i_entidades
						   and a.i_niveis =hist_niveis.i_niveis)
 where dt_alteracoes < (select min(c.dt_alteracoes)
 						  from bethadba.hist_niveis as c
						 where c.i_entidades = hist_niveis.i_entidades
						   and c.i_niveis = hist_niveis.i_niveis);

-- Se a correção acima não resolver, fazer um update do histórico do cargo com a data do histórico do nivel
update bethadba.hist_cargos_compl
   set dt_alteracoes = (select min(a.dt_alteracoes)
   						  from bethadba.hist_niveis as a
   						 where a.i_entidades = hist_cargos_compl.i_entidades
						   and a.i_niveis = hist_cargos_compl.i_niveis)
 where dt_alteracoes < (select min(c.dt_alteracoes)
 						  from bethadba.hist_cargos_compl as c
						 where c.i_entidades = hist_cargos_compl.i_entidades
						   and c.i_niveis = hist_cargos_compl.i_niveis);

-- Se a correção acima não resolver, fazer um insert de um novo histórico na data do histórico do cargo
insert into bethadba.hist_cargos_compl (i_entidades,i_cargos,dt_alteracoes,i_niveis,i_clas_niveis_ini,i_referencias_ini,i_clas_niveis_fin,i_referencias_fin,i_atos,dt_final)
select i_entidades,
	   i_cargos,
	   (select min(a.dt_alteracoes)
		  from bethadba.hist_niveis as a
		 where a.i_entidades = hist_cargos_compl.i_entidades
		   and a.i_niveis = hist_cargos_compl.i_niveis) as dt_alteracoes,
	   i_niveis,
	   i_clas_niveis_ini,
	   i_referencias_ini,
	   i_clas_niveis_fin,
	   i_referencias_fin,
	   i_atos,
	   null
  from bethadba.hist_cargos_compl
 where dt_alteracoes > (select min(c.dt_alteracoes)
						  from bethadba.hist_niveis as c
						 where c.i_entidades = hist_cargos_compl.i_entidades
						   and c.i_niveis = hist_cargos_compl.i_niveis);

commit;

-- FOLHA - Validação - 199

-- Cria tabela temporária para armazenar os ajustes
create table cnv_ajusta_199
(i_entidades integer, menor_dt_alteracao_salario timestamp, nivel_salario integer, i_cargos integer, dt_alteracao_cargo timestamp, nivel_cargo integer, seq integer);

commit;

-- Atualiza a tabela cnv_ajusta_199 com os dados necessários para o ajuste
insert into cnv_ajusta_199 (i_entidades,menor_dt_alteracao_salario,nivel_salario,i_cargos,dt_alteracao_cargo,nivel_cargo,seq)
select hs.i_entidades,
       min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
       hs.i_niveis as nivel_salario,
       hc.i_cargos,
       hcc.dt_alteracoes as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo,
       row_number() over (partition by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis order by hs.dt_alteracoes) as seq
  from bethadba.hist_salariais as hs
  join bethadba.hist_cargos as hc 
    on hs.i_funcionarios = hc.i_funcionarios 
   and hs.i_entidades = hc.i_entidades
  join bethadba.hist_cargos_compl as hcc 
    on hc.i_cargos = hcc.i_cargos 
   and hc.i_entidades = hcc.i_entidades
 where hs.i_niveis is not null
   and hs.dt_alteracoes < hcc.dt_alteracoes
   and hs.i_niveis = hcc.i_niveis
 group by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis, hs.dt_alteracoes
 order by hs.i_entidades, hc.i_cargos, hs.i_niveis;

commit;

-- Atualiza a tabela hist_salariais com a data de alteração do cargo que possui a menor data de alteração de salário
update bethadba.hist_salariais as hs
   set hs.dt_alteracoes = dateadd(second, 
        isnull(
            (select count(*)
               from bethadba.hist_salariais hs2
              where hs2.i_entidades = hs.i_entidades
                and hs2.i_funcionarios = hs.i_funcionarios
                and hs2.dt_alteracoes >= convert(date, cnv.dt_alteracao_cargo)
                and hs2.dt_alteracoes < dateadd(second, 60, convert(date, cnv.dt_alteracao_cargo))
            ), 0) 
        + isnull(cnv.seq, 0) - 1, -- incrementa pelo seq para garantir unicidade
        convert(date, cnv.dt_alteracao_cargo))
  from cnv_ajusta_199 as cnv
 where convert(date, cnv.menor_dt_alteracao_salario) = convert(date, cnv.dt_alteracao_cargo)
   and hs.dt_alteracoes = cnv.menor_dt_alteracao_salario
   and hs.i_niveis = cnv.nivel_salario
   and not exists (
        select 1
          from bethadba.hist_salariais hs3
         where hs3.i_entidades = hs.i_entidades
           and hs3.i_funcionarios = hs.i_funcionarios
           and hs3.dt_alteracoes = dateadd(second, 
                isnull(
                    (select count(*)
                       from bethadba.hist_salariais hs2
                      where hs2.i_entidades = hs.i_entidades
                        and hs2.i_funcionarios = hs.i_funcionarios
                        and hs2.dt_alteracoes >= convert(date, cnv.dt_alteracao_cargo)
                        and hs2.dt_alteracoes < dateadd(second, 60, convert(date, cnv.dt_alteracao_cargo))
                    ), 0)
                + isnull(cnv.seq, 0) - 1, -- incrementa pelo seq para garantir unicidade
                convert(date, cnv.dt_alteracao_cargo))
       );

commit;

-- limpa a tabela cnv_ajusta_199
delete cnv_ajusta_199;

commit;

-- Atualiza a tabela cnv_ajusta_199 com os dados necessários para o ajuste
insert into cnv_ajusta_199 (i_entidades,menor_dt_alteracao_salario,nivel_salario,i_cargos,dt_alteracao_cargo,nivel_cargo,seq)
select hs.i_entidades,
       min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
       hs.i_niveis as nivel_salario,
       hc.i_cargos,
       hcc.dt_alteracoes as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo,
       row_number() over (partition by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis order by hs.dt_alteracoes) as seq
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
 order by hs.i_entidades, hc.i_cargos, hs.i_niveis;

commit;

-- Atualiza a tabela hist_cargos_compl com a menor data de alteração de salário
-- Atualiza hist_cargos_compl, incrementando 1 segundo se houver conflito de chave primária
update bethadba.hist_cargos_compl
  set hist_cargos_compl.dt_alteracoes = (
      -- Busca a menor data de alteração de salário, incrementando segundos até não haver conflito
      select dateadd(second, isnull((
        select count(*)
          from bethadba.hist_cargos_compl as hcc2
         where hcc2.i_entidades = cnv_ajusta_199.i_entidades
          and hcc2.i_cargos = cnv_ajusta_199.i_cargos
          and hcc2.i_niveis = cnv_ajusta_199.nivel_cargo
          and hcc2.dt_alteracoes >= convert(date, cnv_ajusta_199.menor_dt_alteracao_salario)
          and hcc2.dt_alteracoes < dateadd(second, 60, convert(date, cnv_ajusta_199.menor_dt_alteracao_salario))
      ), 0), convert(date, cnv_ajusta_199.menor_dt_alteracao_salario))
   )
  from cnv_ajusta_199
 where convert(date, cnv_ajusta_199.menor_dt_alteracao_salario) < convert(date, cnv_ajusta_199.dt_alteracao_cargo)
  and hist_cargos_compl.i_entidades = cnv_ajusta_199.i_entidades
  and hist_cargos_compl.i_cargos = cnv_ajusta_199.i_cargos
  and hist_cargos_compl.i_niveis = cnv_ajusta_199.nivel_cargo
  and hist_cargos_compl.dt_alteracoes = (
      select min(a.dt_alteracoes)
       from bethadba.hist_cargos_compl as a
      where a.i_entidades = bethadba.hist_cargos_compl.i_entidades
        and a.i_cargos = bethadba.hist_cargos_compl.i_cargos
        and a.i_niveis = bethadba.hist_cargos_compl.i_niveis
   );

commit;

-- Atualiza as datas de alteração dos salários com a data de alteração do cargo que possui a menor data de alteração de salário
update bethadba.hist_salariais
   set hist_salariais.dt_alteracoes = dt_alteracao_cargo
  from cnv_ajusta_199
 where convert(date,menor_dt_alteracao_salario) = convert(date, dt_alteracao_cargo)
   and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
   and hist_salariais.i_niveis = nivel_salario;

commit;

-- limpa a tabela cnv_ajusta_199
delete cnv_ajusta_199;

commit;

-- Atualiza a tabela cnv_ajusta_199 com os dados necessários para o ajuste
insert into cnv_ajusta_199 (i_entidades,menor_dt_alteracao_salario,nivel_salario,i_cargos,dt_alteracao_cargo,nivel_cargo,seq)
select hs.i_entidades,
       min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
       hs.i_niveis as nivel_salario,
       hc.i_cargos,
       hcc.dt_alteracoes as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo,
       row_number() over (partition by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis order by hs.dt_alteracoes) as seq
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
 order by hs.i_entidades, hc.i_cargos, hs.i_niveis;

commit;

-- Atualiza as datas de alteração dos cargos complementares com a menor data de alteração de salário
update bethadba.hist_cargos_compl
   set hist_cargos_compl.dt_alteracoes = menor_dt_alteracao_salario
  from cnv_ajusta_199
 where convert(date,menor_dt_alteracao_salario) < convert(date, dt_alteracao_cargo)
   and hist_cargos_compl.i_entidades = cnv_ajusta_199.i_entidades
   and hist_cargos_compl.i_cargos = cnv_ajusta_199.i_cargos
   and hist_cargos_compl.i_niveis = cnv_ajusta_199.nivel_cargo
   and hist_cargos_compl.dt_alteracoes = (select min(a.dt_alteracoes)
              from bethadba.hist_cargos_compl as a
             where a.i_entidades = bethadba.hist_cargos_compl.i_entidades
               and a.i_cargos = bethadba.hist_cargos_compl.i_cargos
               and a.i_niveis = bethadba.hist_cargos_compl.i_niveis);

commit;

-- Atualiza as datas de alteração dos salários com a data de alteração do cargo que possui a menor data de alteração de salário
update bethadba.hist_salariais
   set hist_salariais.dt_alteracoes = dt_alteracao_cargo
  from cnv_ajusta_199
 where convert(date,menor_dt_alteracao_salario) = convert(date, dt_alteracao_cargo)
   and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
   and hist_salariais.i_niveis = nivel_salario;

commit;

-- Atualiza as datas de alteração dos níveis salariais
update bethadba.hist_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes) - 1
                          from bethadba.hist_cargos_compl as a
                         where a.i_entidades = hist_niveis.i_entidades
                           and a.i_niveis =hist_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
                          from bethadba.hist_niveis as c
                         where c.i_entidades = hist_niveis.i_entidades
                           and c.i_niveis = hist_niveis.i_niveis)
   and (select min(a.dt_alteracoes) + 1
          from bethadba.hist_cargos_compl as a
         where a.i_entidades =hist_niveis.i_entidades
           and a.i_niveis =hist_niveis.i_niveis) < hist_niveis.dt_alteracoes;

commit;

-- Atualiza as datas de alteração das classificações de níveis
update bethadba.hist_clas_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)
                          from bethadba.hist_niveis as a
                         where a.i_entidades =hist_clas_niveis.i_entidades
                           and a.i_niveis =hist_clas_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
                          from bethadba.hist_clas_niveis as c
                         where c.i_entidades = hist_clas_niveis.i_entidades
                           and c.i_niveis = hist_clas_niveis.i_niveis)
   and (select min(a.dt_alteracoes)
          from bethadba.hist_niveis as a
         where a.i_entidades = hist_clas_niveis.i_entidades
           and a.i_niveis =hist_clas_niveis.i_niveis) < hist_clas_niveis.dt_alteracoes;

commit;

commit;

-- RH - Validação - 18

-- Inserir os dados na tabela planos_saude_tabelas_faixas

INSERT INTO bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
VALUES (1, 1, 1, 1, 1, 0, 17, 100.00);

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

call bethadba.pg_setoption('fire_triggers','on');
call bethadba.pg_setoption('wait_for_COMMIT','off');
commit;