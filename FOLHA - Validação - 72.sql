-- VALIDAÇÃO 72
-- Verifica data fim na lotação física deve ser maior que a data início

select i_funcionarios,
       ('Local de trabalho - '||i_locais_trab||', do funcion�rio '||i_funcionarios||' esta com a data Inicio - '||dt_inicial||' maior que a data Fim - '||dt_final) as msg
  from bethadba.locais_mov
 where dt_inicial > dt_final;


-- CORREÇÃO
-- Atualiza a data fim para nulo quando a data início for maior que a data fim

update bethadba.locais_mov 
   set dt_final = null
 where dt_inicial > dt_final;