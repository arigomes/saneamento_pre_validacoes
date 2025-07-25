-- VALIDAÇÃO 191
-- Data de ultimo dia anterior a data de afastamento

select a.i_entidades,
       a.i_funcionarios,
       a.dt_afastamento,
       a.dt_ultimo_dia
  from bethadba.afastamentos as a
 where a.dt_ultimo_dia < a.dt_afastamento;


-- CORREÇÃO

update afastamentos as a
   set a.dt_ultimo_dia = DATEADD(day, 1, a.dt_afastamento)
 where a.dt_ultimo_dia < a.dt_afastamento;