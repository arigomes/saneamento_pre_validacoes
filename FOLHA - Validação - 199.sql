-- VALIDAÇÃO 199
-- Há niveis salarias usados fora da vigência do cargo

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

create table cnv_ajuste_199 (
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
       hcc.dt_alteracoes as dt_alteracao_cargo,
       hcc.i_niveis as nivel_cargo
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
 group by hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis
 order by hs.i_entidades, hc.i_cargos,  hs.i_niveis;

commit;

update bethadba.hist_salariais as hs
   set hs.dt_alteracoes = cnv.dt_alteracao_cargo
  from cnv_ajuste_199 as cnv
 where convert(date, cnv.menor_dt_alteracao_salario ) = convert(date, cnv.dt_alteracao_cargo)
   and hs.dt_alteracoes = cnv.menor_dt_alteracao_salario
   and hs.i_niveis = cnv.nivel_salario;

-- ESSA PARTE DE BAIXO AINDA PRECISA SER COMPREENDIDA
delete  cnv_ajuste_199 ;

insert into cnv_ajuste_199
select 
        hs.i_entidades,
        min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
        hs.i_niveis as nivel_salario,
        hc.i_cargos,
        hcc.dt_alteracoes as dt_alteracao_cargo,
        hcc.i_niveis as nivel_cargo
    from 
        bethadba.hist_salariais hs
    join 
        bethadba.hist_cargos hc 
        on hs.i_funcionarios = hc.i_funcionarios 
        and hs.i_entidades = hc.i_entidades
    join 
        bethadba.hist_cargos_compl hcc 
        on hc.i_cargos = hcc.i_cargos 
        and hc.i_entidades = hcc.i_entidades
    where 
        hs.i_niveis is not null
        and hs.dt_alteracoes < hcc.dt_alteracoes
        and hs.i_niveis = hcc.i_niveis
    group by 
        hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis
    order by 
        hs.i_entidades, hc.i_cargos,  hs.i_niveis
;
commit
;

update    cnv_ajuste_199, bethadba.hist_cargos_compl 
set hist_cargos_compl.dt_alteracoes = menor_dt_alteracao_salario 
where convert(date,menor_dt_alteracao_salario ) < convert(date, dt_alteracao_cargo)
and  hist_cargos_compl.i_entidades = cnv_ajuste_199.i_entidades
and  hist_cargos_compl.i_cargos = cnv_ajuste_199.i_cargos
and  hist_cargos_compl.i_niveis = cnv_ajuste_199.nivel_cargo
and hist_cargos_compl.dt_alteracoes =  (select min(a.dt_alteracoes) from   bethadba.hist_cargos_compl  as a where a.i_entidades =  bethadba.hist_cargos_compl.i_entidades and a.i_cargos =  bethadba.hist_cargos_compl.i_cargos and  a.i_niveis =  bethadba.hist_cargos_compl.i_niveis);
commit
;
update  bethadba.hist_salariais, cnv_ajuste_199 
set  hist_salariais.dt_alteracoes = dt_alteracao_cargo
where convert(date,menor_dt_alteracao_salario ) = convert(date, dt_alteracao_cargo)
and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
and hist_salariais.i_niveis = nivel_salario 
;
delete  cnv_ajuste_199 ;

insert into cnv_ajuste_199
select 
        hs.i_entidades,
        min(hs.dt_alteracoes) as menor_dt_alteracao_salario,
        hs.i_niveis as nivel_salario,
        hc.i_cargos,
        hcc.dt_alteracoes as dt_alteracao_cargo,
        hcc.i_niveis as nivel_cargo
    from 
        bethadba.hist_salariais hs
    join 
        bethadba.hist_cargos hc 
        on hs.i_funcionarios = hc.i_funcionarios 
        and hs.i_entidades = hc.i_entidades
    join 
        bethadba.hist_cargos_compl hcc 
        on hc.i_cargos = hcc.i_cargos 
        and hc.i_entidades = hcc.i_entidades
    where 
        hs.i_niveis is not null
        and hs.dt_alteracoes < hcc.dt_alteracoes
        and hs.i_niveis = hcc.i_niveis
    group by 
        hs.i_entidades, hs.i_niveis, hc.i_cargos, hcc.dt_alteracoes, hcc.i_niveis
    order by 
        hs.i_entidades, hc.i_cargos,  hs.i_niveis
;
commit;

alter table cnv_ajuste_199  add ( seq integer)
;
update cnv_ajuste_199  set seq = number(*);
update cnv_ajuste_199  set menor_dt_alteracao_salario =   replace(menor_dt_alteracao_salario, '.000000', '.00000'||seq) where length(seq) = 1 ;
update cnv_ajuste_199  set menor_dt_alteracao_salario =   replace(menor_dt_alteracao_salario, '.000000', '.0000'||seq) where length(seq) = 2 ;
update cnv_ajuste_199  set menor_dt_alteracao_salario =   replace(menor_dt_alteracao_salario, '.000000', '.000'||seq) where length(seq) = 3 ;
update cnv_ajuste_199  set menor_dt_alteracao_salario =   replace(menor_dt_alteracao_salario, '.000000', '.00'||seq) where length(seq) = 4 ;

update    cnv_ajuste_199, bethadba.hist_cargos_compl 
set hist_cargos_compl.dt_alteracoes = menor_dt_alteracao_salario 
where convert(date,menor_dt_alteracao_salario ) < convert(date, dt_alteracao_cargo)
and  hist_cargos_compl.i_entidades = cnv_ajuste_199.i_entidades
and  hist_cargos_compl.i_cargos = cnv_ajuste_199.i_cargos
and  hist_cargos_compl.i_niveis = cnv_ajuste_199.nivel_cargo
and hist_cargos_compl.dt_alteracoes =  (select min(a.dt_alteracoes) from   bethadba.hist_cargos_compl  as a where a.i_entidades =  bethadba.hist_cargos_compl.i_entidades and a.i_cargos =  bethadba.hist_cargos_compl.i_cargos and  a.i_niveis =  bethadba.hist_cargos_compl.i_niveis)
;
update  bethadba.hist_salariais, cnv_ajuste_199 
set  hist_salariais.dt_alteracoes = dt_alteracao_cargo
where convert(date,menor_dt_alteracao_salario ) = convert(date, dt_alteracao_cargo)
and hist_salariais.dt_alteracoes = menor_dt_alteracao_salario
and hist_salariais.i_niveis = nivel_salario 
;
commit
;
 
update BETHADBA.HIST_NIVEIS
set dt_alteracoes = (select min(a.dt_alteracoes)-1 from   BETHADBA.HIST_CARGOS_COmpl as a where a.i_entidades =HIST_NIVEIS.i_entidades
        and  a.i_niveis =HIST_NIVEIS.i_niveis)
where dt_alteracoes = (select min(c.dt_alteracoes) from  bethadba.HIST_NIVEIS as  c 
where c.i_entidades  = HIST_NIVEIS.i_entidades   and c.i_niveis = HIST_NIVEIS.i_niveis)
and  (select min(a.dt_alteracoes)+1 from   BETHADBA.HIST_CARGOS_COmpl as a where a.i_entidades =HIST_NIVEIS.i_entidades
        and  a.i_niveis =HIST_NIVEIS.i_niveis) < HIST_NIVEIS.dt_alteracoes
;
update  BETHADBA.HIST_clas_NIVEIS
 set dt_alteracoes = (select min(a.dt_alteracoes) from   BETHADBA.HIST_niveis as a where a.i_entidades =HIST_clas_NIVEIS.i_entidades
                       and  a.i_niveis =HIST_clas_NIVEIS.i_niveis)
where dt_alteracoes = (select min(c.dt_alteracoes) from  bethadba.HIST_clas_NIVEIS as  c 
where c.i_entidades  = HIST_clas_NIVEIS.i_entidades   and c.i_niveis = HIST_clas_NIVEIS.i_niveis)
and  (select min(a.dt_alteracoes) from   BETHADBA.HIST_niveis as a where a.i_entidades =HIST_clas_NIVEIS.i_entidades
        and  a.i_niveis =HIST_clas_NIVEIS.i_niveis) < HIST_clas_NIVEIS.dt_alteracoes
;
