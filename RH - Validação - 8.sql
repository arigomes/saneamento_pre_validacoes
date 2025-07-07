-- VALIDAÇÃO 8
-- Comissão de avaliação - O membro da comissão deve possuir uma função com descrição entre PRESIDENTE, MEMBRO ou SECRETARIO

select i_comissoes_aval,
       i_pessoas,
       funcao
  from bethadba.comissoes_aval_membros
 where funcao not like 'MEMBRO%' 
   and funcao not like 'PRESIDENTE%' 
   and funcao not like 'SECRETARIO%';


-- CORREÇÃO

