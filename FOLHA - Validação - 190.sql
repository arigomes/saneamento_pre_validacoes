-- VALIDAÇÃO 190
-- Descrição de habilitação superior ao limite de caracteres

select aa.i_areas_atuacao,
       aa.nome,
       aa.descr_habilitacao
  from bethadba.areas_atuacao as aa
 where length(aa.descr_habilitacao) > 100;


-- CORREÇÃO

