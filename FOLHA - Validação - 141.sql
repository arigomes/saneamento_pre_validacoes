-- VALIDAÇÃO 141
-- Data do processo de homologação maior que a data atual do ou da competência final

select pj.i_entidades,
       pj.i_pessoas,
       pj.i_funcionarios,
       pj.dt_homologacao,
       pj.dt_final,
       dataAtual = getDate()
  from bethadba.processos_judiciais pj 
 where pj.dt_homologacao > dataAtual 
    or pj.dt_homologacao > pj.dt_final;


-- CORREÇÃO

