-- VALIDAÇÃO 136
-- Verifica os funcionarios que não contém rescisão

select fpa.i_entidades,
       fpa.i_funcionarios
  from bethadba.funcionarios_prop_adic fpa  
 where fpa.i_caracteristicas = 20369 
   and fpa.valor_caracter = '1'
   and fpa.i_funcionarios not in (select r.i_funcionarios
                                    from bethadba.rescisoes r
                                   where r.i_motivos_apos is not null
                                     and r.dt_canc_resc is null);


-- CORREÇÃO

update bethadba.funcionarios_prop_adic fpa
   set valor_caracter = null
 where i_caracteristicas = 20369
   and i_funcionarios in (5, 329);