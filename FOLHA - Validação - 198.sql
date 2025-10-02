-- VALIDAÇÃO 198
-- Há níveis salariais não presente nos historicos de cargos

select distinct
        funcionarios.i_entidades as chave_dsk1,
        funcionarios.i_funcionarios as chave_dsk2,        
        dataAlteracao = tabAlt.dataAlteracao,
        hs.i_niveis,
        hc.i_cargos
    from
        bethadba.funcionarios,
        bethadba.hist_cargos hc left outer join
        bethadba.concursos on(hc.i_entidades = concursos.i_entidades and hc.i_concursos = concursos.i_concursos),
        bethadba.hist_funcionarios hf, 
        bethadba.hist_salariais hs left outer join bethadba.niveis on niveis.i_entidades = hs.i_entidades and niveis.i_niveis = hs.i_niveis left outer join 
        bethadba.planos_salariais on planos_salariais.i_planos_salariais = niveis.i_planos_salariais,( select  entidade=f.i_entidades,
                                                                                                        funcionario=f.i_funcionarios,
                                                                                                        dataAlteracao = hf.dt_alteracoes,
                                                                                                        origemHistorico = 'FUNCIONARIO'
                                                                                                        from bethadba.funcionarios f 
                                                                                                        join bethadba.hist_funcionarios hf on (f.i_entidades=hf.i_entidades and f.i_funcionarios=hf.i_funcionarios and hf.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                                                                                                                                                                                                                                     from bethadba.afastamentos afast
                                                                                                                                                                                                                                                    where afast.i_entidades = f.i_entidades and 
                                                                                                                                                                                                                                                          afast.i_funcionarios = f.i_funcionarios and 
                                                                                                                                                                                                                                                          afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                                                                                                                                                                                                                   from bethadba.tipos_afast 
                                                                                                                                                                                                                                                                                  where tipos_afast.i_tipos_afast = afast.i_tipos_afast and 
                                                                                                                                                                                                                                                                                        tipos_afast.classif = 9)),date('2999-12-31'))) 
                                                                                                        union 
                                                                                                        select entidade=f.i_entidades,
                                                                                                               funcionario=f.i_funcionarios,
                                                                                                               dataAlteracao = hc.dt_alteracoes ,
                                                                                                               origemHistorico = 'CARGO'
                                                                                                        from bethadba.funcionarios f 
                                                                                                        join bethadba.hist_cargos hc on (f.i_entidades=hc.i_entidades and f.i_funcionarios=hc.i_funcionarios and hc.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                                                                                                                                                                                                                             from bethadba.afastamentos afast
                                                                                                                                                                                                                                            where afast.i_entidades = f.i_entidades and 
                                                                                                                                                                                                                                                  afast.i_funcionarios = f.i_funcionarios and 
                                                                                                                                                                                                                                                  afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                                                                                                                                                                                                           from bethadba.tipos_afast 
                                                                                                                                                                                                                                                                          where tipos_afast.i_tipos_afast = afast.i_tipos_afast and 
                                                                                                                                                                                                                                                                                tipos_afast.classif = 9)),date('2999-12-31')))  
                                                                                                                                                                                                                                                                                                            where not exists( select distinct 1 from bethadba.hist_funcionarios hf 
                                                                                                                                                                                                                                                                                                                                    where hf.i_entidades = hc.i_entidades and 
                                                                                                                                                                                                                                                                                                                                    hf.i_funcionarios= hc.i_funcionarios and 
                                                                                                                                                                                                                                                                                                                                    hf.dt_alteracoes = hc.dt_alteracoes)
                                                                                                        union 
                                                                                                        select  entidade=f.i_entidades,
                                                                                                                funcionario=f.i_funcionarios,
                                                                                                                dataAlteracao = hs.dt_alteracoes,
                                                                                                                origemHistorico = 'SALARIO' 
                                                                                                                from bethadba.funcionarios f 
                                                                                                        join bethadba.hist_salariais hs on (f.i_entidades=hs.i_entidades and f.i_funcionarios=hs.i_funcionarios and hs.dt_alteracoes <= isnull((select first afast.dt_afastamento
                                                                                                                                                                                                                                                 from bethadba.afastamentos afast
                                                                                                                                                                                                                                                where afast.i_entidades = f.i_entidades and 
                                                                                                                                                                                                                                                      afast.i_funcionarios = f.i_funcionarios and 
                                                                                                                                                                                                                                                      afast.i_tipos_afast = (select tipos_afast.i_tipos_afast
                                                                                                                                                                                                                                                                               from bethadba.tipos_afast 
                                                                                                                                                                                                                                                                              where tipos_afast.i_tipos_afast = afast.i_tipos_afast and 
                                                                                                                                                                                                                                                                                    tipos_afast.classif = 9)),date('2999-12-31')))
                                                                                                        where not exists( select distinct 1 from bethadba.hist_funcionarios hf 
                                                                                                                                where hf.i_entidades = hs.i_entidades and 
                                                                                                                                hf.i_funcionarios= hs.i_funcionarios and 
                                                                                                                                hf.dt_alteracoes = hs.dt_alteracoes) 
                                                                                                        and not exists( select distinct 1 from bethadba.hist_cargos hc 
                                                                                                                                where hs.i_entidades = hc.i_entidades and 
                                                                                                                                hs.i_funcionarios= hc.i_funcionarios and 
                                                                                                                                hs.dt_alteracoes = hc.dt_alteracoes)
                                                                                                        order by dataAlteracao) as tabAlt,
        bethadba.pessoas left outer join
        bethadba.pessoas_fisicas on (pessoas.i_pessoas = pessoas_fisicas.i_pessoas),
        bethadba.cargos,
        bethadba.tipos_cargos,
        bethadba.cargos_compl,
        bethadba.vinculos
        
    where  
        funcionarios.i_entidades = tabAlt.entidade and
        funcionarios.i_funcionarios = tabAlt.funcionario and
        tipos_cargos.i_tipos_cargos = cargos.i_tipos_cargos and 
        cargos.i_cargos = hc.i_cargos and 
        cargos.i_entidades = hc.i_entidades and
        funcionarios.i_funcionarios = hf.i_funcionarios and  
        funcionarios.i_entidades = hf.i_entidades and 
        pessoas.i_pessoas = funcionarios.i_pessoas and 
        hf.i_funcionarios = hc.i_funcionarios and 
        hf.i_entidades = hc.i_entidades and 
        hs.i_funcionarios = hc.i_funcionarios and 
        hs.i_entidades = hc.i_entidades and 
        hs.dt_alteracoes = bethadba.dbf_GetDataHisSal(hs.i_entidades, hs.i_funcionarios, dataAlteracao) and 
        hf.dt_alteracoes = bethadba.dbf_GetDataHisFun(hf.i_entidades, hf.i_funcionarios, dataAlteracao) and 
        hc.dt_alteracoes = bethadba.dbf_GetDataHisCar(hc.i_entidades, hc.i_funcionarios, dataAlteracao) and
        hf.i_vinculos = vinculos.i_vinculos and
        cargos_compl.i_entidades=cargos.i_entidades and
        cargos_compl.i_cargos = cargos.i_cargos and 
        funcionarios.tipo_func = 'F' and
        vinculos.categoria_esocial <> 901 and
        hs.i_niveis is not null and 
        exists (select first 1 from bethadba.hist_cargos_compl hcc where hcc.i_entidades = chave_dsk1 and hcc.i_cargos = hc.i_cargos
                    and date(dataAlteracao) between date(hcc.dt_alteracoes) and isnull(hcc.dt_final,'2999-12-31')) and
        not exists (select first 1 from bethadba.hist_cargos_compl hcc where hcc.i_entidades = chave_dsk1 and hcc.i_cargos = hc.i_cargos and hcc.i_niveis = hs.i_niveis
                            and date(dataAlteracao) between date(hcc.dt_alteracoes) and isnull(hcc.dt_final,'2999-12-31'))


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