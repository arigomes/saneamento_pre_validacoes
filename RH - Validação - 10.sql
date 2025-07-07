-- VALIDAÇÃO 10
-- Tipo de diaria sem valor - É obrigatorio o valor para um tipo de diaria

select i_tipos_diarias,
       descricao
  from bethadba.tipos_diarias as td
 where vlr_diaria is null;


-- CORREÇÃO

