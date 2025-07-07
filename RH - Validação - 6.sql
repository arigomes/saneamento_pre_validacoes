-- VALIDAÇÃO 6
-- Periodo Aquisitivo Licenca premio - A quantidade de dias de direito deve ser informada

select i_entidades,
       i_funcionarios,
       i_licencas_premio
  from bethadba.licencas_premio  
 where num_dias_licenca is null
    or num_dias_licenca < 0
 order by 1,2,3 asc;


-- CORREÇÃO

