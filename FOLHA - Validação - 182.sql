-- VALIDAÇÃO 182
-- Data final da vigência de bases anteriores de outras empresas equivocada. (Causa Travamento do Arqjob)

select i_pessoas,
       i_empresas,
       dt_vigencia_ini,
       dt_vigencia_fin
  from bethadba.bases_calc_outras_empresas 
 where dt_vigencia_fin > '2100-01-01';


-- CORREÇÃO

