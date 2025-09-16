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