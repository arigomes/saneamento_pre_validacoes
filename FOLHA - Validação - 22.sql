-- VALIDAÇÃO 22 
-- Verifica as folha que não foram fechadas conforme competência passada por parâmetro

select i_entidades,
       i_competencias
  from bethadba.processamentos 
 where dt_fechamento is null;


-- CORREÇÃO
-- Atualiza a data de fechamento das folhas que não foram fechadas, adicionando a data de fechamento como o último dia do mês da competência

update bethadba.processamentos
   set dt_fechamento = dateformat(dateadd(dd, -DAY(i_competencias),dateadd(mm,1,i_competencias)),'yyyy-MM-dd')
 where dt_fechamento is null;