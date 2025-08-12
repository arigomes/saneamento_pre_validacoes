-- VALIDAÇÃO 26
-- Verifica se existe variáveis lançadas com data inicial ou final maior que a data de rescisão

select left(tab.data_afastamento, 8) || '01' as nova_data_final,
	   tab.dt_inicial,
	   tab.data_afastamento,
	   tab.dt_final,
	   *
  from (select a.i_entidades,
  			   a.i_funcionarios,
  			   coalesce(ta.classif, 1) as classif,
  			   max(a.dt_afastamento) as data_afastamento,
  			   f.conselheiro_tutelar,
  			   v.i_eventos,
  			   v.i_processamentos,
  			   v.i_tipos_proc,
  			   v.dt_inicial,
  			   v.dt_final 
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on (ta.i_tipos_afast = a.i_tipos_afast)
          join bethadba.funcionarios f
            on (f.i_entidades = a.i_entidades
           and f.i_funcionarios = a.i_funcionarios)
          left join bethadba.variaveis v
            on (v.i_entidades = a.i_entidades
           and v.i_funcionarios = a.i_funcionarios)
         where ta.classif = 8
           and a.dt_afastamento <= today()
           and isnull(a.dt_ultimo_dia, today()) >= today()
           and v.i_eventos is not null
           and f.conselheiro_tutelar = 'N'
         group by a.i_entidades, a.i_funcionarios, ta.classif, f.conselheiro_tutelar, v.i_eventos, v.i_processamentos, v.i_tipos_proc , v.dt_inicial , v.dt_final 
         order by a.i_entidades, a.i_funcionarios,  v.dt_inicial , v.dt_final ) as tab
 where tab.dt_inicial > tab.data_afastamento
    or tab.dt_final > tab.data_afastamento;


-- CORREÇÃO
-- Deleta as variáveis com data inicial maior que a data de rescisão
delete from bethadba.variaveis
 where exists (select 1
      			     from (select a.i_entidades,
      			 		    	        a.i_funcionarios,
      			 			            max(a.dt_afastamento) as data_afastamento
              			     from bethadba.afastamentos a
              			     join bethadba.tipos_afast ta
                		       on ta.i_tipos_afast = a.i_tipos_afast
             			      where ta.classif = 8
               			      and a.dt_afastamento <= today()
               			      and isnull(a.dt_ultimo_dia, today()) >= today()
             			      group by a.i_entidades, a.i_funcionarios) af
      			     join bethadba.funcionarios f
        		       on f.i_entidades = af.i_entidades
       			      and f.i_funcionarios = af.i_funcionarios
     			      where variaveis.i_entidades = af.i_entidades
       			      and variaveis.i_funcionarios = af.i_funcionarios
       			      and variaveis.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis.dt_inicial > af.data_afastamento);

-- Atualiza as variáveis com data final maior que a data de rescisão
update bethadba.variaveis
   set dt_final = cast(left(af.data_afastamento, 7) || '-01' as date)
  from (select a.i_entidades,
               a.i_funcionarios,
               max(a.dt_afastamento) as data_afastamento
          from bethadba.afastamentos a
          join bethadba.tipos_afast ta
            on ta.i_tipos_afast = a.i_tipos_afast
         where ta.classif = 8
           and a.dt_afastamento <= today()
           and isnull(a.dt_ultimo_dia, today()) >= today()
         group by a.i_entidades, a.i_funcionarios) af
  join bethadba.funcionarios f
    on f.i_entidades = af.i_entidades
   and f.i_funcionarios = af.i_funcionarios
 where variaveis.i_entidades = af.i_entidades
   and variaveis.i_funcionarios = af.i_funcionarios
   and variaveis.i_eventos is not null
   and f.conselheiro_tutelar = 'N'
   and variaveis.dt_final > af.data_afastamento;