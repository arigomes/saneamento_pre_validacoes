-- VALIDAÇÃO 13
-- Cursos concomitantes - Existem cursos concomitantes para a mesma pessoa

select pessoa = cp.i_pessoas,
       cursoPessoa = cp.i_cursos,
       dataInicial = cp.dt_inicial,
       dataFinal = cp.dt_final
  from bethadba.cursos_pessoas as cp
 where cp.participacao = 3
   and exists(select first 1
                from bethadba.cursos_pessoas as cp2
               where pessoa = cp2.i_pessoas
                 and cursoPessoa = cp2.i_cursos
                 and (cp2.dt_inicial between dataInicial and dataFinal
                  or cp2.dt_final between dataInicial and dataFinal));


-- CORREÇÃO

