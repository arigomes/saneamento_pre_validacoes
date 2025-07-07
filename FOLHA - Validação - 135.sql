/*
 -- VALIDAÇÃO 135
 * Verifica os lançamentos posteriores a data de cessação do aposentado
 */

select 
    hf.i_entidades as chave_dsk1,
    hf.i_funcionarios as chave_dsk2,
    r.dt_rescisao,
    sub.dt_rescisao as dataCessacao,
    v2.dt_inicial,
    v2.dt_final 
from 
    bethadba.hist_funcionarios hf
inner join 
    bethadba.hist_cargos hc on hf.i_entidades = hc.i_entidades 
                            and hf.i_funcionarios = hc.i_funcionarios 
                            and hf.dt_alteracoes <= hc.dt_alteracoes 
inner join
    bethadba.funcionarios f on f.i_funcionarios = hf.i_funcionarios 
                            and f.i_entidades = hf.i_entidades
inner join 
    bethadba.rescisoes r on r.i_funcionarios = hf.i_funcionarios 
                         and r.i_entidades = hf.i_entidades
inner join 
    bethadba.variaveis v2 on r.i_entidades = v2.i_entidades 
                           and r.i_funcionarios = v2.i_funcionarios 
inner join
    bethadba.vinculos v on v.i_vinculos = hf.i_vinculos
left join (
    select 
        resc.i_entidades,
        resc.i_funcionarios,
        max(resc.dt_rescisao) as dt_rescisao
    from 
        bethadba.rescisoes resc
    join 
        bethadba.motivos_resc mot on resc.i_motivos_resc = mot.i_motivos_resc
    where 
        mot.dispensados = 4
        and resc.dt_canc_resc is null
    group by 
        resc.i_entidades, resc.i_funcionarios
) as sub on hf.i_entidades = sub.i_entidades and hf.i_funcionarios = sub.i_funcionarios
where
    hf.i_entidades in (1,2,3,4) 
    and r.i_motivos_apos is not null 
    and sub.dt_rescisao is not null 
    and (sub.dt_rescisao < v2.dt_inicial or sub.dt_rescisao < v2.dt_final)
order by
    hf.i_entidades, hf.i_funcionarios;
          
/*
 -- CORREÇÃO
 */
                
delete bethadba.variaveis 
               where dt_inicial = '1990-09-01'
               and dt_final = '2999-12-01'
               and i_funcionarios = 27

