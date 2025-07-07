-- VALIDAÇÃO 181
-- Caracteristicas de matrículas não presentes na tabela de caracteristicas CFG

select distinct i_caracteristicas
  from bethadba.funcionarios_prop_adic
 where i_caracteristicas not in (select i_caracteristicas
   								   from bethadba.funcionarios_caract_cfg fcc);


-- CORREÇÃO

insert into bethadba.funcionarios_caract_cfg (i_caracteristicas, ordem, permite_excluir, dt_expiracao)
values (20315, 37, 'S', '2999-12-31');