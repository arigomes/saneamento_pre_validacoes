-- VALIDAÇÃO 133
-- Verifica a existência de data de fechamento de cálculo da folha

select funcionarios.i_funcionarios,
       dados_calc.dt_fechamento
  from bethadba.dados_calc,
       bethadba.funcionarios 
 where dados_calc.i_entidades = funcionarios.i_entidades
   and dados_calc.i_funcionarios = funcionarios.i_funcionarios
   and dt_fechamento is null;


-- CORREÇÃO
-- Adiciona data de fechamento de cálculo da folha para as entidades que não possuem data de fechamento de cálculo da folha

update bethadba.dados_calc
   set dt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
 where dt_fechamento is null
   and i_competencias < '2099-12-01';