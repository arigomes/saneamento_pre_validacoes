-- VALIDAÇÃO 30
-- Busca as alterações de salário dos funcionários maior que a data de rescisão

select hs.i_funcionarios,
       hs.i_entidades,
       hs.dt_alteracoes,
       r.dt_rescisao,
       STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)) as dt_alteracoes_novo
  from bethadba.hist_salariais hs
 inner join bethadba.rescisoes r
    on (hs.i_funcionarios = r.i_funcionarios
   and hs.i_entidades = r.i_entidades)
 where hs.dt_alteracoes > STRING((select max(s.dt_rescisao) 
                                    from bethadba.rescisoes s 
                                    join bethadba.motivos_resc mr
                                      on (s.i_motivos_resc = mr.i_motivos_resc)
                                   where s.i_funcionarios = r.i_funcionarios 
                                     and s.i_entidades = r.i_entidades
                                     and s.dt_canc_resc is null
                                     and s.dt_reintegracao is null
                                     and mr.dispensados != 3), ' 23:59:59')
 order by hs.dt_alteracoes DESC;


-- CORREÇÃO
-- Alterar a data do campo hs.dt_alteracoes para um minuto após a última alteração dentro do mesmo mês da data do campo r.dt_rescisao sem gerar duplicidade

-- Cria a tabela temporária de minutos
create local temporary table minutos (n int);
insert into minutos
select row_num - 1
from sa_rowgenerator(1, 1440);

-- Atualiza a tabela de histórico salarial
update bethadba.hist_salariais hs
   set dt_alteracoes = (
      select min(dt_nova)
        from (
            select dateadd(minute, m.n, STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8))) as dt_nova
              from bethadba.rescisoes r2
             cross join minutos m
             where r2.i_funcionarios = hs.i_funcionarios
               and r2.i_entidades = hs.i_entidades
               and r2.dt_rescisao = r.dt_rescisao
               and not exists (
                   select 1
                     from bethadba.hist_salariais hsx
                    where hsx.i_funcionarios = hs.i_funcionarios
                      and hsx.i_entidades = hs.i_entidades
                      and hsx.dt_alteracoes = dateadd(minute, m.n, STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)))
               )
        ) as possiveis
    )
  from bethadba.rescisoes r
 where hs.i_entidades = r.i_entidades
   and hs.i_funcionarios = r.i_funcionarios
   and dt_alteracoes > STRING((select max(s.dt_rescisao) 
                      from bethadba.rescisoes s 
                      join bethadba.motivos_resc mr
                        on (s.i_motivos_resc = mr.i_motivos_resc)
                      where s.i_funcionarios = r.i_funcionarios 
                        and s.i_entidades = r.i_entidades
                        and s.dt_canc_resc is null
                        and s.dt_reintegracao is null
                        and mr.dispensados != 3), ' 23:59:59');

drop table minutos;

-- CORREÇÃO 2
-- Deleta os registros que ainda permanecem com data maior que a data de rescisão
delete bethadba.hist_salariais
  from bethadba.rescisoes r
 where hist_salariais.i_funcionarios = r.i_funcionarios
   and hist_salariais.i_entidades = r.i_entidades
   and hist_salariais.dt_alteracoes > STRING((select max(s.dt_rescisao) 
                                    from bethadba.rescisoes s 
                                    join bethadba.motivos_resc mr
                                      on (s.i_motivos_resc = mr.i_motivos_resc)
                                   where s.i_funcionarios = r.i_funcionarios 
                                     and s.i_entidades = r.i_entidades
                                     and s.dt_canc_resc is null
                                     and s.dt_reintegracao is null
                                     and mr.dispensados != 3), ' 23:59:59');

-- CORREÇÃO 3
-- Alternativa para atualização das datas que não foram atualizadas na primeira correção
begin
	declare w_i_entidades integer;
    declare w_competencias timestamp;
	
	llloop: for ll as meuloop1 dynamic scroll cursor for
        select hs.i_funcionarios as w_funcionario,
		       hs.i_entidades as w_i_entidade,
		       hs.dt_alteracoes as w_dt_alteracao,
		       r.dt_rescisao,
		       STRING(r.dt_rescisao, ' ', substring(hs.dt_alteracoes, 12, 8)) as dt_alteracoes_novo
		  from bethadba.hist_salariais hs
		 inner join bethadba.rescisoes r
		    on (hs.i_funcionarios = r.i_funcionarios
		   and hs.i_entidades = r.i_entidades)
		 where hs.dt_alteracoes > STRING((select max(s.dt_rescisao) 
		                                    from bethadba.rescisoes s 
		                                    join bethadba.motivos_resc mr
		                                      on (s.i_motivos_resc = mr.i_motivos_resc)
		                                   where s.i_funcionarios = r.i_funcionarios 
		                                     and s.i_entidades = r.i_entidades
		                                     and s.dt_canc_resc is null
		                                     and s.dt_reintegracao is null
		                                     and mr.dispensados != 3), ' 23:59:59')
		 order by hs.i_funcionarios, hs.dt_alteracoes DESC
	do		
		update bethadba.hist_salariais set dt_alteracoes = dt_alteracoes_novo where i_entidades = w_i_entidade and i_funcionarios = w_funcionario and dt_alteracoes = w_dt_alteracao;
	end for;
end;                                     