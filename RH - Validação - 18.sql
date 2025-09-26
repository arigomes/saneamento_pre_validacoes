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
-- Inserir os dados na tabela planos_saude_tabelas_faixas

insert into bethadba.planos_saude_tabelas_faixas (i_pessoas,i_entidades,i_planos_saude,i_tabelas,i_sequencial,idade_ini,idade_fin,vlr_plano)
values (1, 1, 1, 1, 1, 0, 17, 100.00);