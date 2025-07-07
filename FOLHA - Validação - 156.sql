-- VALIDAÇÃO 156
-- Dependente com mais de uma configuração de IRRF

select i_dependentes,
	     count(i_dependentes) as total
  from (select distinct i_dependentes,
  						 dep_irrf
  		    from bethadba.dependentes_func df) as thd
 group by i_dependentes having total > 1;

-- CORREÇÃO

update bethadba.dependentes_func
   set dep_irrf = 'S'
 where i_dependentes in (select i_dependentes
                           from (select distinct i_dependentes,
                                                 dep_irrf
                                   from bethadba.dependentes_func) as thd
                          group by i_dependentes
                         having count(i_dependentes) > 1);