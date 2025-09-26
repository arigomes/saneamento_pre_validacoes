-- VALIDAÇÃO 180
-- Cargos com classificação comissionado ou não classificado com configuração de ferias

select c.i_entidades,
       c.nome,
       c.i_tipos_cargos,
       cc.i_config_ferias,
       tc.classif 
  from bethadba.cargos c
  join bethadba.tipos_cargos tc
    on c.i_tipos_cargos = tc.i_tipos_cargos
  join bethadba.cargos_compl as cc
    on c.i_entidades = cc.i_entidades
   and c.i_cargos = cc.i_cargos,
       bethadba.hist_cargos as hc
 where c.i_entidades = hc.i_entidades
   and c.i_cargos = hc.i_cargos
   and tc.classif in (0, 2)
   and cc.i_config_ferias is not null
   and not exists(select 1
   			    	from bethadba.periodos
               	   where periodos.i_entidades = hc.i_entidades
                 	 and periodos.i_funcionarios = hc.i_funcionarios);


-- CORREÇÃO
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