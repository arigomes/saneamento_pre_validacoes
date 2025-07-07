/*
 -- VALIDAÇÃO 172
 * Rescisão sem afastamento ou data divergente do afastamento com a rescisão.
 */

select r.i_entidades, 
                r.i_funcionarios, 
                r.dt_rescisao
        from bethadba.rescisoes r
        join bethadba.motivos_resc mr on r.i_motivos_resc = mr.i_motivos_resc
        join bethadba.tipos_afast ta2 on mr.i_tipos_afast = ta2.i_tipos_afast
        where r.i_entidades in (1,2,3,4)
        and ta2.classif = 8
        and r.i_motivos_apos is null
        and mr.dispensados <> 4
        and not exists(select 1 from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 8 
            and a.i_entidades = r.i_entidades
            and a.i_funcionarios = r.i_funcionarios 
            and a.dt_afastamento = r.dt_rescisao)      
        
    union all 

    select r.i_entidades, 
                r.i_funcionarios, 
                r.dt_rescisao
        from bethadba.rescisoes r
        join bethadba.motivos_apos mr on r.i_motivos_apos = mr.i_motivos_apos
        join bethadba.tipos_afast ta2 on mr.i_tipos_afast = ta2.i_tipos_afast
        where r.i_entidades in (1,2,3,4)
        and ta2.classif = 9
        and r.i_motivos_apos is not null
        and not exists(select 1 from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 9 
            and a.i_entidades = r.i_entidades
            and a.i_funcionarios = r.i_funcionarios 
            and a.dt_afastamento = r.dt_rescisao)      
        
    union all 

    select r.i_entidades, 
                r.i_funcionarios, 
                r.dt_rescisao
        from bethadba.rescisoes r
        join bethadba.motivos_apos mr on r.i_motivos_apos = mr.i_motivos_apos
        join bethadba.tipos_afast ta2 on mr.i_tipos_afast = ta2.i_tipos_afast
        where r.i_entidades in (1,2,3,4)
        and ta2.classif = 8
        and r.i_motivos_apos is not null
        and not exists(select 1 from bethadba.afastamentos a
            join bethadba.tipos_afast ta on a.i_tipos_afast = ta.i_tipos_afast
            where ta.classif = 8
            and a.i_entidades = r.i_entidades
            and a.i_funcionarios = r.i_funcionarios 
            and a.dt_afastamento = r.dt_rescisao)      
        order by i_funcionarios asc
          
 /*
 -- CORREÇÃO
 */ 
        

       	update bethadba.afastamentos 
        set dt_afastamento = x
        where i_funcionarios = y
        and dt_afastamento = z
        and i_tipos_afast = a
        