//VALIDAÇÃO 173

--173-afastamento 
--Afastamento de demissão com data de retorno. 

select a.i_entidades,
        a.i_funcionarios,
        a.dt_afastamento,
        a.dt_ultimo_dia
            from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 8 
            and a.i_entidades in (1)
            and a.dt_ultimo_dia is not null
            and exists (select first 1
            from bethadba.rescisoes r
            join bethadba.motivos_resc mr on r.i_motivos_resc = mr.i_motivos_resc
            join bethadba.tipos_afast ta2 on mr.i_tipos_afast = ta2.i_tipos_afast
            where r.i_entidades = a.i_entidades
            and r.i_funcionarios = a.i_funcionarios 
            and r.dt_canc_resc is null            
            and r.i_motivos_apos is null
            and r.dt_rescisao = a.dt_afastamento
            and ta2.classif = 8)
        order by i_entidades, i_funcionarios  asc
        
        
------
-- Atualiza os registros da tabela afastamentos deixando nulo a  coluna dt_ultimo_dia
call bethadba.dbp_conn_gera (1, year(today()), 300, 0);
call bethadba.pg_habilitartriggers('off');
update bethadba.afastamentos
set dt_ultimo_dia = null
where i_entidades in (1)
and dt_ultimo_dia is not null
and i_tipos_afast in (
    select a.i_tipos_afast
    from bethadba.afastamentos a
    join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
    where ta.classif = 8
    and a.i_entidades in (1)
    and a.dt_ultimo_dia is not null
    and exists (
        select FIRST 1
        from bethadba.rescisoes r
        join bethadba.motivos_resc mr on r.i_motivos_resc = mr.i_motivos_resc
        join bethadba.tipos_afast ta2 on mr.i_tipos_afast = ta2.i_tipos_afast
        where r.i_entidades = a.i_entidades
        and r.i_funcionarios = a.i_funcionarios
        and r.dt_canc_resc is null
        and r.i_motivos_apos is null
        and r.dt_rescisao = a.dt_afastamento
        and ta2.classif = 8
    )
);
