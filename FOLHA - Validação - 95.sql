-- VALIDAÇÃO 95
-- Data inicial do beneficio menor que a data da admissão

select funcionarios.i_entidades,funcionarios.i_funcionarios
  from bethadba.emprestimos,
       bethadba.funcionarios
 where funcionarios.i_entidades = emprestimos.i_entidades
   and funcionarios.i_funcionarios = emprestimos.i_funcionarios
   and dt_admissao > dt_emprestimo;


-- CORREÇÃO
-- Atualiza a data do empréstimo para a data de admissão do funcionário
-- Atenção: essa correção deve ser feita com cautela, pois pode afetar registros de empréstimos já processados.
-- Certifique-se de que essa alteração é apropriada para o contexto do seu sistema.

update bethadba.emprestimos a
   set dt_emprestimo = dt_admissao
  from bethadba.funcionarios b
 where dt_admissao > dt_emprestimo
   and a.i_entidades = b.i_entidades
   and a.i_funcionarios = b.i_funcionarios;