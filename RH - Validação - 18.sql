-- VALIDAÇÃO 18
-- Verifica se há registro na tabela planos_saude_tabelas_faixas - A tabela planos_saude_tabelas_faixas está vazia. É necessário ter os dados preenchidos

select ps.i_pessoas,
       ps.i_entidades,
       ps.i_planos_saude
  from bethadba.planos_saude as ps
 where not exists (select 1
               	     from bethadba.planos_saude_tabelas_faixas as pstb
					where pstb.i_entidades = ps.i_entidades
					  and pstb.i_pessoas = ps.i_pessoas
					  and pstb.i_planos_saude = ps.i_planos_saude);


-- CORREÇÃO
-- Inserir os dados nas tabelas planos_saude_tabelas e planos_saude_tabelas_faixas
insert into bethadba.planos_saude_tabelas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,vigencia_inicial,vigencia_final,subsidio_titular,subsidio_dep)
select ps.i_pessoas,
	   ps.i_entidades,
	   ps.i_planos_saude,
	   1,
	   '1900-01-01' as vigencia_inicial,
	   '2999-12-31' as vigencia_final,
	   0.00 as subsidio_titular,
	   0.00 as subsidio_dep
  from bethadba.planos_saude as ps
 where not exists(select 1
 					from bethadba.planos_saude_tabelas as pst
 				   where pst.i_pessoas = ps.i_pessoas
 				     and pst.i_entidades = ps.i_entidades
 				     and pst.i_planos_saude = ps.i_planos_saude);

insert into bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
select ps.i_pessoas,
	   ps.i_entidades,
	   ps.i_planos_saude,
	   1,
	   1,
	   0,
	   17,
	   100.00
  from bethadba.planos_saude as ps
 where not exists(select 1
 					from bethadba.planos_saude_tabelas_faixas as pst
 				   where pst.i_pessoas = ps.i_pessoas
 				     and pst.i_entidades = ps.i_entidades
 				     and pst.i_planos_saude = ps.i_planos_saude);