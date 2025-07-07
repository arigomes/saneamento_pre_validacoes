-- VALIDAÇÃO 11
-- Finalidade superior a 100 caracteres - A descrição da finalidade da diaria não pode possuir mais de 100 carcateres

select i_entidades,
       i_funcionarios,
       i_diarias,
       finalidade
  from bethadba.diarias
 where length(finalidade) > 100;


-- CORREÇÃO

