-- VALIDAÇÃO 105
-- Verifica Faltas que tenham competência de desconto quando o tipo da falta for (1 - Em dias)

select i_entidades, 
       i_funcionarios,
       tipo_faltas
  from bethadba.faltas 
 where tipo_faltas = 1
   and comp_descto is not null
   and tipo_descto = 1;


-- CORREÇÃO

