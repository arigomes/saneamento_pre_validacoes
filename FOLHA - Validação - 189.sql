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
           								              from hist_niveis n2
           							               where n2.i_entidades = n.i_entidades
           							   	             and n2.i_niveis = n.i_niveis)) as niveis
 where niveis.rn = 1;


-- CORREÇÃO

update bethadba.hist_niveis
   set dt_alteracoes = (select min(a.dt_alteracoes)-1
   						  from bethadba.hist_cargos_compl as a
   						 where a.i_entidades = hist_niveis.i_entidades
        				   and a.i_niveis =hist_niveis.i_niveis)
 where dt_alteracoes = (select min(c.dt_alteracoes)
 						  from bethadba.hist_niveis as c
						 where c.i_entidades = hist_niveis.i_entidades
						   and c.i_niveis = hist_niveis.i_niveis)
   and (select min(a.dt_alteracoes)+1
   		  from bethadba.hist_cargos_compl as a
   		 where a.i_entidades = hist_niveis.i_entidades
           and a.i_niveis =hist_niveis.i_niveis) < hist_niveis.dt_alteracoes;

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
   		 where a.i_entidades =hist_clas_niveis.i_entidades
           and a.i_niveis =hist_clas_niveis.i_niveis) < hist_clas_niveis.dt_alteracoes;

-- Se a correção acima não resolver, fazer um insert de um novo histórico na data do histórico do cargo
insert into bethadba.hist_niveis (i_entidades,i_niveis,dt_alteracoes,i_motivos_altsal,vlr_anterior,vlr_novo,perc_aumento,i_planos_salariais,vlr_aumento,i_atos,carga_hor,coeficiente,coeficiente_anterior)
values (2,1,'2017-01-01 00:00:00.000',4,1000.00,1000.00,0.0000,1,null,null,220.00,'N','N');