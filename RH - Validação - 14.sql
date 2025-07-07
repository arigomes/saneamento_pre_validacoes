-- VALIDAÇÃO 14
-- Descrição habilitação maior que o permitido - Descrição habilitação maior que o permitido, não é permitido possuir mais de 100 caracateres

select i_areas_atuacao,
       nome
  from bethadba.areas_atuacao
 where length(descr_habilitacao) > 100;


-- CORREÇÃO

