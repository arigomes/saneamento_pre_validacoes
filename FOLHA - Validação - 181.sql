-- VALIDAÇÃO 181
-- Caracteristicas de matrículas não presentes na tabela de caracteristicas CFG

select distinct i_caracteristicas
  from bethadba.funcionarios_prop_adic
 where i_caracteristicas not in (select i_caracteristicas
   								                 from bethadba.funcionarios_caract_cfg fcc);


-- CORREÇÃO
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