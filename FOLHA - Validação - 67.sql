-- VALIDAÇÃO 67
-- Funcionários com data de admissão após o inicio de gozo de férias

select funcionarios.dt_admissao,
       ferias.dt_gozo_ini,
       funcionarios.i_funcionarios
  from bethadba.funcionarios,
       bethadba.ferias
 where funcionarios.i_funcionarios = ferias.i_funcionarios
   and funcionarios.i_entidades = ferias.i_entidades
   and dt_admissao>dt_gozo_ini
   and ferias.num_dias_abono < ferias.saldo_dias
   and num_dias_abono is null;


-- CORREÇÃO
-- Exclui férias de funcionários com data de admissão posterior ao inicio do gozo de férias

delete from bethadba.ferias_proc
 where exists(select 1
                from bethadba.funcionarios, bethadba.ferias
               where funcionarios.i_entidades = ferias.i_entidades
                 and funcionarios.i_funcionarios = ferias.i_funcionarios
                 and ferias.dt_gozo_ini < funcionarios.dt_admissao
                 and ferias.num_dias_abono < ferias.saldo_dias
                 and ferias.i_ferias = ferias_proc.i_ferias
                 and ferias_proc.i_entidades = funcionarios.i_entidades
                 and ferias_proc.i_funcionarios = funcionarios.i_funcionarios);

delete from bethadba.ferias
 where dt_gozo_ini < (select dt_admissao
                        from bethadba.funcionarios
                       where funcionarios.i_entidades = ferias.i_entidades
                         and funcionarios.i_funcionarios = ferias.i_funcionarios)
   and ferias.num_dias_abono < ferias.saldo_dias;