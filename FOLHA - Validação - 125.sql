-- VALIDAÇÃO 125
-- Configuração Rais sem responsável

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and nome_resp is null;


-- CORREÇÃO

