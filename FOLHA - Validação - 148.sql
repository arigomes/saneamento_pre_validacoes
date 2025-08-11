-- VALIDAÇÃO 148
-- Calculo de ferias sem registros

select dc.i_entidades,
       dc.i_funcionarios,
       dc.i_competencias,
       dc.i_processamentos,
       dc.i_tipos_proc,
       dc.dt_pagto
  from bethadba.dados_calc as dc
 where dc.i_tipos_proc = 80
   and dc.dt_fechamento is not null
   and not exists (select 1 
                     from bethadba.ferias_proc as fp
                     left join bethadba.ferias as f
                       on (fp.i_entidades = f.i_entidades
                      and fp.i_funcionarios = f.i_funcionarios
                      and fp.i_ferias = f.i_ferias)
                    where dc.i_entidades = fp.i_entidades
                      and dc.i_funcionarios = fp.i_funcionarios
                      and dc.i_tipos_proc = fp.i_tipos_proc
                      and dc.i_processamentos = fp.i_processamentos
                      and dc.i_competencias = fp.i_competencias);


-- CORREÇÃO
-- Deletar os registros da tabela dados_calc referente ao calculo de ferias sem registros na tabela ferias_proc e ferias

begin
    -- Caso positivo, excluir o registro da tabela movimentos.
  delete from bethadba.movimentos
  where movimentos.i_tipos_proc = 80
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where movimentos.i_entidades = fp.i_entidades
                        and movimentos.i_funcionarios = fp.i_funcionarios
                        and movimentos.i_tipos_proc = fp.i_tipos_proc
                        and movimentos.i_processamentos = fp.i_processamentos
                        and movimentos.i_competencias = fp.i_competencias);

  -- Caso positivo, excluir o registro da tabela dados_calc.
  delete from bethadba.dados_calc
  where dados_calc.i_tipos_proc = 80
    and dados_calc.dt_fechamento is not null
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where dados_calc.i_entidades = fp.i_entidades
                        and dados_calc.i_funcionarios = fp.i_funcionarios
                        and dados_calc.i_tipos_proc = fp.i_tipos_proc
                        and dados_calc.i_processamentos = fp.i_processamentos
                        and dados_calc.i_competencias = fp.i_competencias);

  -- Caso positivo, excluir o registro da tabela bases_calc.
  delete from bethadba.bases_calc
  where bases_calc.i_tipos_proc = 80
    and not exists (select 1 
                      from bethadba.ferias_proc as fp
                      left join bethadba.ferias as f
                        on (fp.i_entidades = f.i_entidades
                        and fp.i_funcionarios = f.i_funcionarios
                        and fp.i_ferias = f.i_ferias)
                      where bases_calc.i_entidades = fp.i_entidades
                        and bases_calc.i_funcionarios = fp.i_funcionarios
                        and bases_calc.i_tipos_proc = fp.i_tipos_proc
                        and bases_calc.i_processamentos = fp.i_processamentos
                        and bases_calc.i_competencias = fp.i_competencias);
end;