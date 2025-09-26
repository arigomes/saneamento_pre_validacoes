-- VALIDAÇÃO 147
-- Calculo mensal sem movimentações

select dc.i_entidades,
       dc.i_funcionarios,
       dc.i_competencias,
       dc.i_processamentos,
       dc.i_tipos_proc,
       dc.dt_pagto,
       temRescisao = if exists (select 1 
                                  from bethadba.movimentos as m
                                 where m.i_entidades = dc.i_entidades
                                   and m.i_funcionarios = dc.i_funcionarios
                                   and m.i_tipos_proc = dc.i_tipos_proc
                                   and m.i_processamentos = dc.i_processamentos
                                   and m.i_competencias = dc.i_competencias
                                   and m.mov_resc = 'S') then 'S' else 'N' endif
  from bethadba.dados_calc as dc
 where dc.i_tipos_proc in (11, 41, 42)
   and dc.dt_fechamento is not null
   and temRescisao = 'N'
   and not exists (select 1
                     from bethadba.movimentos as m 
                    where m.i_funcionarios = dc.i_funcionarios
                      and m.i_entidades = dc.i_entidades
                      and m.i_tipos_proc = dc.i_tipos_proc
                      and m.i_processamentos = dc.i_processamentos
                      and m.i_competencias = dc.i_competencias
                      and m.mov_resc = 'N');


-- CORREÇÃO
-- Verificar se o funcionário realmente não possui movimentações no período.

begin

  -- Caso positivo, excluir o registro da tabela periodos_calculo_fecha.
  delete 
    from bethadba.periodos_calculo_fecha
   where periodos_calculo_fecha.i_tipos_proc in (11, 41, 42)
     and not exists (select 1
                       from bethadba.movimentos as m 
                      where m.i_funcionarios = periodos_calculo_fecha.i_funcionarios
                        and m.i_entidades = periodos_calculo_fecha.i_entidades
                        and m.i_tipos_proc = periodos_calculo_fecha.i_tipos_proc
                        and m.i_processamentos = periodos_calculo_fecha.i_processamentos
                        and m.i_competencias = periodos_calculo_fecha.i_competencias);
	
  -- Caso positivo, excluir o registro da tabela bases_calc.
  delete 
    from bethadba.bases_calc
   where bases_calc.i_tipos_proc in (11, 41, 42)
     and not exists (select 1
                       from bethadba.movimentos as m 
                       where m.i_funcionarios = bases_calc.i_funcionarios
                         and m.i_entidades = bases_calc.i_entidades
                         and m.i_tipos_proc = bases_calc.i_tipos_proc
                         and m.i_processamentos = bases_calc.i_processamentos
                         and m.i_competencias = bases_calc.i_competencias);

  -- Caso positivo, excluir o registro da tabela dados_calc.
  delete
    from bethadba.dados_calc
   where dados_calc.i_tipos_proc in (11, 41, 42)
     and dados_calc.dt_fechamento is not null
     and not exists (select 1
                       from bethadba.movimentos as m 
                      where m.i_funcionarios = dados_calc.i_funcionarios
                        and m.i_entidades = dados_calc.i_entidades
                        and m.i_tipos_proc = dados_calc.i_tipos_proc
                        and m.i_processamentos = dados_calc.i_processamentos
                        and m.i_competencias = dados_calc.i_competencias);

end;