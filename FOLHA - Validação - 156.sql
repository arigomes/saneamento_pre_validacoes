-- VALIDAÇÃO 156
-- Dependente com mais de uma configuração de IRRF

select i_dependentes,
	     count(i_dependentes) as total
  from (select distinct i_dependentes,
  						 dep_irrf
  		    from bethadba.dependentes_func df) as thd
 group by i_dependentes having total > 1;

-- CORREÇÃO
-- Deletar duplicidade de dependentes com mais de uma configuração de IRRF quando o dependente for o mesmo

delete bethadba.dependentes_func
  from (select i_dependentes,
	   		   row_number() over (partition by i_dependentes order by i_dependentes) as rn
		  from (select distinct i_dependentes, dep_irrf
		  		  from bethadba.dependentes_func df) as thd
		 order by i_dependentes) as tab
 where tab.rn > 1
   and dependentes_func.i_dependentes = tab.i_dependentes;