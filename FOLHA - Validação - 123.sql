-- VALIDAÇÃO 123
-- Configuração Rais com tipo de inscrição inválida

select i_entidades,
       i_parametros_rel
  from bethadba.parametros_rel
 where i_parametros_rel = 2
   and (tipo_insc is null or tipo_insc = 'C');


-- CORREÇÃO

