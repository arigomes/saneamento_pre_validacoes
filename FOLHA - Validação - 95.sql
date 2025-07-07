/*
 -- VALIDAÇÃO 95
 * Data inicial do beneficio menor que a data da admissão
 */

select 
                 funcionarios.i_entidades,funcionarios.i_funcionarios
             from bethadba.emprestimos,
                  bethadba.funcionarios
           where funcionarios.i_entidades = emprestimos.i_entidades and 
                 funcionarios.i_funcionarios = emprestimos.i_funcionarios
and dt_admissao> dt_emprestimo

/*
 -- CORREÇÃO
 */

update bethadba.emprestimos a
join bethadba.funcionarios b on (a.i_entidades = b.i_entidades and a.i_funcionarios = b.i_funcionarios)
set dt_emprestimo = dt_admissao
where dt_admissao > dt_emprestimo 
