-- VALIDAÇÃO 183
-- Concessão com tag manual como S porém com lançamento de ferias

select pf.i_entidades,
       pf.i_funcionarios,
       pf.i_periodos,
       pf.manual,
       pf.i_ferias
  from bethadba.periodos_ferias pf
 where pf.tipo <> 1
   and pf.manual = 'S'
   and pf.i_ferias is not null;


-- CORREÇÃO

