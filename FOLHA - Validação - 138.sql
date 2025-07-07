-- VALIDAÇÃO 138
-- Calculo base outras empresas

select i_pessoas,
       dt_vigencia_ini,
       dt_vigencia_fin
  from bethadba.bases_calc_outras_empresas 
 where dt_vigencia_fin >= date(dateadd(year,100,GETDATE()));


-- CORREÇÃO

