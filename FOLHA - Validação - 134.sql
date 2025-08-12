-- VALIDAÇÃO 134
-- Verifica os lançamentos posteriores a rescisão

select hf.i_entidades as chave_dsk1,
       hf.i_funcionarios as chave_dsk2,
       r.dt_rescisao,
       v2.dt_inicial,
       v2.dt_final 
  from bethadba.hist_funcionarios hf
 inner join bethadba.hist_cargos hc
    on hf.i_entidades = hc.i_entidades
   and hf.i_funcionarios = hc.i_funcionarios
   and hf.dt_alteracoes <= hc.dt_alteracoes 
 inner join bethadba.funcionarios f
    on f.i_funcionarios = hf.i_funcionarios
   and f.i_entidades = hf.i_entidades
 inner join bethadba.rescisoes r
    on r.i_funcionarios = hf.i_funcionarios
   and r.i_entidades = hf.i_entidades
 inner join bethadba.variaveis v2
    on r.i_entidades = v2.i_entidades
   and r.i_funcionarios = v2.i_funcionarios 
 inner join bethadba.vinculos v
    on v.i_vinculos = hf.i_vinculos
 where (r.dt_rescisao < v2.dt_inicial or r.dt_rescisao < v2.dt_final)
   and r.i_motivos_apos is null
   and r.dt_canc_resc is null
   and r.i_rescisoes  = (select max(r.i_rescisoes)
                           from bethadba.rescisoes r
                          where r.i_entidades = f.i_entidades
                            and r.i_funcionarios = f.i_funcionarios
                            and r.dt_canc_resc is null
                            and r.i_motivos_apos is null)
 group by hf.i_entidades, hf.i_funcionarios, r.dt_rescisao, v2.dt_inicial, v2.dt_final 
 order by hf.i_entidades, hf.i_funcionarios;


-- CORREÇÃO
-- Deleta as variáveis com data inicial maior que a data de rescisão
delete from bethadba.variaveis
 where exists (select 1
      			     from (select r.i_entidades,
      			 		    	        r.i_funcionarios,
      			 			            max(r.dt_rescisao) as data_rescisao
                         from bethadba.rescisoes r
                        where r.i_entidades = variaveis.i_entidades
                          and r.i_funcionarios = variaveis.i_funcionarios
                          and r.dt_canc_resc is null
                          and r.i_motivos_apos is null
                        group by r.i_entidades, r.i_funcionarios) resc
      			     join bethadba.funcionarios f
        		       on f.i_entidades = resc.i_entidades
       			      and f.i_funcionarios = resc.i_funcionarios
     			      where variaveis.i_entidades = resc.i_entidades
       			      and variaveis.i_funcionarios = resc.i_funcionarios
       			      and variaveis.i_eventos is not null
       			      and f.conselheiro_tutelar = 'N'
       			      and variaveis.dt_inicial > resc.data_rescisao);

-- Atualiza as variáveis com data final maior que a data de rescisão
update bethadba.variaveis
   set dt_final = cast(left(resc.data_rescisao, 7) || '-01' as date)
  from (select r.i_entidades,
               r.i_funcionarios,
               max(r.dt_rescisao) as data_rescisao
          from bethadba.rescisoes r
         where r.dt_canc_resc is null
           and r.i_motivos_apos is null
         group by r.i_entidades, r.i_funcionarios) resc
 where variaveis.i_entidades = resc.i_entidades
   and variaveis.i_funcionarios = resc.i_funcionarios
   and variaveis.i_eventos is not null
   and variaveis.dt_final > resc.data_rescisao;